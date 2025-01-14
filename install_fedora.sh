#!/bin/bash -x
set -eu -o pipefail

install_packages() {
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y \
    bind-chroot \
    bind-utils \
    binutils \
    btrfs-progs \
    cronie \
    direnv \
    dnf-plugins-core \
    etcd \
    fd-find \
    git \
    google-cloud-sdk-gke-gcloud-auth-plugin \
    golang-x-tools-gopls \
    htop \
    iproute \
    iputils \
    jq \
    moby-engine \
    mysql-devel \
    neovim \
    net-tools \
    nmap-ncat \
    npm \
    openssl-devel \
    python \
    python2 \
    python3-neovim \
    python3-numpy \
    redhat-rpm-config \
    ripgrep \
    ruby \
    ruby-devel \
    rubygems \
    socat \
    strace \
    tcpdump \
    the_silver_searcher \
    tmux \
    util-linux-user \
    wget \
    zlib-devel \
    zsh \
    zsh-lovers \
    zsh-syntax-highlighting \

}

install_azure_cli() {
  if [ ! -x /usr/bin/az ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
    sudo dnf install -y azure-cli
  fi
}

install_bosh_cli() {
  if [ ! -x /usr/local/bin/bosh ]; then
    curl -sL https://github.com/cloudfoundry/bosh-cli/releases/download/v7.0.0/bosh-cli-7.0.0-linux-amd64 -o /tmp/bosh
    sudo install /tmp/bosh /usr/local/bin
  fi
}

install_cf_cli() {
  if [ ! -x /usr/bin/cf ]; then
    sudo wget -O /etc/yum.repos.d/cloudfoundry-cli.repo https://packages.cloudfoundry.org/fedora/cloudfoundry-cli.repo
    sudo dnf install -y cf7-cli
  fi
}

install_rtr_cli() {
  if [ ! -x /usr/local/bin/rtr ]; then
    curl -sL https://github.com/cloudfoundry/routing-api-cli/releases/download/2.23.0/rtr-linux-amd64.tgz -o /tmp/rtr.tgz
    pushd /tmp/
    tar xzvf /tmp/rtr.tgz
    sudo install rtr-linux-amd64 /usr/local/bin/rtr
  fi
}

install_chruby() {
  if [ ! -d /usr/local/share/chruby ] ; then
    wget -O ruby-install-0.8.3.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.3.tar.gz
    tar -xzvf ruby-install-0.8.3.tar.gz
    cd ruby-install-0.8.3/
    sudo make install

    wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
    tar -xzvf chruby-0.3.9.tar.gz
    cd chruby-0.3.9/
    sudo make install
    cat >> ~/.zshrc <<EOF

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
EOF
  fi
}

install_fasd() {
  if [ ! -x /usr/local/bin/fasd ]; then
    cd ~/workspace
    git clone git@github.com:clvv/fasd.git
    cd fasd
    sudo make install
    cat >> ~/.zshrc <<EOF

eval "\$(fasd --init posix-alias zsh-hook)"
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
EOF
  fi
}

# Fedora is out-of-date at 1.16.5, should be 1.18; no ip.IsPrivate(), no cf-acceptance-tests
install_go() {
  if [ ! -d /usr/local/go ]; then
    curl -L https://go.dev/dl/go1.18.1.linux-amd64.tar.gz -o /tmp/go.tgz
    sudo tar -C /usr/local -xzvf /tmp/go.tgz
  fi
}

install_bin() {
  if [ ! -d $HOME/bin ]; then
    git clone git@github.com:cunnie/bin.git $HOME/bin
    echo 'PATH="$HOME/bin:$PATH:/usr/local/go/bin"' >> ~/.zshrc
    ln -s ~/bin/env/git-authors ~/.git-authors
  fi
}


install_fly_cli() {
  if [ ! -x $HOME/bin/fly ]; then
    curl -s -o $HOME/bin/fly 'https://ci.nono.io/api/v1/cli?arch=amd64&platform=linux'
    sudo chmod +x $HOME/bin/fly
  fi
}

install_om_cli() {
  if [ ! -x /usr/local/bin/om ]; then
    curl -s -L -o /tmp/om https://github.com/pivotal-cf/om/releases/download/6.3.0/om-linux-6.3.0
    sudo install /tmp/om /usr/local/bin
  fi
}

install_pivnet_cli() {
  if [ ! -x /usr/local/bin/pivnet ]; then
    curl -s -L -o /tmp/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v2.0.1/pivnet-linux-amd64-2.0.1
    sudo install /tmp/pivnet /usr/local/bin
  fi
}

install_luan_nvim() {
  if [ ! -d $HOME/.config/nvim ]; then
    git clone https://github.com/luan/nvim $HOME/.config/nvim
    /usr/bin/python3 -m pip install pynvim
    sudo yarn global add neovim
    sudo yarn global add tree-sitter tree-sitter-cli
  else
    echo "skipping Luan's config; it's already installed"
  fi
  # fix "missing dependencies (fd)!"
  if [ ! -f /usr/bin/fd ]; then
    sudo ln -s /usr/bin/fdfind /usr/bin/fd
  fi
}

install_terraform() {
  if [ ! -x /usr/local/bin/terraform ]; then
    curl -o tf.zip -L https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip
    unzip tf.zip
    sudo install terraform /usr/local/bin/
  fi
}

install_helm() {
  if [ ! -x /usr/local/bin/helm ]; then
    TMP_DIR=/tmp/install-$$
    mkdir $TMP_DIR
    curl -o $TMP_DIR/helm.tgz -L https://get.helm.sh/helm-v3.6.1-linux-amd64.tar.gz
    pushd $TMP_DIR
    tar xzvf helm.tgz
    sudo install linux-amd64/helm /usr/local/bin/
    popd
  fi
}

install_aws_cli() {
  if [ ! -x /usr/local/bin/aws ]; then
    # From https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
  fi
}

install_zsh_autosuggestions() {
  if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
      sed -i 's/^plugins=(/&zsh-autosuggestions /' $HOME/.zshrc
  fi
}

install_gcloud() {
  YUM_REPO_PATH=/etc/yum.repos.d/google-cloud-sdk.repo
  if [ ! -f $YUM_REPO_PATH ]; then
    sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
    sudo dnf install -y google-cloud-sdk
  fi
}

install_yq() {
  if [ ! -x /usr/local/bin/yq ]; then
    curl -o yq -L https://github.com/mikefarah/yq/releases/download/v4.14.1/yq_linux_amd64
    chmod +x yq
    sudo install yq /usr/local/bin/
    rm yq
  fi
}

install_vault() {
  if [ ! -x /usr/bin/vault ]; then
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf -y install vault
  fi
}

install_git_duet() {
  if [ ! -x /usr/local/bin/git-duet ]; then
    mkdir -p /tmp/$$/git-duet
    pushd /tmp/$$
    curl -o git-duet.tgz -L https://github.com/git-duet/git-duet/releases/download/0.9.0/linux_amd64.tar.gz
    tar -xzvf git-duet.tgz -C git-duet/
    sudo install git-duet/* /usr/local/bin
    popd
  fi
}

configure_direnv() {
  if ! grep -q "direnv hook zsh" ~/.zshrc; then
    echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
    eval "$(direnv hook bash)"
  fi
  for envrc in $(find "$HOME/workspace" -maxdepth 2 -name '.envrc' -print); do
    pushd $(dirname $envrc)
      direnv allow
    popd
  done
}

configure_docker() {
  # https://fedoramagazine.org/docker-and-fedora-32/
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
}

configure_zsh() {
  if [ ! -f $HOME/.zshrc ]; then
    sudo chsh -s /usr/bin/zsh $USER
    echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc
    echo 'eval "$(fasd --init posix-alias zsh-hook)"' >> ~/.zshrc
    echo 'export EDITOR=nvim' >> ~/.zshrc
    echo 'alias k=kubectl' >> ~/.zshrc
    echo "# Don't log me out of LastPass for 10 hours" >> ~/.zshrc
    echo 'export LPASS_AGENT_TIMEOUT=36000' >> ~/.zshrc
    echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True # fixes "WARNING: the gcp auth plugin is deprecated in v1.22+, unavailable in v1.25+;' >> ~/.zshrc
  fi
}

use_pacific_time() {
  sudo timedatectl set-timezone America/Los_Angeles
}

configure_git() {
  # https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
  git config --global user.name "Brian Cunnie"
  git config --global user.email brian.cunnie@gmail.com
  git config --global alias.co checkout
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  git config --global color.branch auto
  git config --global color.diff auto
  git config --global color.status auto
  git config --global core.editor nvim
}

configure_tmux() {
  # https://github.com/luan/tmuxfiles, to clear, `rm -rf ~/.tmux.conf ~/.tmux`
  if [ ! -f $HOME/.tmux.conf ]; then
    echo "WARNING: If this scripts fails with \"unknown variable: TMUX_PLUGIN_MANAGER_PATH\""
    echo "If you don't have an ugly magenta bottom of your tmux screen, if nvim is unusable, then"
    echo "you may need to run this command to completely install tmux configuration:"
    echo "zsh -c \"\$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)\""
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)"
  fi
}

configure_bind() {
  if ! sudo grep -q nono.io /etc/named.conf; then
    sudo sed -i 's/listen-on port 53.*/listen-on port 53 { any; };/;
      s/listen-on-v6 port 53.*/listen-on-v6 port 53 { any; };/;
      s/allow-query.*/allow-query     { any; }; allow-query-cache { any; };/' /etc/named.conf
    sudo tee -a /etc/named.conf << EOF
zone "9.0.10.in-addr.arpa" {
	type slave;
	file "9.0.10.in-addr.arpa";
	masters {
		2601:646:100:69f0::a; // atom.nono.io
	};
};
zone "nono.io" {
	type slave;
	file "nono.io";
	masters {
		2a01:4f8:c17:b8f::2; //shay.nono.io
	};
};
EOF
    sudo systemctl enable named-chroot
    sudo systemctl start named-chroot
  fi
}

disable_firewalld() {
  # so that BIND can work
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
}

install_packages
configure_zsh          # needs to come before install steps that modify .zshrc
install_azure_cli
install_bosh_cli
install_cf_cli
install_rtr_cli
install_chruby
install_fasd
install_git_duet
install_go
install_bin
install_fly_cli
install_om_cli
install_pivnet_cli
install_terraform
install_helm
install_aws_cli
install_luan_nvim
install_zsh_autosuggestions
install_gcloud
install_yq
install_vault
use_pacific_time
disable_firewalld
configure_bind
configure_direnv
configure_docker
configure_git
configure_tmux
