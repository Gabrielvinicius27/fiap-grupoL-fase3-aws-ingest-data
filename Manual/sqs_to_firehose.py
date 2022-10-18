import boto3
import csv 
import json 
import io
from botocore.exceptions import ClientError
import logging

arqmemoria = io.BytesIO()
s3 = boto3.resource('s3')
s3_client = boto3.client('s3')
sqs = boto3.client('sqs')
session_fh = boto3.client('firehose')
#Session('firehose')

urlSQS='https://sqs.us-west-2.amazonaws.com/676658052077/SQS-fiap-fase3-grupo-l-manual-json-to-firehose'


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
        
        #pega a mensagem do SQS e guarda nas variáveis
        
        mensagem = json.loads(message_body)
        
        nome_bucket = mensagem['bucket']
        arq = mensagem['key']
        
        arq_json = s3_client.get_object(Bucket=nome_bucket, Key=arq)
        #print(arq)
        arq_json = json.loads(arq_json['Body'].read().decode('utf-8'))
        
        #objeto_s3 = s3_client.get_object(Bucket=nome_bucket, Key=arq)
        
        nomearquivo=arq.split('/')[-1]
        
        i=0

        for linha in arq_json:

            print(linha)
            response = session_fh.put_record(
                                                    DeliveryStreamName='Firehose_rec_json',
                                                    Record={
                                                            'Data': json.dumps(linha)+ ',\n'
                                                            }
                                            )
            i=i+1
        #jsons = arqmemoria_str.split("\n")
            

        #for linha in jsons:
        #    #print(linha)
        #    i=i+1
        #    #try:
        #        #envia mensagem para o Firehose
        #    response = session_fh.put_record(
        #                                            DeliveryStreamName='Firehose_rec_json',
        #                                            Record={
        #                                                    'Data': json.dumps(linha)+ '\n'
        #                                                    }
        #                                            )
        #    print(response)
            print(linha)
        
        response = sqs_client.delete_message(
                                    QueueUrl=urlSQS,
                                    ReceiptHandle=receipt_handle)
            #except:
                #print(linha)
                #print('num_linha'+ str(i) + ' objeto s3: ' + arq)


receive_message()       
