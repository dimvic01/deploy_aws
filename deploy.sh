#!/bin/bash
:;
usage() {
cat<<EOF
usage: $0 [-l] [-w] [-d]

OPTIONS:
    -l   deploy Linux instance only

    -w   deploy Windows instance only

    -d   dry-run (install/check aws-cli)
    
#===================================================================================
#
#   DESCRIPTION:  Deploy Linux (Ubuntu LTS 14.04 x64) and/or Windows Server 8 x64 
#                 appliance in AWS EC2 Cloud, run customized user deployment script
#                 to install Java version 8 and Python 2.7.9 packages
#       OPTIONS: choices of linux, windows and AWS test in any combinations
#  REQUIREMENTS: aws-cli, aws access keys, python >= 2.6.3, bash >= 4.0
#          BUGS: 
#         NOTES: at least 1 option required, -d makes only local changes
#        AUTHOR: Dmitry Victorov
#  ORGANIZATION: Mediative
#       CREATED: 05/07/2015  9:24:13 AM PDT
#      REVISION:  1.1 fixed bugs
#===================================================================================
EOF
        exit 1
}

deploy () {

# $1 - name
# $2 - ami id
# $3 - tcpport
# $4 - startup script

aws ec2 create-security-group \
--group-name $1 \
--description "$1 security group" \
$AWSKEYS

aws ec2 authorize-security-group-ingress \
--group-name $1 \
--protocol tcp --port $3 \
--cidr 0.0.0.0/0 \
$AWSKEYS

aws ec2 create-key-pair --key-name $1 --query 'KeyMaterial' --output text $AWSKEYS > $1.pem 

chmod 600 $1.pem

INSTANCE_ID=$(aws ec2 run-instances \
--image-id $2 \
--count 1 \
--instance-type t2.micro \
--key-name $1 \
--security-groups $1 \
--user-data file://$4 \
--query 'Instances[0].InstanceId' \
$AWSKEYS | tr -d '"')

if [ ! $INSTANCE_ID ]; then
    if [ ! $AWSKEYS ]; then
    echo "Instance failed to start, check AWS log files"
    else
    echo "DryRun flag is set, exiting"
    fi
else 
    echo -ne "Instance OK, waiting for deployment and public IP info\n"
    while [ ! $PUBLIC_IP ]
    do {
    PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    $AWSKEYS 2>/dev/null |tr -d '"')
    sleep 2
    } done

    if [ $1 == "windows8x64" ]; then
    PasswordData=""
    while [ ! $PasswordData ]
	do {
	PasswordData=$(aws ec2 get-password-data --instance-id $INSTANCE_ID \
	--priv-launch-key=$1.pem | grep PasswordData | awk -F '"' '{print $4}')
	sleep 5
	} done
	echo "INSTANCE_ID=$INSTANCE_ID"
	echo "use RDP to $PUBLIC_IP port 3389 Username:Administrator Password:$PasswordData"

    else 
	echo "INSTANCE_ID=$INSTANCE_ID"
	echo "PasswordData=$PasswordData"
	echo "remote access: ssh -i $1.pem ubuntu@$PUBLIC_IP"
    fi
fi    
}
install_py ()
{
    if [ "$(uname)" == "Darwin" ]; then
	wget http://yangapp.googlecode.com/svn/debs/python_2.7.6-3_iphoneos-arm.deb
	dpkg -i python_2.7.6-3_iphoneos-arm.deb
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	echo "Installing Python"
	sudo apt-get update
	sudo apt-get install python2.7
    else echo "Not supported OS. Exiting."; exit -1
    fi
}
#Start here
if [ $# -lt 1 ] ; then
        usage
fi

if [ ! `which python` ]; then
 install_py
elif [ `python -V 2>&1|tr -d "."|awk '{print $NF}'|tail -1` -ge 263 ]; then 
    echo "Python OK"
else
 install_py 
fi

LINUXVM=""
WINDOWSVM=""
AWSKEYS=""
until [ -z "$1" ]
do
    case $1 in
        -l) UBUNTU=1;;
        -w) WINDOWS8=1;;
        -d) AWSKEYS="--dry-run";;
        *) usage ;;
    esac
  shift
done

if [ ! `echo $PATH | grep ~/bin` ]; then
    export PATH=~/bin:$PATH     # Add ~/bin to $PATH
    echo $PATH
fi

if [ ! `which aws` ]; then
echo "installing aws-cli"
cd ~
curl -k "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -b ~/bin/aws
rm -rf ~/awscli-bundle/*
rmdir ~/awscli-bundle
else
echo "aws-cli installed"
fi

if [ ! -f ~/.aws/credentials ]; then
 aws configure
fi

if [ $UBUNTU ]; then
	deploy ubuntu ami-29ebb519 22 install_py279_java8.sh
fi

if [ $WINDOWS8 ]; then
	#deploy windows8x64 ami-9dc9e3ad 3389 install_python_java_win.ps1
	deploy windows8x64 ami-43c2e873 3389 install_python_java_win.ps1
fi
#End