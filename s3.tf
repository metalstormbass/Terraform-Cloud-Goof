resource "aws_s3_bucket" "exposedbucket" {
  bucket = "accidentlyexposed"
  acl    = "public-read"

  tags = {
    Name        = "Exposed Bucket"
    Environment = "Dev"
  }
}
