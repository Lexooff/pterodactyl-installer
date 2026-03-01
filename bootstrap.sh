#!/bin/bash
#
#  ██╗   ██╗██╗   ██╗██████╗  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
#  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔═══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
#  ██║   ██║ ╚████╔╝ ██████╔╝██║   ██║███████║██║   ██║███████╗   ██║
#  ╚██╗ ██╔╝  ╚██╔╝  ██╔══██╗██║   ██║██╔══██║██║   ██║╚════██║   ██║
#   ╚████╔╝    ██║   ██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║   ██║
#    ╚═══╝     ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
#
#  VyroHost — Remote Bootstrap Loader
#  Ce script télécharge et lance l'installeur Pterodactyl à distance
#
#  Usage: bash <(curl -s https://raw.githubusercontent.com/VyroHost/pterodactyl-installer/main/bootstrap.sh)
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
# ╔═══════════════════════════════════════════════════════════════════╗
# ║  MODIFIEZ CETTE URL AVEC VOTRE REPO GITHUB OU VOTRE SERVEUR    ║
# ╚═══════════════════════════════════════════════════════════════════╝
REPO_URL="https://raw.githubusercontent.com/Lexooff/pterodactyl-installer/main"
INSTALL_SCRIPT_URL="${REPO_URL}/install.sh"
INSTALL_DIR="/tmp/vyrohost-installer"
SCRIPT_PATH="${INSTALL_DIR}/install.sh"
VERSION_URL="${REPO_URL}/version.txt"

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
    echo -e "  ${CYAN}${BOLD}             Remote Installer — Bootstrap Loader${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_requirements() {
    # Root check
    if [ "$EUID" -ne 0 ]; then
        echo -e "  ${RED}✘ Ce script doit être exécuté en tant que root !${NC}"
        echo -e "  ${DIM}  Utilisez: sudo bash bootstrap.sh${NC}"
        echo -e "  ${DIM}  Ou:       bash <(curl -s ${INSTALL_SCRIPT_URL})${NC}"
        exit 1
    fi

    # Vérifier curl ou wget
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
    else
        echo -e "  ${RED}✘ curl ou wget requis !${NC}"
        echo -e "  ${DIM}  Installation: apt install curl -y${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}✔${NC} Downloader: ${WHITE}${DOWNLOADER}${NC}"
}

download_file() {
    local url=$1
    local dest=$2
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url" -o "$dest" 2>/dev/null
    else
        wget -qO "$dest" "$url" 2>/dev/null
    fi
}

download_installer() {
    echo -e "  ${CYAN}➜${NC} Téléchargement de l'installeur VyroHost..."
    
    mkdir -p "$INSTALL_DIR"

    # Télécharger le script principal
    if download_file "$INSTALL_SCRIPT_URL" "$SCRIPT_PATH"; then
        chmod +x "$SCRIPT_PATH"
        echo -e "  ${GREEN}✔${NC} Script téléchargé avec succès"
    else
        echo -e "  ${RED}✘ Impossible de télécharger le script !${NC}"
        echo -e "  ${DIM}  URL: ${INSTALL_SCRIPT_URL}${NC}"
        echo -e ""
        echo -e "  ${YELLOW}⚠ Vérifiez :${NC}"
        echo -e "  ${DIM}  • Connexion internet du serveur${NC}"
        echo -e "  ${DIM}  • L'URL du repo est correcte${NC}"
        echo -e "  ${DIM}  • Le repo GitHub est public (ou le token est valide)${NC}"
        exit 1
    fi

    # Vérifier la version distante (optionnel)
    local remote_version=""
    if download_file "$VERSION_URL" "/tmp/vyrohost-version.txt" 2>/dev/null; then
        remote_version=$(cat /tmp/vyrohost-version.txt 2>/dev/null)
        rm -f /tmp/vyrohost-version.txt
        if [ -n "$remote_version" ]; then
            echo -e "  ${GREEN}✔${NC} Version: ${WHITE}${remote_version}${NC}"
        fi
    fi
}

launch_installer() {
    echo ""
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}${BOLD}  Lancement de l'installeur...${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 1

    # Lancer le script principal
    bash "$SCRIPT_PATH"
    local exit_code=$?

    # Nettoyage
    rm -rf "$INSTALL_DIR"

    return $exit_code
}

# ─── Point d'entrée ───
print_banner
check_requirements
download_installer
launch_installer
