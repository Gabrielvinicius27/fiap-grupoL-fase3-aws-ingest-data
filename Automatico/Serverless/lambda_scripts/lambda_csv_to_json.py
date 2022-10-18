import boto3
import csv 
import json
from io import StringIO

def csv_to_json(bucket_name, file_name, destino):
    jsonArray = []
    
    csvf = client.get_object(Bucket=bucket_name, Key=file_name)
    csvf = csvf['Body'].read().decode('utf-8')
    csvReader = csv.DictReader(StringIO(csvf), delimiter = ',') 
    #convert each csv row into python dict
    for row in csvReader: 
        #add this python dict to json array
        jsonArray.append(row)
        
    json_file = json.dumps(jsonArray, indent=4).encode('UTF-8')
    dest = f"{destino}{file_name.split('/')[1].replace('.csv', '.json')}"
    client.put_object(Body=json_file, Bucket=bucket_name, Key=dest)

def lambda_handler(event, context):
    global client
    client = boto3.client('s3')
    destino='raw_json/'
    
    for record in event['Records']:
        payload = json.loads(record["body"])
        bucket_name = payload["bucket"]
        file_name = payload["key"]
        csv_to_json(bucket_name, file_name, destino)