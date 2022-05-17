import json
import os
import boto3
import time 




def lambda_handler(event, context):
    #Parse event
    data = event['body']['data']
    command = event['body']['command']
    command_input = os.popen(command)
    command_output = command_input.read()
    time.sleep(4)
    
    # Send message to SNS
    sns_arn = os.environ['SNS_ARN']
    sns_client = boto3.client('sns')
    sns_client.publish(
    TopicArn = sns_arn,
    Subject = 'Check Point Serverless Test',
             Message = "This is the information sent to the Lambda Function: " + data + " The output of the command: " +command+ " is: " + str(command_output)
             
    )
