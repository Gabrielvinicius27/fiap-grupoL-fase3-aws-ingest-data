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
  shared_credentials_files = ["/home/ec2-user/environment/Manual/Terraform/creds"]
  profile                  = "terraform"
}

#criação do S3
resource "aws_s3_bucket" "bucket" {
  bucket = "fiap-fase3-grupo-l-manual"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

#######SQS CSV -> JSON
#criação do DLQ
resource "aws_sqs_queue" "DLQ-fiap-fase3-grupo-l-manual-csv-to-json" {
  name = "DLQ-fiap-fase3-grupo-l-manual-csv-to-json"
  #redrive_allow_policy = jsonencode({
  #  redrivePermission = "byQueue" #,
  #  sourceQueueArns   = [aws_sqs_queue.SQS-fiap-fase3-grupo-l-manual-csv-to-json.arn]
  #})
}


#criação do SQS
resource "aws_sqs_queue" "SQS-fiap-fase3-grupo-l-manual-csv-to-json" {
  name                      = "SQS-fiap-fase3-grupo-l-manual-csv-to-json"
  delay_seconds             = 20
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.DLQ-fiap-fase3-grupo-l-manual-csv-to-json.arn
    maxReceiveCount     = 50
  })

  tags = {
    Environment = "production"
  }
}

#######SQS JSON -> FIREHOSE
#criação do DLQ json -> firehose
resource "aws_sqs_queue" "DLQ-fiap-fase3-grupo-l-manual-json-to-firehose" {
  name = "DLQ-fiap-fase3-grupo-l-manual-json-to-firehose"
  #redrive_allow_policy = jsonencode({
  #  redrivePermission = "byQueue" #,
  #  sourceQueueArns   = [aws_sqs_queue.SQS-fiap-fase3-grupo-l-manual-json-to-firehose.arn]
  #})
}


#criação do SQS
resource "aws_sqs_queue" "SQS-fiap-fase3-grupo-l-manual-json-to-firehose" {
  name                      = "SQS-fiap-fase3-grupo-l-manual-json-to-firehose"
  delay_seconds             = 20
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.DLQ-fiap-fase3-grupo-l-manual-json-to-firehose.arn
    maxReceiveCount     = 50
  })

  tags = {
    Environment = "production"
  }
}


#######Glue
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table
#resource "aws_glue_catalog_database" "glue_manual" {
#  name = "glue_manual"
#}
#
#resource "aws_glue_catalog_table" "glue_manual_tabela" {
#  name          = "glue_manual_tabela"
#  database_name = aws_glue_catalog_database.glue_manual.name
#
#  table_type = "EXTERNAL_TABLE"
#
#  parameters = {
#    EXTERNAL         = "TRUE"
#    "classification" = "parquet"
#  }
#
#  storage_descriptor {
#    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
#    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
#    location      = "S3://aws_s3_bucket.bucket.bucket/ingested-json"
#
#    ser_de_info {
#      name                  = "JsonSerDe"
#      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
#
#      parameters = {
#        "serialization.format" = 1
#        "explicit.null"        = false
#        "parquet.compression"  = "SNAPPY"
#      }
#    }
#
#    columns { 
#      name = "id"
#      type = "bigint"
#    }
#    columns { 
#      name = "NAME"
#      type = "string"
#    }
#  }
#}



#######FIREHOSE

#cloudwatch do firehose
resource "aws_cloudwatch_log_group" "kinesis_firehose_stream_logging_group_manual" {
  name = "/aws/kinesisfirehose/stream_firehose_manual"
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_stream_logging_stream_manual" {
  log_group_name = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group_manual.name
  name           = "S3Ingested-json"
}



#IAM do Firehose

#Criar a role
resource "aws_iam_role" "firehose_role_manual" {
  name = "firehose_role_manual"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
    
  ]
}
EOF
}

#As policies para inserir na role
data "aws_iam_policy_document" "firehose_policy_manual" {
  statement {
    actions   = [
      "glue:*",
      "s3:*",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "cloudwatch:PutMetricData"
      ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:CreateBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::aws-glue-*",
      "arn:aws:s3:::*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:us-west-2:676658052077:*"
    ]
  }
}

#associar a role com a policy
resource "aws_iam_role_policy" "firehose_role_policy_manual" {
  name   = "firehose_role_policy_manual"
  role   = aws_iam_role.firehose_role_manual.name
  policy = data.aws_iam_policy_document.firehose_policy_manual.json
}


#Criação do Firehose
resource "aws_kinesis_firehose_delivery_stream" "Firehose_rec_json" {
  name        = "Firehose_rec_json"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role_manual.arn
    #bucket criado no mesmo arquivo, acima, com o nome "bucket". A variável do arquivo é substituída aqui.
    bucket_arn = aws_s3_bucket.bucket.arn
    

    # Prefixo partições automáticas do firehose (quando fazemos a ingestão no bucket, ele separa por pastas dentro do bucket)
    #prefix              = "ingested-json/customer_id=!{partitionKeyFromQuery:customer_id}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    #error_output_prefix = "errors-ingested-json/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    prefix              = "ingested-json/"
    error_output_prefix = "errors-ingested-json/"


    buffer_size        = 128
    buffer_interval    = 300

    #habilitar o cloudwatch (logs do firehose)
    cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group_manual.name
        log_stream_name = aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream_manual.name
      }

    
  #  data_format_conversion_configuration {
  #    input_format_configuration {
  #      deserializer {
  #        hive_json_ser_de {}
  #      }
  #    }
  #    #transformar para parquet
  #    output_format_configuration {
  #      serializer {
  #        parquet_ser_de {}
  #      }
  #    }
  #  
  #  
  #  schema_configuration {
  #      database_name = aws_glue_catalog_database.glue_manual.name
  #      table_name    = aws_glue_catalog_table.glue_manual_tabela.name
  #      role_arn      = aws_iam_role.firehose_role_manual.arn
  #    }
  #  }
  }
    
}

#fim do firehose 





###########GLUE
#resource "aws_glue_catalog_database" "glue_catalog_database_manual" {
#  name = var.glue_catalog_database_name
#}
#
#resource "aws_glue_catalog_table" "glue_catalog_table_manual" {
#  name          = var.glue_catalog_table_name
#  database_name = aws_glue_catalog_database.glue_catalog_database.name
#
#  parameters = {
#    "classification" = "parquet"
#  }
#
#  storage_descriptor {
#    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
#    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
#    location      = "s3://${aws_s3_bucket.fiap-fase3-grupo-l-manual.bucket}/"
#
#    ser_de_info {
#      name                  = "JsonSerDe"
#      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
#
#      parameters = {
#        "serialization.format" = 1
#        "explicit.null"        = false
#        "parquet.compression"  = "SNAPPY"
#      }
#    }
#
#    dynamic "columns" {
#      for_each = var.glue_catalog_table_columns
#      content {
#        name = columns.value["name"]
#        type = columns.value["type"]
#      }
#    }
#  }
#}


