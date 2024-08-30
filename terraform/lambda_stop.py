import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']
    
    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        return f'Stopped instance: {instance_id}'
    except Exception as e:
        return str(e)