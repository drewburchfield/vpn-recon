#!/usr/bin/env bash
#
# Quick VPN validation script
# Checks if VPN is working correctly

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Checking VPN status..."

# Check containers
if ! docker ps | grep -q vpn-recon; then
    echo -e "${RED}❌ VPN containers not running${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Containers running${NC}"

# Check VPN IP
VPN_IP=$(curl -x http://localhost:9888 -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "failed")

if [ "$VPN_IP" = "failed" ]; then
    echo -e "${RED}❌ VPN proxy not responding${NC}"
    exit 1
fi

echo -e "${GREEN}✅ VPN IP: $VPN_IP${NC}"

# Get location
LOC=$(curl -x http://localhost:9888 -s --max-time 5 https://ipinfo.io/city 2>/dev/null || echo "unknown")
echo "📍 Location: $LOC"

echo ""
echo -e "${GREEN}VPN is working correctly!${NC}"
