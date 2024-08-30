import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']
    
    try:
        ec2.start_instances(InstanceIds=[instance_id])
        return f'Started instance: {instance_id}'
    except Exception as e:
        return str(e)