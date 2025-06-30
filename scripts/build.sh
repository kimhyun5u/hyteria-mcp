#!/bin/bash

# 변수 설정
IMAGE_NAME="hyteria-mcp"
TAG=${1:-"latest"}
REGISTRY=${2:-""}

# 현재 디렉토리가 프로젝트 루트인지 확인
if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Dockerfile을 찾을 수 없습니다. 프로젝트 루트에서 실행해주세요."
    exit 1
fi

echo "🔨 Docker 이미지 빌드 시작..."

# 레지스트리가 지정된 경우 태그에 포함
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$TAG"
else
    FULL_IMAGE_NAME="$IMAGE_NAME:$TAG"
fi

# Docker 이미지 빌드
docker build -t "$FULL_IMAGE_NAME" .

if [ $? -eq 0 ]; then
    echo "✅ Docker 이미지 빌드 완료: $FULL_IMAGE_NAME"
    
    # 레지스트리가 지정된 경우 푸시 여부 확인
    if [ -n "$REGISTRY" ]; then
        read -p "🚀 이미지를 레지스트리에 푸시하시겠습니까? (y/N): " push_confirm
        if [[ $push_confirm =~ ^[Yy]$ ]]; then
            echo "📤 이미지 푸시 중..."
            docker push "$FULL_IMAGE_NAME"
            if [ $? -eq 0 ]; then
                echo "✅ 이미지 푸시 완료"
            else
                echo "❌ 이미지 푸시 실패"
                exit 1
            fi
        fi
    fi
    
    echo ""
    echo "📋 사용 가능한 명령어:"
    echo "  - 로컬 실행: docker run -p 8000:8000 $FULL_IMAGE_NAME"
    echo "  - Helm 배포: ./scripts/deploy.sh"
else
    echo "❌ Docker 이미지 빌드 실패"
    exit 1
fi 
