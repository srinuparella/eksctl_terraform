
kub_sub = {

  vpcname = "dev_vpc"
  vpccidr = "192.168.0.0/16"
  subnetvalues = {
    subname = "dev_subnet"
    subcidr = "192.168.0.0/24"
    subaz   = "ap-south-1a"
  }
  ig_values = {
    ig_name = "dev_allow_internet"
  }
  rt_values = {
    rtname = "dev_ec2_allow_traffic"
    rtcidr = "0.0.0.0/0"
  }
  sg_values = {
    sgname = "dev_open"
    sgdecs = "dev_openalltraffic"

  }
  ingress_values = {
    ing_from_port = 22
    ing_to_port   = 22
    ingproto      = "TCP"
    ingcidr       = "0.0.0.0/0"
    ingdesc       = "allow ssh"
  }
  egress_values = {
    egr_from_port = 0
    egr_to_port   = 0
    egrproto      = "-1"
    egrcidr       = "0.0.0.0/0"
    egrdesc       = "allow all"
  }
 keypair = {
      keyname = "dev-key-pair"
      pubkey =  "~/.ssh/<Your Pub Key>"
   }
}




