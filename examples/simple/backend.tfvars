# Static vars for backend config:
# Usage:
#  terraform init -backend-config backend.tfvars
resource_group_name  = "some-random-rg"
storage_account_name = "somerandomstorage01"
container_name       = "tfbackend"
key                  = "nsgexample.tfstate"
