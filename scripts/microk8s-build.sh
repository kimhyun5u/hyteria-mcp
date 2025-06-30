#!/bin/bash

# 변수 설정
IMAGE_NAME="hyteria-mcp"
TAG=${1:-"latest"}

echo "🔨 MicroK8s 환경에서 Docker 이미지 빌드 시작..."

# 현재 디렉토리가 프로젝트 루트인지 확인
if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Dockerfile을 찾을 수 없습니다. 프로젝트 루트에서 실행해주세요."
    exit 1
fi

# MicroK8s가 실행 중인지 확인
if ! microk8s status --wait-ready; then
    echo "❌ Error: MicroK8s가 실행되지 않고 있습니다."
    exit 1
fi

# MicroK8s 레지스트리 활성화 확인
echo "📦 MicroK8s 레지스트리 확인 중..."
if ! microk8s kubectl get service -n container-registry registry 2>/dev/null; then
    echo "🚀 MicroK8s 레지스트리 활성화 중..."
    microk8s enable registry
    echo "⏳ 레지스트리가 준비될 때까지 대기 중..."
    microk8s kubectl wait --for=condition=ready pod -l app=registry -n container-registry --timeout=300s
fi

# 로컬 레지스트리 주소
REGISTRY="localhost:32000"
FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$TAG"

echo "🔨 Docker 이미지 빌드 중: $FULL_IMAGE_NAME"

# Docker 이미지 빌드
docker build -t "$FULL_IMAGE_NAME" .

if [ $? -eq 0 ]; then
    echo "✅ Docker 이미지 빌드 완료: $FULL_IMAGE_NAME"
    
    # 이미지를 로컬 레지스트리에 푸시
    echo "📤 로컬 레지스트리에 이미지 푸시 중..."
    docker push "$FULL_IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✅ 이미지 푸시 완료"
        echo ""
        echo "📋 사용 가능한 명령어:"
        echo "  - MicroK8s 배포: ./scripts/microk8s-deploy.sh $TAG"
        echo "  - 이미지 확인: docker images | grep $IMAGE_NAME"
        echo "  - 레지스트리 확인: curl http://localhost:32000/v2/_catalog"
    else
        echo "❌ 이미지 푸시 실패"
        exit 1
    fi
else
    echo "❌ Docker 이미지 빌드 실패"
    exit 1
fi
