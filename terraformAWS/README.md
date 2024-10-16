# Terraform을 활용한 S3 Bucket 생성 및 조작
---
Ubuntu 가상환경에서 Terraform을 활용하여 AWS S3 Bucket을 생성하고 생성한 객체를 조작해보는 실습을 진행하려 합니다.

실습 내용은 다음과 같습니다.

1. s3 bucket 생성</br>

2. s3 정책 권한 승인</br>

3. s3에 index.html 업로드</br>

4. url 동작 확인</br>

5. s3에 Main.html 업로드</br>

6. 이미 존재하는 index.html을 수정하여 s3에 재 업로드</br>

7. 동작 확인</br>

---
# 🟦 실행 환경
```Bash
- ubuntu : 22.04 LTS
  - AWS CLI : aws-cli/2.18.0 Python/3.12.6 Linux/5.15.0-122-generic exe/x86_64.ubuntu.22
```

---
# 🟦 0. AWS Configure
 - 실습에 앞서 AWS 계정에 대한 자격 증명 및 기본 설정을 쉽게 구성하기 위해 `aws configure` 를 해줍니다.
```Ruby
$ aws configure
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxx
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYxxxxxxxxxxxx
Default region name [None]: 리전이름
Default output format [None]: json
```

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

---
# 🟦 2. Terraform 스크립트
- Terraform 구성 스크립트 파일은 각각의 기능을 분리하여 작성하였습니다.
  
### 🔹2-1. 
### 🔹2-2.
### 🔹2-3.
### 🔹2-4.
### 🔹2-5.

---
# 🟦 3. 수행 결과

---
# 🟦 4. Trouble Shooting
