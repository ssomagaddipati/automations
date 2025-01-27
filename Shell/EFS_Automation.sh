#!/bin/bash -xe

################################################################################################################################
# Script name: EFS_Automation.sh
# Description: This script will create filesystem and migration from EBS to EFS
# Author: Reltio MDM Team  
# Arguments: -a AWS_ACCESS_KEY_ID - Mandatory
#    -s AWS_SECRET_ACCESS_KEY - Mandatory
#
# Creation date: 26-June-2024
# Last modified date: 29-June-2025
################################################################################################################################

# Welcome message

echo "******************************************************************************"
echo " "
echo "                        EFS AUTOMATION         "
echo " "
echo "******************************************************************************"

#Variable declaration
aws_region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '"region"\s*:\s*"\K[^"]+')
instance-ids=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '"instanceId"\s*:\s*"\K[^"]+')
availability-zone=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '"availabilityZone"\s*:\s*"\K[^"]+')
addresses.private-ip-address=$(aws ec2 describe-instances --instance-ids "$instance-ids" --filters Name=availability-zone,Values=$availability-zone | grep "INSTANCES"  | awk '{print $13}')
subnet-id=$(aws ec2 describe-instances --instance-ids "$instance-ids" --filters Name=availability-zone,Values=$availability-zone | grep "INSTANCES"  | awk '{print $19}')
security-groups=$(aws ec2 describe-network-interfaces  --filters Name=addresses.private-ip-address,Values=$addresses.private-ip-address | grep "GROUPS" | awk '{print "\x22" $2 "\x22"}' | sed 'N;s/\n/ /')
creation-token=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 11 | head -n 1)
EFS_NAME=$(EFS.$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 7 | head -n 1))
#file-system-id=$(cat filesystem.txt | grep -oP '"FileSystemId"\s*:\s*"\K[^"]+')
##file-system-state=`cat filesystemstate.txt | grep -oP '"LifeCycleState"\s*:\s*"\K[^"]+'`
EFS_DNS=$("${file-system-id}".efs."${aws_region}".amazonaws.com)

###********************* Function Definitions *********************###
func_error() {

# This function is used for error handling. It captures the previous command error code.
# If error code is not equal to 0, then it prints the message and exits with error code 1
# $1 - Return code of the previous command
# $2 - Step name
return_code=$1
step=$2

if [ ${return_code} -ne 0 ]; then

        echo -e "\e[1;31mERROR: Error at step: ${step} \e[0m"

        echo -e "\e[1;31mCheck LogFiles (available if enabled/started) : ${curr_dir}/logs\e[0m"

        exit 1

fi

}

func_error_msg() {

# This function prints error messages with ERROR label.
# $1 - Message to be printed
error_msg=$1

echo -e "\e[1;31mERROR: ${error_msg} \e[0m"

}


func_warn_msg() {

# This function prints warning messages with a WARNING label
# $1 - Message to be printed

warn_msg=$1

echo -e "\e[1;33mWARNING: ${warn_msg} \e[0m"

}

func_info_msg() {

# This function prints information messages with a INFO label
# $1 - Message to be printed

info_msg=$1

echo -e "\e[0;32mINFO: ${info_msg} \e[0m"

}


############################ GET OPTIONS ##############################

while getopts "u:p:f:" option; do
  case "${option}" in
    u)
       AWS_ACCESS_KEY_ID="${OPTARG}"
       if [ "${AWS_ACCESS_KEY_ID}" == "" ]; then
           echo "Invalid option"
    echo "Usage: ./EFS_Automation.sh -u <AWS_ACCESS_KEY_ID> -p <AWS_SECRET_ACCESS_KEY> -f <Tenant_Details_Path>"
    exit 1
       else
           export AWS_ACCESS_KEY_ID=${OPTARG}
       fi
       ;;
    p)
       AWS_SECRET_ACCESS_KEY="${OPTARG}"
       if [ "${AWS_SECRET_ACCESS_KEY}" == "" ]; then
           echo "Invalid option"
    echo "Usage: ./EFS_Automation.sh -u <AWS_ACCESS_KEY_ID> -p <AWS_SECRET_ACCESS_KEY> -f <Tenant_Details_Path>"
    exit 1
       else
           export AWS_SECRET_ACCESS_KEY=${OPTARG}
       fi
       ;;
    f)
       Tenant_Details_Path="${OPTARG}"
       if [ "${Tenant_Details_Path}" == "" ]; then
           echo " Invalid option "
    echo " Usage: ./EFS_Automation.sh -u <AWS_ACCESS_KEY_ID> -p <AWS_SECRET_ACCESS_KEY> -f <Tenant_Details_Path> "
    exit 1
       else
           echo " Tenant_Details_Path = "${OPTARG}" "
       fi
       ;;

  esac
done

 ############################ EFS CREATION ##############################

file-system-id=$(aws efs create-file-system --creation-token $creation-token --performance-mode generalPurpose --throughput-mode bursting --tags Key=Name,Value=$EFS_NAME --no-encrypted | grep -oP '"FileSystemId"\s*:\s*"\K[^"]+' )

### To sleep for 2 minutes: ###
sleep 2m

file-system-state=$(aws efs describe-file-systems --file-system-id $file-system-id | grep -oP '"LifeCycleState"\s*:\s*"\K[^"]+')
 if [ "${file-system-state}" = "available" ]; then
do
aws efs put-lifecycle-configuration --file-system-id $file-system-id --lifecycle-policies TransitionToIA="AFTER_7_DAYS"
done

elif [ "${file-system-state}" = "creating" ]; then
     echo "EFS is in creating state"
     sleep 90


elif [ "${file-system-state}" = "updating" ]; then
     echo "EFS is in updating state"
     sleep 90



else
    echo "EFS is Failed/Not configured properly/deleted"
    exit 1
fi

create-mount-target --file-system-id  $file-system-id --subnet-id  $subnet-id --security-groups $security-groups
sleep 2m

mount-system-state=$(aws efs describe-mount-targets --file-system-id $file-system-id | grep "MOUNTTARGETS" | awk '{print$4}')



 if [ "${mount-system-state}" = "available" ]; then
    echo " Mount Target is Ready "
 
elif [ "${mount-system-state}" = "creating" ]; then
     echo " Mount Target is in creating state "
     sleep 90

elif [ "${mount-system-state}" = "updating" ]; then
     echo " Mount Target is in updating state "
     sleep 90


else
    echo "Mount Target is deleting/deleted"
    exit 1
fi

 ############################ MOUNT/ATTACH EFS ##############################
sleep 10

sudo yum install -y nfs-utils
sleep 60
sudo service nfs start
sleep 10
nfs-check=$(sudo systemctl is-active nfs.service)
if [ "${nfs-check}" = "active" ]
    echo "nfs service is up and running"

else
    do
 sudo service nfs start
    done
fi



mkdir -p /mnt/mdm_data

sudo chmod 777 /mnt/mdm_data

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "${EFS_DNS}":/ /mnt/mdm_data


EFS_STATUS=$(df -h | grep  "${EFS_DNS}")

if [[ "${EFS_STATUS}" == *"${EFS_DNS}"* ]]; then
   echo " EFS Mounted Properly "
else
   echo " EFS ERROR "
   exit 1
fi

cp -r  /etc/fstab  /etc/fstab_bkp
echo "${EFS_DNS}":/ /mnt/mdm_data efs _netdev,tls,iam 0 0 >> /etc/fstab
diff --brief /etc/fstab /etc/fstab_bkp >/dev/null
comp_value=$?

if [ $comp_value -eq 1 ]
then
    echo " they're different "
else
   
    echo "${EFS_DNS}":/ /mnt/mdm_data efs _netdev,tls,iam 0 0 >> /etc/fstab
   
fi



sudo yum -y install git
 sleep 30


git clone https://github.com/aws/efs-utils /tmp
sleep 90

sudo yum -y install make
sleep 20


sudo yum -y install /tmp/efs-utils/rpm-build
sleep 30

sudo make rpm

sudo yum -y install /tmp/efs-utils/rpm-build/build/amazon-efs-utils*rpm
sleep 20

sudo sed -i "s/stunnel_check_cert_hostname \= true/stunnel_check_cert_hostname \= false/1" /etc/amazon/efs/efs-utils.conf

sleep 30



 ############################ Migration to EFS ##############################
echo " file format is Tenant_ID = Tenant_PATH "

for Tenant_Details in `cat "${Tenant_Details_Path}"`
do
Tenant_Path=$(cat "${Tenant_Details_Path}" | awk '{print$3}')
Tenant_Details=$(cat "${Tenant_Details_Path}" | awk '{print$1}')

echo $Tenant_Details = $Tenant_Path
done
 
cp -r "${Tenant_Path}" "${Tenant_Path}"_old
mount --rbind "${Tenant_Path}" /mnt/mdm-data/"${Tenant_Detail}"


################## END OF SCRIPT ##################