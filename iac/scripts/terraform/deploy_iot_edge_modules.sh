#!/bin/bash

set -e

deployment_temp_file="deployment.grpc.amd64.json"
deployment_file="deployment.json"
VIDEO_OUTPUT_FOLDER_ON_DEVICE="/var/media/"
VIDEO_INPUT_FOLDER_ON_DEVICE="/home/localedgeuser/samples/input"
APPDATA_FOLDER_ON_DEVICE="/var/lib/videoanalyzer/"

# Form the url
url="https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.Media/videoAnalyzers/${ava_name}/edgeModules/${ava_edgemodule_name}/listProvisioningToken?api-version=2021-05-01-preview"

# Get access token
printf "getting azure access token\n"
access_token=`az account get-access-token |jq '.accessToken'`
access_token=`echo ${access_token} | sed 's/\"//g'`
echo $access_token

# Get AVA provisioning token
printf "getting AVA provisioning token\n"
list_token_cmd="curl --location --request POST '${url}' --header 'Authorization: Bearer ${access_token}' --header 'Content-Type: application/json' --data-raw '{\"expirationDate\": \"3021-01-23T11:04:49.0526841-08:00\"}' | jq '.token'"
AVA_PROVISIONING_TOKEN=$(eval $list_token_cmd)
AVA_PROVISIONING_TOKEN=`echo ${AVA_PROVISIONING_TOKEN} | sed 's/\"//g'`
echo $AVA_PROVISIONING_TOKEN

# Replace AVA provisioning token in deployment.json
printf "updating deployment.json\n"
cp $deployment_temp_file $deployment_file
# sed -i '' "s@\$AVA_PROVISIONING_TOKEN@${AVA_PROVISIONING_TOKEN}@g" $deployment_file # Changed to run on MacOS
sed -i "s@\$AVA_PROVISIONING_TOKEN@${AVA_PROVISIONING_TOKEN}@g" $deployment_file 
sed -i "s@\$VIDEO_OUTPUT_FOLDER_ON_DEVICE@${VIDEO_OUTPUT_FOLDER_ON_DEVICE}@g" $deployment_file
sed -i "s@\$VIDEO_INPUT_FOLDER_ON_DEVICE@${VIDEO_INPUT_FOLDER_ON_DEVICE}@g" $deployment_file
sed -i "s@\$APPDATA_FOLDER_ON_DEVICE@${APPDATA_FOLDER_ON_DEVICE}@g" $deployment_file

# deploy the manifest to the iot hub
printf "deploying manifest to $iot_edge_device_name on $iot_hub_name\n"
az iot edge set-modules --device-id $iot_edge_device_name --hub-name $iot_hub_name --content $deployment_file --only-show-error -o table