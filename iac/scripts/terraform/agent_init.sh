#!/bin/sh

# python3.6.9 installed by default
# Install Python 
# sudo apt update
# sudo apt install python3.7 -y


#Install Pip based on python3
sudo apt-get update
sudo apt-get install python3-pip -y
sudo ln -s /usr/bin/pip3 /usr/bin/pip


#link 'Python' command to python3 
sudo mv /usr/bin/python /usr/bin/python.bak
sudo ln -s /usr/bin/python3 /usr/bin/python


#Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
#Add docker user, need to restart the vm
sudo usermod -aG docker ${AGENT_USERNAME}
sudo usermod -aG root ${AGENT_USERNAME}


#Install Azure-CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#Install zip jq and azure devops extension
sudo apt-get -y install zip
sudo apt-get install jq -y
sudo runuser -l ${AGENT_USERNAME} -c 'az extension add --name azure-devops'
#sudo az extension add --name azure-cli-ml -y
# sudo apt install flake8 -y


# Install PowerShell
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Creates directory & download ADO agent install files
sudo mkdir /myagent 
cd /myagent
sudo wget https://vstsagentpackage.azureedge.net/agent/2.194.0/vsts-agent-linux-x64-2.194.0.tar.gz
sudo tar zxvf ./vsts-agent-linux-x64-2.194.0.tar.gz
sudo chmod -R 777 /myagent

# Unattended install
sudo runuser -l ${AGENT_USERNAME} -c '/myagent/config.sh --unattended  --url ${ADO_ORG_SERVICE_URL} --auth pat --token ${ADO_PAT} --pool ${AGENT_POOL}'

cd /myagent
#Configure as a service
sudo ./svc.sh install ${AGENT_USERNAME}
#Start svc
sudo ./svc.sh start

# Reboot the vm 
# sudo reboot