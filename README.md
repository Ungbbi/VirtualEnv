# Docker Image Optimization
- Docker 이미지 최적화 방법


# Contents
### 1. Goal </br>

### 2. Method
   ##### 2-1. 이미지 선택 (Alpine)</br>
   ##### 2-2. 레이어 최소화</br>
   ##### 2-3. 멀티 스테이지 빌드 사용</br>
   ##### 2-4. .dockerignore 사용</br>
   ##### 2-5. 특정 태그 사용</br>
   ##### 2-6. 그 외</br>

### 3. Method 적용</br></br>
  ##### 3-1. 환경
  ##### 3-2. 구현
___
# 1. Goal
> Docker 이미지를 **최적화** 하여 다음과 같은 효과를 얻자.
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
`FROM nginx:alpine`
</br>

## 2-2. 레이어 최소화
> 여러 명령을 **하나의 명령**으로 결합하여 **이미지 크기**를 감소시키고 **빌드 속도**를 향상시킬 수 있다.

명령 하나를 실행할 때마다 `RUN` 명령을 하지 말고,</br>
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

다음과 같이 사용할 수 있다. `FROM nginx:<tag>`
</br></br>

## 2-6. 그 외
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
Docker 27.3.1
