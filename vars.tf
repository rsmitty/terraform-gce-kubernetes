#####################
## Google provider ##
#####################
variable "gce_cred_path" { default="/home/rsmitty/Downloads/terraform-testbed-gcloud.json" }
variable "gce_project" { default="testbed-1160" }
variable "gce_region" { default="us-central1" } 
variable "gce_zone" { default = "us-central1-c" }
variable "gce_talos_img" { default="talos" }
variable "gce_talos_disk_size" { default="10" }
variable "gce_talos_flavor" { default="g1-small" }
## There should be one floating IP per master
variable "gce_talos_master_ips" { 
    default = {
        "0" = "xxx"
        "1" = "yyy"
        # "2" = "zzz"
    } 
}

################
## Talos vars ##
################

## Should be same count as number of IPs below
variable "talos_master_count" { default=2 }
variable "talos_worker_count" { default=0 }

variable "talos_user" {
    default="rsmitty"
}

variable "talos_cluster_name" {
    default="talos-gce"
}