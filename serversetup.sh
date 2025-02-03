#!/bin/bash

echo " ___  ___  ________  _____ ______   _______           ___       ________  ________          ________  _______  _________  ___  ___  ________   
|\  \|\  \|\   __  \|\   _ \  _   \|\  ___ \         |\  \     |\   __  \|\   __  \        |\   ____\|\  ___ \|\___   ___\\  \|\  \|\   __  \  
\ \  \\\  \ \  \|\  \ \  \\\__\ \  \ \   __/|        \ \  \    \ \  \|\  \ \  \|\ /_       \ \  \___|\ \   __/\|___ \  \_\ \  \\\  \ \  \|\  \ 
 \ \   __  \ \  \\\  \ \  \\|__| \  \ \  \_|/__       \ \  \    \ \   __  \ \   __  \       \ \_____  \ \  \_|/__  \ \  \ \ \  \\\  \ \   ____\
  \ \  \ \  \ \  \\\  \ \  \    \ \  \ \  \_|\ \       \ \  \____\ \  \ \  \ \  \|\  \       \|____|\  \ \  \_|\ \  \ \  \ \ \  \\\  \ \  \___|
   \ \__\ \__\ \_______\ \__\    \ \__\ \_______\       \ \_______\ \__\ \__\ \_______\        ____\_\  \ \_______\  \ \__\ \ \_______\ \__\   
    \|__|\|__|\|_______|\|__|     \|__|\|_______|        \|_______|\|__|\|__|\|_______|       |\_________\|_______|   \|__|  \|_______|\|__|   
                                                                                              \|_________|                                     
"

userName=$(whoami)
echo "Username is: ${userName}"

if [ "$userName" == "root" ]; then
  echo "WARNING: Run the script as your user, not root!"
fi

echo "This script will install the following:"
echo "  1. Homebrew"
echo "  2. LazyVim"
echo "  3. Docker"
echo "  4. Kubernetes"
echo "  5. Python"
echo "  6. OpenSSH"
echo "  7. QBittorrent"
echo ""
echo "This will also do some inital configuration and setup stuff that I got too lazy to add to the list and other stuff as well"

echo ""
echo "**************************************************************************************"
echo ""

echo "SECTION 0 - INITIAL SETUP"

echo "Performing Update and Upgrade"

sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean -y && sudo apt autoclean -y

echo "Installing some pre-requisites"

sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  wget \
  python3-gpg

echo "Installing HomeBrew"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Installing LazyVim"

sudo apt-get install neovim
sudo apt-get install python3-neovim

mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo "Installing OpenSSH"

sudo apt install openssh-server

if ! systemctl is-active --quiet ssh; then
  echo "SSH service is not running. Starting SSH..."
  sudo systemctl start ssh

  # Verify if it started successfully
  if systemctl is-active --quiet ssh; then
    echo "SSH service started successfully"
  else
    echo "Failed to start SSH service"
    exit 1
  fi
else
  echo "SSH service is already running"
fi

sudo systemctl enable ssh
sudo ufw allow ssh

echo ""
echo "**************************************************************************************"
echo ""

echo "SECTION 1 - INSTALLING DEV RELATED TOOLS"

echo "Installing GitHub CLI"

brew install gh
git config --global user.name "Ruhaab Sheikh"
git config --global user.email "sheikh.ruhaab15@gmail.com"

echo "Installing Python"

sudo apt install python3
sudo apt install python3-pip
sudo apt install python3-venv

echo "Installing Docker"

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

if docker --version >/dev/null 2>&1; then
  echo "Docker installed successfully!"
  echo "Docker version: $(docker --version)"
else
  echo "Docker installation seems to have failed."
  exit 1
fi

echo "Installing Kubernetes"

echo "Installing minikube..."
if ! command -v minikube &>/dev/null; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
else
  echo "minikube is already installed"
fi

echo "Installing kubectl..."
if ! command -v kubectl &>/dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
else
  echo "kubectl is already installed"
fi

echo "Installing Helm..."
if ! command -v helm &>/dev/null; then
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm get_helm.sh
else
  echo "Helm is already installed"
fi

echo "Installing k9s..."
if ! command -v k9s &>/dev/null; then
  # Get latest k9s release version
  K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  curl -LO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
  tar -xf k9s_Linux_amd64.tar.gz
  sudo install -o root -g root -m 0755 k9s /usr/local/bin/k9s
  rm k9s_Linux_amd64.tar.gz k9s
else
  echo "k9s is already installed"
fi

echo "Starting minikube..."
if ! minikube status | grep -q "Running"; then
  minikube start
else
  echo "minikube is already running"
fi

echo -e "\nVerifying installations:"
echo "minikube version: $(minikube version --short)"
echo "kubectl version: $(kubectl version --client -o yaml | grep -m 1 gitVersion)"
echo "Helm version: $(helm version --short)"
echo "k9s version: $(k9s version)"

echo ""
echo "**************************************************************************************"
echo ""

echo "SECTION 2 - CONTENT RELATED SERVICES"

echo "Installing Qbittorrent"

sudo apt install -y qbittorrent-nox

echo "Creating systemd service for Qbittorrent..."
sudo tee /etc/systemd/system/qbittorrent.service <<EOF
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
Type=simple
User=${USER}
ExecStart=/usr/bin/qbittorrent-nox
ExecStop=/usr/bin/killall -w qbittorrent-nox
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start qbittorrent
sudo systemctl enable qbittorrent

echo "Installing Dropbox"

cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
sudo wget -O /usr/local/bin/dropbox "https://www.dropbox.com/download?dl=packages/dropbox.py"
sudo chmod +x /usr/local/bin/dropbox

echo "Creating systemd service for Dropbox..."
sudo tee /etc/systemd/system/dropbox.service <<EOF
[Unit]
Description=Dropbox Service
After=network.target

[Service]
Type=simple
User=${USER}
ExecStart=${HOME}/.dropbox-dist/dropboxd
ExecStop=/usr/local/bin/dropbox stop
Environment=DISPLAY=:0
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start dropbox
sudo systemctl enable dropbox

echo "Installing Plex"

echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -

sudo apt update

sudo apt install -y plexmediaserver

sudo mkdir -p /opt/plexmedia/{movies,tv,music}
sudo chown -R plex:plex /opt/plexmedia

if command -v ufw &>/dev/null; then
  echo "Configuring firewall..."
  sudo ufw allow 32400/tcp
fi

sudo systemctl status plexmediaserver

echo -e "\nInstallation complete!"
echo "Dropbox is now running as a service"
echo "To link your account, run: dropbox start"
echo "To check status, run: dropbox status"

echo "qBittorrent-nox is now running as a service"
echo "Default web interface is available at: http://localhost:8080"
echo "Default login credentials:"
echo "Username: admin"
echo "Password: adminadmin"

echo "gh cli installed run the following to auth"
echo "gh auth login"

echo "Plex Media Server is now installed and running"
echo -e "\nImportant information:"
echo "1. Web interface: http://localhost:32400/web"
echo "2. Media directories created at /opt/plexmedia/:"
echo "   - Movies: /opt/plexmedia/movies"
echo "   - TV Shows: /opt/plexmedia/tv"
echo "   - Music: /opt/plexmedia/music"
echo -e "\nTo manage Plex service:"
echo "sudo systemctl start plexmediaserver   - Start Plex"
echo "sudo systemctl stop plexmediaserver    - Stop Plex"
echo "sudo systemctl restart plexmediaserver - Restart Plex"
echo "sudo systemctl status plexmediaserver  - Check Status"

# Get server IP address for remote access
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\nAccess Plex from another device using:"
echo "http://${SERVER_IP}:32400/web"
