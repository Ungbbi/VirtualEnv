# jenkinsAutoDistribution
---
# 🎯 목표 및 개요
**개발 및 테스트 서버에서 JAR 파일이 갱신되면 운영서버에도 자동으로 반영**되는 것이 **목표**입니다.</br></br>
개발 및 테스트 서버의 JAR파일은 Jenkins가 fisatest 레포지토리의 **Commit을 감지**하면 JAR파일을 다시 빌드하고 바인드 되어있는 경로에 Copy 합니다.</br>
이후, 개발 및 테스트 서버가 JAR파일이 변경됐음을 감지하고 **SCP**를 통해 **운영서버**에 JAR파일을 **전송**합니다.</br>
운영서버는 변경된 JAR파일을 **실시간으로 반영**하여 재실행 시킵니다.</br></br>

---
# 🛠️ 환경 및 설정
### 가상머신
VMVirtualBox / Ubuntu LTS 22.04 환경
- 가상머신 : `myserver01`
  - 개발 및 테스트 서버</br>
  - Docker에서 Jenkins 컨테이너 실행 중</br>
  - iP 10.0.2.15</br>
- 가상머신 : `myserver02`
  - 운영서버</br>
  - ip : 10.0.2.19</br></br>
### Jenkins
- fisatest 레포를 hookup
- `myserver01`에서 Docker로 Jenkins 컨테이너를 실행 중</br>
- port 8080 사용

### JAR File
- Spring Boot Application
- ServerPort = 8899

### Forwarding
<img width="635" alt="{B88EE5A3-2550-4828-AD66-E00A8DF9F7E9}" src="https://github.com/user-attachments/assets/3683c4fd-8945-4ed5-940f-5fdb1366579a"></br></br>
- SprinApp은 `myserver01`에서 실행하는 JAR File이 http 응답을 받을 포트입니다.</br>
- SPringApp2는 `myserver02`에서 실행하는 JAR File이 http 응답을 받을 포트입니다.</br>

### Shell Script
- `autorunning.sh` : 8899 포트를 사용중인 이전 프로세스를 종료시키고 갱신된 JAR file을 백그라운드로 새로 실행시키며  app.log에 로그를 저장합니다.
- `change.sh` : JAR File의 수정을 작성된 시간 변화를 통해 감지하고 `autorunning.sh`를 실행하여 이전 프로세스를 종료시키고 갱신된 JAR를 실행시키도록 합니다.
</br> **( myserver01에서는 추가로 scp 명령어를 추가하여 myserver02로 갱신된 JAR file을 전송합니다. )** 

---
# 📜 Process
다음과 같은 과정으로 진행이 됩니다.</br></br>
**1. Github Commit 발생**</br></br>
**2. Jenkins가 감지**
   1. JAR 파일 빌드
   2. 마운트 되어있는 경로로 COPY</br></br>
**3. `myserver01` 에서 실행중인 `change.sh`에 의해 JAR 파일 갱신 감지 및 재실행**
   1. scp로 `myserver02`로 변경된 JAR 파일 전송</br></br>
**4. `myserver02` 에서 실행중인 `change.sh`에 의해 JAR 파일 갱신 감지 및 재실행**</br></br>

---
# 실습
## 1. Jenkins
### Jenkins Container 생성 및 접속
```shell
docker run --name myjenkins --privileged -p 8080:8080 -v $(pwd)/appjardir:/var/jenkins_home/appjar jenkins/jenkins:lts-jdk17
```
위 명령어를 입력하여 jenkins 컨테이너를 생성합니다. -v 로 로컬저장소에 컨테이너 내 경로인 `/var/jenkins_home/appjar`를 마운트 해줍니다.</br>

Github webhook 설정을 하려면 외부에서 접속이 가능해야 하므로 ngrok을 사용하겠습니다.</br>
ngrok.exe가 위치해있는 디렉토리에서 cmd를 실행시키고 다음 명령어를 입력합니다.</br>
`./ngrok http http://localhost:8080`

컨테이너가 실행됐다면 `127.0.0.1:8080` 또는 ngrok으로 접속한 다음 로그인을 완료합니다.
</br></br>

### Jenkins Pipeline 설정

