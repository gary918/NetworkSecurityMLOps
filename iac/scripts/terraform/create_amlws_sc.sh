# Shell scripts to create a service connection for AML workspace
# Called by: service_endpoint.tf
# Parameters:
# tenant_id="xxx"
# sp_id="xxx"
# sp_key="xxx"
# subscription_id="xxx"
# subscription_name="xxx"
# resource_group_name="xxx"
# amlws_name="xxx"
# location="xxx"
# creation_mode="Manual" or "Automatic"
# amlws_sc_name="xxx"
# project_name="xxx"
# org_url="https://dev.azure.com/xxx"

#!/bin/bash

set -e

amlws_sc_config_tmpl="amlws_sc_config_tmpl.json"
amlws_sc_config="amlws_sc_config.json"

printf "Updating amlws_sc_config.json\n"
cp $amlws_sc_config_tmpl $amlws_sc_config
sed -i -e 's/{tenant_id}/'${tenant_id}'/g' $amlws_sc_config
sed -i -e 's/{sp_id}/'${sp_id}'/g' $amlws_sc_config
sed -i -e 's/{sp_key}/'${sp_key}'/g' $amlws_sc_config
sed -i -e 's/{subscription_id}/'${subscription_id}'/g' $amlws_sc_config
sed -i -e 's/{subscription_name}/'${subscription_name}'/g' $amlws_sc_config

sed -i -e 's/{resource_group_name}/'${resource_group_name}'/g' $amlws_sc_config
sed -i -e 's/{amlws_name}/'${amlws_name}'/g' $amlws_sc_config
sed -i -e 's/{location}/'${location}'/g' $amlws_sc_config
sed -i -e 's/{creation_mode}/'${creation_mode}'/g' $amlws_sc_config
sed -i -e 's/{amlws_sc_name}/'${amlws_sc_name}'/g' $amlws_sc_config

printf "Creating AML workspace service connection..."
az devops service-endpoint create --service-endpoint-configuration $amlws_sc_config -p $project_name --org $org_url