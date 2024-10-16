# S3 버킷 생성
resource "aws_s3_bucket" "bucket2" {
  bucket = "ce08-bucket2"  # 생성하고자 하는 S3 버킷 이름
}

# S3 버킷의 웹사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "xweb_bucket_website" {
  bucket = aws_s3_bucket.bucket2.id  # 생성된 S3 버킷 이름 사용

  index_document {
    suffix = "index.html"
  }
}