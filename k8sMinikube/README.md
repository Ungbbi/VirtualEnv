# Kubernetes MiniKube</br>
## < Minikube를 사용한 Spring Application 배포 >
---
# 🎯 목표 및 개요
**Minikube를 사용하여 Spring Application을 배포**하는 것이 **목표**</br></br>

아래와 같은 순서로 작업을 수행하여 최종적으로 Service 3개의 Pod(컨테이너)을 생성하고 외부와 통신 가능한 서비스 1개를 생성
1. SpringApplication을 Build하여 Jar 파일을 생성
2. Docker 이미지를 생성하고 Docker Hub에 Push
3. Minikube를 사용하며 작성한 yml파일로 이미지를 Pull받아와서 컨테이너 생성 및 실행


---
# 🛠️ 환경 및 설정

```ruby
virtualbox: version 7.0
ubuntu: version 22.04.4 LTS
docker: version 27.3.1
minikube: version v1.34.0
```

---
# 💻 실습
## 🟦 1. Docker Image 생성
### 🔹1-1. Dockerfile 작성
여러 Pod들로 로드밸런싱이 잘 되는지 눈으로 확인해보기 위해 다음과 같이 코드를 작성하였다.

외부에서 접속하면 어떤 Pod로 접속되는지 Pod의 이름을 출력한다.

`ProcessController.java`
```JAVA
package com.ce.fisa.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
public class ProcessController {
	@Autowired
	Environment env;
	
	@GetMapping("/status")
	public String status() {
		return "Status - returned by Pod - " + env.getProperty("HOSTNAME");
	}
}
```

⚠️ Spring의 application.properties에서 server.port를 9988로 설정하였다.

이제 docker Image를 Build하기 위해 Docker file을 작성해준다.

`Dockerfile`
```ruby
FROM openjdk:17-slim AS base
# 작업 디렉토리 설정
WORKDIR /app

# 애플리케이션 JAR 파일을 컨테이너의 /app 디렉토리로 복사
COPY springAPPk8s-0.0.1-SNAPSHOT.jar app.jar

# 헬스 체크 설정
HEALTHCHECK --interval=10s --timeout=30s CMD curl -f http://localhost:9988/test || exit 1

# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 🔹1-2. Image 생성 및 Push
이미지 생성</br>
`$ docker build -t ungbini/ungbinkube:1.0 .`

DockerHub Push</br>
`$ docker push ungbini/ungbinkube:1.0`


## 🟦 2. yml 파일 작성
### 🔹2-1. deployment.yml 파일 작성
쿠버네티스는 컨테이너를 등록하고 관리하기 위해 **Pod**라는 오브젝트를 사용하는데 Pod는 다시 Pod의 단위를 그룹으로 만들어 관리한다.

이때, Pod의 복제 단위인 **Replica**와 Replica의 배포단위인 **Deployment** 가 바로 그것들이다.

즉, 지금 내가 만든 ungbinkube 어플리케이션은 컨테이너 이미지화 되어있고 이 **컨테이너 이미지는 Pod에 탑재되어 관리된다**.

쿠버네티스에 이러한 Pod를 몇쌍의 복제로 만들어(=레플리카) 배포(Deployment)할 것인지 지정하는것이 `deployment.yml` 파일이다.

`deployment.yml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ungbin
spec:
  replicas: 3          # 3개의 Pod를 사용
  selector:
    matchLabels:
      app: ungbinkube
  template:
    metadata:
      labels:
        app: ungbinkube
    spec:
      containers:
      - name: ungbin
        image: ungbini/ungbinkube:1.0 #docker hub에 푸쉬한 image 사용
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"   
        ports:
        - containerPort: 9988 #application.properties의 server.port와 동일하게 설정
```

### 🔹2-2. service.yml 파일 작성
이제 `service.yaml` 을 작성하여 deployment 된 pod들 외부에서 접속할 수 있도록 **ip 와 port를 노출**시켜줘야 한다.

`service.yml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-spring-svc
spec:
  type: LoadBalancer
  selector:
    app: ungbinkube
  ports:
  - port: 80 #외부와 통신할 port
    targetPort: 9988 #depolyment의 containerPort와 동일하게 설정
```

## 🟦 3. 배포 및 외부 접속
### 🔹Flow

외부 클라이언트 요청: localhost:80/status → Minikube 서비스: port 80 → Pod의 9988 포트로 **포워딩** (targetPort: 9988) → Pod 컨테이너 응답 (containerPort: 9988).

### 🔹배포
- `deployment.yml` 실행</br>
```BASH
kubectl apply -f deployment.yml
```

- service.yml 실행</br>
```BASH
kubectl apply -f service.yml
```

- 실행 상태 정보 확인</br>
```BASH
kubectl get all
```


<img width="650" alt="{98A4FFD9-F428-4B6E-90F1-843B74DD1C80}" src="https://github.com/user-attachments/assets/728c72ca-543c-4c25-8191-db40734df280">




### 🔹외부 접속
외부 접속을 위해 터널링을 해줘야 한다. 다음 명령어를 입력하면된다.

```BASH
minikube tunnel
```

<img width="650" alt="{CF97B9A6-2A61-4ADB-9895-919EC9CF12EF}" src="https://github.com/user-attachments/assets/5d596307-df8d-4354-b03c-4523dfcd5578">

```BASH
kubectl get service
minikube service <서비스명>
```
<img width="650" alt="{21CE9C11-5BA9-478E-899B-F75F63F01F2D}" src="https://github.com/user-attachments/assets/473830a8-5b4d-4208-badc-473ff142dd0f">

EXTERNAL-IP가 10.103.76.69이며, 외부에서는 Port:80으로 접속해야한다.

외부에서 접속할 수 있도록 Port Forwarding을 설정해주자.

<img width="650" alt="{812156D8-BB2C-48C1-86AB-D73C3FC043F2}" src="https://github.com/user-attachments/assets/ade84ebb-e315-4e42-9eee-85965872e86c">

</br>
### 🔹결과 (http의 port가 80이므로 따로 안적어도 된다)</br>

<img width="650" alt="{52E36B8C-F241-4991-A3DC-86B0B78BA602}" src="https://github.com/user-attachments/assets/acdef303-5140-453e-82cc-4fe90b57a17d">

<img width="650" alt="{BC43D3EB-4C90-46E7-A0BF-985F1A1DA68A}" src="https://github.com/user-attachments/assets/b7fea70b-b077-413f-afa6-473644f9b114">

성공적으로 접속하였으며 출력문 끝을 보면 값이 바뀐 것을 확인되므로 로드밸런싱이 된 것을 확인 가능하다.


## 🟦 4. 아키텍처
### 🔹4-1. Code
Python으로 Diagram Package를 사용하여 생성

```PYTHON
from diagrams import Cluster, Diagram
from diagrams.k8s.compute import Pod, Deployment, ReplicaSet
from diagrams.k8s.network import Service
from diagrams.onprem.client import Users
from diagrams.aws.network import ELB

with Diagram("SpringApp Kubernetes Architecture", show=False, direction="LR"):
    user = Users("User")

    with Cluster("Kubernetes Cluster"):
        lb_service = Service("Service (LoadBalancer)")

        with Cluster("Deployment"):
            deploy = Deployment("Deployment")

            with Cluster("ReplicaSet"):
                replica_set = ReplicaSet("Replicaset")
                pods = [Pod("Pod1"),
                        Pod("Pod2"),
                        Pod("Pod3")]

        user >> lb_service >> replica_set >> pods
```
### 🔹4-2. Diagram
<img src="https://github.com/user-attachments/assets/5aabce40-f6dd-41b8-a659-889f63617153" width="650" />


## 🟦 5. 트러블슈팅
### 🔹Pending 상태

<img width="650" alt="{2348ECE9-CD43-4EF6-BB99-1066E315236B}" src="https://github.com/user-attachments/assets/c1e9e132-5419-4d6e-aacd-9cfea8bfd1ef">


`kubectl get all` 명령어를 실행했을 때 위 사진과 같이 Pod 하나가 Pending 상태인 것을 확인할 수 있었다.

원인을 알기 위해 다음 명령어를 실행하여 파악하였다.

```BASH
kubectl describe pod <pod이름>
```

에러 원인</br>
<img width="950" alt="{5A26ED24-FA81-43C1-AA2A-DB480269100A}" src="https://github.com/user-attachments/assets/679a0567-ac1d-43e9-bb52-1a88f14e29e3">


즉, Pending 상태인 원인은 현재 사용 가능한 CPU가 부족하여 Pod를 배치할 수 없었기 때문인데 하나의 Pod가 요청하는 CPU 자원이 커서 안되는 듯 하다.

그러므로 `deployment.yml` 파일에서 cpu resource를 500에서 250으로 수정했다.
```BASH
resources:
  limits:
    memory: "128Mi"
    cpu: "250m"
```

이후, 기존에 실행중이었던 deployment를 삭제하고 수정한 yml파일로 deployment를 실행시켰다.

<img width="650" alt="{98A4FFD9-F428-4B6E-90F1-843B74DD1C80}" src="https://github.com/user-attachments/assets/728c72ca-543c-4c25-8191-db40734df280">

성공!!


### 🔹Port Forwarding

port를 80으로 사용하니 포트80을 포워딩 해주면 될 것이라 생각했었다.
<img width="650" alt="{21B620E0-37E5-444C-AC9C-7F4B895D2D4E}" src="https://github.com/user-attachments/assets/ad774d07-4dee-4d7c-908d-bb97974a2c4b">

하지만 위와 같이 설정하면 무한 로딩이 발생하게 된다.

Externer-IP:80으로 포워딩 설정을 해줘야한다.
<img width="650" alt="{73AE08D6-BF97-4F01-93F5-2B39EF161427}" src="https://github.com/user-attachments/assets/c22d71f8-d8af-42da-bfc4-b3edf9f9c04d">
