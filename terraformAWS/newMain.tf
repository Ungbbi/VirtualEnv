provider "aws" {
  region = "ap-northeast-2" # 사용할 AWS 리전 설정
}

# 이미 존재하는 S3 버킷에 파일 업로드
resource "aws_s3_object" "Main" {
  bucket = aws_s3_bucket.bucket2.id # 이미 존재하는 S3 버킷 이름
  key    = "Main.html" # S3 버킷 내에서 파일의 경로
  source = "Main.html" # 로컬 파일의 경로
  content_type  = "text/html"

  tags = {
    Name        = "Main.html"
    Environment = "Production"
  }
}