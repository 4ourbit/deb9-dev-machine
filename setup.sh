#!/usr/bin/env bash

###############################################################
## PACKAGE VERSIONS - CHANGE AS REQUIRED
###############################################################
versionPhp="7.2";
versionGo="1.11.4";
versionHelm="2.10.0";
versionSops="3.1.1";
versionDapp="0.27.14";
versionNode="9";
versionPopcorn="0.3.10";
versionPhpStorm="2018.3.1";
versionDockerCompose="1.24.0";

# Disallow running with sudo or su
##########################################################
if [[ "$EUID" -eq 0 ]]
  then printf "\033[1;101mNein, Nein, Nein!! Please do not run this script as root (no su or sudo)! \033[0m \n";
  exit;
fi

###############################################################
## HELPERS
###############################################################
title() {
    printf "\033[1;42m";
    printf '%*s\n'  "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' ';
    printf '%-*s\n' "${COLUMNS:-$(tput cols)}" "  # $1" | tr ' ' ' ';
    printf '%*s'  "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' ';
    printf "\033[0m";
    printf "\n\n";
}

breakLine() {
    printf "\n";
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -;
    printf "\n\n";
    sleep .5;
}

sudo apt install -y libnotify-bin;
alias alert='notify-send --urgency=low --app-name="$(uname -n)" -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

notify() {
    printf "\n";
    printf "\033[1;46m $1 \033[0m \n";
    notify-send "$1";
}

title "Installing Pre-Requisite Packages";
    sudo apt install -y curl lsb-release xclip;
    alias sudo='sudo -E';
    alias pbcopy='xclip -selection clipboard';
    alias pbpaste='xclip -selection clipboard -o';
    alias grep='grep --color=auto';
    alias h='history';
    alias r='fc -s';
    alias ll='ls -lsa';
    source <(alias | tee ~/.bash_aliases);
    notify "Pre-Requisite Packages installed"
breakLine;

curlToFile() {
    notify "Downloading: $1 ----> $2";
    sudo curl -fSL "$1" -o "$2";
}

###############################################################
## REGISTERED VARIABLES
###############################################################
installedFlatpak=0;
installedGit=0;
installedGo=0;
installedZsh=0;
installedPhp=0;
installedNode=0;
repoUrl="https://raw.githubusercontent.com/4ourbit/deb9-dev-machine/master/";
emacsStarterKit="https://github.com/4ourbit/emacs24-starter-kit"

###############################################################
## REPOSITORIES
###############################################################

# PHP
##########################################################
repoPhp() {
    if [[ ! -f /etc/apt/sources.list.d/php.list ]]; then
        notify "Adding PHP sury repository";
        curl -fsSL "https://packages.sury.org/php/apt.gpg" | sudo apt-key add -;
        echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list;
    fi
}

# Docker CE
##########################################################
repoDocker() {
    if [[ ! -f /var/lib/dpkg/info/docker-ce.list ]]; then
        notify "Adding Docker repository";
        curl -fsSL "https://download.docker.com/linux/debian/gpg" | sudo apt-key add -;
        echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list;
    fi
}

# Kubernetes
##########################################################
repoKubernetes() {
    if [[ ! -f /etc/apt/sources.list.d/kubernetes.list ]]; then
        notify "Adding Kubernetes repository";
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo apt-key add -;
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list;
    fi
}

# Wine
##########################################################
repoWine() {
    if [[ ! -f /var/lib/dpkg/info/wine-stable.list ]]; then
        notify "Adding Wine repository";
        sudo dpkg --add-architecture i386;
        curl -fsSL "https://dl.winehq.org/wine-builds/winehq.key" | sudo apt-key add -;
        curl -fsSL "https://dl.winehq.org/wine-builds/Release.key" | sudo apt-key add -;
        sudo apt-add-repository "https://dl.winehq.org/wine-builds/debian/";
    fi
}

# Atom
##########################################################
repoAtom() {
    if [[ ! -f /etc/apt/sources.list.d/atom.list ]]; then
        notify "Adding Atom IDE repository";
        curl -fsSL "https://packagecloud.io/AtomEditor/atom/gpgkey" | sudo apt-key add -;
        echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" | sudo tee /etc/apt/sources.list.d/atom.list;
    fi
}

# Backports
##########################################################
repoBackports() {
    if [[ ! -f /etc/apt/sources.list.d/stretch-backports.list ]]; then
        notify "Adding Backports repository";
        sudo touch /etc/apt/sources.list.d/stretch-backports.list;
        echo "deb http://ftp.debian.org/debian stretch-backports main" | sudo tee --append /etc/apt/sources.list.d/stretch-backports.list >> /dev/null
    fi
}

# Google Cloud SDK
##########################################################
repoGoogleSdk() {
    if [[ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]]; then
        notify "Adding GCE repository";
        export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)";
        echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list;
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo apt-key add -;
    fi
}

# VLC
##########################################################
repoVlc() {
    if [[ ! -f /etc/apt/sources.list.d/videolan-ubuntu-stable-daily-disco.list ]]; then
        notify "Adding VLC repository";
        sudo add-apt-repository ppa:videolan/stable-daily
    fi
}

###############################################################
## INSTALLATION
###############################################################

# Debian Software Center
installSoftwareCenter() {
    sudo apt install -y gnome-software gnome-packagekit;
}

# Flatpack
##########################################################
installFlatpak() {
    title "Installing Flatpak";
    sudo apt install -y flatpak;
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;
    installedFlatpak=1;
    breakLine;
}

# Git
##########################################################
installGit() {
    title "Installing Git";
    sudo apt install -y git;
    curl -L https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh | sudo tee /etc/profile.d/git-prompt.sh
    echo "declare -x GIT_PS1_SHOWDIRTYSTATE=TRUE" | sudo tee --append /etc/profile.d/git-prompt.sh
    source /etc/profile.d/git-prompt.sh
    echo "PS1=$'${PS1::-3}\[\033[01;31m\]\$(__git_ps1 "")\[\033[00m\]\$ '" | tee --append ~/.bashrc
    installedGit=1;
    breakLine;
}

# Node
##########################################################
installNode() {
    title "Installing Node ${versionNode}";
    curl -L "https://deb.nodesource.com/setup_${versionNode}.x" | sudo -E bash -;
    sudo apt install -y nodejs;
    sudo chown -R $(whoami) /usr/lib/node_modules;
    sudo chmod -R 777 /usr/lib/node_modules;
    installedNode=1;
    breakLine;
}

# React Native
##########################################################
installReactNative() {
    title "Installing React Native";
    sudo npm install -g create-react-native-app;
    breakLine;
}

# Cordova
##########################################################
installCordova() {
    title "Installing Apache Cordova";
    sudo npm install -g cordova;
    breakLine;
}

# Phonegap
##########################################################
installPhoneGap() {
    title "Installing Phone Gap";
    sudo npm install -g phonegap;
    breakLine;
}

# Webpack
##########################################################
installWebpack() {
    title "Installing Webpack";
    sudo npm install -g webpack;
    breakLine;
}

# PHP
##########################################################
installPhp() {
    title "Installing PHP ${versionPhp}";
    sudo apt install -y php${versionPhp} php${versionPhp}-{bcmath,cli,common,curl,dev,gd,intl,mbstring,mysql,sqlite3,xml,zip} php-pear php-memcached php-redis;
    sudo apt install -y libphp-predis php-xdebug php-ds;
    php --version;

    sudo pecl install igbinary ds;
    installedPhp=1;
    breakLine;
}

# Ruby
##########################################################
installRuby() {
    title "Installing Ruby with DAPP v${versionDapp}";
    sudo apt install -y ruby-dev gcc pkg-config;
    sudo gem install mixlib-cli -v 1.7.0;
    sudo gem install dapp -v ${versionDapp};
    breakLine;
}

# Python
##########################################################
installPython() {
    title "Installing Python & PIP";
    sudo apt install -y python-pip;
    curl "https://bootstrap.pypa.io/get-pip.py" | sudo python;
    sudo pip install --upgrade setuptools;
    breakLine;
}

# GoLang
##########################################################
installGoLang() {
    title "Installing GoLang ${versionGo}";
    curlToFile "https://dl.google.com/go/go${versionGo}.linux-amd64.tar.gz" "go.tar.gz";
    tar xvf go.tar.gz;

    if [[ -d /usr/local/go ]]; then
        sudo rm -rf /usr/local/go;
    fi

    sudo mv go /usr/local;
    echo "y" | rm go.tar.gz;

    echo 'export GOROOT="/usr/local/go"' >> ~/.bashrc;
    echo 'export GOPATH="$HOME/go"' >> ~/.bashrc;
    echo 'export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"' >> ~/.bashrc;

    source ~/.bashrc;
    mkdir ${GOPATH};
    sudo chown -R root:root ${GOPATH};

    installedGo=1;
    breakLine;
}

# Yarn
##########################################################
installYarn() {
    title "Installing Yarn";
    sudo apt install -y yarn;
    breakLine;
}

# Memcached
##########################################################
installMemcached() {
    title "Installing Memcached";
    sudo apt install -y memcached;
    sudo systemctl start memcached;
    sudo systemctl enable memcached;
    breakLine;
}

# Redis
##########################################################
installRedis() {
    title "Installing Redis";
    sudo apt install -y redis-server;
    sudo systemctl start redis;
    sudo systemctl enable redis;
    breakLine;
}

# Composer
##########################################################
installComposer() {
    title "Installing Composer";
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');";
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer;
    sudo rm /tmp/composer-setup.php;
    breakLine;
}

# Laravel Installer
##########################################################
installLaravel() {
    title "Installing Laravel Installer";
    composer global require "laravel/installer";
    echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' | tee -a ~/.bashrc;
    breakLine;
}

# SQLite Browser
##########################################################
installSqLite() {
    title "Installing SQLite Browser";
    sudo apt install -y sqlitebrowser;
    breakLine;
}

# DBeaver
##########################################################
installDbeaver() {
    title "Installing DBeaver SQL Client";
    sudo apt install -y \
    ca-certificates-java* \
    java-common* \
    libpcsclite1* \
    libutempter0* \
    openjdk-8-jre-headless* \
    xbitmaps*;

    curlToFile "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" "dbeaver.deb";
    sudo dpkg -i ~/dbeaver.deb;
    sudo rm ~/dbeaver.deb;
    breakLine;
}

# Redis Desktop Manager
##########################################################
installRedisDesktopManager() {
    title "Installing Redis Desktop Manager";
    sudo snap install redis-desktop-manager;
    breakLine;
}

# Docker
##########################################################
installDocker() {
    title "Installing Docker CE with Docker Compose";
    sudo apt install -y docker-ce;
    curlToFile "https://github.com/docker/compose/releases/download/${versionDockerCompose}/docker-compose-$(uname -s)-$(uname -m)" "/usr/local/bin/docker-compose";
    sudo chmod +x /usr/local/bin/docker-compose;
    
    source <(echo "declare -x DOCKER_HOST=tcp://docker.lxd:2375" | sudo tee /etc/profile.d/docker-host.sh)

    sudo groupadd docker;
    sudo usermod -aG docker ${USER};
    breakLine;
}

# Kubernetes
##########################################################
installKubernetes() {
    title "Installing Kubernetes";
    sudo apt install -y kubectl;
    breakLine;
}

# Helm
##########################################################
installHelm() {
    title "Installing Helm v${versionHelm}";
    curl -fsSl "https://storage.googleapis.com/kubernetes-helm/helm-v${versionHelm}-linux-amd64.tar.gz" -o helm.tar.gz;
    tar -zxvf helm.tar.gz;
    sudo mv linux-amd64/helm /usr/local/bin/helm;
    sudo rm -rf linux-amd64 && sudo rm helm.tar.gz;
    breakLine;
}

# Sops
##########################################################
installSops() {
    title "Installing Sops v${versionSops}";
    wget -O sops_${versionSops}_amd64.deb "https://github.com/mozilla/sops/releases/download/${versionSops}/sops_${versionSops}_amd64.deb";
    sudo dpkg -i sops_${versionSops}_amd64.deb;
    sudo rm sops_${versionSops}_amd64.deb;
    breakLine;
}

# Wine
##########################################################
installWine() {
    title "Installing Wine & Mono";
    sudo apt install -y cabextract;
    sudo apt install -y --install-recommends winehq-stable;
    sudo apt install -y mono-vbnc winbind;

    notify "Installing WineTricks";
    curlToFile "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" "winetricks";
    sudo chmod +x ~/winetricks;
    sudo mv ~/winetricks /usr/local/bin;

    notify "Installing Windows Fonts";
    winetricks allfonts;

    notify "Installing Smooth Fonts for Wine";
    curlToFile ${repoUrl}"wine_fontsmoothing.sh" "wine_fontsmoothing";
    sudo chmod +x ~/wine_fontsmoothing;
    sudo ./wine_fontsmoothing;
    clear;

    notify "Installing Royale 2007 Theme";
    curlToFile "http://www.gratos.be/wincustomize/compressed/Royale_2007_for_XP_by_Baal_wa_astarte.zip" "Royale_2007.zip";

    sudo chown -R $(whoami) ~/;
    mkdir -p ~/.wine/drive_c/Resources/Themes/;
    unzip ~/Royale_2007.zip -d ~/.wine/drive_c/Resources/Themes/;
    
    notify "Cleaning up...";
    echo "y" | rm ~/wine_fontsmoothing;
    echo "y" | rm ~/Royale_2007.zip;
}

# Postman
##########################################################
installPostman() {
    title "Installing Postman";
    curlToFile "https://dl.pstmn.io/download/latest/linux64" "postman.tar.gz";
    sudo tar xfz ~/postman.tar.gz;

    sudo rm -rf /opt/postman/;
    sudo mkdir /opt/postman/;
    sudo mv ~/Postman*/* /opt/postman/;
    sudo rm -rf ~/Postman*;
    sudo rm -rf ~/postman.tar.gz;
    sudo ln -s /opt/postman/Postman /usr/bin/postman;

    notify "Adding desktop file for Postman";
    curlToFile ${repoUrl}"desktop/postman.desktop" "/usr/share/applications/postman.desktop";
    breakLine;
}

# Atom IDE
##########################################################
installAtom() {
    title "Installing Atom IDE";
    sudo apt install -y atom;
    breakLine;
}

# Emacs
##########################################################
installEmacs() {
    title "Installing Emacs";
    
    sudo apt install -y emacs \
      emacs-goodies-el \
      elpa-magit \
      elpa-undo-tree \
      elpa-paredit \
      elpa-expand-region \
      elpa-hydra \
      elpa-flx-ido \
      elpa-ido-completing-read+ \
      elpa-ido-ubiquitous \
      org-mode;
    # sudo flatpak install -y flathub org.gnu.emacs;
    # alias emacs="flatpak run org.gnu.emacs";
    # source <(alias | tee ~/.bash_aliases);
    sudo sed -i 's|/emacs24 %F|/emacsclient.emacs24 --alternate-editor="" -c %F|' /usr/share/applications/emacs24.desktop

    # git clone "${emacsStarterKit}" -o ~/.emacs.d;
    breakLine;
}

# PHP Storm
##########################################################
installPhpStorm() {
    title "Installing PhpStorm IDE ${versionPhpStorm}";
    curlToFile "https://download.jetbrains.com/webide/PhpStorm-${versionPhpStorm}.tar.gz" "phpstorm.tar.gz";
    sudo tar xfz ~/phpstorm.tar.gz;

    sudo rm -rf /opt/phpstorm/;
    sudo mkdir /opt/phpstorm/;
    sudo mv ~/PhpStorm-*/* /opt/phpstorm/;
    sudo rm -rf ~/phpstorm.tar.gz;
    sudo rm -rf ~/PhpStorm-*;

    notify "Adding desktop file for PhpStorm";
    curlToFile ${repoUrl}"desktop/jetbrains-phpstorm.desktop" "/usr/share/applications/jetbrains-phpstorm.desktop";
    breakLine;
}

# Remmina
##########################################################
installRemmina() {
    title "Installing Remmina Client";
    sudo apt install -t stretch-backports remmina remmina-plugin-rdp remmina-plugin-secret -y;
    breakLine;
}

# Google Cloud SDK
##########################################################
installGoogleSdk() {
    title "Installing Google Cloud SDK";
    sudo apt install -y google-cloud-sdk;
    breakLine;
}

# Popcorn Time
##########################################################
installPopcorn() {
    title "Installing Popcorn Time v${versionPopcorn}";
    sudo apt install -y libnss3 vlc;

    if [[ -d /opt/popcorn-time ]]; then
        sudo rm -rf /opt/popcorn-time;
    fi

    sudo mkdir /opt/popcorn-time;
    sudo wget -qO- "https://get.popcorntime.sh/build/Popcorn-Time-${versionPopcorn}-Linux-64.tar.xz" | sudo tar Jx -C /opt/popcorn-time;
    sudo ln -sf /opt/popcorn-time/Popcorn-Time /usr/bin/popcorn-time;

    notify "Adding desktop file for Popcorn Time";
    curlToFile ${repoUrl}"desktop/popcorn.desktop" "/usr/share/applications/popcorn.desktop";
    breakLine;
}

# ZSH
##########################################################
installZsh() {
    title "Installing ZSH Terminal Plugin";
    sudo apt install -y zsh fonts-powerline;
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)";

    if [[ -f ${HOME}"/.zshrc" ]]; then
        sudo mv ${HOME}"/.zshrc" ${HOME}"/.zshrc.bak";
    fi

    if [[ -f ${HOME}"/.oh-my-zsh/themes/agnoster.zsh-theme" ]]; then
        sudo mv ${HOME}"/.oh-my-zsh/themes/agnoster.zsh-theme" ${HOME}"/.oh-my-zsh/themes/agnoster.zsh-theme.bak";
    fi

    echo '/bin/zsh' >> ~/.bashrc;

    installedZsh=1;
    breakLine;
}

# nano
##########################################################
installNano() {
    title "Installing nano";
    sudo apt install -y nano;
    breakLine;
}

# smbnetfs
##########################################################
installSmbNetFS() {
    title "Installing SmbNetFS";
    sudo apt install -y fuse smbnetfs;
    breakLine;
}

# Cockpit
##########################################################
installCockpit() {
    title "Installing Cockpit";
    sudo apt install -t stretch-backports cockpit -y;
    breakLine;
}

###############################################################
## MAIN PROGRAM
###############################################################
sudo apt install -y dialog;

cmd=(dialog --backtitle "Debian 9 Developer Container - USAGE: <space> select/un-select options & <enter> start installation." \
--ascii-lines \
--clear \
--nocancel \
--separate-output \
--checklist "Select installable packages:" 42 50 50);

options=(
    01 "Git" on
    15 "Docker CE (with docker compose)" on
    16 "Kubernetes (Kubectl)" off
    17 "Helm v${versionHelm}" off
    19 "Postman" off
    21 "Wine" off
    25 "Emacs" on
    26 "Atom" off
    30 "Software Center" on
    32 "Google Cloud SDK" off
    36 "Nano" on
    37 "SmbNetFS" off
    38 "Cockpit" off
);

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty);

clear;

# Preparation
##########################################################
title "Adding Repositories";
for choice in ${choices}
do
    case ${choice} in
        03) repoPhp ;;
        08) repoPhp ;;
        20) repoPhp ;;
        07) repoYarn ;;
        15) repoDocker ;;
        16) repoKubernetes ;;
        21) repoWine ;;
        31) repoBackports ;;
        32) repoGoogleSdk ;;
        33) repoVlc ;;
        38) repoBackports ;;
    esac
done
notify "Required repositories have been added...";
breakLine;

title "Updating apt";
    sudo apt update;
    notify "The apt package manager is fully updated...";
breakLine;

for choice in ${choices}
do
    case ${choice} in
        01) installGit ;;
        02) installNode ;;
        03) installPhp ;;
        04) installRuby ;;
        05) installPython ;;
        06) installGoLang ;;
        07) installYarn ;;
        08)
            if [[ ${installedPhp} -ne 1 ]]; then
                installPhp;
            fi
            installComposer;
        ;;
        09)
            if [[ ${installedNode} -ne 1 ]]; then
                installNode;
            fi
            installReactNative;
        ;;
        10)
            if [[ ${installedNode} -ne 1 ]]; then
                installNode;
            fi
            installCordova;
        ;;
        11)
            if [[ ${installedNode} -ne 1 ]]; then
                installNode;
            fi
            installPhoneGap;
        ;;
        12)
            if [[ ${installedNode} -ne 1 ]]; then
                installNode;
            fi
            installWebpack;
        ;;
        13) installMemcached ;;
        14) installRedis ;;
        15) installDocker ;;
        16) installKubernetes ;;
        17) installHelm ;;
        18)
            if [[ ${installedGo} -ne 1 ]]; then
                installGoLang;
            fi
            installSops;
        ;;
        19) installPostman ;;
        20)
            if [[ ${installedPhp} -ne 1 ]]; then
                installPhp;
            fi
            installLaravel;
        ;;
        21) installWine ;;
        23) installSqLite ;;
        24) installDbeaver ;;
        25)             
            # if [[ ${installedFlatpak} -ne 1 ]]; then
            #     installFlatpak;
            # fi
            if [[ ${installedGit} -ne 1 ]]; then
                installGit;
            fi
            installEmacs;
        ;;
        26) installAtom ;;
        28) installSublime ;;
        30) installSoftwareCenter ;;
        31) installRemmina ;;
        32) installGoogleSdk ;;
        33) installPopcorn ;;
        34) installZsh ;;
        36) installNano ;;
        37) installSmbNetFS ;;
        38) installCockpit ;;
    esac
done

# Clean
##########################################################
title "Finalising & Cleaning Up...";
    sudo apt --fix-broken install -y;
    sudo apt dist-upgrade -y;
    sudo apt autoremove -y --purge;
breakLine;

notify "Great, the installation is complete =)";
echo "If you want to install further tool in the future you can run this script again.";

###############################################################
## POST INSTALLATION ACTIONS
###############################################################
if [[ ${installedZsh} -eq 1 ]]; then
    breakLine;
    notify "ZSH Plugin Detected..."

    cd ~/;
    curlToFile ${repoUrl}"zsh/.zshrc" ".zshrc";
    curlToFile ${repoUrl}"zsh/agnoster.zsh-theme" ".oh-my-zsh/themes/agnoster.zsh-theme";
    source ~/.zshrc;

    echo "";
    echo "If you are on a Chromebook, to complete the zsh setup you must manually change your terminal settings 'Ctrl+Shift+P':";
    echo "";
    echo "   1) Set user-css path to: $(tput bold)https://cdnjs.cloudflare.com/ajax/libs/hack-font/3.003/web/hack.css$(tput sgr0)";
    echo "   2) Add $(tput bold)'Hack'$(tput sgr0) as a font-family entry.";
    echo "";
    echo "Alternatively:";
    echo "";
    echo "   1) Import this file directly: $(tput bold)${repoUrl}zsh/crosh.json$(tput sgr0)";
    echo "";
    echo "If the zsh plugin does not take effect you can manually activate it by adding /bin/zsh to you .bashrc file. ";
    echo "Further information & documentation on the ZSH plugin: https://github.com/robbyrussell/oh-my-zsh";
fi

echo "";
