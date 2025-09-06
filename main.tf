resource "aws_s3_bucket" "static_bucket" {
  bucket        = "sridhar-tf-s3.sctp-sandbox.com"
  force_destroy = true
}

# Allow public access (website hosting needs this)
resource "aws_s3_bucket_public_access_block" "enable_public_access" {
  bucket = aws_s3_bucket.static_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.static_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.static_bucket.id}/*"
      }
    ]
  })
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Lookup hosted zone
data "aws_route53_zone" "sctp_zone" {
  name = "sctp-sandbox.com"
}

# Route53 record to point www.<name>.sctp-sandbox.com → S3 website
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name    = "sridhar-tf-s3.sctp-sandbox.com" # prefix before .sctp-sandbox.com
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.website.website_domain
    zone_id                = aws_s3_bucket.static_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}