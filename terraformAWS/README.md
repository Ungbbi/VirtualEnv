# 🤓 Terraform을 활용한 S3 Bucket 생성 및 조작
---
Ubuntu 가상환경에서 **Terraform**을 활용하여 AWS S3 Bucket을 생성하고 생성한 객체를 조작해보는 실습을 진행하려 합니다.

실습 내용은 다음과 같습니다.

**1. s3 bucket 생성</br>**

**2. s3 정책 권한 승인</br>**

**3. s3에 index.html 업로드</br>**

**4. url 동작 확인</br>**

**5. s3에 Main.html 업로드</br>**

**6. 이미 존재하는 index.html을 수정하여 s3에 재 업로드</br>**

**7. 동작 확인</br>**
</br></br>

---
# 🟦 실행 환경
```Bash
- ubuntu : 22.04 LTS
  - AWS CLI : aws-cli/2.18.0 Python/3.12.6 Linux/5.15.0-122-generic exe/x86_64.ubuntu.22
```
</br></br>


---
# 🟦 0. AWS Configure
 - 실습에 앞서 AWS 계정에 대한 자격 증명 및 기본 설정을 쉽게 구성하기 위해 **`aws configure`** 를 해줍니다.
```Ruby
$ aws configure
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxx
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYxxxxxxxxxxxx
Default region name [None]: 리전이름
Default output format [None]: json
```
</br></br>

---
# 🟦 1. Terraform 설치
```Ruby
$ sudo su -

# HashiCorp의 패키지 저장소에 대한 신뢰할 수 있는 GPG 키를 시스템에 추가
$ wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# HashiCorp의 APT 저장소를 시스템의 소스 목록에 추가하여, 나중에 Terraform을 설치할 수 있도록 준비
$ echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# HashiCorp의 APT 저장소에서 Terraform을 설치
$ apt-get update && apt-get install terraform -y

# 설치된 terraform의 버전 확인
$ terraform -version
```
</br></br>

---
# 🟦 2. Terraform 스크립트
- Terraform 구성 스크립트 파일은 각각의 기능을 분리하여 작성하였습니다.

- **`resource "resource_type" "resource_name"`**
    - `resource_type` : Terraform 에서 사용하는 리소스 유형 중 하나를 지정해야 합니다.
      
    - `resource_name` : `resource_type`의 이름을 선언해주는 것입니다.

    - **⚠️주의 : `resource_name`은 중복이 되어선 안됩니다.**
 </br></br>

### 🔹2-1. createBucket.tf
```HCL
# S3 버킷 생성
resource "aws_s3_bucket" "bucket2" {
  bucket = "ce08-bucket2"  # 생성하고자 하는 S3 버킷 이름
}

# S3 버킷의 웹사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "xweb_bucket_website" {
  bucket = aws_s3_bucket.bucket2.id  # 생성된 S3 버킷 리소스 사용

  index_document {
    suffix = "index.html"
  }
}
```
</br></br>

### 🔹2-2. policy.tf

- bucket 부분을 보면 `aws_s3_bucket` 리소스 유형의 bucket2 리소스를 사용하여 id 값을 가져오는 것입니다.


```HCL
# S3 버킷의 public read 정책 설정
resource "aws_s3_bucket_public_access_block" "bucket2_public_access_block" {
  bucket = aws_s3_bucket.bucket2.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.bucket2.id  # 생성된 S3 버킷 이름 사용

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [ "s3:GetObject" ],
      "Resource": [
        "arn:aws:s3:::ce08-bucket2",
        "arn:aws:s3:::ce08-bucket2/*"
      ]
    }
  ]
}
EOF
}
```
</br></br>

### 🔹2-3. newIndex.tf
- `etag`로 s3에 업로드 돼있는 index.html 파일의 **변경 사항을 감지**합니다.
  
```HCL
resource "aws_s3_object" "index" {
  bucket        = aws_s3_bucket.bucket2.id  # 생성된 S3 버킷 이름 사용
  key           = "index.html"
  source        = "index.html"
  content_type  = "text/html"
  etag          = filemd5("index.html")  # 파일이 변경될 때 MD5 체크섬을 사용해 변경 사항 감지
}
```
</br></br>

### 🔹2-4. newMain.tf

```HCL
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
```

### 🔹2-5. output.tf
```HCL
output "website_endpoint" {
  value = aws_s3_bucket.bucket2.website_endpoint
  description = "The endpoint for the S3 bucket website."
}
```
</br></br>

---
# 🟦 3. Terraform 실행 및 결과

### 🔹3-1. Terraform 실행
- Terraform은 리소스 간의 **의존성을 자동으로 감지**하여 구성 파일을 실행하는 순서를 결정합니다.
  
- Terraform은 현재 명령어를 수행하는 디렉터리에 있는 **모든 `.tf` 파일을 병합하여 하나의 구성**으로 처리합니다. 
  따라서 특정 리소스나 리소스 그룹만을 대상으로 변경 사항을 적용할 때 사용하려면 `-target`옵션을 사용하면 됩니다.</br>
  
  - `terraform apply -target= targetFile` 와 같이 -target 옵션을 사용
 

```Ruby
# Terraform 작업 디렉토리를 초기화
terraform init

# 현재 상태와 Terraform 구성 파일을 비교하여 어떤 변경이 필요한지 예측
terraform plan

# 실제 Terraform 구성에 따라 리소스를 생성, 변경 또는 삭제
terraform apply

# terraform apply  실행 시 도중 yes를 입력해야 하는데 이를 Skip
terraform apply -auto-approve
```
</br></br>

### 🔹3-2. 실행 결과

<img width="428" alt="{85788110-5009-49E0-9D5B-ECDAB3647CA0}" src="https://github.com/user-attachments/assets/be96ffc2-c1d4-49fc-aed1-2c867e205f2d">

<img width="424" alt="{E23BFA5D-1B2E-4B6C-A94F-4527B992AEC9}" src="https://github.com/user-attachments/assets/8f0e9e4a-ffea-481f-bd4b-ae54e5d312b6">
</br></br>

---
# 🟦 4. Trouble Shooting
### 🔹4-1. 구성파일 실행 순서
![image](https://github.com/user-attachments/assets/917c3d90-5ea6-4846-a1a0-40ecf3075f00)

- 지정한 S3 버켓에 Main.html 을 업로드 해야하는데 S3 버켓이 없다는 에러입니다.
  
- `.tf` 파일들 간 실행을 할 때 bucket을 사용하였었습니다. 이 때 아래와 같이 각 tf 파일들에 bucket이름에 **직접 값**을 넣어주었기 때문에 에러가 발생한 것입니다.</br>
  앞서 설명했듯이 **Terraform**은 리소스 간 **의존성을 자동으로 감지**하여 구성 파일의 실행 순서를 결정하는데 `# 2`의 스크립트들 처럼 aws_s3_bucket.bucket2 리소스에 **의존**한다면</br>
  Terraform은 해당 리소스를 생성하는 구성 파일을 먼저 실행할 것입니다.</br>

  하지만 아래와 같이 직접 값을 넣어준다면 의존성이 사라지니 실행 순서에 영향을 주는 일이 없어져, 없는 리소스를 참조하는 스크립트가 실행되므로 결국 에러가 발생하는 것입니다.
  
```HCL
resource "aws_s3_object" "Main" {
  bucket = "test08-bucket" # s3에 실제로 존재하는 bucket 명
  ```
}


