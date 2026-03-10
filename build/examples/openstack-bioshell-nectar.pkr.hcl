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
  flavor              = "r3.small"
  source_image        = "c0250c96-98a4-4bfa-b67c-51874808337f"
  ssh_username        = "ubuntu"
  volume_size          = 20
}

build {
  sources = ["source.openstack.ubuntu"]

provisioner "ansible" {
  playbook_file = "./build-bioshell.yml"
  
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
