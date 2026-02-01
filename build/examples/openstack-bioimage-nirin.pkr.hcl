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
  image_name          = "bioimage"
  flavor              = "c3.1c2m10d"
  networks            = [""] # update via: openstack network list - select network associated with your project
  availability_zone   = "CloudV3"
  source_image        = "68b8635c-9ae8-457a-afd6-b8609a36bf66"
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
    "ANSIBLE_SCP_IF_SSH=True"  # ← This is the key fix
  ]

  use_proxy = false
 }
}
