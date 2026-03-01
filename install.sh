#!/bin/bash
#
#  ██╗   ██╗██╗   ██╗██████╗  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
#  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔═══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
#  ██║   ██║ ╚████╔╝ ██████╔╝██║   ██║███████║██║   ██║███████╗   ██║
#  ╚██╗ ██╔╝  ╚██╔╝  ██╔══██╗██║   ██║██╔══██║██║   ██║╚════██║   ██║
#   ╚████╔╝    ██║   ██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║   ██║
#    ╚═══╝     ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
#
#  Script d'installation Pterodactyl - VyroHost Staff Tool
#  Version: 2.0.0
#  Auteur: VyroHost Team
#

# ============================================================================
#                              COULEURS & STYLES
# ============================================================================
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

# Caractères spéciaux
CHECK="${GREEN}✔${NC}"
CROSS="${RED}✘${NC}"
ARROW="${CYAN}➜${NC}"
STAR="${YELLOW}★${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"

# ============================================================================
#                              VARIABLES GLOBALES
# ============================================================================
PTERO_PANEL_VERSION="1.11.9"
WINGS_VERSION="1.11.13"
FQDN=""
EMAIL=""
DB_PASSWORD=""
ADMIN_EMAIL=""
ADMIN_USERNAME=""
ADMIN_FIRSTNAME=""
ADMIN_LASTNAME=""
ADMIN_PASSWORD=""
MYSQL_ROOT_PASSWORD=""
OS=""
OS_VERSION=""
ARCH=$(uname -m)
PHP_VERSION="8.3"
WEBSERVER=""
INSTALL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/var/backups/pterodactyl"
LOG_FILE="/var/log/vyrohost-installer.log"
PHPMYADMIN_VERSION="5.2.1"
USE_SSL=true

# ============================================================================
#                              FONCTIONS UTILITAIRES
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo -e "  ██╗   ██╗██╗   ██╗██████╗  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗"
    echo -e "  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔═══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
    echo -e "  ██║   ██║ ╚████╔╝ ██████╔╝██║   ██║███████║██║   ██║███████╗   ██║   "
    echo -e "  ╚██╗ ██╔╝  ╚██╔╝  ██╔══██╗██║   ██║██╔══██║██║   ██║╚════██║   ██║   "
    echo -e "   ╚████╔╝    ██║   ██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║   ██║   "
    echo -e "    ╚═══╝     ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝"
    echo -e "${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${CYAN}${BOLD}       Pterodactyl Installer — Staff Tool v2.0.0${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "  ${CHECK} ${GREEN}$1${NC}"
    log "[SUCCESS] $1"
}

print_error() {
    echo -e "  ${CROSS} ${RED}$1${NC}"
    log "[ERROR] $1"
}

print_warning() {
    echo -e "  ${WARN} ${YELLOW}$1${NC}"
    log "[WARNING] $1"
}

print_info() {
    echo -e "  ${INFO} ${BLUE}$1${NC}"
    log "[INFO] $1"
}

print_step() {
    echo -e "\n  ${ARROW} ${WHITE}${BOLD}$1${NC}"
    log "[STEP] $1"
}

print_separator() {
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${NC}"
}

spinner() {
    local pid=$1
    local msg=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spinstr:$i:1}"
        echo -ne "\r  ${BLUE}${char}${NC} ${msg}"
        i=$(( (i + 1) % ${#spinstr} ))
        sleep 0.1
    done
    echo -ne "\r"
}

confirm() {
    local msg=$1
    local default=${2:-"o"}
    if [ "$default" = "o" ]; then
        echo -ne "  ${ARROW} ${msg} ${DIM}[O/n]${NC} "
    else
        echo -ne "  ${ARROW} ${msg} ${DIM}[o/N]${NC} "
    fi
    read -r response
    response=${response:-$default}
    [[ "$response" =~ ^[OoYy]$ ]]
}

input_prompt() {
    local msg=$1
    local default=$2
    local var_name=$3
    if [ -n "$default" ]; then
        echo -ne "  ${ARROW} ${msg} ${DIM}[$default]${NC}: "
    else
        echo -ne "  ${ARROW} ${msg}: "
    fi
    read -r input
    input=${input:-$default}
    eval "$var_name='$input'"
}

password_prompt() {
    local msg=$1
    local var_name=$2
    echo -ne "  ${ARROW} ${msg}: "
    read -rs input
    echo ""
    eval "$var_name='$input'"
}

random_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%' | head -c 24
}

# Retourne "https" ou "http" selon USE_SSL
get_panel_scheme() {
    [ "$USE_SSL" = true ] && echo "https" || echo "http"
}

# Retourne l'URL PHPMyAdmin selon le mode SSL
# Retourne l'URL PHPMyAdmin (sous-dossier /phpmyadmin du panel)
get_pma_url() {
    local scheme=$(get_panel_scheme)
    echo "${scheme}://${FQDN}/phpmyadmin"
}

# Crée le service systemd Wings (réutilisé dans install_wings et install_node_only)
create_wings_service() {
    cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
}

# Installe Docker si nécessaire (réutilisé dans install_wings et install_node_only)
ensure_docker() {
    if ! command -v docker &>/dev/null; then
        curl -sSL https://get.docker.com/ | CHANNEL=stable bash >> "$LOG_FILE" 2>&1 &
        spinner $! "Installation de Docker..."
        systemctl enable --now docker >> "$LOG_FILE" 2>&1
        print_success "Docker installé"
    else
        print_info "Docker déjà installé"
    fi
}

# Télécharge et installe le binaire Wings (réutilisé)
download_wings() {
    mkdir -p /etc/pterodactyl
    curl -Lo /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}" >> "$LOG_FILE" 2>&1 &
    spinner $! "Téléchargement de Wings..."
    chmod u+x /usr/local/bin/wings
    print_success "Wings téléchargé"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r  ${BLUE}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC} ${WHITE}${BOLD}%3d%%${NC}" "$percentage"
}

# ============================================================================
#                              DÉTECTION SYSTÈME
# ============================================================================

detect_os() {
    print_step "Détection du système d'exploitation..."

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
    else
        print_error "Système d'exploitation non supporté !"
        exit 1
    fi

    case "$OS" in
        ubuntu)
            case "$OS_VERSION" in
                20.04|22.04|24.04) ;;
                *)
                    print_warning "Ubuntu $OS_VERSION n'est pas officiellement supporté"
                    if ! confirm "Continuer quand même ?" "n"; then
                        exit 1
                    fi
                    ;;
            esac
            ;;
        debian)
            case "$OS_VERSION" in
                11|12) ;;
                *)
                    print_warning "Debian $OS_VERSION n'est pas officiellement supporté"
                    if ! confirm "Continuer quand même ?" "n"; then
                        exit 1
                    fi
                    ;;
            esac
            ;;
        centos|rocky|almalinux|rhel)
            case "$OS_VERSION" in
                8*|9*) ;;
                *)
                    print_warning "$OS $OS_VERSION n'est pas officiellement supporté"
                    if ! confirm "Continuer quand même ?" "n"; then
                        exit 1
                    fi
                    ;;
            esac
            ;;
        *)
            print_error "OS non supporté: $OS"
            exit 1
            ;;
    esac

    print_success "OS détecté: ${BOLD}$OS $OS_VERSION${NC} ${GREEN}($ARCH)${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Ce script doit être exécuté en tant que root !"
        echo -e "  ${DIM}Utilisez: sudo bash install.sh${NC}"
        exit 1
    fi
}

check_resources() {
    print_step "Vérification des ressources système..."

    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    local disk_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
    local cpu_cores=$(nproc)

    echo -e "  ${DIM}├─${NC} RAM: ${WHITE}${ram_mb} MB${NC}"
    echo -e "  ${DIM}├─${NC} Disque libre: ${WHITE}${disk_gb} GB${NC}"
    echo -e "  ${DIM}└─${NC} CPU: ${WHITE}${cpu_cores} cœur(s)${NC}"

    if [ "$ram_mb" -lt 1024 ]; then
        print_warning "Moins de 1 GB de RAM détecté. Pterodactyl recommande au minimum 2 GB."
        if ! confirm "Continuer malgré les ressources limitées ?" "n"; then
            exit 1
        fi
    fi

    if [ "$disk_gb" -lt 5 ]; then
        print_error "Espace disque insuffisant (minimum 5 GB requis)"
        exit 1
    fi

    print_success "Ressources système suffisantes"
}

# ============================================================================
#                          INSTALLATION DES DÉPENDANCES
# ============================================================================

install_dependencies_debian() {
    print_step "Installation des dépendances (apt)..."

    apt update -y >> "$LOG_FILE" 2>&1 &
    spinner $! "Mise à jour des paquets..."
    print_success "Paquets mis à jour"

    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation des pré-requis..."
    print_success "Pré-requis installés"

    # Ajout du repo PHP
    if [ "$OS" = "ubuntu" ]; then
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php >> "$LOG_FILE" 2>&1 &
        spinner $! "Ajout du dépôt PHP..."
    else
        curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg >> "$LOG_FILE" 2>&1
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list
    fi

    # Ajout du repo MariaDB
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash >> "$LOG_FILE" 2>&1 &
    spinner $! "Ajout du dépôt MariaDB..."
    print_success "Dépôts ajoutés"

    apt update -y >> "$LOG_FILE" 2>&1

    # Installation PHP et extensions
    apt install -y php${PHP_VERSION} php${PHP_VERSION}-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,sqlite3,tokenizer} >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de PHP ${PHP_VERSION}..."
    print_success "PHP ${PHP_VERSION} installé"

    # Installation MariaDB
    apt install -y mariadb-server >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de MariaDB..."
    print_success "MariaDB installé"

    # Installation du serveur web
    if [ "$WEBSERVER" = "nginx" ]; then
        apt install -y nginx >> "$LOG_FILE" 2>&1 &
        spinner $! "Installation de Nginx..."
        print_success "Nginx installé"
    else
        apt install -y apache2 libapache2-mod-php${PHP_VERSION} >> "$LOG_FILE" 2>&1 &
        spinner $! "Installation d'Apache..."
        a2enmod rewrite php${PHP_VERSION} ssl >> "$LOG_FILE" 2>&1
        print_success "Apache installé"
    fi

    # Redis
    apt install -y redis-server >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de Redis..."
    print_success "Redis installé"

    # Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de Composer..."
    print_success "Composer installé"

    # Certbot
    apt install -y certbot >> "$LOG_FILE" 2>&1
    if [ "$WEBSERVER" = "nginx" ]; then
        apt install -y python3-certbot-nginx >> "$LOG_FILE" 2>&1
    else
        apt install -y python3-certbot-apache >> "$LOG_FILE" 2>&1
    fi
    print_success "Certbot installé"
}

install_dependencies_rhel() {
    print_step "Installation des dépendances (dnf)..."

    dnf install -y epel-release >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation EPEL..."
    print_success "EPEL installé"

    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm >> "$LOG_FILE" 2>&1 &
    spinner $! "Ajout du dépôt Remi..."
    print_success "Dépôt Remi ajouté"

    dnf module reset php -y >> "$LOG_FILE" 2>&1
    dnf module enable php:remi-${PHP_VERSION} -y >> "$LOG_FILE" 2>&1

    dnf install -y php php-{common,cli,gd,mysqlnd,mbstring,bcmath,xml,fpm,curl,zip,intl,sqlite3,tokenizer} >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de PHP ${PHP_VERSION}..."
    print_success "PHP ${PHP_VERSION} installé"

    dnf install -y mariadb-server >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de MariaDB..."
    print_success "MariaDB installé"

    if [ "$WEBSERVER" = "nginx" ]; then
        dnf install -y nginx >> "$LOG_FILE" 2>&1 &
        spinner $! "Installation de Nginx..."
        print_success "Nginx installé"
    else
        dnf install -y httpd mod_ssl >> "$LOG_FILE" 2>&1 &
        spinner $! "Installation d'Apache..."
        print_success "Apache installé"
    fi

    dnf install -y redis >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de Redis..."
    print_success "Redis installé"

    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >> "$LOG_FILE" 2>&1 &
    spinner $! "Installation de Composer..."
    print_success "Composer installé"

    dnf install -y certbot >> "$LOG_FILE" 2>&1
    if [ "$WEBSERVER" = "nginx" ]; then
        dnf install -y python3-certbot-nginx >> "$LOG_FILE" 2>&1
    else
        dnf install -y python3-certbot-apache >> "$LOG_FILE" 2>&1
    fi
    print_success "Certbot installé"
}

install_dependencies() {
    case "$OS" in
        ubuntu|debian)
            install_dependencies_debian
            ;;
        centos|rocky|almalinux|rhel)
            install_dependencies_rhel
            ;;
    esac
}

# ============================================================================
#                          CONFIGURATION BASE DE DONNÉES
# ============================================================================

setup_database() {
    print_step "Configuration de la base de données..."

    # Démarrer MariaDB (avec récupération automatique si échec)
    if ! systemctl start mariadb &>/dev/null; then
        print_warning "MariaDB n'a pas pu démarrer, tentative de réparation..."
        
        # Arrêter proprement tout processus MariaDB/MySQL
        systemctl stop mariadb &>/dev/null
        pkill -9 mysqld &>/dev/null || true
        pkill -9 mariadbd &>/dev/null || true
        sleep 2

        # Créer le dossier run s'il n'existe pas
        mkdir -p /var/run/mysqld
        chown mysql:mysql /var/run/mysqld
        chmod 755 /var/run/mysqld

        # Nettoyer les fichiers de verrouillage et logs corrompus
        rm -f /var/lib/mysql/aria_log_control &>/dev/null
        rm -f /var/lib/mysql/ib_logfile* &>/dev/null
        rm -f /var/lib/mysql/*.pid &>/dev/null
        rm -f /var/run/mysqld/mysqld.sock &>/dev/null
        rm -f /var/lib/mysql/tc.log &>/dev/null
        rm -f /var/lib/mysql/multi-master.info &>/dev/null

        if ! systemctl start mariadb &>/dev/null; then
            print_warning "Réinitialisation complète de MariaDB..."
            systemctl stop mariadb &>/dev/null
            
            # Purger complètement MariaDB
            (
                DEBIAN_FRONTEND=noninteractive apt-get purge -y mariadb-server mariadb-client mariadb-common mysql-common >> "$LOG_FILE" 2>&1
                apt-get autoremove -y >> "$LOG_FILE" 2>&1
                rm -rf /var/lib/mysql /etc/mysql /var/run/mysqld /var/log/mysql 2>/dev/null
                # Réinstaller proprement
                DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server >> "$LOG_FILE" 2>&1
            ) &
            spinner $! "Réinstallation de MariaDB (cela peut prendre un moment)..."
            
            # Préparer les dossiers après réinstallation
            mkdir -p /var/run/mysqld
            chown mysql:mysql /var/run/mysqld
            chmod 755 /var/run/mysqld
            mkdir -p /var/lib/mysql
            chown mysql:mysql /var/lib/mysql
            
            # Initialiser la base de données si vide
            if [ ! -f /var/lib/mysql/ibdata1 ]; then
                print_info "Initialisation de la base de données..."
                mariadb-install-db --user=mysql --datadir=/var/lib/mysql >> "$LOG_FILE" 2>&1 || \
                mysql_install_db --user=mysql --datadir=/var/lib/mysql >> "$LOG_FILE" 2>&1 || true
            fi
            
            if ! systemctl start mariadb &>/dev/null; then
                # Dernier recours : démarrer manuellement pour voir l'erreur
                print_error "Impossible de démarrer MariaDB"
                print_info "Erreur détaillée:"
                journalctl -xeu mariadb.service --no-pager -n 10 2>/dev/null | while read -r line; do
                    echo -e "  ${DIM}  ${line}${NC}"
                done
                print_info "Essayez manuellement: apt purge mariadb-* mysql-* -y && apt install mariadb-server -y"
                return 1
            fi
            print_success "MariaDB réinstallé et démarré"
        else
            print_success "MariaDB réparé et démarré"
        fi
    fi
    systemctl enable mariadb >> "$LOG_FILE" 2>&1

    DB_PASSWORD=$(random_password)

    # Tester si on peut se connecter sans mot de passe
    local EXISTING_ROOT_PASS=""
    local CAN_CONNECT_NO_PASS=false
    mysql -u root -e "SELECT 1;" &>/dev/null && CAN_CONNECT_NO_PASS=true || true

    if [ "$CAN_CONNECT_NO_PASS" = true ]; then
        # Pas de mot de passe root — première installation
        MYSQL_ROOT_PASSWORD=$(random_password)
        mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    else
        # MariaDB a déjà un mot de passe root (réinstallation)
        print_warning "MariaDB a déjà un mot de passe root configuré"

        # Essayer de le récupérer depuis les credentials existants
        if [ -f /root/.vyrohost-credentials ]; then
            EXISTING_ROOT_PASS=$(grep "MySQL Root" /root/.vyrohost-credentials 2>/dev/null | awk '{print $NF}')
        fi

        local CREDS_PASS_OK=false
        if [ -n "$EXISTING_ROOT_PASS" ]; then
            mysql -u root -p"${EXISTING_ROOT_PASS}" -e "SELECT 1;" &>/dev/null && CREDS_PASS_OK=true || true
        fi

        if [ "$CREDS_PASS_OK" = true ]; then
            MYSQL_ROOT_PASSWORD="$EXISTING_ROOT_PASS"
            print_info "Mot de passe root récupéré depuis les credentials existants"
        else
            # Demander le mot de passe à l'utilisateur
            print_info "Entrez le mot de passe root MariaDB actuel"
            password_prompt "Mot de passe root MariaDB" "EXISTING_ROOT_PASS"
            local MANUAL_PASS_OK=false
            mysql -u root -p"${EXISTING_ROOT_PASS}" -e "SELECT 1;" &>/dev/null && MANUAL_PASS_OK=true || true
            if [ "$MANUAL_PASS_OK" = true ]; then
                MYSQL_ROOT_PASSWORD="$EXISTING_ROOT_PASS"
                print_success "Connexion MariaDB réussie"
            else
                print_error "Mot de passe incorrect. Impossible de configurer la base de données."
                print_info "Réinitialisez MariaDB: systemctl stop mariadb && mysqld_safe --skip-grant-tables &"
                exit 1
            fi
        fi

        # Nettoyage des anciennes entrées
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    fi

    # Création de la base et de l'utilisateur
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

    print_success "Base de données configurée"
    echo -e "  ${DIM}├─${NC} DB: ${WHITE}panel${NC}"
    echo -e "  ${DIM}├─${NC} User: ${WHITE}pterodactyl${NC}"
    echo -e "  ${DIM}└─${NC} Mot de passe: ${WHITE}sauvegardé dans /root/.vyrohost-credentials${NC}"
}

# ============================================================================
#                          INSTALLATION DU PANEL
# ============================================================================

install_panel() {
    print_step "Installation du Panel Pterodactyl..."

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Téléchargement du panel
    curl -Lo panel.tar.gz "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz" >> "$LOG_FILE" 2>&1 &
    spinner $! "Téléchargement du Panel..."
    print_success "Panel téléchargé"

    tar -xzvf panel.tar.gz >> "$LOG_FILE" 2>&1
    chmod -R 755 storage/* bootstrap/cache/
    rm panel.tar.gz

    # Configuration
    cp .env.example .env

    (
        COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction >> "$LOG_FILE" 2>&1
    ) &
    spinner $! "Installation des dépendances PHP (cela peut prendre un moment)..."
    print_success "Dépendances PHP installées"

    php artisan key:generate --force >> "$LOG_FILE" 2>&1

    # Configuration de l'environnement
    local PANEL_SCHEME=$(get_panel_scheme)
    
    php artisan p:environment:setup \
        --author="$EMAIL" \
        --url="${PANEL_SCHEME}://$FQDN" \
        --timezone="Europe/Paris" \
        --cache="redis" \
        --session="redis" \
        --queue="redis" \
        --redis-host="127.0.0.1" \
        --redis-pass="" \
        --redis-port="6379" \
        --settings-ui=true \
        --telemetry=false >> "$LOG_FILE" 2>&1

    php artisan p:environment:database \
        --host="127.0.0.1" \
        --port="3306" \
        --database="panel" \
        --username="pterodactyl" \
        --password="$DB_PASSWORD" >> "$LOG_FILE" 2>&1

    print_success "Environnement configuré"

    # Migration de la base de données
    (
        php artisan migrate --seed --force >> "$LOG_FILE" 2>&1
    ) &
    spinner $! "Migration de la base de données..."
    print_success "Base de données migrée"

    # Création de l'utilisateur admin
    php artisan p:user:make \
        --email="$ADMIN_EMAIL" \
        --username="$ADMIN_USERNAME" \
        --name-first="$ADMIN_FIRSTNAME" \
        --name-last="$ADMIN_LASTNAME" \
        --password="$ADMIN_PASSWORD" \
        --admin=1 >> "$LOG_FILE" 2>&1

    print_success "Utilisateur administrateur créé"

    # Permissions
    chown -R www-data:www-data "$INSTALL_DIR"/* 2>/dev/null || chown -R nginx:nginx "$INSTALL_DIR"/* 2>/dev/null || chown -R apache:apache "$INSTALL_DIR"/* 2>/dev/null

    # Crontab
    (crontab -l 2>/dev/null; echo "* * * * * php ${INSTALL_DIR}/artisan schedule:run >> /dev/null 2>&1") | crontab -
    print_success "Crontab configuré"

    # Queue worker (systemd service)
    cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php ${INSTALL_DIR}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable --now pteroq >> "$LOG_FILE" 2>&1
    print_success "Service Queue Worker démarré"
}

# ============================================================================
#                          CONFIGURATION SERVEUR WEB
# ============================================================================

setup_nginx() {
    print_step "Configuration de Nginx..."

    if [ "$USE_SSL" = true ]; then
        cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${FQDN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FQDN};

    root ${INSTALL_DIR}/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    else
        cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${FQDN};

    root ${INSTALL_DIR}/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    fi

    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    nginx -t >> "$LOG_FILE" 2>&1
    systemctl restart nginx
    print_success "Nginx configuré et redémarré"
}

setup_apache() {
    print_step "Configuration d'Apache..."

    cat > /etc/apache2/sites-available/pterodactyl.conf <<EOF
<VirtualHost *:80>
    ServerName ${FQDN}
    Redirect permanent / https://${FQDN}/
</VirtualHost>

<VirtualHost *:443>
    ServerName ${FQDN}
    DocumentRoot ${INSTALL_DIR}/public

    AllowEncodedSlashes On

    php_value upload_max_filesize 100M
    php_value post_max_size 100M

    <Directory "${INSTALL_DIR}/public">
        Require all granted
        AllowOverride all
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${FQDN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${FQDN}/privkey.pem
</VirtualHost>
EOF

    a2ensite pterodactyl.conf >> "$LOG_FILE" 2>&1
    a2dissite 000-default.conf >> "$LOG_FILE" 2>&1
    systemctl restart apache2
    print_success "Apache configuré et redémarré"
}

setup_webserver() {
    if [ "$WEBSERVER" = "nginx" ]; then
        setup_nginx
    else
        setup_apache
    fi
}

# ============================================================================
#                          CERTIFICAT SSL
# ============================================================================

setup_ssl() {
    print_step "Configuration du certificat SSL (Let's Encrypt)..."

    if [ "$WEBSERVER" = "nginx" ]; then
        systemctl stop nginx

        certbot certonly --standalone \
            --non-interactive \
            --agree-tos \
            --email "$EMAIL" \
            -d "$FQDN" >> "$LOG_FILE" 2>&1 &
        spinner $! "Obtention du certificat SSL..."

        systemctl start nginx
    else
        systemctl stop apache2

        certbot certonly --standalone \
            --non-interactive \
            --agree-tos \
            --email "$EMAIL" \
            -d "$FQDN" >> "$LOG_FILE" 2>&1 &
        spinner $! "Obtention du certificat SSL..."

        systemctl start apache2
    fi

    # Renouvellement automatique
    (crontab -l 2>/dev/null; echo "0 23 * * * certbot renew --quiet --deploy-hook 'systemctl restart ${WEBSERVER}'") | crontab -

    print_success "Certificat SSL installé et renouvellement automatique configuré"
}

# ============================================================================
#                          INSTALLATION WINGS
# ============================================================================

install_wings() {
    print_step "Installation de Wings (Daemon)..."

    ensure_docker
    download_wings
    create_wings_service
    print_success "Service Wings configuré"

    # ── Configuration automatique du Node via l'API ──
    print_step "Configuration automatique du Node..."

    # Récupérer la clé API depuis le panel
    local API_KEY=""
    if [ -f "${INSTALL_DIR}/.env" ]; then
        # Créer une clé API application via tinker (en tant que www-data)
        print_info "Création de la clé API..."
        local TINKER_OUTPUT=""
        TINKER_OUTPUT=$(cd "$INSTALL_DIR" && sudo -u www-data php artisan tinker --execute="
            \$key = \Illuminate\Support\Str::random(48);
            \$token = new \Pterodactyl\Models\ApiKey();
            \$token->identifier = \Illuminate\Support\Str::random(16);
            \$token->token = hash('sha256', \$key);
            \$token->key_type = 2;
            \$token->user_id = 1;
            \$token->memo = 'VyroHost Auto Installer';
            \$token->r_nodes = 3;
            \$token->r_locations = 3;
            \$token->r_allocations = 3;
            \$token->r_servers = 3;
            \$token->r_users = 3;
            \$token->r_eggs = 3;
            \$token->r_nests = 3;
            \$token->r_server_databases = 3;
            \$token->r_database_hosts = 3;
            \$token->save();
            echo 'APIKEY:' . \$token->identifier . '.' . \$key;
        " 2>&1)
        
        # Extraire la clé depuis la sortie (chercher APIKEY:xxx)
        API_KEY=$(echo "$TINKER_OUTPUT" | grep "APIKEY:" | sed 's/.*APIKEY://' | tr -d '[:space:]')
        
        if [ -z "$API_KEY" ]; then
            log "[DEBUG] Tinker output: $TINKER_OUTPUT"
            print_warning "Tinker n'a pas pu créer la clé API"
            print_info "Sortie: $(echo "$TINKER_OUTPUT" | tail -3)"
        else
            print_success "Clé API créée"
        fi
    fi

    if [ -z "$API_KEY" ]; then
        print_warning "Impossible de créer la clé API automatiquement"
        print_info "Configurez le Node manuellement depuis le Panel"
        return
    fi

    local PANEL_SCHEME=$(get_panel_scheme)
    # Utiliser localhost pour l'API (le panel est sur la même machine)
    local API_URL="http://localhost/api/application"
    local SERVER_IP=$(curl -s4 https://ifconfig.me 2>/dev/null || curl -s4 https://ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')

    # 1. Créer la Location
    print_info "Création de la Location..."
    local LOCATION_RESPONSE=$(curl -sk "${API_URL}/locations" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST \
        -d '{"short": "VyroHost", "long": "Serveur VyroHost"}' 2>&1)

    log "[DEBUG] Location response: $LOCATION_RESPONSE"
    local LOCATION_ID=$(echo "$LOCATION_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['attributes']['id'])" 2>/dev/null)

    if [ -z "$LOCATION_ID" ]; then
        print_info "Tentative de récupération d'une location existante..."
        local LIST_RESPONSE=$(curl -sk "${API_URL}/locations" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Accept: application/json" 2>&1)
        log "[DEBUG] Location list response: $LIST_RESPONSE"
        LOCATION_ID=$(echo "$LIST_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['attributes']['id'])" 2>/dev/null)
    fi

    if [ -z "$LOCATION_ID" ]; then
        print_warning "Impossible de créer la Location"
        print_info "Réponse API: $(echo "$LOCATION_RESPONSE" | head -1)"
        print_info "Configurez le Node manuellement depuis le Panel"
        return
    fi
    print_success "Location créée (ID: ${LOCATION_ID})"

    # 2. Créer le Node
    local TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    local TOTAL_DISK=$(df -BM / | awk 'NR==2{gsub(/M/,"",$4); print $4}')
    # Réserver 1Go pour le système
    local ALLOC_MEM=$((TOTAL_MEM - 1024))
    [ "$ALLOC_MEM" -lt 512 ] && ALLOC_MEM=$TOTAL_MEM

    print_info "Création du Node..."
    local NODE_RESPONSE=$(curl -sk "${API_URL}/nodes" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST \
        -d "{
            \"name\": \"VyroHost-Node-01\",
            \"description\": \"Node auto-configuré par VyroHost Installer\",
            \"location_id\": ${LOCATION_ID},
            \"fqdn\": \"${FQDN}\",
            \"scheme\": \"${PANEL_SCHEME}\",
            \"memory\": ${ALLOC_MEM},
            \"memory_overallocate\": 0,
            \"disk\": ${TOTAL_DISK},
            \"disk_overallocate\": 0,
            \"upload_size\": 100,
            \"daemon_sftp\": 2022,
            \"daemon_listen\": 8080,
            \"behind_proxy\": false,
            \"maintenance_mode\": false
        }" 2>&1)

    log "[DEBUG] Node response: $NODE_RESPONSE"
    local NODE_ID=$(echo "$NODE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['attributes']['id'])" 2>/dev/null)

    if [ -z "$NODE_ID" ]; then
        print_warning "Impossible de créer le Node"
        print_info "Réponse API: $(echo "$NODE_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors', [{}])[0].get('detail', 'inconnu'))" 2>/dev/null || echo "$NODE_RESPONSE" | head -1)"
        print_info "Configurez le Node manuellement depuis le Panel"
        return
    fi
    print_success "Node créé (ID: ${NODE_ID}) — RAM: ${ALLOC_MEM}MB, Disque: ${TOTAL_DISK}MB"

    # 3. Créer les Allocations (tous les ports jeux)
    # Envoi par lots pour éviter les requêtes trop grandes
    local GAME_PORTS=(
        "25565-26000"   # Minecraft Java Edition
        "19100-19200"   # Minecraft Bedrock Edition
        "30000-30050"   # FiveM (lot 1)
        "30050-30100"   # FiveM (lot 2)
        "27000-27100"   # VALVE Source Engine (lot 1)
        "27100-27200"   # VALVE Source Engine (lot 2)
        "28015-28100"   # Rust
        "34100-34200"   # Factorio
        "9000-9100"     # TeamSpeak3 (lot 1)
        "9100-9200"     # TeamSpeak3 (lot 2)
        "8200-8300"     # Palworld
        "7100-7200"     # SCP: Secret Laboratory
        "7770-7790"     # Nova Life
        "1194-1294"     # OpenVPN
        "51820-51920"   # Wireguard
        "40120-40220"   # TxAdmin
        "40140"         # BeamMP
    )

    for RANGE in "${GAME_PORTS[@]}"; do
        local ALLOC_PAYLOAD='{"ip": "'${SERVER_IP}'", "ports": ["'${RANGE}'"]}'
        curl -sk "${API_URL}/nodes/${NODE_ID}/allocations" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -X POST \
            -d "$ALLOC_PAYLOAD" >> "$LOG_FILE" 2>&1
    done

    print_success "Allocations créées (Minecraft, FiveM, Rust, VALVE, TS3, Palworld, etc.)"

    # 4. Récupérer la configuration Wings et l'appliquer
    # Extraire le daemon_token depuis la réponse de création du Node
    local DAEMON_TOKEN=$(echo "$NODE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['attributes']['daemon_token'])" 2>/dev/null)

    if [ -n "$DAEMON_TOKEN" ]; then
        # Utiliser wings configure pour générer le YAML correctement
        print_info "Configuration de Wings via auto-deploy..."
        mkdir -p /etc/pterodactyl
        cd /etc/pterodactyl
        wings configure \
            --panel-url "${PANEL_SCHEME}://${FQDN}" \
            --token "${DAEMON_TOKEN}" \
            --node "${NODE_ID}" \
            --allow-insecure >> "$LOG_FILE" 2>&1
        cd - > /dev/null

        if [ -f /etc/pterodactyl/config.yml ]; then
            print_success "Configuration Wings appliquée"
        else
            print_warning "wings configure n'a pas créé le fichier config"
            print_info "Récupérez la config depuis: Panel → Admin → Nodes → Configuration"
        fi
    else
        # Fallback : télécharger la config JSON et convertir en YAML
        print_info "Récupération de la configuration Wings..."
        local CONFIG_RESPONSE=$(curl -sk "${API_URL}/nodes/${NODE_ID}/configuration" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Accept: application/json" 2>/dev/null)

        if [ -n "$CONFIG_RESPONSE" ] && echo "$CONFIG_RESPONSE" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
            # Installer pyyaml si nécessaire et convertir JSON → YAML
            pip3 install pyyaml -q 2>/dev/null || apt-get install -y python3-yaml -qq 2>/dev/null
            echo "$CONFIG_RESPONSE" | python3 -c "
import sys, json
try:
    import yaml
    data = json.load(sys.stdin)
    yaml.dump(data, sys.stdout, default_flow_style=False, allow_unicode=True)
except ImportError:
    # Fallback: simple JSON to YAML conversion
    import json as j
    def to_yaml(obj, indent=0):
        s = ''
        sp = '  ' * indent
        if isinstance(obj, dict):
            for k, v in obj.items():
                if isinstance(v, (dict, list)):
                    s += f'{sp}{k}:\n' + to_yaml(v, indent+1)
                elif isinstance(v, bool):
                    s += f'{sp}{k}: {str(v).lower()}\n'
                elif v is None:
                    s += f'{sp}{k}:\n'
                else:
                    s += f'{sp}{k}: {v}\n'
        elif isinstance(obj, list):
            for item in obj:
                if isinstance(item, (dict, list)):
                    s += f'{sp}-\n' + to_yaml(item, indent+1)
                else:
                    s += f'{sp}- {j.dumps(item)}\n'
        return s
    data = json.load(open('/dev/stdin'))
    print(to_yaml(data))
" > /etc/pterodactyl/config.yml 2>/dev/null
            print_success "Configuration Wings appliquée"
        else
            print_warning "Impossible de récupérer la config Wings automatiquement"
            print_info "Récupérez-la depuis: Panel → Admin → Nodes → Configuration"
        fi
    fi

    # 5. Démarrer Wings
    systemctl enable --now wings >> "$LOG_FILE" 2>&1
    sleep 3

    if systemctl is-active --quiet wings; then
        print_success "Wings démarré et fonctionnel !"
    else
        print_warning "Wings installé mais n'a pas pu démarrer"
        print_info "Vérifiez: journalctl -xeu wings"
    fi

    echo ""
    echo -e "  ${DIM}├─${NC} IP du Node:    ${WHITE}${SERVER_IP}${NC}"
    echo -e "  ${DIM}├─${NC} Location:      ${WHITE}VyroHost (ID: ${LOCATION_ID})${NC}"
    echo -e "  ${DIM}├─${NC} Node:          ${WHITE}VyroHost-Node-01 (ID: ${NODE_ID})${NC}"
    echo -e "  ${DIM}├─${NC} Ports alloués: ${WHITE}Minecraft, FiveM, Rust, VALVE, TS3, Palworld...${NC}"
    echo -e "  ${DIM}├─${NC} Daemon:        ${WHITE}port 8080${NC}"
    echo -e "  ${DIM}└─${NC} SFTP:          ${WHITE}port 2022${NC}"

}

# ============================================================================
#                          INSTALLATION PHPMYADMIN
# ============================================================================

install_phpmyadmin() {
    print_step "Installation de PHPMyAdmin..."

    local PMA_DIR="/var/www/phpmyadmin"
    mkdir -p "$PMA_DIR"

    curl -Lo /tmp/phpmyadmin.tar.gz "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz" >> "$LOG_FILE" 2>&1 &
    spinner $! "Téléchargement de PHPMyAdmin..."

    tar -xzf /tmp/phpmyadmin.tar.gz -C "$PMA_DIR" --strip-components=1 >> "$LOG_FILE" 2>&1
    rm -f /tmp/phpmyadmin.tar.gz

    # Configuration
    local BLOWFISH_SECRET=$(openssl rand -base64 32)
    cp "$PMA_DIR/config.sample.inc.php" "$PMA_DIR/config.inc.php"
    sed -i "s#\$cfg\['blowfish_secret'\] = ''#\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}'#" "$PMA_DIR/config.inc.php"
    
    mkdir -p "$PMA_DIR/tmp"
    chown -R www-data:www-data "$PMA_DIR" 2>/dev/null || chown -R nginx:nginx "$PMA_DIR" 2>/dev/null || chown -R apache:apache "$PMA_DIR" 2>/dev/null

    # Ajouter PHPMyAdmin comme sous-dossier /phpmyadmin dans la config du Panel
    if [ "$WEBSERVER" = "nginx" ]; then
        # Injecter le bloc location /phpmyadmin dans la config Nginx du panel
        # On l'insère juste avant la dernière accolade fermante }
        local NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
        if [ -f "$NGINX_CONF" ]; then
            # Créer le bloc à insérer
            local PMA_BLOCK="
    # PHPMyAdmin
    location /phpmyadmin {
        alias ${PMA_DIR};
        index index.php;

        location ~ ^/phpmyadmin/(.+\\.php)\$ {
            alias ${PMA_DIR}/\$1;
            fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME ${PMA_DIR}/\$1;
        }
    }
"
            # Insérer avant le dernier } du fichier
            sed -i "\$i\\${PMA_BLOCK}" "$NGINX_CONF"
            
            # Supprimer l'ancienne config PMA séparée si elle existe
            rm -f /etc/nginx/sites-available/phpmyadmin.conf 2>/dev/null
            rm -f /etc/nginx/sites-enabled/phpmyadmin.conf 2>/dev/null
            
            systemctl restart nginx
        fi
    else
        # Apache : alias /phpmyadmin
        cat > /etc/apache2/conf-available/phpmyadmin.conf <<EOF
Alias /phpmyadmin ${PMA_DIR}
<Directory ${PMA_DIR}>
    Require all granted
    AllowOverride all
</Directory>
EOF
        a2enconf phpmyadmin >> "$LOG_FILE" 2>&1
        # Supprimer l'ancienne config PMA séparée si elle existe
        a2dissite phpmyadmin 2>/dev/null
        rm -f /etc/apache2/sites-available/phpmyadmin.conf 2>/dev/null
        systemctl restart apache2
    fi

    local PANEL_SCHEME=$(get_panel_scheme)
    print_success "PHPMyAdmin installé sur ${PANEL_SCHEME}://${FQDN}/phpmyadmin"
}

# ============================================================================
#                          THÈME VYROHOST
# ============================================================================

install_vyrohost_theme() {
    print_step "Installation du thème VyroHost..."

    local THEME_DIR="${INSTALL_DIR}/resources/scripts"
    
    # Personnalisation du nom et des couleurs
    if [ -f "${INSTALL_DIR}/.env" ]; then
        sed -i "s/APP_NAME=.*/APP_NAME=\"VyroHost\"/" "${INSTALL_DIR}/.env"
    fi

    # Couleur personnalisée VyroHost (violet/purple)
    local CSS_FILE="${INSTALL_DIR}/resources/scripts/components/App.css"
    if [ -d "${INSTALL_DIR}/resources/scripts" ]; then
        # Création du fichier CSS custom VyroHost
        cat > "${INSTALL_DIR}/public/themes/vyrohost/css/custom.css" <<'CSSEOF'
/* VyroHost Custom Theme */
:root {
    --vyro-primary: #7c3aed;
    --vyro-primary-dark: #6d28d9;
    --vyro-primary-light: #a78bfa;
    --vyro-accent: #8b5cf6;
    --vyro-bg-dark: #0f0a1a;
    --vyro-bg-card: #1a1025;
    --vyro-bg-sidebar: #150d22;
    --vyro-text: #e2e8f0;
    --vyro-text-muted: #94a3b8;
    --vyro-success: #10b981;
    --vyro-danger: #ef4444;
    --vyro-warning: #f59e0b;
    --vyro-border: rgba(124, 58, 237, 0.2);
}

/* Sidebar */
.NavigationBar {
    background: linear-gradient(180deg, var(--vyro-bg-sidebar) 0%, var(--vyro-bg-dark) 100%) !important;
    border-right: 1px solid var(--vyro-border) !important;
}

/* Boutons primaires */
button[class*="primary"], .Button.primary, a[class*="primary"] {
    background: linear-gradient(135deg, var(--vyro-primary) 0%, var(--vyro-accent) 100%) !important;
    border: none !important;
    box-shadow: 0 4px 15px rgba(124, 58, 237, 0.3) !important;
    transition: all 0.3s ease !important;
}

button[class*="primary"]:hover, .Button.primary:hover {
    box-shadow: 0 6px 20px rgba(124, 58, 237, 0.5) !important;
    transform: translateY(-1px) !important;
}

/* Cards */
div[class*="ContentContainer"], .ContentBox {
    background: var(--vyro-bg-card) !important;
    border: 1px solid var(--vyro-border) !important;
    border-radius: 12px !important;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3) !important;
}

/* Header */
div[class*="PageContentBlock"] > div:first-child {
    background: linear-gradient(135deg, var(--vyro-bg-dark) 0%, #1e1133 100%) !important;
}

/* Input fields */
input[type="text"], input[type="password"], input[type="email"], input[type="number"], textarea, select {
    background: rgba(15, 10, 26, 0.8) !important;
    border: 1px solid var(--vyro-border) !important;
    color: var(--vyro-text) !important;
    border-radius: 8px !important;
    transition: border-color 0.3s ease !important;
}

input:focus, textarea:focus, select:focus {
    border-color: var(--vyro-primary) !important;
    box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.15) !important;
}

/* Status indicators */
.status-running {
    color: var(--vyro-success) !important;
}

/* Console */
div[class*="terminal"] {
    background: #0a0612 !important;
    border-radius: 8px !important;
}

/* Scrollbar */
::-webkit-scrollbar {
    width: 6px;
}

::-webkit-scrollbar-track {
    background: var(--vyro-bg-dark);
}

::-webkit-scrollbar-thumb {
    background: var(--vyro-primary);
    border-radius: 3px;
}

/* Footer branding */
footer::after {
    content: "Powered by VyroHost";
    display: block;
    text-align: center;
    color: var(--vyro-text-muted);
    font-size: 0.75rem;
    padding: 1rem;
}

/* Animations */
@keyframes vyro-glow {
    0%, 100% { box-shadow: 0 0 5px rgba(124, 58, 237, 0.2); }
    50% { box-shadow: 0 0 20px rgba(124, 58, 237, 0.4); }
}

.server-card:hover {
    animation: vyro-glow 2s ease-in-out infinite;
}
CSSEOF
        mkdir -p "${INSTALL_DIR}/public/themes/vyrohost/css"
        print_success "CSS custom VyroHost créé"
    fi

    # Injection du thème dans le layout
    local LAYOUT_FILE="${INSTALL_DIR}/resources/views/templates/wrapper.blade.php"
    if [ -f "$LAYOUT_FILE" ]; then
        # Ajouter le lien CSS custom dans le head
        sed -i '/<\/head>/i\    <link rel="stylesheet" href="/themes/vyrohost/css/custom.css">' "$LAYOUT_FILE"
        print_success "Thème injecté dans le layout"
    fi

    # Favicon et logo VyroHost
    print_info "Remplacez le logo dans: ${INSTALL_DIR}/public/assets/svgs/"
    print_info "Remplacez le favicon dans: ${INSTALL_DIR}/public/favicons/"

    # Rebuild des assets si node est disponible
    if command -v node &>/dev/null && [ -f "${INSTALL_DIR}/package.json" ]; then
        cd "${INSTALL_DIR}"
        (
            yarn install >> "$LOG_FILE" 2>&1 && yarn build:production >> "$LOG_FILE" 2>&1
        ) &
        spinner $! "Compilation des assets..."
        print_success "Assets compilés avec le thème VyroHost"
    fi

    print_success "Thème VyroHost installé"
}

# ============================================================================
#                              BACKUP SYSTÈME
# ============================================================================

setup_backup() {
    print_step "Configuration du système de backup..."

    mkdir -p "$BACKUP_DIR"

    cat > /usr/local/bin/vyrohost-backup <<'BACKUPEOF'
#!/bin/bash
# VyroHost - Script de backup Pterodactyl
# Exécuté automatiquement via cron

BACKUP_DIR="/var/backups/pterodactyl"
INSTALL_DIR="/var/www/pterodactyl"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_PATH="${BACKUP_DIR}/${DATE}"
RETENTION_DAYS=7

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}[VyroHost]${NC} Démarrage du backup - ${DATE}"

mkdir -p "$BACKUP_PATH"

# Backup de la base de données
echo -e "${CYAN}[VyroHost]${NC} Backup de la base de données..."
if [ -f "${INSTALL_DIR}/.env" ]; then
    DB_HOST=$(grep ^DB_HOST "${INSTALL_DIR}/.env" | cut -d= -f2)
    DB_NAME=$(grep ^DB_DATABASE "${INSTALL_DIR}/.env" | cut -d= -f2)
    DB_USER=$(grep ^DB_USERNAME "${INSTALL_DIR}/.env" | cut -d= -f2)
    DB_PASS=$(grep ^DB_PASSWORD "${INSTALL_DIR}/.env" | cut -d= -f2)
    
    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "${BACKUP_PATH}/database.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} Base de données sauvegardée"
    else
        echo -e "${RED}[ERREUR]${NC} Échec du backup de la base de données"
    fi
fi

# Backup du fichier .env
echo -e "${CYAN}[VyroHost]${NC} Backup de la configuration..."
cp "${INSTALL_DIR}/.env" "${BACKUP_PATH}/.env" 2>/dev/null

# Backup de la configuration Wings
cp /etc/pterodactyl/config.yml "${BACKUP_PATH}/wings-config.yml" 2>/dev/null

# Backup du thème custom
if [ -d "${INSTALL_DIR}/public/themes" ]; then
    cp -r "${INSTALL_DIR}/public/themes" "${BACKUP_PATH}/themes" 2>/dev/null
fi

# Compression
echo -e "${CYAN}[VyroHost]${NC} Compression..."
cd "$BACKUP_DIR"
tar -czf "${DATE}.tar.gz" "${DATE}" 2>/dev/null
rm -rf "${BACKUP_PATH}"

# Nettoyage des anciens backups
echo -e "${CYAN}[VyroHost]${NC} Nettoyage des backups de plus de ${RETENTION_DAYS} jours..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete

# Stats
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}/${DATE}.tar.gz" 2>/dev/null | cut -f1)
echo -e "${GREEN}[VyroHost]${NC} Backup terminé ! Taille: ${BACKUP_SIZE}"
echo -e "${GREEN}[VyroHost]${NC} Fichier: ${BACKUP_DIR}/${DATE}.tar.gz"
BACKUPEOF

    chmod +x /usr/local/bin/vyrohost-backup

    # Cron pour backup quotidien à 3h du matin
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/vyrohost-backup >> /var/log/vyrohost-backup.log 2>&1") | crontab -

    print_success "Backup automatique configuré (quotidien à 3h)"
    echo -e "  ${DIM}├─${NC} Script: ${WHITE}/usr/local/bin/vyrohost-backup${NC}"
    echo -e "  ${DIM}├─${NC} Dossier: ${WHITE}${BACKUP_DIR}${NC}"
    echo -e "  ${DIM}└─${NC} Rétention: ${WHITE}7 jours${NC}"
}

# ============================================================================
#                          DÉSINSTALLATION COMPLÈTE
# ============================================================================

uninstall_pterodactyl() {
    print_header
    echo -e "  ${RED}${BOLD}⚠  DÉSINSTALLATION COMPLÈTE DE PTERODACTYL  ⚠${NC}"
    echo ""
    print_separator
    echo ""
    print_warning "Cette action est IRRÉVERSIBLE !"
    echo -e "  ${DIM}Les éléments suivants seront supprimés :${NC}"
    echo -e "  ${DIM}  • Panel Pterodactyl (/var/www/pterodactyl)${NC}"
    echo -e "  ${DIM}  • Wings (/usr/local/bin/wings)${NC}"
    echo -e "  ${DIM}  • Base de données (panel)${NC}"
    echo -e "  ${DIM}  • Configurations Nginx/Apache${NC}"
    echo -e "  ${DIM}  • Services systemd${NC}"
    echo -e "  ${DIM}  • PHPMyAdmin${NC}"
    echo ""

    if ! confirm "Êtes-vous sûr de vouloir tout supprimer ?" "n"; then
        print_info "Désinstallation annulée"
        return
    fi

    echo ""
    if ! confirm "DERNIÈRE CHANCE - Confirmer la suppression totale ?" "n"; then
        print_info "Désinstallation annulée"
        return
    fi

    echo ""

    # Créer un backup avant suppression
    if confirm "Créer un backup avant suppression ?" "o"; then
        /usr/local/bin/vyrohost-backup 2>/dev/null
        print_success "Backup créé dans ${BACKUP_DIR}"
    fi

    print_step "Désinstallation en cours..."


    # Arrêt des services
    systemctl stop wings 2>/dev/null
    systemctl disable wings 2>/dev/null
    systemctl stop pteroq 2>/dev/null
    systemctl disable pteroq 2>/dev/null
    print_success "Services arrêtés"

    # Suppression Wings
    rm -f /usr/local/bin/wings
    rm -rf /etc/pterodactyl
    rm -f /etc/systemd/system/wings.service
    print_success "Wings supprimé"

    # Suppression du Panel
    rm -rf "$INSTALL_DIR"
    rm -f /etc/systemd/system/pteroq.service
    print_success "Panel supprimé"

    # Suppression de la base de données
    if command -v mysql &>/dev/null; then
        CREDS_FILE="/root/.vyrohost-credentials"
        if [ -f "$CREDS_FILE" ]; then
            ROOT_PASS=$(grep "MySQL Root" "$CREDS_FILE" | awk '{print $NF}')
            mysql -u root -p"$ROOT_PASS" -e "DROP DATABASE IF EXISTS panel; DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null
        fi
    fi
    print_success "Base de données supprimée"

    # Suppression PHPMyAdmin
    rm -rf /var/www/phpmyadmin
    print_success "PHPMyAdmin supprimé"

    # Suppression des configs serveur web
    rm -f /etc/nginx/sites-available/pterodactyl.conf 2>/dev/null
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf 2>/dev/null
    rm -f /etc/nginx/sites-available/phpmyadmin.conf 2>/dev/null
    rm -f /etc/nginx/sites-enabled/phpmyadmin.conf 2>/dev/null
    rm -f /etc/apache2/sites-available/pterodactyl.conf 2>/dev/null
    rm -f /etc/apache2/sites-enabled/pterodactyl.conf 2>/dev/null
    rm -f /etc/apache2/sites-available/phpmyadmin.conf 2>/dev/null
    rm -f /etc/apache2/sites-enabled/phpmyadmin.conf 2>/dev/null
    systemctl restart nginx 2>/dev/null || systemctl restart apache2 2>/dev/null
    print_success "Configurations serveur web supprimées"

    # Nettoyage des crontabs
    (crontab -l 2>/dev/null | grep -v "pterodactyl\|vyrohost-backup\|certbot" | crontab -) 2>/dev/null
    print_success "Crontabs nettoyés"

    # Suppression du script de backup
    rm -f /usr/local/bin/vyrohost-backup
    print_success "Script de backup supprimé"

    # Suppression des credentials
    rm -f /root/.vyrohost-credentials
    print_success "Fichier credentials supprimé"

    systemctl daemon-reload 2>/dev/null

    echo ""
    print_separator
    echo -e "\n  ${CHECK} ${GREEN}${BOLD}Désinstallation complète terminée !${NC}\n"
    echo -e "  ${DIM}Note: Docker, MariaDB, PHP et le serveur web n'ont PAS été supprimés.${NC}"
    echo -e "  ${DIM}Pour les retirer: apt remove --purge docker-ce mariadb-server nginx php*${NC}"
    echo ""
}

# ============================================================================
#                          SAUVEGARDE CREDENTIALS
# ============================================================================

save_credentials() {
    print_step "Sauvegarde des identifiants..."

    local PANEL_SCHEME=$(get_panel_scheme)
    local PMA_URL=$(get_pma_url)

    cat > /root/.vyrohost-credentials <<EOF
╔══════════════════════════════════════════════════════════════════╗
║                    VyroHost - Credentials                       ║
║                 Généré le $(date '+%Y-%m-%d %H:%M:%S')                   ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Panel URL:         ${PANEL_SCHEME}://${FQDN}
║  PHPMyAdmin URL:    ${PMA_URL}
║                                                                  ║
║  ─── Admin Panel ───                                             ║
║  Email:             ${ADMIN_EMAIL}
║  Username:          ${ADMIN_USERNAME}
║  Password:          ${ADMIN_PASSWORD}
║                                                                  ║
║  ─── Base de données ───                                         ║
║  MySQL Root Pass:   ${MYSQL_ROOT_PASSWORD}
║  DB Name:           panel                                        ║
║  DB User:           pterodactyl                                  ║
║  DB Password:       ${DB_PASSWORD}
║                                                                  ║
║  ─── Fichiers importants ───                                     ║
║  Panel:             ${INSTALL_DIR}
║  Wings Config:      /etc/pterodactyl/config.yml                  ║
║  Backups:           ${BACKUP_DIR}
║  Logs:              ${LOG_FILE}
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF

    chmod 600 /root/.vyrohost-credentials
    print_success "Credentials sauvegardés dans /root/.vyrohost-credentials"
}

# ============================================================================
#                          RÉSUMÉ FINAL
# ============================================================================

print_summary() {
    local PANEL_SCHEME=$(get_panel_scheme)
    local PMA_URL=$(get_pma_url)

    echo ""
    print_separator
    echo ""
    echo -e "  ${STAR} ${GREEN}${BOLD}INSTALLATION TERMINÉE AVEC SUCCÈS !${NC} ${STAR}"
    echo ""
    print_separator
    echo ""
    echo -e "  ${RED}${BOLD}⚠  SAUVEGARDEZ CES INFORMATIONS MAINTENANT !  ⚠${NC}"
    echo ""
    print_separator
    echo ""
    echo -e "  ${WHITE}${BOLD}Accès au Panel:${NC}"
    echo -e "  ${DIM}├─${NC} URL:      ${CYAN}${PANEL_SCHEME}://${FQDN}${NC}"
    echo -e "  ${DIM}├─${NC} Email:    ${WHITE}${ADMIN_EMAIL}${NC}"
    echo -e "  ${DIM}├─${NC} Username: ${WHITE}${ADMIN_USERNAME}${NC}"
    echo -e "  ${DIM}└─${NC} Password: ${WHITE}${ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}PHPMyAdmin:${NC}"
    echo -e "  ${DIM}└─${NC} URL:      ${CYAN}${PMA_URL}${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}Base de données:${NC}"
    echo -e "  ${DIM}├─${NC} MySQL Root: ${WHITE}${MYSQL_ROOT_PASSWORD}${NC}"
    echo -e "  ${DIM}├─${NC} DB Name:    ${WHITE}panel${NC}"
    echo -e "  ${DIM}├─${NC} DB User:    ${WHITE}pterodactyl${NC}"
    echo -e "  ${DIM}└─${NC} DB Pass:    ${WHITE}${DB_PASSWORD}${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}Commandes utiles:${NC}"
    echo -e "  ${DIM}├─${NC} ${YELLOW}systemctl status pteroq${NC}     — Status du Queue Worker"
    echo -e "  ${DIM}├─${NC} ${YELLOW}systemctl status wings${NC}      — Status de Wings"
    echo -e "  ${DIM}├─${NC} ${YELLOW}vyrohost-backup${NC}             — Backup manuel"
    echo -e "  ${DIM}├─${NC} ${YELLOW}cat /root/.vyrohost-credentials${NC} — Voir les identifiants"
    echo -e "  ${DIM}└─${NC} ${YELLOW}bash install.sh${NC}             — Relancer le menu"
    echo ""
    print_separator
    echo -e "\n  ${DIM}Merci d'utiliser VyroHost ! 💙${NC}\n"
}

# ============================================================================
#                          COLLECTE DES INFORMATIONS
# ============================================================================

collect_info() {
    print_header
    echo -e "  ${WHITE}${BOLD}Configuration de l'installation${NC}"
    echo ""
    print_separator
    echo ""

    # Serveur web
    echo -e "  ${WHITE}${BOLD}Choix du serveur web :${NC}"
    echo -e "  ${DIM}  [1]${NC} Nginx ${GREEN}(recommandé)${NC}"
    echo -e "  ${DIM}  [2]${NC} Apache"
    echo ""
    echo -ne "  ${ARROW} Votre choix ${DIM}[1]${NC}: "
    read -r ws_choice
    ws_choice=${ws_choice:-1}
    if [ "$ws_choice" = "2" ]; then
        WEBSERVER="apache2"
        print_success "Serveur web: Apache"
    else
        WEBSERVER="nginx"
        print_success "Serveur web: Nginx"
    fi
    echo ""

    # Informations réseau
    print_separator
    echo ""
    echo -e "  ${WHITE}${BOLD}Configuration réseau${NC}"
    echo ""
    local SERVER_IP=$(curl -s4 https://ifconfig.me 2>/dev/null || curl -s4 https://ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')
    echo -e "  ${INFO} ${BLUE}IP détectée: ${WHITE}${SERVER_IP}${NC}"
    echo -e "  ${DIM}  Entrez votre nom de domaine (ex: exemple.com) ou l'IP du VPS${NC}"
    echo -e "  ${DIM}  Si vous n'avez pas de domaine, vous pouvez:${NC}"
    echo -e "  ${DIM}    • Utiliser l'IP de votre VPS: ${WHITE}${SERVER_IP}${NC}"
    echo -e "  ${DIM}    • Demander un sous-domaine gratuit à VyroHost${NC}"
    echo ""
    input_prompt "Domaine ou IP" "${SERVER_IP}" "FQDN"
    
    # Détecter si c'est une IP (pas de SSL possible avec une IP seule)
    USE_SSL=true
    if [[ "$FQDN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        USE_SSL=false
        print_warning "Vous utilisez une IP — SSL Let's Encrypt ne sera pas configuré"
        print_info "Utilisez http://${FQDN} pour accéder au panel"
    fi
    
    input_prompt "Email (pour SSL & Panel)" "" "EMAIL"
    echo ""

    # Informations admin
    print_separator
    echo ""
    echo -e "  ${WHITE}${BOLD}Compte administrateur${NC}"
    echo ""
    input_prompt "Email admin" "$EMAIL" "ADMIN_EMAIL"
    input_prompt "Nom d'utilisateur" "admin" "ADMIN_USERNAME"
    input_prompt "Prénom" "Admin" "ADMIN_FIRSTNAME"
    input_prompt "Nom" "VyroHost" "ADMIN_LASTNAME"
    password_prompt "Mot de passe admin (min. 8 caractères)" "ADMIN_PASSWORD"
    echo ""

    # Résumé
    print_separator
    echo ""
    echo -e "  ${WHITE}${BOLD}Résumé de la configuration :${NC}"
    echo ""
    echo -e "  ${DIM}├─${NC} FQDN:        ${CYAN}${FQDN}${NC}"
    echo -e "  ${DIM}├─${NC} Email:        ${WHITE}${EMAIL}${NC}"
    echo -e "  ${DIM}├─${NC} Serveur web:  ${WHITE}${WEBSERVER}${NC}"
    echo -e "  ${DIM}├─${NC} Admin user:   ${WHITE}${ADMIN_USERNAME}${NC}"
    echo -e "  ${DIM}├─${NC} Admin email:  ${WHITE}${ADMIN_EMAIL}${NC}"
    echo -e "  ${DIM}└─${NC} PHP:          ${WHITE}${PHP_VERSION}${NC}"
    echo ""

    if ! confirm "Lancer l'installation avec ces paramètres ?" "o"; then
        print_info "Installation annulée"
        exit 0
    fi
}

# ============================================================================
#                     INSTALLATION NODE SEULE (WINGS)
# ============================================================================

install_node_only() {
    print_header
    echo -e "  ${WHITE}${BOLD}Installation d'une Node Wings (connexion à un Panel externe)${NC}"
    echo ""
    print_separator
    echo ""

    local SERVER_IP=$(curl -s4 https://ifconfig.me 2>/dev/null || curl -s4 https://ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')
    echo -e "  ${INFO} ${BLUE}IP de ce serveur: ${WHITE}${SERVER_IP}${NC}"
    echo ""

    input_prompt "URL du Panel Pterodactyl (ex: https://panel.exemple.com)" "" "PANEL_URL"
    echo ""
    echo -e "  ${DIM}  Pour obtenir le token, allez sur votre Panel :${NC}"
    echo -e "  ${DIM}  Admin → Nodes → Créer un Node → Configuration tab${NC}"
    echo -e "  ${DIM}  Copiez tout le contenu du bloc 'Auto-Deploy'${NC}"
    echo ""
    input_prompt "Token Wings (depuis le Panel)" "" "WINGS_TOKEN"
    echo ""

    if ! confirm "Installer Wings avec ces paramètres ?" "o"; then
        print_info "Installation annulée"
        return
    fi

    print_header
    echo -e "  ${WHITE}${BOLD}Installation de la Node Wings...${NC}"
    echo ""

    local start_time=$(date +%s)

    detect_os

    # Docker
    ensure_docker
    download_wings
    create_wings_service
    print_success "Service Wings configuré"

    # Configurer Wings avec le token
    cd /etc/pterodactyl
    wings configure \
        --panel-url "${PANEL_URL}" \
        --token "${WINGS_TOKEN}" \
        --node 1 >> "$LOG_FILE" 2>&1 && print_success "Wings configuré avec le Panel" || {
        print_warning "Configuration automatique échouée"
        print_info "Copiez manuellement la config YAML dans /etc/pterodactyl/config.yml"
    }

    # Démarrer Wings
    systemctl enable --now wings >> "$LOG_FILE" 2>&1
    sleep 3

    local end_time=$(date +%s)
    local duration=$(( end_time - start_time ))
    local minutes=$(( duration / 60 ))
    local seconds=$(( duration % 60 ))

    echo ""
    print_separator
    echo ""

    if systemctl is-active --quiet wings; then
        echo -e "  ${STAR} ${GREEN}${BOLD}NODE WINGS INSTALLÉE ET FONCTIONNELLE !${NC} ${STAR}"
    else
        echo -e "  ${STAR} ${YELLOW}${BOLD}NODE WINGS INSTALLÉE (vérifiez la config)${NC} ${STAR}"
    fi

    echo ""
    print_separator
    echo ""
    echo -e "  ${WHITE}${BOLD}Informations de la Node:${NC}"
    echo -e "  ${DIM}├─${NC} IP:          ${WHITE}${SERVER_IP}${NC}"
    echo -e "  ${DIM}├─${NC} Panel:       ${WHITE}${PANEL_URL}${NC}"
    echo -e "  ${DIM}├─${NC} Daemon:      ${WHITE}port 8080${NC}"
    echo -e "  ${DIM}├─${NC} SFTP:        ${WHITE}port 2022${NC}"
    echo -e "  ${DIM}└─${NC} Config:      ${WHITE}/etc/pterodactyl/config.yml${NC}"
    echo ""
    echo -e "  ${DIM}Temps d'installation: ${WHITE}${minutes}m ${seconds}s${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}Commandes utiles:${NC}"
    echo -e "  ${DIM}├─${NC} ${YELLOW}systemctl status wings${NC}    — Status de Wings"
    echo -e "  ${DIM}├─${NC} ${YELLOW}systemctl restart wings${NC}   — Redémarrer Wings"
    echo -e "  ${DIM}└─${NC} ${YELLOW}journalctl -xeu wings${NC}    — Logs de Wings"
    echo ""
    print_separator
    echo -e "\n  ${DIM}Merci d'utiliser VyroHost ! 💙${NC}\n"
}

# ============================================================================
#                          INSTALLATION COMPLÈTE
# ============================================================================

full_install() {
    collect_info

    print_header
    echo -e "  ${WHITE}${BOLD}Installation en cours...${NC}"
    echo -e "  ${DIM}Cela peut prendre 5 à 15 minutes selon votre serveur${NC}"
    echo ""

    local start_time=$(date +%s)

    detect_os
    check_resources
    install_dependencies
    setup_database
    if [ "$USE_SSL" = true ]; then
        setup_ssl
    else
        print_info "SSL ignoré (utilisation d'une IP)"
    fi
    install_panel
    setup_webserver
    install_wings
    install_phpmyadmin
    install_vyrohost_theme
    setup_backup
    save_credentials

    local end_time=$(date +%s)
    local duration=$(( end_time - start_time ))
    local minutes=$(( duration / 60 ))
    local seconds=$(( duration % 60 ))

    print_header
    echo -e "  ${DIM}Temps d'installation: ${WHITE}${minutes}m ${seconds}s${NC}"
    print_summary
}

# ============================================================================
#                          MENU PRINCIPAL
# ============================================================================

main_menu() {
    while true; do
        print_header

        echo -e "  ${WHITE}${BOLD}Que souhaitez-vous faire ?${NC}"
        echo ""
        echo -e "  ${BLUE}${BOLD}  INSTALLATION${NC}"
        echo -e "  ${DIM}  ─────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}  [1]${NC}  ${GREEN}⚡${NC} Installation complète ${DIM}(Panel + Wings + PHPMyAdmin + SSL + Thème)${NC}"
        echo -e "  ${WHITE}  [2]${NC}  ${CYAN}🌐${NC} Installer une Node Wings ${DIM}(connexion à un Panel externe)${NC}"
        echo -e "  ${WHITE}  [3]${NC}  ${BLUE}📦${NC} Installer uniquement le Panel"
        echo -e "  ${WHITE}  [4]${NC}  ${BLUE}🗄️${NC}  Installer uniquement PHPMyAdmin"
        echo -e "  ${WHITE}  [5]${NC}  ${BLUE}🔒${NC} Configurer SSL (Let's Encrypt)"
        echo -e "  ${WHITE}  [6]${NC}  ${BLUE}🎨${NC} Installer le thème VyroHost"
        echo ""
        echo -e "  ${YELLOW}${BOLD}  MAINTENANCE${NC}"
        echo -e "  ${DIM}  ─────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}  [7]${NC}  ${CYAN}💾${NC} Backup manuel"
        echo -e "  ${WHITE}  [8]${NC}  ${CYAN}⚙️${NC}  Configurer le backup automatique"
        echo ""
        echo -e "  ${RED}${BOLD}  DANGER${NC}"
        echo -e "  ${DIM}  ─────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}  [9]${NC}  ${RED}🗑️${NC}  Désinstallation complète"
        echo ""
        echo -e "  ${DIM}  ─────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}  [0]${NC}  ${DIM}Quitter${NC}"
        echo ""
        echo -ne "  ${ARROW} Votre choix: "
        read -r choice

        case "$choice" in
            1)
                full_install
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            2)
                install_node_only
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            3)
                collect_info
                print_header
                detect_os
                check_resources
                install_dependencies
                setup_database
                if [ "$USE_SSL" = true ]; then
                    setup_ssl
                fi
                install_panel
                setup_webserver
                install_vyrohost_theme
                save_credentials
                print_summary
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            4)
                if [ -z "$FQDN" ]; then
                    local SERVER_IP=$(curl -s4 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
                    input_prompt "Domaine ou IP" "${SERVER_IP}" "FQDN"
                    if [[ "$FQDN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                        USE_SSL=false
                    fi
                fi
                if [ -z "$WEBSERVER" ]; then
                    echo -e "  ${DIM}  [1]${NC} Nginx  ${DIM}  [2]${NC} Apache"
                    echo -ne "  ${ARROW} Serveur web ${DIM}[1]${NC}: "
                    read -r ws
                    ws=${ws:-1}
                    [ "$ws" = "2" ] && WEBSERVER="apache2" || WEBSERVER="nginx"
                fi
                install_phpmyadmin
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            5)
                if [ -z "$FQDN" ]; then
                    input_prompt "Nom de domaine (FQDN)" "" "FQDN"
                fi
                if [ -z "$EMAIL" ]; then
                    input_prompt "Email pour Let's Encrypt" "" "EMAIL"
                fi
                if [ -z "$WEBSERVER" ]; then
                    echo -e "  ${DIM}  [1]${NC} Nginx  ${DIM}  [2]${NC} Apache"
                    echo -ne "  ${ARROW} Serveur web ${DIM}[1]${NC}: "
                    read -r ws
                    ws=${ws:-1}
                    [ "$ws" = "2" ] && WEBSERVER="apache2" || WEBSERVER="nginx"
                fi
                setup_ssl
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            6)
                install_vyrohost_theme
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            7)
                if [ -x /usr/local/bin/vyrohost-backup ]; then
                    /usr/local/bin/vyrohost-backup
                else
                    print_error "Le script de backup n'est pas installé"
                    print_info "Utilisez l'option [8] pour le configurer d'abord"
                fi
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            8)
                setup_backup
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            9)
                uninstall_pterodactyl
                echo -ne "\n  ${DIM}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -r
                ;;
            0)
                echo ""
                echo -e "  ${BLUE}${BOLD}Au revoir ! 💙${NC}"
                echo -e "  ${DIM}VyroHost Staff Tool${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Choix invalide"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
#                              POINT D'ENTRÉE
# ============================================================================

# Vérification root
check_root

# Initialisation du log
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
log "=== VyroHost Installer démarré ==="

# Lancer le menu
main_menu
