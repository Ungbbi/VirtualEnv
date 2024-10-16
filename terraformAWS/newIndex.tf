resource "aws_s3_object" "index" {
  bucket        = aws_s3_bucket.bucket2.id  # 생성된 S3 버킷 이름 사용
  key           = "index.html"
  source        = "index.html"
  content_type  = "text/html"
  etag          = filemd5("index.html")  # 파일이 변경될 때 MD5 체크섬을 사용해 변경 사항 감지
}