<img width="506" alt="{62BF0AE1-4324-4605-8139-7A4DC8A2FD77}" src="https://github.com/user-attachments/assets/ea93fdc2-8de7-47f7-ab12-0e2082797196"># Docker Image Optimization
- Docker 이미지 최적화 방법


# Contents
### 1. Goal </br>

### 2. Method
   ##### 2-1. 이미지 선택 (Alpine)</br>
   ##### 2-2. 레이어 최소화</br>
   ##### 2-3. 멀티 스테이지 빌드 사용</br>
   ##### 2-4. .dockerignore 사용</br>
   ##### 2-5. 특정 태그 사용</br>
   ##### 2-6. 종속성 관리</br>
   ##### 2-7. 그 외</br>

### 3. Method 적용</br></br>
  ##### 3-1. 환경
  ##### 3-2. 구현
___
# 1. Goal

> Docker는 컨테이너화된 애플리케이션을 실행하는 데 유용하지만, 제대로 **최적화**하지 않으면 큰 이미지 크기와 비효율성, 보안 취약점 등의 문제를 야기할 수 있다.</br></br>
Docker 이미지를 **최적화** 하여 다음과 같은 효과를 얻자.</br>
- 더 작고, 효율적인 Docker 이미지 생성
- 배포 속도 개선
- 리소스 사용 감소
- 보안 강화

</br></br>
___
# 2. Method

## 2-1. 이미지 선택 (Alpine)
> **최소한의 이미지**를 사용하자. (Ex. Alpine)

Ubuntu 표준 이미지의 경우 약 128MB이다. 하지만 **Alpine**은 약 5MB로 이미지 크기가 훨씬 작다.
</br>

다음과 같이 사용할 수 있다. </br>
```
FROM nginx:alpine
```
</br>

## 2-2. 레이어 최소화
> 여러 명령을 **하나의 명령**으로 결합하여 **이미지 크기**를 감소시키고 **빌드 속도**를 향상시킬 수 있다.</br></br>
FROM, RUN 등의 명령어들은 하나의 레이어를 구축하게 되는데, 여러 개의 레이어로 나누는 것보다는 하나의 레이어로 묶음으로써 관리를 더욱 쉽게할 수 있다.</br></br>
예를 들면, 명령 하나를 실행할 때마다 `RUN` 명령을 하지 말고,</br>
여러 명령을 **하나의 `RUN` 명령**으로 **결합**하자.</br>

다음과 같이 사용할 수 있다.</br>
```
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

</br>

## 2-3. 멀티 스테이지 빌드
> 하나의 `Dockerfile`에서 여러 `FROM`문을 사용하고, 빌드 환경을 최종 이미지에서 분리하자.</br></br>
빌드 시 의존성이나 불필요한 파일을 최종 이미지에서 제거(분리)함으로써 이미지 크기를 줄일 수 있다.


다음과 같이 사용할 수 있다.</br>
```
# 빌드 단계
FROM node:14-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 프로덕션 단계
FROM node:14-alpine as production
WORKDIR /app
COPY --from=build /app/package*.json ./
RUN npm ci --production
COPY --from=build /app/dist ./dist
CMD ["npm", "start"]
```

<br>

## 2-4. .dockerignore 사용
> `.dockerignore` 파일을 생성하여 Dokcer 빌드에 불필요한 파일이나 디렉토리를 제외하면 빌드 시간 감소를 할 수 있다.

</br>

## 2-5. 특정 태그 사용
> 기본 이미지나 의존성을 가져올 때 `latest` 대신 특정 버전 태그를 사용하면 재현성을 보장하고 예기치 않은 변화를 방지할 수 있다.

다음과 같이 사용할 수 있다. 
```
FROM nginx:<tag>
```
</br></br>
## 2-6. 종속성 관리
> Dockerfile에 지정한 모든 명령은 레이어를 나타낸다.</br></br>
최종명령 이전의 모든 명령은 이미 이미지의 일부이자 별도의 레이어이다.</br></br>
컨테이너는 이미지 위에 추가된 얇은 레이어일 뿐이다.</br></br>
컨테이너는 이미지에 저장된 환경을 사용하고, 그 위에 부가 레이어를 추가한다.</br></br>

- 이미지를 기반으로 컨테이너를 실행하면, 명령마다 새로운 레이어를 추가하고 이러한 레이어는 캐시되는데</br>
만일, 아무것도 변경하지 않은 채 재빌드하면, 이미지를 구성하는 모든 레이어를 캐시해서 사용할 수 있다.</br></br>

- 조금이라도 변경하고 재빌드하면 시간이 걸리는데, 이는 캐시의 일부 결과만을 사용하기 때문이다.</br>
   - (도커가 복사해야할 파일을 스캔하고, 조금이라도 파일 변경사항이 감지되면, 그 이후의 모든 파일을 다시 복사한다.)</br>
   - (하나의 레이어가 변경될 때마다, 그 이후의 모든 후속 레이어가 다시 빌드된다.)
</br></br>

다음 코드를 통해 이해해보자.
#### 최적화 전 Dockerfile
```bash
FROM node

WORKDIR /app

COPY . /app #소스코드 복사하는 명령

RUN npm install # 종속성 설치

EXPOSE 80

CMD ["node", "server.js"]

```
> 위와 같은 상황에서는 소스코드를 변경할 때 마다, 이 **레이어**로부터 **캐시**된 결과를 이용하지 못하기 때문에,</br>
**종속성**을 다시 설치해야 한다.

#### 최적화 후 Dockerfile
```bash
FROM node

WORKDIR /app

COPY package.json /app

RUN npm install

COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
```
>  이렇게 바꾸면, 도커가 package.json 파일이 변경되지 않았음을 확인했기 때문에
캐시된 결과를 이용하고 종속성 설치를 다시 실행하지 않는다.
</br></br>**소스코드가 변경되었을 때**</br>
종속성에 영향을 미치는 코드면, package.json 파일의 변경사항을 감지하고, 종속성 설치를 다시 실행하게 된다.</br></br>
종속성에 영향을 미치지 않는 코드면, package.json 파일의 캐시된 결과를 이용하고, 종속성 설치를 다시 실행하지 않으며, 여기서 빌드 속도를 높일 수 있다.</br></br>
(소스코드를 변경할 때마다 RUN npm install 레이어가 무효화되지 않는다.)</br></br>

## 2-7. 그 외
- 압축</br>
   : `Docker Slim`과 같은 도구를 통해 Docker 이미지를 분석하고 최소화하여 압축 가능하다.</br>
- 이미지 레이어 분석</br>
   : `docker history`와 `docker inspect`를 사용하여 이미지 레이어를 분석하고 최적화 가능한 것들을 찾아 불필요한 파일이나 명령을 제거한다.</br>
   
- Docker 이미지 정리</br>
   : `docker system prune` 명령을 통해 사용하지 않는 Docker 이미지, 컨테이너, 볼륨, 네트워크 등등을 정기적으로 정리한다.</br>
   
- 캐시 활용</br>
   : 자주 변경되는 명령은 Dockerfile의 마지막에 배치하여 캐시 무효화를 최소화한다.</br>
   
- 보안 스캐닝</br>
   : Docker 보안 스캐닝 도구를 사용한다.</br>
   
- Docker Squash</br>
   : 레이어를 병합하여 이미지 크기를 줄이는 것에 사용할 수 있으나 빌드 시간이 길어지고 캐시 활용이 감소될 수 있으니 상황에 맞게 사용한다.</br>
</br></br>
___
# 3. Method 적용
## 3-1. 환경
> Ubuntu 22.04.5 LTS</br></br>
Docker 27.3.1</br></br>
Image : Node14

## 3-2. 구현
### 최적화 전 (Non-Optimized)
```bash
# 최적화 전 Dockerfile
FROM node:14

WORKDIR /app

# 모든 소스코드와 종속성 복사
COPY . /app

# 종속성 설치
RUN npm install

EXPOSE 3000

# 애플리케이션 실행
CMD ["npm", "start"]
```

### 최적화 후 (Optimized)
```bash
# 멀티 스테이지 빌드 적용
FROM node:14-alpine as build

# 빌드 단계: 종속성 설치 및 애플리케이션 빌드
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 최종 이미지: 빌드된 결과물만 복사하여 실행
FROM node:14-alpine

WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./
RUN npm ci --production

EXPOSE 3000
CMD ["npm", "start"]
```
### 최적화 전후 비교
#### 1. 시간
- 최적화 전
<img width="248" alt="{8FA20ECD-8013-46BB-BC91-5AA6D7E7AAD7}" src="https://github.com/user-attachments/assets/4db521a1-21b7-4f8c-9a2e-c1b14ffa767a">

- 최적화 후

#### 2. 이미지 크기
- 최적화 전
<img width="506" alt="{62BF0AE1-4324-4605-8139-7A4DC8A2FD77}" src="https://github.com/user-attachments/assets/0f9710b4-fec7-4ec7-8eb5-a3ea3146741e">

