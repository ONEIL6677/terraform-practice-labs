provider "aws" {
  region = "us-east-1"
}

module "ec2_instance" {                #instead of resource write modules
  source = "./modules/ec2_instance"    # provide path of the module even if it is in another github account
  ami_value = "ami-053b0d53c279acc90"  # replace this
  instance_type_value = "t2.micro"
  subnet_id_value = "subnet-019ea91ed9b5252e7". # replace this
}

# you can pass variables to terraform.tfvars as well when trying to use a module if needed