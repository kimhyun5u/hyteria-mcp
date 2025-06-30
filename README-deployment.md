# Hyteria MCP 배포 가이드

이 문서는 Hyteria MCP 서비스를 Docker와 Kubernetes에 배포하는 방법을 설명합니다.

## 📋 사전 요구사항

### Docker 배포
- Docker Engine 20.10+
- Docker Compose (선택사항)

### Kubernetes 배포
- Kubernetes 클러스터 (1.19+)
- kubectl CLI 도구
- Helm 3.8+

## 🔨 Docker 빌드 및 실행

### 1. 이미지 빌드

```bash
# 기본 빌드
./scripts/build.sh

# 특정 태그로 빌드
./scripts/build.sh v1.0.0

# 레지스트리와 함께 빌드
./scripts/build.sh latest your-registry.com
```

### 2. 로컬 실행

```bash
# 기본 실행
docker run -p 8000:8000 hyteria-mcp:latest

# 환경 변수와 함께 실행
docker run -p 8000:8000 \
  -e LOG_LEVEL=DEBUG \
  hyteria-mcp:latest
```

## 🚀 Kubernetes 배포

### 1. 기본 배포

```bash
# 기본 설정으로 배포
./scripts/deploy.sh

# 커스텀 설정으로 배포
./scripts/deploy.sh my-release production v1.0.0
```

### 2. Helm 값 커스터마이징

`values-production.yaml` 파일을 생성하여 프로덕션 설정을 정의할 수 있습니다:

```yaml
replicaCount: 3

image:
  repository: your-registry.com/hyteria-mcp
  tag: "v1.0.0"

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: hyteria-mcp.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: hyteria-mcp-tls
      hosts:
        - hyteria-mcp.yourdomain.com
```

커스텀 값으로 배포:

```bash
helm upgrade --install hyteria-mcp ./helm/hyteria-mcp \
  --namespace production \
  --values values-production.yaml
```

### 3. 모니터링 및 관리

```bash
# 상태 확인
kubectl get pods -n default -l app.kubernetes.io/name=hyteria-mcp

# 로그 확인
kubectl logs -n default -l app.kubernetes.io/name=hyteria-mcp -f

# 서비스 접근 (포트 포워딩)
kubectl port-forward -n default svc/hyteria-mcp 8080:8000

# 스케일링
kubectl scale deployment hyteria-mcp --replicas=5 -n default

# 설정 업데이트
helm upgrade hyteria-mcp ./helm/hyteria-mcp \
  --set replicaCount=5 \
  --set config.logLevel=DEBUG
```

## 🔧 문제 해결

### 일반적인 문제들

1. **이미지 Pull 실패**
   ```bash
   # 이미지 태그 확인
   docker images | grep hyteria-mcp
   
   # 레지스트리 로그인 확인
   docker login your-registry.com
   ```

2. **Pod 시작 실패**
   ```bash
   # 상세 정보 확인
   kubectl describe pod <pod-name> -n <namespace>
   
   # 이벤트 확인
   kubectl get events -n <namespace> --sort-by='.lastTimestamp'
   ```

3. **서비스 접근 불가**
   ```bash
   # 서비스 확인
   kubectl get svc -n <namespace>
   
   # 엔드포인트 확인
   kubectl get endpoints -n <namespace>
   ```

### 리소스 정리

```bash
# Helm 릴리스 삭제
helm uninstall hyteria-mcp -n <namespace>

# 네임스페이스 삭제 (필요시)
kubectl delete namespace <namespace>

# Docker 이미지 정리
docker rmi hyteria-mcp:latest
```

## 📊 성능 튜닝

### 리소스 할당

- **개발 환경**: CPU 100m, Memory 128Mi
- **스테이징 환경**: CPU 200m, Memory 256Mi  
- **프로덕션 환경**: CPU 500m, Memory 512Mi

### 오토스케일링 권장사항

- **최소 레플리카**: 2개 (고가용성을 위해)
- **최대 레플리카**: 트래픽에 따라 조정
- **CPU 임계값**: 70% (응답성과 효율성의 균형)

## 🔐 보안 고려사항

1. **비루트 사용자 실행**: Dockerfile에서 이미 설정됨
2. **읽기 전용 루트 파일시스템**: 필요시 활성화 가능
3. **네트워크 정책**: 클러스터 환경에 따라 설정
4. **시크릿 관리**: 민감한 설정은 Kubernetes Secret 사용

## 📞 지원

문제가 발생하거나 질문이 있으시면 다음을 참고하세요:

- [Kubernetes 문서](https://kubernetes.io/docs/)
- [Helm 문서](https://helm.sh/docs/)
- [Docker 문서](https://docs.docker.com/) 
