# Kubernetes Cluster Installation

Using terraform and ansible to install a high availability kubernetes cluster followed this instruction: https://kubernetes.io/docs/setup/independent/high-availability/

## Prerequisites

* Terraform version v0.11.8 (other version may work as well, but not tested)
* Configured cloudstack terraform provider - [Cloudstack Provider Configuration](#cloudstack-provider-configuration)

## Run example

     terraform init
     terraform get
     terraform plan -var-file='./exoscale.tfvars' -out=next-steps.plan
     terraform apply -parallelism=10 next-steps.plan

## Cloudstack Provider Configuration

To configure the cloudstack provider just create a file exoscale.tfvars inside the
root directory of this example, which contains information about the API. Eg.

      cloudstack_api_url = "https://api.exoscale.ch/compute"
      cloudstack_api_key = "EXO02a0186f1234ab2a606700a9"
      cloudstack_secret_key = "6uRPl00k9EddcljHJlywFJEFFOUzJnV9GXICXyicgvY"

## Contribute

Before contribution run

      terraform fmt
      terraform validate -var-file='./exoscale.tfvars'

to run

## Clean up

terraform destroy -parallelism=10 -var-file='./exoscale.tfvars'
