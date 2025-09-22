terraform {
  backend "s3" {
    bucket = "dev-richard-bucket"
    key = "env/dev/srinustatefile"
    region = "ap-south-1"
  }

# #   Yes, specifying "env/dev/srinustafile" makes Terraform store the state file inside that path with the file name srinustafile.
# #   backend "local" {
# #     path = "C:/Users/lenovo/Downloads/test-pod-sep/hbh"
# #   }
  }
provider "aws" {
  region = "ap-south-1"
}


