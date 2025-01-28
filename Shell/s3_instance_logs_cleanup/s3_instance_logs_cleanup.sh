#!/bin/bash
#Last Modified: January 26, 2025
#This Bash script automates the cleanup of S3 buckets containing instance logs across multiple AWS accounts.

/usr/local/bin/aws configure list-profiles > /home/ec2-user/S3_CLEANUP/all-profiles.txt
#
for account in `cat /home/ec2-user/S3_CLEANUP/all-profiles.txt`
    do
        aws ec2 describe-regions --query "Regions[].{Name:RegionName}" --output text |xargs -I {} aws ec2 describe-instances --query Reservations[].Instances[].[InstanceId] --output text --region {} --profile $account > /home/ec2-user/S3_CLEANUP/InstanceID.txt
        aws s3 ls --profile $account | cut -d " " -f 3 | sed -e 's/\ *$//g' > /home/ec2-user/S3_CLEANUP/S3List.txt
#
        for S3 in `cat /home/ec2-user/S3_CLEANUP/S3List.txt`
            do
                echo $S3
                TEST_S3="s3://$S3/instanceLogs/"
                echo "Path is : $TEST_S3"
                action=`aws s3 ls $TEST_S3 --profile $account`
#
                if [ -z "$action" ]
                    then
                        echo "$S3 is not having TEST Logs"
                    else
                        echo "$S3 is TEST Bucket"
                        aws s3api put-object --bucket $S3 --key InstanceLogsBackup/ --profile $account
                        aws s3api put-bucket-lifecycle --bucket $S3 --profile $account --lifecycle-configuration file:///home/ec2-user/S3_CLEANUP/lifecycle_testlogs.json
                        aws s3 ls s3://$S3/instanceLogs/  --profile $account | awk '{print $2}' | cut -d / -f 1 > /home/ec2-user/S3_CLEANUP/TESTInstnaces_Existing_S3.txt
                        grep -Fxf /home/ec2-user/S3_CLEANUP/TESTInstnaces_Existing_S3.txt   /home/ec2-user/S3_CLEANUP/InstanceID.txt  >  /home/ec2-user/S3_CLEANUP/TESTInstances_Running.txt
                        cd /home/ec2-user/S3_CLEANUP
                        i=1
#
                            while IFS= read -r line; do
                            declare Instance$((i++))="$line"
                            done < /home/ec2-user/S3_CLEANUP/TESTInstances_Running.txt
                            count="$((i-1))"
#
                            if [ $count == 1 ]
                                then
                                    echo $Instance1
                                    aws s3 sync  s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/  --exclude "$Instance1/*" --profile $account
                                    aws s3 rm s3://$S3/instanceLogs/ --recursive --exclude "$Instance1/*"  --profile $account
                                elif [ $count == 2 ]
                                then
                                    echo $Instance1
                                    echo $Instance2
                                    aws s3 sync s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/  --exclude "$Instance1/" --exclude "$Instance2/" --profile $account
                                    aws s3 rm s3://$S3/instanceLogs/ --recursive --exclude "$Instance1/" --exclude "$Instance2/" --profile $account
                                elif [ $count == 3 ]
                                then
                                    echo $Instance1
                                    echo $Instance2
                                    echo $Instance3
                                    aws s3 sync s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/  --exclude "$Instance1/" --exclude "$Instance2/" --exclude "$Instance3/*" --profile $account
                                    aws s3 rm s3://$S3/instanceLogs/  --recursive --exclude "$Instance1/" --exclude "$Instance2/" --exclude "$Instance3/*" --profile $account
                                elif [ $count == 4 ]
                                then
                                    echo $Instance1
                                    echo $Instance2
                                    echo $Instance3
                                    echo $Instance4
                                    aws s3 sync s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/  --exclude "$Instance1/" --exclude "$Instance2/" --exclude "$Instance3/" --exclude "$Instance4/" --profile $account
                                    aws s3 rm s3://$S3/instanceLogs/  --recursive --exclude "$Instance1/" --exclude "$Instance2/" --exclude "$Instance3/" --exclude "$Instance4/" --profile $account
                                elif [ $count == 5 ]
                                then
                                    echo $Instance1
                                    echo $Instance2
                                    echo $Instance3
                                    echo $Instance4
                                    echo $Instance5
                                    aws s3 sync s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/  --exclude "$Instance1/" --exclude "$Instance2/" --exclude "$Instance3/" --exclude "$Instance4/" --exclude "$Instance5/*" --profile $account
                                    aws s3 rm s3://$S3/instanceLogs/  --recursive --exclude "$Instance1/" --exclude "$Instance2/" --exclude "$Instance3/" --exclude "$Instance4/" --exclude "$Instance5/*"--profile $account
                                elif [ $count == 0 ]
                                then
                                    aws s3 sync s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/ --profile $account
                                    aws s3 rm s3://$S3/instanceLogs/ --recursive  --profile $account
                                    aws s3api put-object --bucket $S3 --key instanceLogs/ --profile $account
                                else
                                    aws s3 sync s3://$S3/instanceLogs/  s3://$S3/InstanceLogsBackup/ --profile $account

                            fi
                fi
        done
cat /dev/null > /home/ec2-user/S3_CLEANUP/S3List.txt
cat /dev/null > /home/ec2-user/S3_CLEANUP/TESTInstances_Running.txt
cat /dev/null > /home/ec2-user/S3_CLEANUP/TESTInstnaces_Existing_S3.txt
done