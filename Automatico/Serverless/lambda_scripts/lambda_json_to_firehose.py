import boto3
import json
import base64

def send_to_firehose(bucket_name, file_name):
    jsonf = s3_client.get_object(Bucket=bucket_name, Key=file_name)
    jsonf = json.loads(jsonf['Body'].read().decode('utf-8'))

    for row in jsonf:
        # call put_record_batch
        firehose_client.put_record_batch(
            DeliveryStreamName="Firehose_rec_json_automatico",
            Records=[{'Data':json.dumps(row)+',\n'}]
        )

def lambda_handler(event, context):
    global s3_client
    s3_client = boto3.client('s3')
    global firehose_client
    firehose_client = boto3.client('firehose')
    for record in event['Records']:
        payload = json.loads(record["body"])
        bucket_name = payload["bucket"]
        file_name = payload["key"]
        send_to_firehose(bucket_name, file_name)
        