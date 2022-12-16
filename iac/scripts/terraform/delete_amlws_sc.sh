# Shell script used to delete the service connection by name
# Called by: service_endpoint.tf

# Parameters:
# amlws_sc_name="svc_connection"
# project_name="projectname"
# org_url="https://dev.azure.com/xxx"

printf "Deleting service connection: ${amlws_sc_name} ..."
sc_id=`az devops service-endpoint list --org ${org_url} -p ${project_name} --query "[?name=='${amlws_sc_name}'].id" -o tsv`
az devops service-endpoint delete --id $sc_id --org $org_url -p $project_name -y