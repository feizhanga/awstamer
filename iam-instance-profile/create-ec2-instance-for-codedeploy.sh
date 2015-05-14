#!/bin/bash
amiID=ami-fd9cecc7
keyName=FZKeyPair2
instanceType=t2.micro
securitygroupId=sg-54d67131

aws ec2 run-instances  --image-id $amiID  --key-name $keyName --user-data file://instance-setup.sh --count 1 --instance-type $instanceType --security-group-ids $securitygroupId --iam-instance-profile Name=CodeDeployFZen-EC2-Instance-Profile


aws ec2 wait instance-running

#[ec2-user@ip-10-0-0-98 iam-instance-profile]$ aws ec2 describe-instances --filters "Name=key-name,Values=FZKeyPair2" --query "Reservations[*].Instances[*].[InstanceId]" --output text
##	i-0b378ad7
##	i-a8cb4074

#[ec2-user@ip-10-0-0-98 iam-instance-profile]$ aws ec2 create-tags --resources i-a8cb4074 --tags Key=Name,Value=CodeDeployFZen

