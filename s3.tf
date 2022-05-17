resource "aws_s3_bucket" "exposedbucket" {
  bucket = "accidentlyexposed"

  tags = {
    Name        = "Exposed Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "exposedbucket_acl" {
  bucket = aws_s3_bucket.exposedbucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket" "intentionallyexposedbucket" {
  bucket = "intentionallylyexposed"
  acl    = "public-read"

  tags = {
    Name        = "Intentionally Exposed Bucket"
    Environment = "Production"
  }
}
resource "aws_s3_bucket_acl" "intentionallyexposedbucket_acl" {
  bucket = aws_s3_bucket.intentionallyexposedbucket.id
  acl    = "public-read"
}