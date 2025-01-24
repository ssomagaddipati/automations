"""
Script Usage:
This script updates AWS EC2 and Auto Scaling Group (ASG) tags based on predefined valid tags.
It retrieves account details from AWS credentials, iterates through instances and ASGs,
and updates missing or incorrect tags accordingly.

Requirements:
- AWS credentials configured in `~/.aws/credentials`
- `boto3` library installed
- `variables.py` containing required tag values

"""

import configparser
import boto3
import variables 


config = configparser.ConfigParser()
config.read('/home/ec2-user/.aws/credentials')
accounts = config.sections()
tags = { "env" : variables.env,"applicationOwner" : variables.applicationOwner,"accountOwner" : variables.accountOwner,"costcenter" : variables.costcenter,"accountemail" : variables.accountemail,"app_role" : variables.app_role,"group" : variables.group,"PatchGroup" : variables.PatchGroup,"account_shared" : variables.account_shared,"Name" : variables.Name,"ManualPatch" : variables.ManualPatch,"AutoPatch" : variables.AutoPatch }

validtags = [ 'Name', 'application', 'app_role', 'application_owner', 'account_owner', 'costcenter', 'environment', 'group', 'account_email', 'account_environment', 'account_shared', 'Patch Group', 'Patch_Method' ]
def editTags(ec2client, ec2instance, tagsactions):
    if bool(tagsactions):
        # try:
        ec2tagresponse = ec2client.create_tags(
            Resources=[ec2instance["InstanceId"]],
            Tags = tagsactions
        )
        print(ec2tagresponse)
def editASTags(asgclient, asname, astagsactions):
    if bool(astagsactions):
        asgtagresponse = asgclient.create_or_update_tags(
            # Resources=[autoscalinggroup],
            Tags = astagsactions
        )
        print(asgtagresponse)
def checktags(tags, accountdata):
    map = {}
    tagstoadd = []
    for tag in tags:
        #print(tag['Key'] + ' : ' + tag['Value'])
        map[tag['Key']] = tag['Value']
        #keys.append(tag['Key'])
    for validtag in validtags:
        if (validtag in map.keys()):
            print(validtag + " : " + map[validtag])
            if (validtag=='group' and map[validtag]== "it"):
                tagstoadd.append({'Key': 'group', 'Value': accountdata['group']})
                tagstoadd.append({'Key': 'application_owner', 'Value': accountdata['applicationOwner']})
                tagstoadd.append({'Key': 'account_owner', 'Value': accountdata['accountOwner']})
                tagstoadd.append({'Key': 'account_email', 'Value': accountdata['accountemail']})
                tagstoadd.append({'Key': 'costcenter', 'Value': accountdata['costcenter']})
                tagstoadd.append({'Key': 'application', 'Value': accountdata['app_role']})
        else:
            print(validtag + " does not exists")
            if (validtag=='Name'):
                tagstoadd.append({'Key': 'Name', 'Value': accountdata['Name']})
            if (validtag=='application_owner' and 'applicationOwner' in map.keys()):
                tagstoadd.append({'Key': 'application_owner', 'Value':map['applicationOwner']})
            if (validtag=='application_owner' and ('applicationOwner' not in map.keys())):
                tagstoadd.append({'Key': 'application_owner', 'Value': accountdata['applicationOwner']})
            if (validtag=='account_owner' and 'accountOwner' in map.keys()):
                tagstoadd.append({'Key': 'account_owner', 'Value':map['accountOwner']})
            if (validtag=='account_owner' and ('accountOwner' not in map.keys())):
                tagstoadd.append({'Key': 'account_owner', 'Value': accountdata['accountOwner']})
            if (validtag=='account_email' and 'accountemail' in map.keys()):
                tagstoadd.append({'Key': 'account_email', 'Value':map['accountemail']})
            if (validtag=='account_email' and ('accountemail' not in map.keys())):
                tagstoadd.append({'Key': 'account_email', 'Value': accountdata['accountemail']})
            if (validtag=='application' and 'app_role' in map.keys()):
                tagstoadd.append({'Key': 'application', 'Value':map['app_role']})
            if (validtag=='application' and 'app_role' not in map.keys()):
                tagstoadd.append({'Key': 'application', 'Value': accountdata['app_role']})
            if (validtag=='environment'):
                tagstoadd.append({'Key': 'environment', 'Value':accountdata['env']})
            if (validtag=='account_environment'):
                tagstoadd.append({'Key': 'account_environment', 'Value':accountdata['env']})
            if (validtag=='costcenter'):
                tagstoadd.append({'Key': 'costcenter', 'Value': accountdata['costcenter']})
            if (validtag=='group'):
                tagstoadd.append({'Key': 'group', 'Value': accountdata['group']})
            if (validtag=='division'):
                tagstoadd.append({'Key': 'division', 'Value': accountdata['division']})
            if (validtag=='account_shared'):
                tagstoadd.append({'Key': 'account_shared', 'Value': accountdata['account_shared']})


        #update Patch group based
    if 'aws:autoscaling:groupName' in map.keys():
        tagstoadd.append({'Key': 'Patch Group', 'Value': accountdata['PatchGroup']})
        tagstoadd.append({'Key': 'Patch_Method', 'Value': accountdata['AutoPatch']})
    else:
        tagstoadd.append({'Key': 'Patch Group', 'Value': accountdata['PatchGroup']})
        tagstoadd.append({'Key': 'Patch_Method', 'Value': accountdata['ManualPatch']})
    return tagstoadd
def checkastags(tags, asname, accountdata):
    map = {}
    tagstoadd = []
    for tag in tags:
        #print(tag['Key'] + ' : ' + tag['Value'])
        map[tag['Key']] = tag['Value']
        #keys.append(tag['Key'])
    for validtag in validtags:
        if (validtag in map.keys()):
            print(validtag + " : " + map[validtag])
            if (validtag=='group' and map[validtag]== "it"):
                tagstoadd.append({'Key': 'group', 'Value': accountdata['group'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
                tagstoadd.append({'Key': 'application_owner', 'Value': accountdata['accountOwner'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
                tagstoadd.append({'Key': 'account_owner', 'Value': accountdata['applicationOwner'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
                tagstoadd.append({'Key': 'account_email', 'Value': accountdata['accountemail'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
                tagstoadd.append({'Key': 'costcenter', 'Value': accountdata['costcenter'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
                tagstoadd.append({'Key': 'application', 'Value': accountdata['app_role'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
        else:
            print(validtag + " does not exists")
            if (validtag=='Name'):
                tagstoadd.append({'Key': 'Name', 'Value': accountdata['Name'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='application_owner' and 'applicationOwner' in map.keys()):
                tagstoadd.append({'Key': 'application_owner', 'Value':map['applicationOwner'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='application_owner' and ('applicationOwner' not in map.keys())):
                tagstoadd.append({'Key': 'application_owner', 'Value': accountdata['applicationOwner'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='account_owner' and 'accountOwner' in map.keys()):
                tagstoadd.append({'Key': 'account_owner', 'Value':map['accountOwner'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='account_owner' and ('accountOwner' not in map.keys())):
                tagstoadd.append({'Key': 'account_owner', 'Value': accountdata['accountOwner'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='account_email' and 'accountemail' in map.keys()):
                tagstoadd.append({'Key': 'account_email', 'Value':map['accountemail'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='account_email' and ('accountemail' not in map.keys())):
                tagstoadd.append({'Key': 'account_email', 'Value': accountdata['accountemail'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='environment'):
                tagstoadd.append({'Key': 'environment', 'Value':accountdata['env'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='account_environment'):
                tagstoadd.append({'Key': 'account_environment', 'Value':accountdata['env'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='application' and 'app_role' in map.keys()):
                tagstoadd.append({'Key': 'application', 'Value':map['app_role'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='application' and 'app_role' not in map.keys()):
                tagstoadd.append({'Key': 'application', 'Value': accountdata['app_role'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='compliance'):
                tagstoadd.append({'Key': 'compliance', 'Value': accountdata['compliance'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='costcenter'):
                tagstoadd.append({'Key': 'costcenter', 'Value': accountdata['costcenter'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='group'):
                tagstoadd.append({'Key': 'group', 'Value': accountdata['group'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
            if (validtag=='account_shared'):
                tagstoadd.append({'Key': 'account_shared', 'Value': accountdata['account_shared'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})

        #update Patch group based
    if 'aws:autoscaling:groupName' in map.keys():
        tagstoadd.append({'Key': 'Patch Group', 'Value': accountdata['PatchGroup'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
        tagstoadd.append({'Key': 'Patch_Method', 'Value': accountdata['AutoPatch'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
    else:
        tagstoadd.append({'Key': 'Patch Group', 'Value': accountdata['PatchGroup'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
        tagstoadd.append({'Key': 'Patch_Method', 'Value': accountdata['ManualPatch'], 'PropagateAtLaunch': True, 'ResourceId': asname, 'ResourceType': 'auto-scaling-group'})
    return tagstoadd



print(variables.env)
# awsaccounts = accounts.keys()
for account in accounts:
    # Get list of regions
    count = 0
    print(account)
    acctsession = boto3.Session(profile_name=account)
    acctec2client = acctsession.client('ec2')
    regions = [region['RegionName'] for region in acctec2client.describe_regions()['Regions']]
    for region in regions:
        print('Account: ' + account + ' Region: ' + region)
        ec2session = boto3.Session(profile_name=account, region_name=region)
        ec2client = ec2session.client('ec2')
        ec2response = ec2client.describe_instances()
        # print(ec2response)
        for reservation in ec2response["Reservations"]:
            for ec2instance in reservation["Instances"]:
                count  += 1
                print(ec2instance["InstanceId"])
                if ("Tags" not in ec2instance.keys()):
                    ec2instance["Tags"]=[]
                tagupdate = checktags(ec2instance["Tags"], tags)
                print(tagupdate)
                editTags(ec2client, ec2instance, tagupdate)
                print(count)
        asgsession = boto3.Session(profile_name=account, region_name=region)
        asgclient = asgsession.client('autoscaling')
        asgresponse = asgclient.describe_auto_scaling_groups()
        for autoscalinggroup in asgresponse["AutoScalingGroups"]:
            count += 1
            asname = autoscalinggroup["AutoScalingGroupName"]
            print(autoscalinggroup["AutoScalingGroupName"])
            if ("Tags" not in autoscalinggroup.keys()):
                autoscalinggroup["Tags"]=[]
            astagupdate = checkastags(autoscalinggroup["Tags"], asname, tags)
            print(astagupdate)
            editASTags(asgclient, asname, astagupdate)
            print(count)