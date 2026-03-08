#!/bin/bash
set -euo pipefail
APP_PORT=$1
MAX_RETRIES=5
RETRY_INTERVAL=10
 
echo "==> Running health check on port ${APP_PORT}"
for i in $(seq 1 $MAX_RETRIES); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT}/health || true)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Health check PASSED (attempt ${i}) — HTTP ${HTTP_CODE}"
        exit 0
    fi
    echo "⚠️  Attempt ${i}/${MAX_RETRIES} — HTTP ${HTTP_CODE}, retrying in ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done
echo "❌ Health check FAILED after ${MAX_RETRIES} attempts"