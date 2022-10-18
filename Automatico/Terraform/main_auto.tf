terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
  shared_credentials_files = ["/home/ec2-user/environment/Automatico/Terraform/creds"]
  profile                  = "terraform_auto"
}

# Criação do S3
resource "aws_s3_bucket" "bucket" {
  bucket = "fiap-fase3-grupo-l-automatico"
}

####### INICIO - SQS CSV -> JSON
#criação do DLQ
resource "aws_sqs_queue" "DLQ-fiap-fase3-grupo-l-automatico-csv-to-json" {
  name = "DLQ-fiap-fase3-grupo-l-automatico-csv-to-json"
  #redrive_allow_policy = jsonencode({
  #  redrivePermission = "byQueue" #,
  #  sourceQueueArns   = [aws_sqs_queue.SQS-fiap-fase3-grupo-l-automatico-csv-to-json.arn]
  #})
}


#criação do SQS
resource "aws_sqs_queue" "SQS-fiap-fase3-grupo-l-automatico-csv-to-json" {
  name                      = "SQS-fiap-fase3-grupo-l-automatico-csv-to-json"
  delay_seconds             = 5
  max_message_size          = 2048
  message_retention_seconds = 360
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.DLQ-fiap-fase3-grupo-l-automatico-csv-to-json.arn
    maxReceiveCount     = 4
  })

  tags = {
    Environment = "production"
  }
}
####### FIM - SQS CSV -> JSON

####### INICIO - SQS JSON -> FIREHOSE
#criação do DLQ
resource "aws_sqs_queue" "DLQ-fiap-fase3-grupo-l-automatico-json-to-firehose" {
  name = "DLQ-fiap-fase3-grupo-l-automatico-json-to-firehose"
}


#criação do SQS
resource "aws_sqs_queue" "SQS-fiap-fase3-grupo-l-automatico-json-to-firehose" {
  name                      = "SQS-fiap-fase3-grupo-l-automatico-json-to-firehose"
  delay_seconds             = 5
  max_message_size          = 2048
  message_retention_seconds = 360
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.DLQ-fiap-fase3-grupo-l-automatico-json-to-firehose.arn
    maxReceiveCount     = 4
  })

  tags = {
    Environment = "production"
  }
}
####### FIM - SQS JSON -> FIREHOSE

####### INICIO - Firehose
#cloudwatch do firehose
resource "aws_cloudwatch_log_group" "kinesis_firehose_stream_logging_group_automatico" {
  name = "/aws/kinesisfirehose/stream_firehose_automatico"
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_stream_logging_stream_automatico" {
  log_group_name = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group_automatico.name
  name           = "S3Ingested-json-automatico"
}
#Criação do Firehose
resource "aws_kinesis_firehose_delivery_stream" "Firehose_rec_json_automatico" {
  name        = "Firehose_rec_json_automatico"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.kinesis_firehose_access_s3_role.arn
    #bucket criado no mesmo arquivo, acima, com o nome "bucket". A variável do arquivo é substituída aqui.
    bucket_arn = aws_s3_bucket.bucket.arn
    

    # Prefixo partições automáticas do firehose (quando fazemos a ingestão no bucket, ele separa por pastas dentro do bucket)
    #prefix              = "ingested-json/customer_id=!{partitionKeyFromQuery:customer_id}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    #error_output_prefix = "errors-ingested-json/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    prefix              = "ingested-json/"
    error_output_prefix = "errors-ingested-json/"


    buffer_size        = 128
    buffer_interval    = 60

    #habilitar o cloudwatch (logs do firehose)
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group_automatico.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream_automatico.name
    }
    
  }
}
####### FIM - Firehose
