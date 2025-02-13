RG = frigo-we
INST = 0


all:
	az deployment group create -g $(RG) --template-file all.bicep --parameters @params.json --parameters @tags.json

fw:
	az deployment group create -g $(RG) --template-file fw.bicep --parameters @params.json --parameters @tags.json

disk:
	az deployment group create -g $(RG) --template-file disk.bicep --parameters @params.json --parameters @tags.json

nvme:
	az deployment group create -g $(RG) --template-file $@.bicep --parameters @params.json --parameters @tags.json -o table

kv:
	az deployment group create -g $(RG) --template-file $@.bicep --parameters @tags.json -o table
	az keyvault key show --vault-name frigo-we-kv --name ec -o json | jq -r .key.kid
	az keyvault key show --vault-name frigo-we-kv --name rsa -o json | jq -r .key.kid

stop:
	az vm deallocate -g $(RG) -n vm1
	az vm deallocate -g $(RG) -n vm2
	az vmss scale -n fw -g $(RG) --new-capacity 0
start:
	az vm start -g $(RG) -n vm1
	az vm start -g $(RG) -n vm2
	az vmss scale -n fw -g $(RG) --new-capacity 1
delete:
	az vm delete -g $(RG) -n vm1 -y
	az vm delete -g $(RG) -n vm2 -y
	az vmss scale -n fw -g $(RG) --new-capacity 0

list:
	@az vm list -g $(RG) --show-details -o table
	@az vmss list-instances -g $(RG) -n fw -o table
	@az vmss nic list -g $(RG) --vmss-name fw -o json | jq -r '.[] | .ipConfigurations[0].privateIPAddress'
	az vmss show -n fw -g $(RG) -o json | jq .id,.tags.fastpathenabled
	az network vnet show -o json -g $(RG) -n vnetfw | jq .tags.fastpathenabled
	az vmss show --instance-id $(INST) -n fw -g $(RG) -o json | jq .id,.sku.name,.timeCreated
	az vmss nic show --name nic -g $(RG) --vmss-name fw --virtualmachine-index $(INST) -o json | jq '.auxiliaryMode,.auxiliarySku'
	az vm show -n vm1 -g $(RG) -o json | jq .id,.timeCreated
	az vm show -n vm2 -g $(RG) -o json | jq .id,.timeCreated
	az network lb show -g $(RG) -n lb -o json | jq '.id,.frontendIPConfigurations[].zones[]'

nw:
	az deployment group create -g NetworkWatcherRG --template-file nw.bicep --parameters @tags.json --parameters targetRg=$(RG)

security:
	az deployment group create -g $(RG) --template-file security.bicep

client: pkg/client/client.go
	go build pkg/client/client.go

server: pkg/server/server.go
	go build pkg/server/server.go
