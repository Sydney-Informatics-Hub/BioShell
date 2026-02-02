# BioImage

BioImage is a pre‑configured, cloud‑ready bioinformatics environment designed to make command‑line–based biological data analysis easy to deploy, use, and scale. The primary goal of BioImage is to provide researchers and training providers with a flexible and cost‑effective platform for running bioinformatics workflows without the overhead of complex system setup or infrastructure management.

BioImage enables users to focus on analysis and training, rather than on system configuration and resource provisioning.

### How BioImage Is Built
BioImage is built using Packer and Ansible, and is designed to run on OpenStack‑based cloud infrastructure. This approach enables reproducible image builds, consistent configuration, and rapid deployment. The result is a ready‑to‑use virtual machine (VM) image that includes commonly used bioinformatics tools, dependencies, and sensible defaults for CLI‑based analysis.

This repository contains configuration and automation for building a custom Ubuntu‑based BioImage and provisioning instances on OpenStack‑compatible cloud environments.

----------------------------
## Table of Contents
----------------------------
* [Spinning up a VM]()
* [Installation](#installation)
* [Environment](#environment)
    * [Downloading openstack credentials](#openstack-credentials)
    * [Setup](#setup)
    * [Activation](#activation)
* [Build Image](#build-image)
* [Using the BioImage](#Using-the-BioImage)

## Spinning up a VM in OpenStack

OpenStack is a cloud computing platform that lets you create and manage virtual machines (or instances), networks, and storage; an instance or VM is essentially a virtual computer running in the cloud.

The control host (or head VM) is the machine from which you manage and deploy resources on an OpenStack cloud. It is responsible for:

- Holding your OpenStack credentials (RC file)
- Running OpenStack CLI commands
- Orchestrating or launching additional compute resources
- Acting as the control point for bioimage installation and management

The head VM does not need to run workloads itself. It can be a VM running inside your OpenStack project (recommended) or a local machine (laptop or workstation) with network access to OpenStack APIs

For most users, a small Ubuntu VM inside OpenStack is the simplest and most reproducible option.
Recommended head VM characteristics:

```
Operating System: Ubuntu LTS (20.04 or newer)
CPU/RAM: minimal (e.g. 1–2 vCPUs, 2–4 GB RAM)
Access: SSH enabled via key pair
```

The following steps describe how to create a head VM using the generic OpenStack Horizon dashboard. Terminology may vary slightly between cloud providers, but the workflow is consistent across OpenStack environments.

### Launch an Instance

1. Log in to your OpenStack dashboard and navigate to `Compute → Instance` 
2. Select `launch instance`
3. The Launch Instance dialog will appear, open on the Details tab
4. Enter an instance name, choose a something descriptive (e.g. bioimage-head, control-host), and add a description

### Select the Source Image (Operating System)

1. In the source tab, Select Boot Source: Image
2. Choose a supported Ubuntu image (eg. Ubuntu 22.04)
3. If the bioimage has been previously built you should be able to select bioimage at this step.

### Choose an Instance Flavor

In the Flavor tab Select a small flavor suitable for administration tasks (eg. 1–2 vCPUs, 2–4 GB RAM)

NOTE: The flavor defines the CPU, memory, and (sometimes) ephemeral storage available to the VM.

### Select the Network

In the Networks tab select your project’s private network (often named like <project-name>-network)

NOTE: Do not select an external/public network here

### Select Security Groups

In the Security Groups tab, ensure the following are listed under Allocated by clicking the up arrow in the Avialable groups:
- **default** that allows outbound traffic and internal communication
- **SSH-access security group** that allows inbound TCP port 22 from your IP or network

SSH access is required to log in to the instance.

### Select a Key Pair

In the Key Pair tab:
- Select an existing key pair or create a new one
- This key pair is required for SSH access

Make sure you have access to the corresponding private key on your local machine.

### Launch the Instance

1. Click Launch Instance (You should not have to change anything in the other options after setting a key pair)
2. The instance will appear on the Instances page with status BUILD
3. When ready, its status will change to ACTIVE
4. Your head VM is now running.

### Assigning a Floating IP (External Access)

Depending on the cloud configuration, instances may receive only a private IP address (e.g. 192.168.x.x or 10.x.x.x) by default; to connect via SSH from outside the cloud, you must assign a Floating IP.

Allocate a Floating IP
1. Navigate to `Network → Floating IPs`
2. Click Allocate IP to Project
3. Select the public or external IP pool
4. Click Allocate IP

Associate the Floating IP
1. Next to the allocated IP, click Associate
2. Choose your newly created instance
3. Select its private network interface
4. Click Associate


## Installation

After creating and configuring your Ubuntu control host (head VM) as described above, log in to it via SSH (typically as the ubuntu user) 
```
ssh -i /path/to/your/key <remote_user>@<control_host_ip>
```
then clone this repository:

```
git clone https://github.com/AustralianBioCommons/bioimage
cd bioimage
```

## Environment

### OpenStack Credentials

Before proceeding, download your OpenStack RC file, `[project_id]-openrc.sh`, from your cloud provider’s OpenStack dashboard and copy it to the control host (head VM).

You can download your credentials from:

- the dashboard menu: `Project → API Access → Download OpenStack RC File → OpenStack RC File`, or
- the user drop-down menu in the top‑right corner, by selecting `⇩ OpenStack RC File`

This file contains the environment variables required to authenticate with OpenStack from the command line.

### Copying the RC File to the Control Host

If the RC file was downloaded to your local machine, copy it to the control host using scp. If your VM requires an SSH key for access, include the -i option:
```shell
scp -i /path/to/your/private_key \
    /path/to/[project_id]-openrc.sh \    
    <remote_user>@<control_host_ip>:/path/to/destination/
```
Example (template):
```Shell
scp -i ~/.ssh/your_ssh_key \ 
    ~/Downloads/my-project-openrc.sh \
    ubuntu@<control_host_ip>:/home/ubuntu/bioimage
```
Where:

- `/path/to/your/private_key` is the path to your SSH private key
- `/path/to/[project_id]-openrc.sh` is the local path to the downloaded RC file
- `<remote_user>` is the username used to access the control host
- `<control_host_ip>` is the IP address or hostname of the control host
- `/path/to/destination/` is the target directory on the control host

Once copied, confirm the file is present on the control host before sourcing it during environment activation.

### Setup

The environment requires the following tools:
- Packer
- Ansible
- OpenStack CLI

Run the setup script to install dependencies and configure the environment:
```
./setup.sh
```

### Activation
To use your OpenStack credentials, load the RC file into your shell environment using source:
```
source openstack_cli/bin/activate
source /path/to/[project_id]-openrc.sh
```
You will be prompted:
```
Please enter your OpenStack Password for project [project_id] as [username]:
```
Enter your OpenStack password. If the command succeeds, no output will be shown. You can verify that the credentials were loaded by checking one of the OpenStack environment variables:
```
echo $OS_PROJECT_NAME
```
If a project name is returned, your OpenStack environment is configured correctly and ready for use. If it is blank, you may have made a mistake or put in the wrong password. Make sure you are using the right password and try again.

## Build Image

### Step 1: Initialize Packer
Navigate to the `build` directory and initialize the Packer plugins:
```
cd bioimage/build
packer init .
```

### Step 2: Build the BioImage

Before running the build, review and update `openstack-bioimage.pkr.hcl` to ensure the values match your OpenStack environment.

**Note: Example working configurations for [Nectar](build/examples/openstack-bioimage-nectar.pkr.hcl) and [Nirin](build/examples/openstack-bioimage-nirin.pkr.hcl) are included and were last successfully tested on 2 February 2026. The Nirin configuration requires you to add your project [network](#network-cloud-dependant).**

At a minimum, check the following fields in the `source "openstack"` block:
#### Source Image (Base OS)
Use this to find a suitable Ubuntu image to use as the build source:
```
openstack image list
```
Example output:
```
+--------------------------------------+-------------------------------+--------+
| ID                                   | Name                          | Status |
+--------------------------------------+-------------------------------+--------+
| <uuid>                               | Ubuntu 20.04                  | active |
+--------------------------------------+-------------------------------+--------+
```
Copy the ID of the image you want to use and set it as:
```
source_image = "<ubuntu-image-uuid>"
```

#### Flavor
Choose a flavor with enough resources to build the image (at least 10 GB RAM is recommended):
```
openstack flavor list
```
Example output:
```
+--------------------------------------+-------------+-------+------+-------+
| ID                                   | Name        | RAM   | Disk | VCPUs |
+--------------------------------------+-------------+-------+------+-------+
| <uuid>                               | build.small |  8192 |  20  |   4   |
| <uuid>                               | build.large | 16384 |  20  |   8   |
+--------------------------------------+-------------+-------+------+-------+
```
Update the configuration:
```
flavor = "<flavor-name>"
```
#### Availability Zone (if applicable)
Some OpenStack clouds require an availability zone to be specified (e.g. Nirin), while others do not (e.g. Nectar).
```
openstack availability zone list
```
Example output:
```
+-------------+-----------+
| Zone Name   | Status    |
+-------------+-----------+
| zone-a      | available |
| zone-b      | available |
+-------------+-----------+

```
Update (or omit if not required):
```
availability_zone = "<zone-name>"
```
If your cloud supports automatic placement, this line can be omitted.

#### Network (cloud-dependant)
Some OpenStack clouds (e.g. Nirin) require the network to be specified explicitly. Others (e.g. Nectar) provide a default network and do not require this field.
```
openstack network list
```
Example output:
```
+--------------------------------------+----------+
| ID                                   | Name     |
+--------------------------------------+----------+
| <uuid>                               | private  |
| <uuid>                               | external |
+--------------------------------------+----------+

```
Add the network  to the Packer configuration:
```
networks = ["<network-uuid>"]
```
If your cloud has a default network, this field may be omitted.

#### CVMFS Configuration

The [`build-bioimage.yml`](build/build-bioimage.yml) playbook configures CVMFS for the image.  

- By default, the CVMFS HTTP proxy is set to **DIRECT** to make the build more portable across environments.  
- If a infrastructure specific proxy is available (eg. `http://cvmfs-proxy-1.nci.org.au:3128;http://cvmfs-proxy-2.nci.org.au:3128` on Nirin), update the `CVMFS_HTTP_PROXY` line in the playbook.

The relevant task in the playbook:

```yaml
- name: Write default.local
  copy:
    dest: /etc/cvmfs/default.local
    content: |
      CVMFS_REPOSITORIES=data.biocommons.aarnet.edu.au,data.galaxyproject.org,singularity.galaxyproject.org
      CVMFS_HTTP_PROXY='DIRECT'
      CVMFS_QUOTA_LIMIT=4096
      CVMFS_USE_GEOAPI=yes
```
packer build openstack-bioimage.pkr.hcl
```
### Step 3: Verify Image
After the build process is complete, verify the newly created image by running:
```
openstack image list | grep bioimage
```
If successful, you should see output similar to the following (showing the image ID (UUID), Name, and Status):
```
| <UUID> | bioimage | active |
```
## Using the BioImage

This section describes how to launch a virtual machine using the BioImage and what functionality is available once the instance is running.

### Launching a BioImage VM

Launch a new instance by following the steps in [Launch an Instance](#launch-an-instance).

When you reach the Source section, select Image and choose bioimage instead of a standard Ubuntu image. If the image was built successfully, no other changes are required

Once the instance is active, connect to it via SSH using the selected 
key pair.
```
ssh -i /path/to/your/key <remote_user>@<bioimage_ip>
```

### Tools Available in BioImage

BioImage includes a curated set of commonly used bioinformatics and workflow tools, exposed through the environment modules system.

#### modules

The image should include the following applications:
- Singularity
- SHPC
- Spack
- Ansible
- Jupyter Notebook
- RStudio
- Nextflow
- Snakemake
- CernVM-FS client

Check available modules with:
```
module avail
```

To use an application, load it with:
```
module load <app>
```
#### CernVM-FS (CVMFS)

This image uses CernVM-FS (CVMFS) to provide access to shared bioinformatics software and datasets without installing them locally on the VM.

Access CVMFS repositories:
```
ls /cvmfs/data.biocommons.aarnet.edu.au
ls /cvmfs/data.galaxyproject.org
ls /cvmfs/singularity.galaxyproject.org

```
For an explanation of what CVMFS is, how it works, and how it is used in BioImage, see [CVMFS documentation](docs/cvmfs.md).

