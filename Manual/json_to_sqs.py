import boto3
import csv 
import json 
import io
import tempfile

nome_bucket = 'fiap-fase3-grupo-l-manual'
s3 = boto3.resource('s3')
s3_client = boto3.client('s3')
my_bucket = s3.Bucket(nome_bucket)
prefix_orig = 'json-raw/'
sqs = boto3.client('sqs')

urlSQS='https://sqs.us-west-2.amazonaws.com/676658052077/SQS-fiap-fase3-grupo-l-manual-json-to-firehose'

for objeto_s3 in my_bucket.objects.filter(Prefix=prefix_orig):
    if objeto_s3.key not in prefix_orig:
        response = sqs.send_message(
                                    QueueUrl=urlSQS,
                                    MessageBody='{"bucket": "' +nome_bucket+ '", "key": "'+ objeto_s3.key+'"}',
                                    DelaySeconds=12
                                    )
                                
        print (response)