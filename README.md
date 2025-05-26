# terraformProyect1
Automatic deployment of web server cluster in Azure using GitHub wokflows and Terraform

This proyect's goal is to automate the deployment and destroy of a web server cluster in Azure using Terraform with a remote backend, the terraform plan and server's public IP are available after the run for testing.
To make the code function on an Azure account, you must install azure clin and execute the following commands using your tenat ID and subscription ID:

az login --tenant xxxxxxxxxxxxxxxx --use-device-code

az account set --subscription "xxxxxxxxxxxxxxxx"

az ad sp create-for-rbac --name "github-actions-terraform" --role="Contributor" --scopes="/subscriptions/xxxxxxxxxxxxxxxx" --sdk-auth


Use the last command's output to populate the following secrets used in the workflows:

ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
