#Define Buckets
resource "aws_s3_bucket" "exposedbucket" {
  bucket = "${var.victim_company}accidentlyexposed"

  tags = {
    Name        = "Exposed Bucket"
    env = "Dev"
    Owner = var.owner
  }
}

resource "aws_s3_bucket_acl" "exposedbucket_acl" {
  bucket = aws_s3_bucket.exposedbucket.id
  acl    = "public-read"

}

resource "aws_s3_bucket" "intentionallyexposedbucket" {
  bucket = "${var.victim_company}intentionallylyexposed"

  tags = {
    Name        = "Intentionally Exposed Bucket"
    env = "Production"
    Owner = var.owner
  }
}
resource "aws_s3_bucket_acl" "intentionallyexposedbucket_acl" {
  bucket = aws_s3_bucket.intentionallyexposedbucket.id
  acl    = "public-read"
}
