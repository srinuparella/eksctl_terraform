variable "kub_sub" {
  type = object({

    vpcname = string
    vpccidr = string
    subnetvalues = object({
      subname = string
      subcidr = string
      subaz   = string
    })
    ig_values = object({
      ig_name = string
    })
    rt_values = object({
      rtname = string
      rtcidr = string
    })
    sg_values = object({
      sgname = string
      sgdecs = string
    })
    ingress_values = object({
      ing_from_port = number
      ing_to_port   = number
      ingproto      = string
      ingcidr       = string
      ingdesc       = string
    })
    egress_values = object({
      egr_from_port = number
      egr_to_port   = number
      egrproto      = string
      egrcidr       = string
      egrdesc       = string
    })
    keypair = object({
      keyname = string
      pubkey =  string  
    })
  })

}