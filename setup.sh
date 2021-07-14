#!/bin/bash

. ./codexsoft.dialog.sh

echo "Welcome dockerizer script. Should be executed by root user."

if [ "${UID}" == '0' ]
then
  echo 'Seems that you are under root, all right.'
else
  if confirm "WARNING. Seems that you are NOT under root. Do you want to continue?"
  then
    echo '';
  else
    exit 0;
  fi
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm "Allow tools like xip.io? This will set net.ipv4.conf.default.rp_filter and net.ipv4.conf.all.rp_filter to 0 in /etc/sysctl.conf"
then
  echo "/etc/sysctl.conf : Preventing issue with docker networking"
  echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
  echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
fi

if confirm_default_yes "Install Docker Enging?"
then
  apt-get update
  if confirm "Uninstall any previously installed Docker Engine versions?"
  then
    apt-get remove docker docker-engine docker.io containerd runc
  fi
  sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install docker-ce docker-ce-cli containerd.io -y
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm_default_yes "Install Docker Compose?"
then
  prompt DOCKER_COMPOSE_VERSION "Docker Compose version to install:" "1.26.0"
  curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm_default_yes "Restrict Docker containers IP range for containers?"
then
  prompt CONTAINERS_ALLOWED_NETWORK "Network range to allow:" "172.17.0.0/16"
  echo '{"default-address-pools":[{"base":"'"$CONTAINERS_ALLOWED_NETWORK"'","size":24}]}' > /etc/docker/daemon.json
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
echo "Searching for existing random digit generator..."
RND_INSTALLED=$( [[ -z $(grep -F -e rdseed -e rdrand /proc/cpuinfo) ]] || echo 1 )

if [ "${RND_INSTALLED}" == '1' ]
then
  echo 'Seems that random number generator installed on the system'
else
  echo 'Seems that random number generator IS NOT installed on the system'
  echo 'It may cause issues like this: https://github.com/docker/compose/issues/6931'
  if confirm_default_yes "Install rng-tools to fix it?"
  then
    apt-get install rng-tools -y
    echo "HRNGDEVICE=/dev/urandom" >> /etc/default/rng-tools && systemctl restart rng-tools
  fi
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm "Allow AllowTcpForwarding for SSH? (it is handy to connect to DB through SSH tunnel)"
then
  echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
  service ssh restart
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm_default_yes "Install Midnight Commander?"
then
  apt-get install mc -y
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm_default_yes "Install HTOP?"
then
  apt-get install htop -y
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm_default_yes "Install lazydocker ( https://github.com/jesseduffield/lazydocker )?"
then
  echo "Installing lazydocker"
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm "Create docker network for traefik — traefik-local-network?"
then
  docker network create --driver bridge traefik-local-network || true
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - "
if confirm "Create new user (handy when deploying on server)?"
then
  prompt USERNAME "Enter new user name:" "server"
  adduser --gecos "" "$USERNAME"
  usermod server --append --groups docker
  sudo -u server ssh-keygen -t rsa -b 2048 -f /home/"$USERNAME"/.ssh/id_rsa -N ""
  echo "Here is generated RSA public key for user $USERNAME:"
  cat /home/"$USERNAME"/.ssh/id_rsa.pub
  systemctl restart sshd.service
fi
