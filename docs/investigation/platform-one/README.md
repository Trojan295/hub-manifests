# Platform One installation

This document describes Platform One installation on K3d and AWS RKE2 cluster, including both environments provisioning and configuration.

## Table of contents

<!-- toc -->

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Prepare local environment](#prepare-local-environment)
  - [Provision EC2 instance (optional)](#provision-ec2-instance-optional)
  - [Install all prerequisites on the target machine](#install-all-prerequisites-on-the-target-machine)
  - [Clone the Quick Start repository](#clone-the-quick-start-repository)
  - [Option A: Use local container registry](#option-a-use-local-container-registry)
  - [Option B: Use existing AWS registry with all images pushed](#option-b-use-existing-aws-registry-with-all-images-pushed)
  - [Run K3d cluster](#run-k3d-cluster)
- [RKE2 cluster](#rke2-cluster)
  - [Create cluster](#create-cluster)
- [Install Platform One Big Bang](#install-platform-one-big-bang)
- [Configure certificate](#configure-certificate)
- [Cleanup](#cleanup)
  - [Local](#local)
  - [Delete EC2 instance](#delete-ec2-instance)
  - [RKE2 Cluster](#rke2-cluster-1)
- [Troubleshooting](#troubleshooting)
  - [Logging pods fail](#logging-pods-fail)
  - [Errors during image pulls](#errors-during-image-pulls)
- [Summary](#summary)
  - [Difficulties](#difficulties)
  - [Cluster provisioning manifests: Local](#cluster-provisioning-manifests-local)
  - [Cluster provisioning manifests: RKE2](#cluster-provisioning-manifests-rke2)
  - [Platform One Big Bang installation](#platform-one-big-bang-installation)
- [Agreement](#agreement)

<!-- tocstop -->

## Introduction

[Platform One](https://p1.dso.mil/#/products) is an ecosystem of multiple hardened CNCF-compliant projects: Iron Bank (container registry), Big Bang (GitOps-based "software factory"), CNAP (Cloud Native Access Point) and others. Platform One's main purpose is to be a base for Deparatment of Defense (DoD) programs.

What we actually need to install with Capact is [Big Bang](https://p1.dso.mil/#/products/big-bang/), which is a set of different integrated components, like Istio, Grafana, Kiali, Jaeger or Twistlock. With Big Bang you can also enable addons, such as GitLab, Mattermost, Minio, Velero, SonarQube.

## Prerequisites

- Terraform
- AWS CLI
- The following repository cloned:

    ```bash
    git clone -b p1-1.11 https://github.com/pkosiec/Quick-Start-Big-Bang.git
    ```

    This fork:
    - bumps Platform One to latest version (1.11),
    - configures K3d image registry for local installation,
    - exposes kubeconfig path variable (useful especially for AWS installation),
    - configures load balancer to be publicly available for the AWS RKE2 deployment.

- Other software listed for a specific steps

## Prepare local environment

### Provision EC2 instance (optional)

> Based on https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/developer/development-environment.md#aws-cli-commands-to-manually-create-ec2-instance with some edits, such as removing unnecessary steps, bigger EC2 instance or more permissive access to the EC2 instance.

This is optional, as you can try to use it on your local machine, if you have more than 16GB of RAM.

```bash
# Set variables
AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )

# Disable local pager
export AWS_PAGER=""

# Recreate key pair
rm -f $AWSUSERNAME.pem
aws ec2 delete-key-pair --key-name $AWSUSERNAME
aws ec2 create-key-pair --key-name $AWSUSERNAME --query 'KeyMaterial' --output text > $AWSUSERNAME.pem
chmod 400 $AWSUSERNAME.pem

# Verify private key
openssl rsa -noout -inform PEM -in $AWSUSERNAME.pem
aws ec2 describe-key-pairs --key-name $AWSUSERNAME

# Get current datetime
DATETIME=$( date +%Y%m%d%H%M%S )

# Create new Security Group
# A security group acts as a virtual firewall for your instance to control inbound and outbound traffic.
aws ec2 create-security-group \
    --group-name $AWSUSERNAME \
    --description "Created by $AWSUSERNAME at $DATETIME"

# Add rule to security group
aws ec2 authorize-security-group-ingress \
     --group-name $AWSUSERNAME \
     --protocol tcp \
     --port 0-65535 \
     --cidr 0.0.0.0/0

# Create userdata.txt
# https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
cat << EOF > userdata.txt
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
# Set the vm.max_map_count to 262144.
# Required for Elastic to run correctly without OOM errors.
sysctl -w vm.max_map_count=262144
EOF

# Create new instance
aws ec2 run-instances \
    --image-id ami-0a8e758f5e873d1c1 \
    --count 1 \
    --instance-type t2.2xlarge \
    --key-name $AWSUSERNAME \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Owner,Value=$AWSUSERNAME},{Key=env,Value=bigbangdev}]" \
    --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=50}' \
    --security-groups $AWSUSERNAME \
    --user-data file://userdata.txt

mv $AWSUSERNAME.pem ~/.ssh/$AWSUSERNAME-bigbang.pem
```

SSH to the instance. Get the public IP first - the easiest way is to get it from the AWS Console. You can also use CLI to do that:

```bash
# Get public IP
AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )
AWSINSTANCEID=$( aws ec2 describe-instances \
    --output text \
    --query "Reservations[].Instances[].InstanceId" \
    --filters "Name=tag:Owner,Values=$AWSUSERNAME" "Name=tag:env,Values=bigbangdev")
export EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $AWSINSTANCEID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
ssh -i  ~/.ssh/$AWSUSERNAME-bigbang.pem ubuntu@$EC2_PUBLIC_IP
```

### Install all prerequisites on the target machine
On the target machine you will run Big Bang, do these steps:

1. Install **latest** k3d:

    ```bash
    wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
    ```
  
    The latest k3d is required to configure the Docker image registry mirroring.

1. Install software listed here **EXCEPT k3d, which you have already installed**: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/deployment_scenarios/quickstart.md#step-2-ssh-into-machine-and-install-prerequisite-software

> **NOTE**: Make sure you configured the operating system - e.g. `vm.max_map_count`, which is needed to run Elasticsearch without any issues.

### Clone the Quick Start repository

1. Navigate to the cloned `pkosiec/Quick-Start-Big-Bang` repository from the [Prerequisites](#prerequisites) section. If you install Platform One Big Bang on EC2 instance, clone this repository using the active SSH session with the instance. 

### Option A: Use local container registry

1. Download `images.tar.gz` file from https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases/1.11.0
1. Untar the directory and navigate to the root of it.

    > **WARNING:** On my machine it takes around 40-50 minutes to unpack it.

1. Run your own local registry:

    ```bash
    docker container run --name registry.localhost -v $(pwd)/var/lib/registry:/var/lib/registry --restart always -p 5000:5000 registry:2
    ```

**NOTE:** This is NOT a proper air-gapped solution. It is just for our purposes. See the official airgap guide here: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/airgap/README.md. Also, it wasn't tested on EC2, but it should work the same way it works on local machine.

### Option B: Use existing AWS registry with all images pushed

Instead of local Docker registry we will use the AWS registries I configured during the investigation. All needed Platform One 1.11 images are already pushed there to the `347763108806.dkr.ecr.eu-west-1.amazonaws.com` using the very dirty [`pull-push-images.sh`](./pull-push-images.sh) script. The images are private.

1. Change the `registries.yaml` file in the cloned repository to:

    ```yaml
    mirrors:
      "registry1.dso.mil":
        endpoint:
          - 347763108806.dkr.ecr.eu-west-1.amazonaws.com
    ```

### Run K3d cluster

1. Create k3d cluster.

    ```bash
    ./init-k3d.sh
    ```

1. **Option A only:** If you use local registry, connect it to the Docker network:
    ```bash
    docker network connect k3d-big-bang-quick-start registry.localhost
    ````

## RKE2 cluster

### Create cluster

1. Export AWS credentials for IAM User with `AdministratorAccess` policy:

    ```bash
    export AWS_ACCESS_KEY_ID='{access_key}'
    export AWS_SECRET_ACCESS_KEY='{secret_key}'
    ```

1. Clone this repository:

  ```bash
  git clone https://github.com/Project-Voltron/hub-manifests.git commercial-hub-manifests
  ```

1. Navigate to the `rke2-tf` directory on this repository:

    ```bash
    cd docs/investigation/platform-one/rke2-tf
    ```

1. Run:

    ```bash
    terraform init
    terraform apply
    ```

    > **NOTE**: The Terraform module is based on the Big Bang Gitlab CI setup for testing purposes. See the full list of changes [here](https://github.com/Project-Voltron/platform-one-big-bang/pull/1).

1. Use kubeconfig to access the cluster:

    ```bash
    export KUBECONFIG=$(pwd)/rke2.yaml
    ```

1. Test it and wait for K8s Nodes ready:

    ```bash
    kubectl get nodes -w
    ```

1. Deploy a default StorageClass for AWS:


    ```bash
    curl https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/.gitlab-ci/jobs/rke2/dependencies/k8s-resources/aws/default-ebs-sc.yaml > /tmp/sc.yaml
    kubectl apply -f /tmp/sc.yaml
    ``` 

1. Patch PSP to successfully deploy OPA Gatekeeper:

    ```bash
    kubectl --kubeconfig rke2.yaml patch psp global-unrestricted-psp  -p '{"metadata": { "annotations": { "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*" } } }'
    kubectl --kubeconfig rke2.yaml patch psp system-unrestricted-psp  -p '{ "metadata": { "annotations": { "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*" } } }'
    kubectl --kubeconfig rke2.yaml patch psp global-restricted-psp  -p '{ "metadata": { "annotations": { "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*" } } }'
    ```

## Install Platform One Big Bang

1. Navigate to the cloned `pkosiec/Quick-Start-Big-Bang` repository from the [Prerequisites](#prerequisites) section.
1. Initialize the Terraform module:

    ```bash
    terraform init
    ```

1. Apply Terraform:

    > **NOTE:** the ECR password fetched the way described below is valid only for 12 hours.

   1. **Local installation Option A only:** If you use local registry with K3d, run:

      ```bash
      terraform apply -var "registry1_username=''" -var "registry1_password=''"
      ```

   1. **Local installation with Option B only**: If you use existing AWS registry with K3d, run:

      On the machine where you have the AWS CLI configured, run:

      ```bash
      aws ecr get-login-password --region eu-west-1
      ```

      Copy the printed password and set it on the target machine (etc. EC2) as environment variable:

      ```bash
      export ECR_PASSWD={ecr_passwd}
      terraform apply -var "registry1_username=AWS" -var "registry1_password=$ECR_PASSWD"
      ```

   1. **RKE2 Cluster installation only**: Run:

      ```bash
      # Run it in directory with the RKE2 module
      export KUBECONFIG=$(pwd)/rke2.yaml
      # Navigate to the Quick Start repository
      export ECR_PASSWD=$(aws ecr get-login-password --region eu-west-1)
      terraform apply -var "registry1_username=AWS" -var "registry1_password=$ECR_PASSWD" -var "kube_conf_file=$KUBECONFIG"
      ```

## Configure certificate

In this PoC, for all kind of installations we will use `*.bigbang.dev` domain.

> **NOTE:** The target configuration for RKE2 cluster installation is to use dedicated domain with generated cert.

1. Configure certificate: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/deployment_scenarios/quickstart.md#step-5-add-the-lef-https-demo-certificate.

    > **NOTE:** For local EC2 environment, make sure you ran this command inside the VM.

1. Configure `/etc/hosts`:

    Get all hosts from the machine where you run k3d:
    ```bash
    kubectl get virtualservices --all-namespaces -o jsonpath="{.items[*].spec.hosts[*]}"
    ```

    Modify `/etc/hosts` on your computer and paste all the hosts printed with the command above:
    ```
    {ip} {hosts}
    ```

    Where `{hosts}` are copied from the previous step and `{ip}` is:
    - for RKE2 deployment use this command to know the IP:

        ```bash
        host $(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.status.loadBalancer.ingress[0].hostname}")
        ```

    - for local K3d deployment - `127.0.0.1`
    - for EC2 deployment - public IP of the EC2 instance

1. Test that it works:

    -  Navigate to https://grafana.bigbang.dev and log in using credentials fetched from the k3d host machine:

      ```bash
      GF_USERNAME=$(kubectl -n monitoring get secrets monitoring-monitoring-grafana -ojsonpath="{.data.admin-user}" | base64 -d)
      GF_PASSWORD=$(kubectl -n monitoring get secrets monitoring-monitoring-grafana -ojsonpath="{.data.admin-password}" | base64 -d)
      echo $GF_USERNAME:$GF_PASSWORD
      ```

    - Navigate to https://twistlock.bigbang.dev/ and create user

1. Congratulations, you've just installed Platform One!

## Cleanup

### Local

Delete the local cluster with:

```
k3d cluster delete big-bang-quick-start
```

### Delete EC2 instance

If you created EC2 instance during local run, delete it with these commands:

```bash
AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )

# Get InstanceId
AWSINSTANCEID=$( aws ec2 describe-instances \
    --output text \
    --query "Reservations[].Instances[].InstanceId" \
    --filters "Name=tag:Owner,Values=$AWSUSERNAME" "Name=tag:env,Values=bigbangdev" )

# Terminate existing instance
aws ec2 terminate-instances --instance-ids $AWSINSTANCEID

# Delete old Security Group
aws ec2 delete-security-group --group-name=$AWSUSERNAME
```

### RKE2 Cluster

Delete Istio namespace to deprovision Amazon ELB.

```bash
kubectl delete namespace istio-system
```

Delete whole cluster with Terraform. In this (`commercial-hub-manifests`) repository, run:

```
cd docs/investigation/platform-one/rke2-tf
terraform destroy
```

## Troubleshooting

### Logging pods fail

If the Elasticsearch (logging) fails in this configuration because of the following problem:

```
ERROR: [1] bootstrap checks failed. You must address the points described in the following [1] lines before starting Elasticsearch.
bootstrap check failure [1] of [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
ERROR: Elasticsearch did not exit normally - check the logs at /usr/share/elasticsearch/logs/logging-ek.log
```

Then Jaeger also crashes because it depends on the Elasticsearch.

You need to configure the OS according to the last step of the section https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/deployment_scenarios/quickstart.md#step-2-ssh-into-machine-and-install-prerequisite-software.

### Errors during image pulls

Make sure you passed proper credentials to pull the image.
You can observe some temporary errors during image pulls on RKE2 cluster. That's nothing you should worry about, as the Container registry mirroring configuration will make a fall back to our AWS container registry, which will properly handle pulls.

## Summary

- They have a full dedicated repository template which should be used for every customer: https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/
- There are also dedicated Terraform manifests for the infrastructure: https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/terraform which are used as a starting point. To handle that with Capact, we would need to have Terragrunt support in Terraform runner to handle the files properly.
- Quick Start Big Bang is just for development/demo purposes only. Currently it's not configurable, but we can still use it as described below.

### Difficulties

The main difficulties were/are:
- we don't have access to the Registry1 Docker registry
- we don't have access to the custom build of RHEL8 AMI - repo is private
- we didn't get the Docker images from the Registry1. There were one package from Paul with just a few images packed in different versions.
  - I could find them as assets to the BigBang releases. However, it is compressed directory structure of a dedicated registry. I could pull all the images based on what runs in the cluster and push them to the AWS registry
- The `registry1.dso.mil` Docker registry is not configurable for the Platform One installation
  - we can workaround it with container registry configuration for RKE2 and K3d
- the Platform One documentation lacks description and can be found on different repos
- There are different ways to install Big Bang:
    - We got a 800-lines-long custom script from Paul for K3d installation
    - For CI, Platform One guys use Big Bang Helm charts directly without Terraform: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/scripts/deploy/01_deploy_bigbang.sh
    - In docs they describe just the "development deployment scenario" using the Big Bang Terraform Launcher: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/deployment_scenarios/quickstart.md

### Cluster provisioning manifests: Local

- we need to enable passing `registries.yaml` mapping as input
- for local usage we could assume that all required tools for P1 installation need to be installed upfront before running Action.
- configuring /etc/hosts - manual step at the end of the installation

### Cluster provisioning manifests: RKE2

- As input params, we definitely need to expose AMI ID (it's different for AWS GovCloud)
- We need to prepare Terraform module closer to production. For PoC I made the Control Plane publicly available, the same with the load balancer for apps. Also, the RKE2 EC instances are placed in public subnet.
- Maybe we can reuse https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/terraform, but it uses Terragrunt. I didn't test that. We would probably need to support Terragrunt in Capact Terraform Runner (or have a separate Runner for that).

### Platform One Big Bang installation

- Use Quick Start Terraform fork
  - we can even use original repo, as they bumped Platform One to 1.11 recently: https://repo1.dso.mil/platform-one/quick-start/big-bang - and we don't need the kubeconfig variable

- As input for the Capact Interface/Impl we take:
  - registry creds (login + password to Docker registry)

- Should we take as an input the Repo URL for the `environment-repo` GitRepository CR? And the path for the kustomization directory. Then people can use the customers template
  - what about private repo? we can handle them with `secretRef` for GitRepository CR. Maybe we should take them as input and create secret?

- Hostname & certificates:
    - for local usage and production usage, we can pass them directly in values.yaml on our fork using `istio.ingress` override in a form of `{"cert":"","key":""}`. As the repo can be private, it should be fine.

Suggested approach:

As a part of the Big Bang installation manifest:

0. As an input for the Interface: get repo url + optional HTTPS/SSH repo authentication details, Iron Bank credentials
1. Clone Quick Start repo
2. get repo url + optional HTTPS/SSH repo authentication details 
3. (optional) create K8s secret with the Git repository authentication details. See the [Flux GitRepository spec](https://fluxcd.io/docs/components/source/gitrepositories/#specification)
4. Modify `start.yaml` file with the repo details
5. Run `terraform init && terraform apply` with Iron Bank registry credentials
6. We assume that hostname, Istio Gateway certs are configured in values.yaml file in the provided repository

## Agreement

As agreed with [@platten](https://github.com/platten), [@Trojan295](https://github.com/Trojan295), [@lukaszo](https://github.com/lukaszo), and [@mszostok](https://github.com/mszostok) on 13.07.2021, we will implement the manifests according to the plan below:

Provision Platform One Environment consists of the following steps:

**input**: (among other things):
- initially: existing empty Git repository URL
    - optional creds ssh / https if it's private
- stretch: if not existing repo provided, create such empty repository by ourselves (maybe we can use [AWS CodeCommit](https://aws.amazon.com/codecommit/))
- credentials for container registry (Iron Bank / mirror)
- `registries.yaml` configuration
- (optional) `values.yaml` overrides

1. create env - Two Implementations: RKE2 or K3d
   - input (among other things):
     - RKE2: AMI ID, `registries.yaml` configuration
     - K3d: `registries.yaml` configuration
   - output (among other things):
     - kubeconfig

1. create repo from template
   - use [official template](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/)
   - (optional) replace values.yaml with the user provided ones
   - push `main` branch

1. Install Big Bang
   - clone Git repository [`Quick-Start-Big-Bang`](https://repo1.dso.mil/platform-one/quick-start/big-bang)
   - (optional) create secret with credentials to the Git repo with the template from previous step
   - replace `bigbang/start.yaml` with custom repo location and optional secret
   - run `terraform init & apply` with Terraform Runner
