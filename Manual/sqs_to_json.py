import boto3
import csv 
import json 
import io
from botocore.exceptions import ClientError
import logging
import os


s3 = boto3.resource('s3')
s3_client = boto3.client('s3')
prefix_json = 'json-raw/'
pasta='csv_to_json/'
sqs = boto3.client('sqs')

urlSQS='https://sqs.us-west-2.amazonaws.com/676658052077/SQS-fiap-fase3-grupo-l-manual-csv-to-json'

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s: %(levelname)s: %(message)s')


def receive_message():
    sqs_client = boto3.client('sqs')
    
    response = sqs_client.receive_message(
                                    QueueUrl=urlSQS,
                                    MaxNumberOfMessages=10,
                                    WaitTimeSeconds=10
                                    )
                                    
    print(f'Número de mensagens: {len(response.get("Messages",[]))}')                                    
    
    for message in response.get('Messages',[]):
        message_body=message["Body"]
        receipt_handle = message['ReceiptHandle']
        print(f"Message body: {json.loads(message_body)}")
        #print(f"ReceiptHandle: {message['ReceiptHandle']}")
        
        conteudo_json = json.loads(message_body)
        nome_bucket = conteudo_json['bucket']
        arq = conteudo_json['key']
        
        #objeto_s3 = s3_client.get_object(Bucket=nome_bucket, Key=arq)
        
        nomearquivo=arq.split('/')[-1]
        i=0
    
        with open('tempcsv',"w+b") as csvmemoria:
            
            s3_client.download_fileobj(nome_bucket, arq, csvmemoria )
            csvmemoria.seek(0)
            
            csv_reader = csv.DictReader(io.TextIOWrapper(csvmemoria, encoding="utf-8"))
            
            #data = list(csv_reader)
            #print (data)
            
            split1 = nomearquivo.split('.csv')
            nomearq_json= split1[0]+'.json'
            rows = list(csv_reader)
            totalrows = len(rows)
            print ('total de linhas:'+str(totalrows))
            csvmemoria.seek(0)
            
            with open(nomearq_json, 'w+') as output:
                output.write('[')
                for row in csv_reader:
                    i=i+1
                    json.dump(row,output)
                    #output.write(',\n')
                    if i <= totalrows:
                        output.write(',\n')
                    else:
                        #print(str(i))
                        output.write('\n')

                output.write(']')
                output.close()
                
                s3_client.upload_file(nomearq_json, nome_bucket, prefix_json+nomearq_json)

                response = sqs_client.delete_message(
                                    QueueUrl=urlSQS,
                                    ReceiptHandle=receipt_handle)
                                    
                os.remove(output.name)
        
receive_message()