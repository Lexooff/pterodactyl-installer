#!/bin/bash
#
#  VyroHost — Script de déploiement distant (à exécuter depuis TON PC)
#
#  Ce script se connecte en SSH au serveur du client,
#  télécharge l'installeur VyroHost et le lance automatiquement.
#
#  Usage:
#    ./deploy.sh                     → Mode interactif (demande IP, user, etc.)
#    ./deploy.sh 192.168.1.100       → Connexion rapide en root
#    ./deploy.sh user@192.168.1.100  → Connexion avec user spécifique
#    ./deploy.sh -k ~/.ssh/id_rsa 192.168.1.100  → Avec clé SSH
#

set -e

# ─── Couleurs ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Config ───
# URL du script d'installation (à modifier avec votre repo)
REPO_URL="https://raw.githubusercontent.com/Lexooff/pterodactyl-installer/main"
BOOTSTRAP_URL="${REPO_URL}/bootstrap.sh"
INSTALL_URL="${REPO_URL}/install.sh"

# ─── Variables ───
SSH_HOST=""
SSH_USER="root"
SSH_PORT="22"
SSH_KEY=""
SSH_PASSWORD=""
USE_PASSWORD=false

# ─── Fonctions ───

print_banner() {
    clear
    echo -e "${PURPLE}"
    echo -e "  ██╗   ██╗██╗   ██╗██████╗  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗"
    echo -e "  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔═══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
    echo -e "  ██║   ██║ ╚████╔╝ ██████╔╝██║   ██║███████║██║   ██║███████╗   ██║   "
    echo -e "  ╚██╗ ██╔╝  ╚██╔╝  ██╔══██╗██║   ██║██╔══██║██║   ██║╚════██║   ██║   "
    echo -e "   ╚████╔╝    ██║   ██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║   ██║   "
    echo -e "    ╚═══╝     ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝"
    echo -e "${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${CYAN}${BOLD}           Déploiement distant — Staff Tool${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() { echo -e "  ${GREEN}✔${NC} ${GREEN}$1${NC}"; }
print_error()   { echo -e "  ${RED}✘${NC} ${RED}$1${NC}"; }
print_info()    { echo -e "  ${BLUE}ℹ${NC} ${BLUE}$1${NC}"; }
print_warn()    { echo -e "  ${YELLOW}⚠${NC} ${YELLOW}$1${NC}"; }

usage() {
    echo -e "  ${WHITE}${BOLD}Usage:${NC}"
    echo -e "    ${CYAN}./deploy.sh${NC}                           ${DIM}Mode interactif${NC}"
    echo -e "    ${CYAN}./deploy.sh${NC} ${WHITE}IP${NC}                        ${DIM}Connexion rapide (root@IP)${NC}"
    echo -e "    ${CYAN}./deploy.sh${NC} ${WHITE}user@IP${NC}                   ${DIM}Avec user spécifique${NC}"
    echo -e "    ${CYAN}./deploy.sh -p${NC} ${WHITE}PORT IP${NC}               ${DIM}Port SSH custom${NC}"
    echo -e "    ${CYAN}./deploy.sh -k${NC} ${WHITE}~/.ssh/key IP${NC}         ${DIM}Avec clé SSH${NC}"
    echo -e "    ${CYAN}./deploy.sh -pw${NC} ${WHITE}IP${NC}                   ${DIM}Demander mot de passe${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}Options:${NC}"
    echo -e "    ${YELLOW}-p PORT${NC}     Port SSH (défaut: 22)"
    echo -e "    ${YELLOW}-k KEY${NC}      Chemin vers la clé SSH"
    echo -e "    ${YELLOW}-pw${NC}         Utiliser un mot de passe"
    echo -e "    ${YELLOW}-h${NC}          Afficher cette aide"
    echo ""
}

# ─── Parse des arguments ───
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                SSH_PORT="$2"
                shift 2
                ;;
            -k|--key)
                SSH_KEY="$2"
                shift 2
                ;;
            -pw|--password)
                USE_PASSWORD=true
                shift
                ;;
            -h|--help)
                print_banner
                usage
                exit 0
                ;;
            *)
                # C'est soit user@host soit juste host
                if [[ "$1" == *"@"* ]]; then
                    SSH_USER="${1%%@*}"
                    SSH_HOST="${1#*@}"
                else
                    SSH_HOST="$1"
                fi
                shift
                ;;
        esac
    done
}

# ─── Mode interactif ───
interactive_mode() {
    echo -e "  ${WHITE}${BOLD}Informations de connexion SSH${NC}"
    echo ""
    
    # IP / Hostname
    echo -ne "  ${CYAN}➜${NC} IP ou hostname du serveur: "
    read -r SSH_HOST
    if [ -z "$SSH_HOST" ]; then
        print_error "IP requise !"
        exit 1
    fi

    # User
    echo -ne "  ${CYAN}➜${NC} Utilisateur SSH ${DIM}[root]${NC}: "
    read -r input
    SSH_USER=${input:-root}

    # Port
    echo -ne "  ${CYAN}➜${NC} Port SSH ${DIM}[22]${NC}: "
    read -r input
    SSH_PORT=${input:-22}

    # Méthode d'auth
    echo ""
    echo -e "  ${WHITE}${BOLD}Méthode d'authentification :${NC}"
    echo -e "  ${DIM}  [1]${NC} Clé SSH ${GREEN}(recommandé)${NC}"
    echo -e "  ${DIM}  [2]${NC} Mot de passe"
    echo -e "  ${DIM}  [3]${NC} Agent SSH (ssh-agent)"
    echo ""
    echo -ne "  ${CYAN}➜${NC} Votre choix ${DIM}[3]${NC}: "
    read -r auth_choice
    auth_choice=${auth_choice:-3}

    case "$auth_choice" in
        1)
            echo -ne "  ${CYAN}➜${NC} Chemin de la clé SSH ${DIM}[~/.ssh/id_rsa]${NC}: "
            read -r input
            SSH_KEY=${input:-~/.ssh/id_rsa}
            if [ ! -f "$SSH_KEY" ]; then
                print_error "Clé SSH introuvable: $SSH_KEY"
                exit 1
            fi
            ;;
        2)
            USE_PASSWORD=true
            ;;
        3)
            # Agent SSH, pas de config supplémentaire
            ;;
    esac
}

# ─── Construction de la commande SSH ───
build_ssh_cmd() {
    local cmd="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10"
    cmd+=" -p ${SSH_PORT}"
    
    if [ -n "$SSH_KEY" ]; then
        cmd+=" -i ${SSH_KEY}"
    fi

    cmd+=" ${SSH_USER}@${SSH_HOST}"
    echo "$cmd"
}

# ─── Test de connexion ───
test_connection() {
    echo ""
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}${BOLD}Test de connexion...${NC}"
    echo ""

    local ssh_cmd=$(build_ssh_cmd)

    if $USE_PASSWORD; then
        # Vérifier que sshpass est installé
        if ! command -v sshpass &>/dev/null; then
            print_warn "sshpass n'est pas installé (nécessaire pour l'auth par mot de passe)"
            print_info "Installation: sudo apt install sshpass  /  brew install sshpass"
            echo ""
            echo -ne "  ${CYAN}➜${NC} Mot de passe SSH: "
            read -rs SSH_PASSWORD
            echo ""
            print_warn "Connexion manuelle SSH (sshpass non disponible)"
            print_info "Le script va ouvrir une session SSH interactive"
            echo ""
            
            echo -e "  ${YELLOW}Copiez-collez cette commande une fois connecté :${NC}"
            echo ""
            echo -e "  ${WHITE}bash <(curl -fsSL ${INSTALL_URL})${NC}"
            echo ""
            echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -ne "  ${CYAN}➜${NC} Appuyez sur Entrée pour ouvrir SSH..."
            read -r
            $ssh_cmd
            return $?
        fi
        
        echo -ne "  ${CYAN}➜${NC} Mot de passe SSH: "
        read -rs SSH_PASSWORD
        echo ""
        
        if sshpass -p "$SSH_PASSWORD" $ssh_cmd "echo connected" &>/dev/null; then
            print_success "Connexion réussie à ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
        else
            print_error "Impossible de se connecter à ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
            exit 1
        fi
    else
        if $ssh_cmd "echo connected" &>/dev/null; then
            print_success "Connexion réussie à ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
        else
            print_error "Impossible de se connecter à ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
            echo -e "  ${DIM}Vérifiez : IP, port, clé SSH, utilisateur${NC}"
            exit 1
        fi
    fi
}

# ─── Vérifications distantes ───
check_remote_server() {
    echo ""
    echo -e "  ${WHITE}${BOLD}Vérification du serveur distant...${NC}"
    echo ""

    local ssh_cmd=$(build_ssh_cmd)
    local ssh_exec=""
    
    if $USE_PASSWORD && command -v sshpass &>/dev/null; then
        ssh_exec="sshpass -p '$SSH_PASSWORD' $ssh_cmd"
    else
        ssh_exec="$ssh_cmd"
    fi

    # OS
    local remote_os=$(eval "$ssh_exec" "cat /etc/os-release 2>/dev/null | grep '^PRETTY_NAME' | cut -d'\"' -f2" 2>/dev/null)
    echo -e "  ${DIM}├─${NC} OS: ${WHITE}${remote_os:-Inconnu}${NC}"

    # RAM
    local remote_ram=$(eval "$ssh_exec" "free -m 2>/dev/null | awk '/^Mem:/{print \$2}'" 2>/dev/null)
    echo -e "  ${DIM}├─${NC} RAM: ${WHITE}${remote_ram:-?} MB${NC}"

    # Disque
    local remote_disk=$(eval "$ssh_exec" "df -BG / 2>/dev/null | awk 'NR==2{print \$4}'" 2>/dev/null)
    echo -e "  ${DIM}├─${NC} Disque libre: ${WHITE}${remote_disk:-?}${NC}"

    # CPU
    local remote_cpu=$(eval "$ssh_exec" "nproc 2>/dev/null" 2>/dev/null)
    echo -e "  ${DIM}├─${NC} CPU: ${WHITE}${remote_cpu:-?} cœur(s)${NC}"

    # Vérifier si Pterodactyl est déjà installé
    local ptero_exists=$(eval "$ssh_exec" "test -d /var/www/pterodactyl && echo 'yes' || echo 'no'" 2>/dev/null)
    if [ "$ptero_exists" = "yes" ]; then
        echo -e "  ${DIM}└─${NC} Pterodactyl: ${YELLOW}DÉJÀ INSTALLÉ${NC}"
        echo ""
        print_warn "Pterodactyl semble déjà installé sur ce serveur !"
        echo -ne "  ${CYAN}➜${NC} Continuer quand même ? ${DIM}[o/N]${NC} "
        read -r response
        if [[ ! "$response" =~ ^[OoYy]$ ]]; then
            print_info "Déploiement annulé"
            exit 0
        fi
    else
        echo -e "  ${DIM}└─${NC} Pterodactyl: ${GREEN}Non installé${NC}"
    fi

    # Vérifier root
    local is_root=$(eval "$ssh_exec" "whoami" 2>/dev/null)
    if [ "$is_root" != "root" ]; then
        print_warn "Connecté en tant que '${is_root}', pas root"
        print_info "Le script utilisera sudo automatiquement"
    fi
}

# ─── Déploiement ───
deploy() {
    echo ""
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}${BOLD}Déploiement de l'installeur VyroHost${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -ne "  ${CYAN}➜${NC} Prêt à déployer sur ${WHITE}${SSH_USER}@${SSH_HOST}${NC}. Continuer ? ${DIM}[O/n]${NC} "
    read -r response
    response=${response:-o}
    if [[ ! "$response" =~ ^[OoYy]$ ]]; then
        print_info "Déploiement annulé"
        exit 0
    fi

    echo ""

    local ssh_cmd=$(build_ssh_cmd)
    local ssh_exec=""

    if $USE_PASSWORD && command -v sshpass &>/dev/null; then
        ssh_exec="sshpass -p '$SSH_PASSWORD' $ssh_cmd"
    else
        ssh_exec="$ssh_cmd"
    fi

    # Choix du mode de déploiement
    echo -e "  ${WHITE}${BOLD}Mode de déploiement :${NC}"
    echo -e "  ${DIM}  [1]${NC} Automatique ${GREEN}(télécharge et lance directement)${NC}"
    echo -e "  ${DIM}  [2]${NC} Interactif ${DIM}(ouvre un SSH et tu lances manuellement)${NC}"
    echo ""
    echo -ne "  ${CYAN}➜${NC} Votre choix ${DIM}[1]${NC}: "
    read -r deploy_mode
    deploy_mode=${deploy_mode:-1}

    echo ""

    if [ "$deploy_mode" = "2" ]; then
        # ─── Mode interactif : ouvre SSH avec commande prête ───
        print_info "Ouverture de la session SSH..."
        print_info "Le script sera téléchargé automatiquement. Lancez-le avec :"
        echo ""
        echo -e "  ${WHITE}${BOLD}bash /tmp/vyrohost-install.sh${NC}"
        echo ""
        echo -e "  ${DIM}Ou pour tout faire en une commande :${NC}"
        echo -e "  ${WHITE}bash <(curl -fsSL ${INSTALL_URL})${NC}"
        echo ""
        echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -ne "  Appuyez sur Entrée pour ouvrir SSH..."
        read -r

        # Télécharger le script puis ouvrir la session interactive
        eval "$ssh_exec" "curl -fsSL '${INSTALL_URL}' -o /tmp/vyrohost-install.sh && chmod +x /tmp/vyrohost-install.sh && echo '✔ Script prêt: /tmp/vyrohost-install.sh'" 2>/dev/null

        # Ouvrir la session SSH interactive
        if $USE_PASSWORD && command -v sshpass &>/dev/null; then
            sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" ${SSH_KEY:+-i "$SSH_KEY"} "${SSH_USER}@${SSH_HOST}"
        else
            ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" ${SSH_KEY:+-i "$SSH_KEY"} "${SSH_USER}@${SSH_HOST}"
        fi
    else
        # ─── Mode automatique : lance le script directement ───
        print_info "Lancement de l'installation à distance..."
        print_info "La session SSH interactive va s'ouvrir avec l'installeur"
        echo ""
        
        # On ouvre une session SSH interactive qui télécharge et lance le script
        if $USE_PASSWORD && command -v sshpass &>/dev/null; then
            sshpass -p "$SSH_PASSWORD" ssh -t -o StrictHostKeyChecking=no -p "$SSH_PORT" ${SSH_KEY:+-i "$SSH_KEY"} "${SSH_USER}@${SSH_HOST}" \
                "curl -fsSL '${INSTALL_URL}' -o /tmp/vyrohost-install.sh && chmod +x /tmp/vyrohost-install.sh && bash /tmp/vyrohost-install.sh; rm -f /tmp/vyrohost-install.sh"
        else
            ssh -t -o StrictHostKeyChecking=no -p "$SSH_PORT" ${SSH_KEY:+-i "$SSH_KEY"} "${SSH_USER}@${SSH_HOST}" \
                "curl -fsSL '${INSTALL_URL}' -o /tmp/vyrohost-install.sh && chmod +x /tmp/vyrohost-install.sh && bash /tmp/vyrohost-install.sh; rm -f /tmp/vyrohost-install.sh"
        fi
    fi

    local exit_code=$?

    echo ""
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ $exit_code -eq 0 ]; then
        echo ""
        print_success "Session SSH terminée"
        echo ""
        echo -e "  ${WHITE}${BOLD}Commandes utiles post-installation :${NC}"
        echo -e "  ${DIM}├─${NC} ${YELLOW}ssh ${SSH_USER}@${SSH_HOST} -p ${SSH_PORT}${NC}       → Se reconnecter"
        echo -e "  ${DIM}├─${NC} ${YELLOW}cat /root/.vyrohost-credentials${NC}  → Voir les identifiants"
        echo -e "  ${DIM}└─${NC} ${YELLOW}systemctl status wings pteroq${NC}    → Vérifier les services"
    else
        print_error "La session SSH s'est terminée avec une erreur (code: $exit_code)"
    fi
    echo ""
}

# ─── Point d'entrée ───

# Parser les arguments si fournis
parse_args "$@"

print_banner

# Si pas d'host, mode interactif
if [ -z "$SSH_HOST" ]; then
    interactive_mode
fi

# Résumé de connexion
echo ""
echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${WHITE}${BOLD}Connexion :${NC} ${CYAN}${SSH_USER}@${SSH_HOST}:${SSH_PORT}${NC}"
if [ -n "$SSH_KEY" ]; then
    echo -e "  ${WHITE}${BOLD}Auth :${NC}      ${WHITE}Clé SSH (${SSH_KEY})${NC}"
elif $USE_PASSWORD; then
    echo -e "  ${WHITE}${BOLD}Auth :${NC}      ${WHITE}Mot de passe${NC}"
else
    echo -e "  ${WHITE}${BOLD}Auth :${NC}      ${WHITE}Agent SSH${NC}"
fi
echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

test_connection
check_remote_server
deploy
