---
name: vpn-recon
description: Route reconnaissance through VPN with 5-layer security defense. Use for "probe through VPN", "fetch securely", or IP-masked security research.
version: 1.0.0
---

# VPN Reconnaissance Skill - Security Hardened

**5-Layer Defense Against IP Leakage**

## CRITICAL: Use MCP Tools, Not Bash

This plugin provides MCP tools that implement ALL security layers automatically. **You MUST use these tools instead of manual Bash commands.**

### Available MCP Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `vpn_curl(url, method)` | Fetch URL through VPN | Any reconnaissance request |
| `vpn_ip()` | Get current VPN IP and location | Verify VPN status |
| `vpn_verify_kill_switch()` | Verify VPN protection active | Initial check or troubleshooting |

### Why MCP Tools Are Required

The MCP tools have **built-in security** that manual Bash commands do not:

1. **Pre-flight IP verification** - Every call checks VPN first
2. **Visual confirmation** - Every response includes `[VPN IP: x.x.x.x]`
3. **Input validation** - Prevents URL injection attacks
4. **Fail-hard mode** - No fallback to direct connection
5. **Automatic blocking** - Blocks requests if VPN fails

**Manual Bash commands bypass these protections and could leak your real IP.**

---

## Execution Protocol

### STEP 1: Verify MCP Server Available

Before making requests, verify the vpn-recon MCP server is connected. Check your available tools - you should see:
- `vpn_curl`
- `vpn_ip`
- `vpn_verify_kill_switch`

**If tools are NOT available:**
1. User needs to start Docker: `cd mcp-server && docker-compose up -d`
2. Reconnect MCP server in Claude Code

### STEP 2: Verify VPN Protection (First Request Only)

On your first VPN request in a session, call `vpn_verify_kill_switch()` to confirm protection is active.

**Expected response:**
```
✅ VPN Protection Active

Current VPN IP: x.x.x.x

Protection layers:
1. ✅ Network isolation - this container has NO independent network access
2. ✅ All traffic routes through Gluetun VPN tunnel
3. ✅ Gluetun kill switch blocks traffic if VPN drops
4. ✅ VPN connection verified working
```

**If verification fails → STOP and tell user to check Docker containers.**

### STEP 3: Execute Request Using MCP Tool

For any reconnaissance request, use the `vpn_curl` tool:

```
vpn_curl(url="https://target.com", method="GET")
```

**Every response will include the VPN IP for visual confirmation:**
```
[VPN IP: 185.228.19.162]

<response content>
```

### STEP 4: Report Results with VPN Confirmation

Always include the VPN IP in your response to the user so they can verify the request went through the VPN.

---

## Security Layers (Built Into MCP Tools)

### Layer 1: Gluetun Kill Switch
- Gluetun firewall blocks ALL non-VPN traffic
- If VPN drops, container has zero internet access
- Runs in Docker container, not controllable by Claude

### Layer 2: Pre-Flight IP Verification
- MCP tools verify VPN connection before EVERY request
- Automatically blocks requests if VPN is not working
- No manual check required - built into `vpn_curl`

### Layer 3: Visual IP Confirmation
- Every response includes: `[VPN IP: x.x.x.x]`
- User can visually verify VPN is active
- No silent failures possible

### Layer 4: Fail-Hard Mode
- Strict timeouts (30s max, 10s connect)
- Fails completely if proxy unavailable
- No fallback to direct connection

### Layer 5: Network Isolation
- MCP container shares VPN network (`network_mode: service:vpn-recon`)
- Container shares VPN network stack
- Even misconfigured requests go through VPN

> **Deep Dive:** See [references/security-layers.md](references/security-layers.md) for detailed architecture.

---

## Example Usage

### User Request
"Probe https://api.example.com through VPN"

### Correct Execution

```
# Step 1: Use MCP tool (NOT Bash)
vpn_curl(url="https://api.example.com", method="GET")
```

### Expected Response Format

```
[VPN IP: 185.228.19.162]

{"status": "ok", "data": {...}}
```

### Your Response to User

> Request completed through VPN.
>
> **VPN IP:** 185.228.19.162
>
> **Response:**
> ```json
> {"status": "ok", "data": {...}}
> ```

---

## Error Handling

### VPN Verification Failed
```
🚨 BLOCKED: VPN VERIFICATION FAILED! Could not connect through VPN proxy.
```

**Action:** Tell user to check Docker containers:
```bash
cd mcp-server && docker-compose ps
docker-compose logs vpn-recon
```

### Invalid URL
```
🚨 BLOCKED: Invalid URL: <reason>
```

**Action:** Ask user to provide a valid HTTP/HTTPS URL.

### Request Timeout
```
[VPN IP: 185.228.19.162]
❌ Error: Request timed out
```

**Action:** VPN is working (IP confirmed). Target may be slow or blocking VPN IPs.

> **More Help:** See [references/troubleshooting.md](references/troubleshooting.md) for additional error scenarios.

---

## If MCP Tools Are Unavailable

**DO NOT use manual Bash commands as a workaround.**

If MCP tools (`vpn_curl`, `vpn_ip`, `vpn_verify_kill_switch`) are not available:

1. **STOP** - Do not proceed with the request
2. **Tell the user** the VPN infrastructure needs to be started:
   ```bash
   cd mcp-server && docker-compose up -d
   ```
3. **Wait** for user to confirm containers are running
4. **Reconnect** the MCP server in Claude Code

**Never bypass the MCP tools.** They contain security protections that manual commands do not have.

---

## Security Design

With MCP tools:

✅ **Defense in depth** - multiple layers protect your IP
✅ **Visual confirmation** on every request
✅ **Fail-safe** - requests abort if VPN fails
✅ **Network isolated** - MCP container has no bypass path
✅ **Kill switch** - Gluetun blocks traffic if VPN drops

**Confidence Level: Maximum**

Every request goes through 5 independent security checks. Even if 3 layers fail, the remaining 2 still protect you.

---

## Quick Reference

| User Says | You Do |
|-----------|--------|
| "Probe X through VPN" | `vpn_curl(url="X")` |
| "Check my VPN IP" | `vpn_ip()` |
| "Is VPN working?" | `vpn_verify_kill_switch()` |
| "Fetch X securely" | `vpn_curl(url="X")` |
| "GET/POST/etc to X via VPN" | `vpn_curl(url="X", method="POST")` |

---

## Management Commands (For User)

```bash
# Start VPN infrastructure
cd mcp-server && docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs vpn-recon

# Stop VPN
docker-compose down

# Run security tests
./test-security.sh
```
