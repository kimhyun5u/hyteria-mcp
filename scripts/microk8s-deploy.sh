#!/bin/bash

# 변수 설정
RELEASE_NAME=${1:-"hyteria-mcp"}
NAMESPACE=${2:-"default"}
IMAGE_TAG=${3:-"latest"}
REGISTRY="localhost:32000"

# MicroK8s가 실행 중인지 확인
if ! microk8s status --wait-ready; then
    echo "❌ Error: MicroK8s가 실행되지 않고 있습니다."
    exit 1
fi

# MicroK8s Helm 확인 및 활성화
if ! microk8s helm version &> /dev/null; then
    echo "🚀 MicroK8s Helm 활성화 중..."
    microk8s enable helm3
fi

echo "🚀 MicroK8s에서 Hyteria MCP 배포 시작..."
echo "📋 배포 정보:"
echo "  - Release Name: $RELEASE_NAME"
echo "  - Namespace: $NAMESPACE"
echo "  - Image Tag: $IMAGE_TAG"
echo "  - Registry: $REGISTRY"
echo ""

# 네임스페이스 생성 (존재하지 않는 경우)
if [ "$NAMESPACE" != "default" ]; then
    microk8s kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | microk8s kubectl apply -f -
    echo "✅ 네임스페이스 '$NAMESPACE' 확인 완료"
fi

# Helm 차트 린트 검사
echo "🔍 Helm 차트 검사 중..."
microk8s helm lint helm/hyteria-mcp/

if [ $? -ne 0 ]; then
    echo "❌ Helm 차트 검사 실패"
    exit 1
fi

# 배포 실행
echo "📦 MicroK8s Helm 배포 실행 중..."
microk8s helm upgrade --install "$RELEASE_NAME" ./helm/hyteria-mcp \
    --namespace "$NAMESPACE" \
    --set image.repository="$REGISTRY/hyteria-mcp" \
    --set image.tag="$IMAGE_TAG" \
    --set image.pullPolicy="IfNotPresent" \
    --wait --timeout=300s
    -v

if [ $? -eq 0 ]; then
    echo "✅ 배포 완료!"
    echo ""
    echo "📋 배포 상태 확인:"
    microk8s kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=hyteria-mcp
    echo ""
    echo "📖 추가 정보:"
    echo "  - 상태 확인: microk8s kubectl get all -n $NAMESPACE -l app.kubernetes.io/name=hyteria-mcp"
    echo "  - 로그 확인: microk8s kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=hyteria-mcp -f"
    echo "  - 포트 포워딩: microk8s kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:8000"
    echo "  - 서비스 노출: microk8s kubectl expose deployment $RELEASE_NAME --type=NodePort --port=8000 -n $NAMESPACE"
    echo "  - 삭제: microk8s helm uninstall $RELEASE_NAME -n $NAMESPACE"
    
    # NodePort로 서비스 노출된 경우 포트 정보 표시
    echo ""
    echo "🌐 서비스 접근 정보:"
    microk8s kubectl get svc -n "$NAMESPACE" "$RELEASE_NAME" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null && \
    echo "  - NodePort: $(microk8s kubectl get svc -n "$NAMESPACE" "$RELEASE_NAME" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)" && \
    echo "  - 접근 URL: http://localhost:$(microk8s kubectl get svc -n "$NAMESPACE" "$RELEASE_NAME" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)"
else
    echo "❌ 배포 실패"
    echo ""
    echo "🔍 문제 해결을 위한 디버깅 명령어:"
    echo "  - Pod 상태 확인: microk8s kubectl get pods -n $NAMESPACE"
    echo "  - Pod 이벤트 확인: microk8s kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
    echo "  - Pod 상세 정보: microk8s kubectl describe pods -n $NAMESPACE -l app.kubernetes.io/name=hyteria-mcp"
    exit 1
fi
