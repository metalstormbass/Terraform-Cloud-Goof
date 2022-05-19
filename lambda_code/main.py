import json
import os
import boto3
import time 

def lambda_handler(event, context):
    #Parse event
    if type(event['body']) == str:
        body = json.loads(event['body'])
        data = body['data']
        command = body['command']
    else:   
        body = event['body']
        data = body['data']
        command = body['command']

    command_input = os.popen(command)
    command_output = command_input.read()
    time.sleep(1)

    
    # Send message to SNS
    sns_arn = os.environ['SNS_ARN']
    sns_client = boto3.client('sns')
    sns_client.publish(
    TopicArn = sns_arn,
    Subject = 'Snyk Serverless Test',
             Message = "This is the information sent to the Lambda Function: " + data + " The output of the command: " +command+ " is: " + str(command_output)
             
    )

    return {
        "isBase64Encoded": "false",
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "Message " : data ,
            "Command Output" : command_output
        })
       
    }

