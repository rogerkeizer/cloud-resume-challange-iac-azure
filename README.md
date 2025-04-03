# Infrastructure-as-code for Cloud Resume Challenge

__(Azure / [Terraform](https://www.terraform.io) version)__

This repository covers step 2 to 6, 12 and 13 of the Azure version of [the Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/azure/) created by [Forrest Brazeal](https://github.com/forrestbrazeal) and contains the files to deploy a static website on an Azure Storage Account with an Azure managed certificate and a custom domain name.

## Terraform
The Terraform Github packages used in this repository are [archived here](https://github.com/hashicorp/terraform-github-actions?tab=readme-ov-file). These packages are used in the yaml files in the .github/workflows folder. [These packages](https://github.com/hashicorp/setup-terraform) need to be implemented in order to replace the archived ones.

> At the time of writing this README it is possible to deploy the infra needed to host the static website for the Cloud Resume Challenge using these __archived__ packages.

### Create Terraform state (tfstate)

You have to create the storage account for the Terraform state manually. Log in the Azure portal by entering `az login` in your terminal.

Make sure to replace the `<SUBSCRIPTION ID>` with the id of your own subscription. You can find that `id` when entering `az account show` after logging on succesfully.

````
# Create Resource Group to hold the Terraform state resources
az group create -n rg-tfstate-test-westeur-001 -l westeurope

# Create Storage Account
az storage account create -n sttfstatetestwesteur001 -g rg-tfstate-test-westeur-001 -l westeurope --sku Standard_LRS
 
# Create Storage Account Container
az storage container create \
--account-name sttfstatetestwesteur001 \
--name tfstatecrciac \
--public-access off \
--fail-on-exist

# Create Service Principal and role
az ad sp create-for-rbac \
--name "sp-trstate-test" \
--role "Contributor" \
--scopes="/subscriptions/<SUBSCRIPTION ID>"
````

## Credentials
Please note the details in the output in your terminal, especially the password! You need these in the Github Action. Go to Settings of the repository. Choose Secrets and Variables and enter the app_id and password as Action secrets. See the yaml files in the folder .github/workflows for more details.

````
AZURE_AD_CLIENT_ID
AZURE_AD_CLIENT_SECRET
AZURE_AD_TENANT_ID
AZURE_SUBSCRIPTION_ID
````

## DNS
This tutorial assumes that you manage your domain's records yourself with an external domain name provider. Otherwise you have to create an Azure DNS Zone and some other configurations which are not tested or discussed in this repository (see the commented lines in `main.tf` for some reference).

### Creating
Before deploying the Terraform Create workflow you have to create a CNAME record for your custom domain. You have to decide upfront the name of the CDN endpoint of the storage account. Check the `variables.tf` file for the variables you have to provide a value for. Your static website can be reached at `https://<YOUR_DNS_ENDPOINT>.azureedge.net` so you have to map this CDN endpoint to your custom domain providing the CNAME record.
To enforce HTTP to HTTPS redirection you need a custom rule on the CDN endpoint resource.

### Deleting
Before deleting the resource group and the content make sure the CNAME record for your custom domain has been deleted. Azure or the Github Action workflow will __not__ delete the resources as long as this record exists.

## tfvars file
Not present in this repo is the variables.auto.tfvars file. In this file you will provide the values of the variables based on an environment. For example: `env-test.auto.tfvars`.
Terraform will load these values automatically when `auto` is present in the file name.
In `.gitignore` tfvars files are __excluded__ from source control because of potential security related information in these files.

The json structure of the tfvars file is:
````
rg_name              = "rg-crc-test-westeur-001"
location             = "westeurope"
tags = {
  environment = "test"
  provisioned = "terraform"
}
storage-account = {
    name                  = "stcrctestwesteur001"
    container             = "$web"
    kind                  = "StorageV2"
    tier                  = "Standard"
    replication           = "LRS"
    blob-type             = "Block"
    access-tier           = "Cool"
    container-access-type = "private"
    content-type          = "text/html"
    min-tls-version       = "TLS1_2"
}
cdn = {
    profile-name      = "cdnp-crc-test-westeur-001"
    profile-sku       = "Standard_Microsoft"
    endpoint          = "cdne-crc-test-westeur-001"
    min-tls-version   = "TLS1_2"
    caching-behaviour = "IgnoreQueryString"
    origin            = "origin-name"
    custom-domain     = "cdn-custom-domain"
    host-name         = "<your custom domain with subdomain>"
}
````

After running the Create workflow you have a basic static website containing two files. You have to manually upload or create another workflow to transfer your static website files to Azure.

## Failing Github Actions
The workflows will fail without the correct Azure credentials.
You will get this error: `Error building ARM Config: please ensure you have installed Azure CLI version 2.0.79 or newer. Error parsing json result from the Azure CLI: launching Azure CLI: exec: "az": executable file not found in $PATH.`

The solution is to proper configure credentials as described [here](https://github.com/rogerkeizer/cloud-resume-challange-iac-azure?tab=readme-ov-file#credentials) in this README.
