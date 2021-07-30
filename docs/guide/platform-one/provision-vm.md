# Provision VM for K3d Big Bang installation

If you would like to run Capact and K3d on EC2 instance, instead of using your local machine, follow the steps descibed in the document.

## Provision AWS EC2 instance

Run the following script:

```bash
#
# Based on https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/developer/development-environment.md#aws-cli-commands-to-manually-create-ec2-instance with some edits, such as removing unnecessary steps, bigger EC2 instance or more permissive access to the EC2 instance.
#

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

## Connect to the VM

1. Get public IP of the instance.

    You can use AWS UI or the following script:

    ```bash
    # Get public IP
    AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )
    AWSINSTANCEID=$( aws ec2 describe-instances \
        --output text \
        --query "Reservations[].Instances[].InstanceId" \
        --filters "Name=tag:Owner,Values=$AWSUSERNAME" "Name=tag:env,Values=bigbangdev")
    export EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $AWSINSTANCEID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    ```

1. Connect to the EC2 instance with the following command:

    ```bash
    ssh -i  ~/.ssh/$AWSUSERNAME-bigbang.pem ubuntu@$EC2_PUBLIC_IP
    ```

**Next steps:** Navigate back to the [`README`](./README.md) and follow next steps.