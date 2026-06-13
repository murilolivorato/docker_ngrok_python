#!/bin/bash
# Print the current public ngrok URL(s) by querying the local ngrok API.

echo "🔗 Your ngrok public URLs:"
echo "=========================="

URLS=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)

if [ -n "$URLS" ] && command -v python3 &> /dev/null; then
    echo "$URLS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tunnels = data.get('tunnels', [])
if not tunnels:
    print('  ❌ No tunnels found — is the ngrok service running?')
for t in tunnels:
    print(f\"  ✅ {t['name']}: {t['public_url']}\")
"
else
    echo "  ❌ Cannot reach ngrok API at http://localhost:4040"
    echo "     Start it with: docker compose --profile ngrok up"
fi

echo ""
echo "🌐 Inspect requests at: http://localhost:4040"
