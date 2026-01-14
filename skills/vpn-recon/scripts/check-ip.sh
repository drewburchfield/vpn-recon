#!/usr/bin/env bash
#
# Compare real IP vs VPN IP
# Visual confirmation of IP masking

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}━━━ IP Comparison ━━━${NC}"
echo ""

# Real IP (without VPN)
echo -n "Real IP:  "
REAL=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "unknown")
echo -e "${YELLOW}$REAL${NC}"

# VPN IP (through proxy)
echo -n "VPN IP:   "
VPN=$(curl -x http://localhost:9888 -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "failed")

if [ "$VPN" = "failed" ]; then
    echo "❌ VPN not responding"
    exit 1
elif [ "$VPN" = "$REAL" ]; then
    echo "🚨 SAME AS REAL IP - VPN NOT WORKING!"
    exit 1
else
    echo -e "${GREEN}$VPN${NC} ✅"
fi

echo ""

# Location (handle JSON with or without spaces)
LOC=$(curl -x http://localhost:9888 -s --max-time 5 https://ipinfo.io 2>/dev/null | grep -oE '"city":\s*"[^"]*"' | cut -d'"' -f4)
if [ -n "$LOC" ]; then
    echo "VPN Location: $LOC"
else
    echo "VPN Location: (unknown)"
fi

echo ""
echo -e "${GREEN}✅ IP masking confirmed!${NC}"
