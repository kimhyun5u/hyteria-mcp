#!/bin/bash

# 변수 설정
RELEASE_NAME=${1:-"hyteria-mcp"}
NAMESPACE=${2:-"default"}
IMAGE_TAG=${3:-"latest"}

# Helm이 설치되어 있는지 확인
if ! command -v helm &> /dev/null; then
    echo "❌ Error: Helm이 설치되어 있지 않습니다."
    echo "📖 설치 가이드: https://helm.sh/docs/intro/install/"
    exit 1
fi

# kubectl이 설치되어 있는지 확인
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl이 설치되어 있지 않습니다."
    exit 1
fi

# 클러스터 연결 확인
#if ! kubectl cluster-info > /dev/null 2>&1; then
#    echo "❌ Error: Kubernetes 클러스터에 연결할 수 없습니다."
#    echo "📋 kubectl config current-context로 현재 컨텍스트를 확인하세요."
#    exit 1
#fi

echo "🚀 Hyteria MCP 배포 시작..."
echo "📋 배포 정보:"
echo "  - Release Name: $RELEASE_NAME"
echo "  - Namespace: $NAMESPACE"
echo "  - Image Tag: $IMAGE_TAG"
echo ""

# 네임스페이스 생성 (존재하지 않는 경우)
if [ "$NAMESPACE" != "default" ]; then
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ 네임스페이스 '$NAMESPACE' 확인 완료"
fi

# Helm 차트 린트 검사
echo "🔍 Helm 차트 검사 중..."
helm lint helm/hyteria-mcp/

if [ $? -ne 0 ]; then
    echo "❌ Helm 차트 검사 실패"
    exit 1
fi

# 배포 실행
echo "📦 Helm 배포 실행 중..."
helm upgrade --install "$RELEASE_NAME" ./helm/hyteria-mcp \
    --namespace "$NAMESPACE" \
    --set image.tag="$IMAGE_TAG" \
#    --wait --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ 배포 완료!"
    echo ""
    echo "📋 배포 상태 확인:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=hyteria-mcp
    echo ""
    echo "📖 추가 정보:"
    echo "  - 상태 확인: kubectl get all -n $NAMESPACE -l app.kubernetes.io/name=hyteria-mcp"
    echo "  - 로그 확인: kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=hyteria-mcp -f"
    echo "  - 포트 포워딩: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:8000"
    echo "  - 삭제: helm uninstall $RELEASE_NAME -n $NAMESPACE"
else
    echo "❌ 배포 실패"
    exit 1
fi 
