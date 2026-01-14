# 5-Layer Security Defense - Detailed Explanation

Complete technical explanation of each security layer and how they work together.

## Layer 1: Gluetun Kill Switch

**What it does:** Firewall blocks ALL traffic if VPN connection drops

**Implementation:**
- Gluetun uses iptables rules to block non-VPN traffic
- Only tun0 interface (VPN tunnel) is allowed
- DROP/REJECT rules for all other interfaces

**Verification:**
```bash
docker exec vpn-recon iptables -L -n | grep -E "REJECT|DROP"
```

**Expected:** 3+ firewall rules

**Protection:**
If VPN disconnects, container has no internet access. Traffic is blocked from non-VPN routes.

## Layer 2: Pre-Flight IP Verification

**What it does:** Checks VPN IP before every request, blocks if it matches direct IP

**Implementation:**
```bash
VPN_IP=$(curl -x http://localhost:9888 -s --max-time 5 https://ifconfig.me)
DIRECT_IP=$(curl -s --max-time 5 https://ifconfig.me || echo "unknown")

if [ "$VPN_IP" = "$DIRECT_IP" ]; then
    echo "🚨 BLOCKED"
    exit 1
fi
```

**Auto-detection:**
- Direct IP detected at runtime (without proxy)
- Compared against VPN IP
- Blocks if match detected (VPN not working)

**Protection:**
Even if kill switch fails, pre-flight check catches real IP and blocks request.

## Layer 3: Visual IP Confirmation

**What it does:** Shows VPN IP in every response for visual verification

**Implementation:**
Every response includes header:
```
[VPN IP: 94.140.9.17]

<actual response>
```

**Protection:**
- No silent failures
- User can visually verify VPN is active
- Immediate detection if IP changes unexpectedly

## Layer 4: Curl Fail-Hard Mode

**What it does:** Strict timeouts, fails if proxy unavailable

**Implementation:**
```bash
curl -x http://localhost:9888 \
     --fail \
     --max-time 30 \
     --connect-timeout 10 \
     "$URL"
```

**Flags explained:**
- `--fail`: Exit with error on HTTP 4xx/5xx
- `--max-time 30`: Total request timeout
- `--connect-timeout 10`: Connection timeout
- `-x`: Proxy (required - no fallback)

**Protection:**
If proxy is dead, curl fails immediately instead of falling back to direct connection.

## Layer 5: Network Isolation (Nuclear Option)

**What it does:** MCP server shares VPN network stack - all traffic routes through VPN

**Implementation:**
```yaml
# docker-compose.yml
mcp-server:
  network_mode: "service:vpn-recon"
```

**Effect:**
- MCP container has NO independent network
- All traffic MUST route through vpn-recon container
- Even misconfigured curl goes through VPN

**Verification:**
```bash
docker inspect vpn-recon-mcp --format '{{.HostConfig.NetworkMode}}'
# Output: container:vpn-recon-xxxxx
```

**Protection:**
Even if you forget `-x http://localhost:9888`, traffic still routes through the VPN tunnel.

## Defense-in-Depth Analysis

**Redundancy table:**

| Layers Working | Real IP Can Leak? |
|----------------|-------------------|
| All 5 | ❌ No |
| Any 4 | ❌ No |
| Any 3 | ❌ No |
| Any 2 | ❌ No |
| 1 only | Depends which one |
| 0 | ✅ Yes (but VPN completely broken) |

**Minimum for safety:** Any 1 layer active = protected

**Realistic scenario:** All 5 layers would need to fail simultaneously for IP to leak, which is unlikely under normal operation.

## Testing Each Layer

See [../scripts/test-security.sh](../scripts/test-security.sh) for automated testing of all layers.

**Manual verification:**

```bash
# Layer 1: Kill switch
docker exec vpn-recon iptables -L -n | grep REJECT

# Layer 2: Pre-flight
curl -x http://localhost:9888 https://ifconfig.me
# Compare to real IP (should be different)

# Layer 3: Visual
# Check responses include [VPN IP: x.x.x.x]

# Layer 4: Fail-hard
curl -x http://localhost:9999 https://ifconfig.me
# Should fail (wrong proxy)

# Layer 5: Network isolation
docker inspect vpn-recon-mcp --format '{{.HostConfig.NetworkMode}}'
# Should show: container:vpn-recon-xxxxx
```
