# 🦅 VyroHost — Pterodactyl Installer

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-purple?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/Pterodactyl-1.11.x-blue?style=for-the-badge" alt="Pterodactyl">
  <img src="https://img.shields.io/badge/Wings-1.11.x-green?style=for-the-badge" alt="Wings">
  <img src="https://img.shields.io/badge/License-Internal-red?style=for-the-badge" alt="License">
</p>

<p align="center">
  <strong>Script d'installation Pterodactyl pour le staff VyroHost</strong><br>
  <em>Déploiement distant • Menu interactif • Thème custom • Backup auto</em>
</p>

---

## 🚀 Déploiement distant (depuis ton PC)

Le cas d'usage principal : un client te demande d'installer Pterodactyl. Tu lances le script depuis **ton PC** et ça se connecte à son serveur automatiquement.

### Méthode 1 — Script `deploy.sh` (recommandé)

```bash
# Mode interactif (demande IP, user, port, etc.)
./deploy.sh

# Connexion rapide en root
./deploy.sh 192.168.1.100

# Avec user + IP
./deploy.sh root@panel.client.com

# Port SSH custom
./deploy.sh -p 2222 root@panel.client.com

# Avec clé SSH spécifique
./deploy.sh -k ~/.ssh/vyrohost root@panel.client.com

# Avec mot de passe (nécessite sshpass)
./deploy.sh -pw root@panel.client.com
```

Le script va :
1. Se connecter en SSH au serveur du client
2. Vérifier l'OS, la RAM, le disque
3. Télécharger l'installeur VyroHost
4. Lancer le menu interactif directement dans le SSH

### Méthode 2 — One-liner sur le serveur client

Si tu es **déjà connecté en SSH** au serveur du client :

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Lexooff/pterodactyl-installer/main/install.sh)
```

### Méthode 3 — Bootstrap loader

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Lexooff/pterodactyl-installer/main/bootstrap.sh)
```

### Méthode 4 — Installation manuelle

```bash
git clone https://github.com/Lexooff/pterodactyl-installer.git
cd pterodactyl-installer
chmod +x install.sh
sudo bash install.sh
```

---

## 📁 Structure du projet

```
├── install.sh       → Script d'installation principal (tourne sur le serveur client)
├── deploy.sh        → Script de déploiement distant (tourne sur TON PC)
├── bootstrap.sh     → Bootstrap loader (télécharge et lance install.sh)
├── version.txt      → Version actuelle
└── README.md        → Cette documentation
```

---

## 📋 Fonctionnalités

| Fonctionnalité | Description |
|---|---|
| 📦 **Panel Pterodactyl** | Installation complète avec PHP 8.3, MariaDB, Redis |
| 🔧 **Wings (Daemon)** | Installation de Docker + Wings avec service systemd |
| 🗄️ **PHPMyAdmin** | Interface web pour la gestion de la base de données |
| 🔒 **SSL Let's Encrypt** | Certificat SSL automatique avec renouvellement |
| 🎨 **Thème VyroHost** | Thème purple/violet custom pour le panel |
| 💾 **Backup automatique** | Backup quotidien de la BDD, config et thème |
| 🗑️ **Désinstallation** | Suppression complète avec option de backup |
| 🖥️ **Multi-OS** | Ubuntu, Debian, CentOS, Rocky Linux, AlmaLinux |

---

## 🖥️ Systèmes supportés

| OS | Versions |
|---|---|
| Ubuntu | 20.04, 22.04, 24.04 |
| Debian | 11, 12 |
| CentOS | 8, 9 |
| Rocky Linux | 8, 9 |
| AlmaLinux | 8, 9 |

### Prérequis minimum
- **RAM** : 2 GB (minimum 1 GB)
- **Disque** : 5 GB libres
- **Accès** : Root
- **Domaine** : FQDN pointant vers le serveur

---

## 📖 Menu principal

```
  ██╗   ██╗██╗   ██╗██████╗  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔═══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
  ██║   ██║ ╚████╔╝ ██████╔╝██║   ██║███████║██║   ██║███████╗   ██║
  ╚██╗ ██╔╝  ╚██╔╝  ██╔══██╗██║   ██║██╔══██║██║   ██║╚════██║   ██║
   ╚████╔╝    ██║   ██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║   ██║
    ╚═══╝     ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝

  [1] ⚡ Installation complète
  [2] 📦 Panel uniquement
  [3] 🔧 Wings uniquement
  [4] 🗄️ PHPMyAdmin
  [5] 🔒 SSL Let's Encrypt
  [6] 🎨 Thème VyroHost
  [7] 💾 Backup manuel
  [8] ⚙️ Config backup auto
  [9] 🗑️ Désinstallation
  [0] Quitter
```

---

## 🎨 Thème VyroHost

Le thème custom applique les couleurs VyroHost (violet/purple) au panel :

- **Couleur primaire** : `#7c3aed`
- **Fond sombre** : `#0f0a1a`
- **Sidebar** : gradient violet
- **Boutons** : gradient avec effet glow
- **Cards** : fond sombre avec bordures violettes
- **Footer** : "Powered by VyroHost"

---

## 💾 Système de backup

Le script configure un backup automatique quotidien à 3h du matin :

**Éléments sauvegardés :**
- Base de données complète (mysqldump)
- Fichier `.env` de configuration
- Configuration Wings (`config.yml`)
- Thème custom VyroHost

**Commandes :**
```bash
# Backup manuel
vyrohost-backup

# Voir les backups
ls -la /var/backups/pterodactyl/

# Logs de backup
cat /var/log/vyrohost-backup.log
```

**Rétention** : 7 jours (configurable)

---

## 🔐 Identifiants

Après l'installation, tous les identifiants sont sauvegardés dans :

```bash
cat /root/.vyrohost-credentials
```

Ce fichier contient :
- URL du Panel et PHPMyAdmin
- Identifiants admin
- Mots de passe MySQL
- Chemins des fichiers importants

---

## 📁 Structure des fichiers

```
/var/www/pterodactyl/          → Panel Pterodactyl
/var/www/phpmyadmin/           → PHPMyAdmin
/etc/pterodactyl/config.yml   → Configuration Wings
/usr/local/bin/wings           → Binaire Wings
/usr/local/bin/vyrohost-backup → Script de backup
/var/backups/pterodactyl/      → Dossier des backups
/var/log/vyrohost-installer.log → Log d'installation
/root/.vyrohost-credentials    → Identifiants (chmod 600)
```

---

## ⚠️ Notes importantes

1. **DNS** : Assurez-vous que votre domaine pointe vers le serveur AVANT l'installation
2. **PHPMyAdmin** : Accessible via `pma.votredomaine.com` (nécessite un enregistrement DNS séparé)
3. **Wings** : Après l'installation, configurez le Node dans le Panel puis collez la config dans `/etc/pterodactyl/config.yml`
4. **Sécurité** : Le fichier credentials est en chmod 600. Ne le partagez jamais.

---

## 🆘 Dépannage

```bash
# Logs d'installation
cat /var/log/vyrohost-installer.log

# Status des services
systemctl status pteroq
systemctl status wings
systemctl status nginx     # ou apache2
systemctl status mariadb
systemctl status redis-server

# Redémarrer tous les services
systemctl restart pteroq wings nginx mariadb redis-server

# Vérifier PHP
php -v
php -m

# Vérifier la base de données
mysql -u root -p -e "SHOW DATABASES;"
```

---

<p align="center">
  <strong>VyroHost</strong> — Staff Internal Tool<br>
  <em>Ne pas distribuer en dehors de l'équipe</em>
</p>
