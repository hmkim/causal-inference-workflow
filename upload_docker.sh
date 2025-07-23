#!/bin/bash

# 스크립트 실행 시작 메시지
echo "ECR에 Docker 이미지 업로드 시작..."

# ECR 리포지토리 정보
AWS_REGION="ap-northeast-2"
ECR_REPO="causal-inference"
ECR_ACCOUNT="*********"
ECR_URI="${ECR_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="causal-inference"
IMAGE_TAG="latest"

# ECR 로그인
echo "ECR에 로그인 중..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

# 로그인 성공 확인
if [ $? -ne 0 ]; then
    echo "ECR 로그인 실패. AWS 자격 증명을 확인하세요."
    exit 1
fi

# 이미지 태그 지정
echo "Docker 이미지에 태그 지정: ${IMAGE_NAME}:${IMAGE_TAG} -> ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}"
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}

# 이미지 푸시
echo "ECR에 이미지 푸시 중..."
docker push ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}

# 푸시 성공 확인
if [ $? -eq 0 ]; then
    echo "이미지 업로드 성공: ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}"
else
    echo "이미지 업로드 실패. 오류를 확인하세요."
    exit 1
fi

echo "작업 완료!"
