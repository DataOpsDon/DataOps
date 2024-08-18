az login 

az deployment group create `
--resource-group "rg-avm-test-01" `
--template-file "main.bicep"