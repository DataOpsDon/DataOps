
az login --tenant ""
az account set --subscription ""
az deployment group create --resource-group "rg-dbr-snbox-dev01" --template-file "main.bicep"