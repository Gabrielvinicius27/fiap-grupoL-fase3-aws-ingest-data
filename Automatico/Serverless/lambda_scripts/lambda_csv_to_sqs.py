import boto3

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']
        sqs = boto3.client('sqs')
        sqs.send_message(
            QueueUrl="https://sqs.us-west-2.amazonaws.com/676658052077/SQS-fiap-fase3-grupo-l-automatico-csv-to-json",
            MessageBody='{"bucket": "' + bucket + '", "key": "'+ file_key +'"}',
            DelaySeconds=12
        )