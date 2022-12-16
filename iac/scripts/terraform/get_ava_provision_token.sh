#!/bin/bash
set -e

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
echo "{\"token\": \"${AVA_PROVISIONING_TOKEN}\"}"