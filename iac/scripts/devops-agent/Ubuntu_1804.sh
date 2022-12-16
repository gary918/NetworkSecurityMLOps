#!/bin/bash

#************************Install Devops Agent to folder myagent and config it********************#
# ~/$ wget https://vstsagentpackage.azureedge.net/agent/2.194.0/vsts-agent-linux-x64-2.194.0.tar.gz
# ~/$ mkdir myagent && cd myagent
# ~/myagent$ tar zxvf ~/vsts-agent-linux-x64-2.194.0.tar.gz
# ~/myagent$ ./config.sh
## Prepare https://dev.azure.com/{YourOrgName} and PAT Token for configuration
#*************************************************************************************************#


#Install Python 
sudo apt update
sudo apt install python3.7 python3.8


#Install Pip based on python3
sudo apt update
sudo apt install python3-pip
sudo ln -s /usr/bin/pip3 /usr/bin/pip


#link 'Python' command to python3 
sudo mv /usr/bin/python /usr/bin/python.bak
sudo ln -s /usr/bin/python3 /usr/bin/python


#Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
#Add docker user, need to restart the vm
sudo usermod -aG docker azureuser
usermod -aG root azureuser


#Install Azure-CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#Install zip jq and azure devops extension
sudo apt-get -y install zip
sudo apt-get install jq
az extension add --name azure-devops


# Install PowerShell
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell


#Start Agent in Background
#~$ cd myagent
nohup ./run.sh&
