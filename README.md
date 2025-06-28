# hyteria-mcp
하이테리아 메뉴(B1)의 오늘 메뉴를 조회합니다.

## 실행방법

### sse 서버 실행
```shell
uv sync

source ./venv/bin/activate

uv run main.py
```
### mcp 설정

```json
{
  "mcpServers": {
    ...
    "hyteria": {
        "url": "http://localhost:8000/sse"
      }
    }
}
```