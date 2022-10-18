data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#### INICIO - IAM Role para a lambda function fiap-fase3-grupo-l-load-csv-to-sqs
data "aws_iam_policy_document" "lambda_load_csv_to_sqs_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "sqs:*"
    ]

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:logs:*:*:*",
      "arn:aws:sqs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "lambda_load_csv_to_sqs_role" {
  name               = "lambda_load_csv_to_sqs_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_load_csv_to_sqs_policy" {
  name   = "lambda_load_csv_to_sqs_policy"
  role   = aws_iam_role.lambda_load_csv_to_sqs_role.name
  policy = data.aws_iam_policy_document.lambda_load_csv_to_sqs_policy_document.json
}
#### FIM - IAM Role para a lambda function fiap-fase3-grupo-l-load-csv-to-sqs

#### INICIO - IAM Role para a lambda function fiap-fase3-grupo-l-csv-to-json
data "aws_iam_policy_document" "lambda_csv_to_json_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "sqs:*"
    ]

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:logs:*:*:*",
      "arn:aws:sqs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "lambda_csv_to_json_role" {
  name               = "lambda_csv_to_json_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_csv_to_json_policy" {
  name   = "lambda_csv_to_json_policy"
  role   = aws_iam_role.lambda_csv_to_json_role.name
  policy = data.aws_iam_policy_document.lambda_csv_to_json_policy_document.json
}
#### FIM - IAM Role para a lambda function fiap-fase3-grupo-l-csv-to-json

#### INICIO - IAM Role para a lambda function fiap-fase3-grupo-l-load-json-to-sqs
data "aws_iam_policy_document" "lambda_load_json_to_sqs_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "sqs:*"
    ]

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:logs:*:*:*",
      "arn:aws:sqs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "lambda_load_json_to_sqs_role" {
  name               = "lambda_load_json_to_sqs_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_load_json_to_sqs_policy" {
  name   = "lambda_load_json_to_sqs_policy"
  role   = aws_iam_role.lambda_load_json_to_sqs_role.name
  policy = data.aws_iam_policy_document.lambda_load_json_to_sqs_policy_document.json
}
#### FIM - IAM Role para a lambda function fiap-fase3-grupo-l-load-json-to-sqs

#### INICIO - IAM Role para a lambda function fiap-fase3-grupo-l-json_to_firehose
data "aws_iam_policy_document" "lambda_json_to_firehose_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "sqs:*",
      "firehose:*"
    ]

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:logs:*:*:*",
      "arn:aws:sqs:*:*:*",
      "arn:aws:firehose:*:*:*"
    ]
  }
}

resource "aws_iam_role" "lambda_json_to_firehose_role" {
  name               = "lambda_json_to_firehose_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_json_to_firehose_policy" {
  name   = "lambda_json_to_firehose_policy"
  role   = aws_iam_role.lambda_json_to_firehose_role.name
  policy = data.aws_iam_policy_document.lambda_json_to_firehose_policy_document.json
}
#### FIM - IAM Role para a lambda function fiap-fase3-grupo-l-json_to_firehose

#### INICIO - IAM Role para o Firehose acessar o S3
data "aws_iam_policy_document" "kinesis_firehose_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "kinesis_firehose_access_s3_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "kinesis_firehose_access_s3_role" {
  name               = "kinesis_firehose_access_s3_role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_firehose_assume_role.json
}

resource "aws_iam_role_policy" "kinesis_firehose_access_s3_policy" {
  name   = "kinesis_firehose_access_s3_policy"
  role   = aws_iam_role.kinesis_firehose_access_s3_role.name
  policy = data.aws_iam_policy_document.kinesis_firehose_access_s3_policy_document.json
}
#### FIM - IAM Role para o Firehose acessar o S3
