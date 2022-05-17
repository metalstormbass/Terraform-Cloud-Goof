resource "aws_s3_bucket" "exposedbucket" {
  bucket = "accidentlyexposed"
  acl    = "public-read"

  tags = {
    Name        = "Exposed Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "intentionallyexposedbucket" {
  bucket = "intentionallylyexposed"
  acl    = "public-read"

  tags = {
    Name        = "Intentionally Exposed Bucket"
    Environment = "Production"
  }
}
