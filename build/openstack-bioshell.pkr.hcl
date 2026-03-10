packer {
  required_plugins {
    openstack = {
      version = ">= 1.1.2"
      source = "github.com/hashicorp/openstack"
    }

    ansible = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "openstack" "ubuntu" {
  image_name          = "bioshell"
  flavor              = "" # update via: openstack flavor list
  networks            = [""] # update via: openstack network list
  availability_zone   = "" # update via: openstack availability zone list
  source_image        = "" # update via: openstack image list
  ssh_username        = "ubuntu"
  volume_size          = 20
}

build {
  sources = ["source.openstack.ubuntu"]

provisioner "ansible" {
  playbook_file = "./build-bioimage.yml"
  
  extra_arguments = [
    "--extra-vars", "ansible_user=ubuntu"
  ]
  
  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SCP_IF_SSH=True"
  ]

  use_proxy = false
 }
}
