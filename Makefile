#!make
include .env
#export $("shell sed 's/=.*//' .env")

OS=$(shell lsb_release -cs)

rng-tools:
	grep -F -e rdseed -e rdrand /proc/cpuinfo || test -f /etc/default/rng-tools || (apt-get install rng-tools -y && echo "HRNGDEVICE=/dev/urandom" >> /etc/default/rng-tools && systemctl restart rng-tools)

sysctl:
	@echo "/etc/sysctl.conf : Preventing issue with docker networking"
	echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
	echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf

docker:
	@echo "Installing Docker (version 2019-12-12)"
	apt-get update
	sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(OS) stable"
	apt-get update
	apt-get install docker-ce docker-ce-cli containerd.io -y

docker-compose:
	@echo "Installing Docker Compose 1.25.0"
	curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(shell uname -s)-$(shell uname -m)" -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose

lazydocker:
	echo "Installing lazydocker"
	curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

htop:
	echo "Installing htop"
	apt-get install htop -y

mc:
	echo "Installing Midnight Commander"
	apt-get install mc -y

user:
	echo "Creating user $(USERNAME)"
	adduser --gecos "" $(USERNAME)
	usermod $(USERNAME) --append --groups docker
	sudo -u $(USERNAME) ssh-keygen -t rsa -b 2048 -f /home/$(USERNAME)/.ssh/id_rsa -N ""
	echo "Here is generated RSA public key for user $(USERNAME):"
	cat /home/$(USERNAME)/.ssh/id_rsa.pub
	systemctl restart sshd.service
