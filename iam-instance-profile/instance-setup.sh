#!/bin/bash
# http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-set-up-new-instance.html
bucketname="aws-codedeploy-ap-southeast-2"
regionname="ap-southeast-2"

yum -y update
yum install -y aws-cli
cd /home/ec2-user
aws s3 cp s3://$bucketname/latest/install . --region $regionname
chmod +x ./install
./install auto
