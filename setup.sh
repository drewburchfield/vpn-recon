#!/usr/bin/env bash
#
# VPN Recon - Docker/VPN Setup
# Sets up Gluetun VPN + MCP server infrastructure
#
# NOTE: This script sets up the VPN infrastructure.
# For Claude Code integration, use the plugin marketplace:
#   claude plugins marketplace add drewburchfield/vpn-recon
#   claude plugins install vpn-recon@vpn-recon

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print() { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

# Auto-detect script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print "  VPN Recon - Docker/VPN Setup"
print "  5-Layer Security Defense"
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Setting up from: $SCRIPT_DIR"
echo ""

# ============================================================================
# Prerequisites Check
# ============================================================================

print "Step 1: Checking prerequisites..."
echo ""

# Check Docker
if ! docker info >/dev/null 2>&1; then
    error "Docker not running"
    echo "  Start Docker Desktop and try again"
    exit 1
fi
success "Docker running"

# Check docker-compose
if ! command -v docker-compose >/dev/null 2>&1; then
    error "docker-compose not found"
    echo "  Install with: ${CYAN}brew install docker-compose${NC}"
    exit 1
fi
success "docker-compose installed"

echo ""

# ============================================================================
# Setup .env Configuration
# ============================================================================

print "Step 2: Configuration setup..."
echo ""

cd mcp-server

if [ ! -f .env ]; then
    print "Creating .env from template..."
    cp .env.example .env

    # Loop until valid credentials are set
    while true; do
        echo ""
        warn "IMPORTANT: Configure your VPN credentials"
        echo ""
        echo "  1. See ${CYAN}mcp-server/.env.example${NC} for provider-specific instructions"
        echo "  2. Edit ${YELLOW}mcp-server/.env${NC} with your VPN provider and credentials"
        echo "  3. Supports: NordVPN, Mullvad, ProtonVPN, Surfshark, ExpressVPN, and 30+ more"
        echo ""
        echo "  Press ${CYAN}ENTER${NC} when done editing .env, or ${CYAN}Ctrl+C${NC} to exit"
        read -p ""

        # Verify credentials are set
        if grep -q "your_service_username" .env 2>/dev/null || grep -q "your_service_password" .env 2>/dev/null; then
            warn ".env still has placeholder values"
            echo "  Please edit mcp-server/.env with your actual VPN credentials"
            echo ""
        else
            success "Credentials configured"
            break
        fi
    done
else
    success "Credentials already configured in .env"
fi

echo ""

# ============================================================================
# Start Services
# ============================================================================

print "Step 3: Starting VPN and MCP server..."
echo ""

docker-compose down 2>/dev/null || true
docker-compose up -d

if [ $? -ne 0 ]; then
    error "Failed to start services"
    echo "  Check logs with: ${CYAN}docker-compose logs${NC}"
    exit 1
fi

success "Docker containers started"

echo ""

# ============================================================================
# Wait for Services
# ============================================================================

print "Step 4: Waiting for services to be ready..."
echo ""

info "Waiting for VPN connection (this takes ~20 seconds)..."

for i in {1..30}; do
    if docker-compose ps | grep vpn-recon | grep -q "healthy"; then
        echo ""
        success "Gluetun VPN connected!"
        break
    fi
    remaining=$((30 - i))
    printf "\r  [%2ds remaining] Establishing VPN connection..." "$remaining"
    sleep 1
done

echo ""
echo ""

info "Waiting for MCP server (this takes ~10 seconds)..."

for i in {1..15}; do
    if docker logs vpn-recon-mcp 2>&1 | grep -q "Uvicorn running"; then
        echo ""
        success "MCP server ready!"
        break
    fi
    remaining=$((15 - i))
    printf "\r  [%2ds remaining] Starting MCP server..." "$remaining"
    sleep 1
done

echo ""
echo ""

# ============================================================================
# Verification
# ============================================================================

print "Step 5: Verifying VPN..."
echo ""

# Check VPN proxy
info "Testing VPN proxy..."
VPN_IP=$(curl -x http://localhost:9888 -s --max-time 10 https://ifconfig.me 2>/dev/null || echo "failed")

if [ "$VPN_IP" != "failed" ] && [ -n "$VPN_IP" ]; then
    success "VPN proxy working! IP: $VPN_IP"

    # Get location
    VPN_LOC=$(curl -x http://localhost:9888 -s --max-time 10 https://ipinfo.io 2>/dev/null || echo "{}")
    CITY=$(echo "$VPN_LOC" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
    COUNTRY=$(echo "$VPN_LOC" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$CITY" ]; then
        info "Location: $CITY, $COUNTRY"
    fi
else
    error "VPN proxy not responding"
    echo "  Check logs: ${CYAN}docker-compose logs vpn-recon${NC}"
    exit 1
fi

echo ""

# Check MCP server
info "Testing MCP server..."
if curl -s --max-time 5 http://localhost:3100/ >/dev/null 2>&1; then
    success "MCP server responding on port 3100"
else
    warn "MCP server may still be starting"
    echo "  Check logs: ${CYAN}docker-compose logs vpn-recon-mcp${NC}"
fi

echo ""

# ============================================================================
# Setup Complete
# ============================================================================

print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "VPN Infrastructure Ready!"
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print "📋 Summary:"
echo ""
echo "  VPN IP:        ${GREEN}$VPN_IP${NC}"
echo "  VPN Proxy:     ${CYAN}http://localhost:9888${NC}"
echo "  MCP Server:    ${CYAN}http://localhost:3100${NC}"
echo ""

print "🔌 Install Claude Code Plugin:"
echo ""
echo "  # Add marketplace (one-time)"
echo "  ${CYAN}claude plugins marketplace add drewburchfield/vpn-recon${NC}"
echo ""
echo "  # Install plugin"
echo "  ${CYAN}claude plugins install vpn-recon@vpn-recon${NC}"
echo ""

print "🚀 Quick Test:"
echo ""
echo "  # Test VPN directly"
echo "  ${CYAN}curl -x http://localhost:9888 https://ipinfo.io${NC}"
echo ""

print "🔒 Security Testing:"
echo ""
echo "  ${CYAN}./test-security.sh${NC}"
echo "  Expected: Passed: 11, Failed: 0"
echo ""

print "🛠️  Management:"
echo ""
echo "  Start:   ${CYAN}cd mcp-server && docker-compose up -d${NC}"
echo "  Stop:    ${CYAN}cd mcp-server && docker-compose down${NC}"
echo "  Logs:    ${CYAN}cd mcp-server && docker-compose logs -f${NC}"
echo "  Status:  ${CYAN}cd mcp-server && docker-compose ps${NC}"
echo ""
