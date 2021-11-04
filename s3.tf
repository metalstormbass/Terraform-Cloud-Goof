resource "aws_s3_bucket" "exposed_bucket" {
  bucket = "accidently_exposed"
  acl    = "public-read"

  tags = {
    Name        = "Exposed Bucket"
    Environment = "Dev"
  }
}