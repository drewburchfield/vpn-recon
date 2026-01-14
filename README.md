# VPN Recon - Security-Hardened Reconnaissance

Route network reconnaissance commands through your VPN with 5-layer defense against IP leakage.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security: 5-Layer Defense](https://img.shields.io/badge/Security-5--Layer%20Defense-green)](./test-security.sh)

## What This Does

Provides **hardened VPN routing** for security research and API reconnaissance:
- **Defense in depth** - 5 independent security layers protect your IP
- **Visual confirmation** - Every response shows `[VPN IP: x.x.x.x]`
- **Auto-verification** - Pre-flight check blocks requests if VPN fails
- **Claude Code plugin** - Enforces security protocol automatically

**Powered by:** [Gluetun](https://github.com/qdm12/gluetun) - supports 30+ VPN providers

## Features

### 5-Layer Security Defense

1. **Kill Switch** - Gluetun firewall blocks ALL non-VPN traffic
2. **Pre-Flight Check** - Verifies VPN IP before every request
3. **Visual Confirmation** - Shows `[VPN IP: x.x.x.x]` in responses
4. **Fail-Hard Mode** - Strict timeouts, no fallback to direct connection
5. **Network Isolation** - Container shares VPN network stack

**Result:** Even if 3 layers fail, the remaining 2 still protect you.

### Use Cases

- Subdomain enumeration without exposing your IP
- API probing from different geolocations
- Security research requiring IP masking
- Rate limit testing
- Geo-restriction verification

## Installation

VPN Recon has two components that must be installed **in order**:

| Component | What It Does | How to Install |
|-----------|--------------|----------------|
| **1. Docker Infrastructure** | Gluetun VPN + MCP server | Clone repo, run `./setup.sh` |
| **2. Claude Code Plugin** | Skill, commands, MCP config | Install via marketplace |

**Important:** The Docker infrastructure must be running before the plugin will work.

### Prerequisites

- **Docker Desktop** (running)
- **VPN subscription** (any Gluetun-supported provider)
- **Claude Code** (for plugin integration)

### Step 1: Setup Docker/VPN Infrastructure

```bash
# Clone repository
git clone https://github.com/drewburchfield/vpn-recon
cd vpn-recon

# Configure VPN credentials and start containers
./setup.sh
```

The setup script will:
- Check prerequisites (Docker, docker-compose)
- Prompt you to configure VPN credentials in `mcp-server/.env`
- Start Gluetun VPN + MCP server containers
- Verify VPN connection

**Supported providers:** NordVPN, Mullvad, ProtonVPN, Surfshark, ExpressVPN, PIA, Windscribe, and [30+ more](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).

### Step 2: Verify VPN is Working

Before installing the plugin, confirm the VPN infrastructure is healthy:

```bash
# Test VPN is working
curl -x http://localhost:9888 https://ifconfig.me
# Should show VPN IP (NOT your real IP)

# Run security tests
./test-security.sh
# Should show: Passed: 11, Failed: 0
```

**Do not proceed until verification passes.**

### Step 3: Install Claude Code Plugin

Choose one installation method:

**Option A: From GitHub (Recommended)**

```bash
claude plugins marketplace add drewburchfield/vpn-recon
claude plugins install vpn-recon@vpn-recon
```

**Option B: From Local Clone**

```bash
# From your cloned repo directory
claude plugins marketplace add ./
claude plugins install vpn-recon@vpn-recon
```

**Option C: From Your Fork**

```bash
# After forking on GitHub and cloning locally
claude plugins marketplace add YOUR_USERNAME/vpn-recon
claude plugins install vpn-recon@vpn-recon
```

## Usage

### Direct Command Line

```bash
# Check VPN IP
curl -x http://localhost:9888 https://ifconfig.me

# Fetch URL through VPN
curl -x http://localhost:9888 https://api.example.com

# Get headers
curl -x http://localhost:9888 -sI https://target.com

# POST request
curl -x http://localhost:9888 -X POST -d '{"key":"value"}' https://api.example.com
```

### Claude Code (Recommended)

The plugin enforces the 5-layer security protocol automatically:

```
You: "Probe https://api.example.com through VPN"

Claude:
[VPN IP: 94.140.9.17]

<response from api.example.com>
```

**Triggers:**
- "probe through VPN"
- "check via VPN"
- "fetch securely"
- "recon securely"

### MCP Tools Available

When the plugin is active, these tools are available:

- `vpn_curl` - Fetch URL through VPN with security verification
- `vpn_ip` - Get current VPN IP and location
- `vpn_verify_kill_switch` - Verify VPN protection is active

## Security Architecture

```
┌─────────────────────┐
│  Request            │
│  "Probe via VPN"    │
└──────────┬──────────┘
           │
     ┌─────▼──────┐
     │   Skill    │  Layer 2: Pre-flight IP check
     │  Enforces  │  → Blocks if real IP detected
     │  Security  │  Layer 3: Visual confirmation
     └─────┬──────┘  → Shows [VPN IP: x.x.x.x]
           │
     ┌─────▼──────────────────────┐
     │  Docker: vpn-recon-mcp     │
     │  Layer 5: Network isolated │
     │  (shares VPN network)      │
     └─────┬──────────────────────┘
           │
     ┌─────▼──────────────────────┐
     │  Docker: vpn-recon         │
     │  (Gluetun VPN)             │
     │  Layer 1: Kill switch      │  ← Blocks if VPN drops
     │  Layer 4: Fail-hard curl   │  ← Strict timeouts
     └─────┬──────────────────────┘
           │ VPN tunnel
           ▼
     ┌────────────┐
     │  Internet  │
     │  (via VPN) │
     └────────────┘
```

### How Each Layer Protects You

| Layer | Protection | Failure Mode |
|-------|------------|--------------|
| **1. Kill Switch** | Gluetun firewall | VPN drops → All traffic blocked |
| **2. Pre-Flight** | IP verification | Real IP detected → Request blocked |
| **3. Visual** | IP in response | No silent failures → User sees VPN IP |
| **4. Fail-Hard** | Strict timeouts | Proxy dead → curl fails (no fallback) |
| **5. Network Isolation** | Shared network | Misconfigured → Still uses VPN |

Multiple redundant layers are designed to prevent IP leakage.

## Configuration

**File:** `mcp-server/.env` (see `.env.example` for full documentation)

```bash
# VPN Provider (any Gluetun-supported provider)
VPN_PROVIDER=nordvpn          # Or: mullvad, protonvpn, surfshark, expressvpn, etc.
VPN_TYPE=openvpn              # Or: wireguard (for supported providers)

# Credentials (varies by provider)
VPN_USER=your_service_username
VPN_PASS=your_service_password

# WireGuard (if using WireGuard instead of OpenVPN)
# VPN_WIREGUARD_KEY=your_base64_private_key
# VPN_WIREGUARD_ADDRESSES=10.x.x.x/32

# VPN server location
VPN_COUNTRY=United States     # Options: United Kingdom, Germany, Netherlands, Japan, etc.

# Proxy port
PROXY_PORT=9888

# Timezone
TZ=America/New_York
```

### Change VPN Location

```bash
# Edit .env
VPN_COUNTRY=United Kingdom

# Restart
cd mcp-server && docker-compose restart
```

## Security Testing

Run the comprehensive security test harness:

```bash
./test-security.sh
```

**Expected output:**
```
All security layers verified!

Passed: 11
Failed: 0

Security layers active:
  1. Kill switch blocks non-VPN traffic
  2. Pre-flight check blocks real IP
  3. Visual confirmation shows VPN IP
  4. Curl fails hard (no fallback)
  5. Network isolated (shared VPN stack)
```

### What Gets Tested

- Container network isolation
- Gluetun kill switch active (firewall rules)
- VPN tunnel (tun0) exists
- Real IP auto-detection
- VPN IP verification
- Bypass prevention
- Proxy failure handling
- Integration test (full request through all layers)

## Management

```bash
cd mcp-server

# Start VPN
docker-compose up -d

# Check status
docker-compose ps
docker logs vpn-recon

# View current VPN IP
curl -x http://localhost:9888 https://ipinfo.io

# Stop VPN
docker-compose down

# Restart (after config changes)
docker-compose restart
```

## Troubleshooting

### VPN won't connect

```bash
# Check logs
docker-compose logs vpn-recon | tail -50

# Verify credentials in .env
cat .env

# Common issues:
# - Wrong credentials (get from your VPN provider's dashboard)
# - Network connectivity (check internet)
# - Docker not running (start Docker Desktop)
```

### Security test fails

```bash
# Check which layer failed
./test-security.sh

# Fix based on failure:
# - Kill switch: Restart Gluetun
# - Pre-flight: Check VPN connection
# - Network isolation: docker-compose down && up -d
```

### Real IP detected

If you see: `REAL IP DETECTED!`

1. **STOP immediately** - Don't make requests
2. Check VPN status: `docker-compose ps`
3. Check logs: `docker logs vpn-recon`
4. Restart: `docker-compose restart`
5. Re-run tests: `./test-security.sh`

**Do not proceed until tests pass.**

## Project Structure

```
vpn-recon/
├── README.md                  # This file
├── .gitignore                 # Protects credentials
├── .mcp.json                  # MCP server configuration (for plugin)
├── .claude-plugin/            # Plugin metadata
│   ├── plugin.json           # Plugin definition
│   └── marketplace.json      # Marketplace registry
├── commands/                  # User-facing command (thin wrapper)
│   └── vpn-recon.md
├── skills/                    # Claude Code skills
│   └── vpn-recon/
│       ├── SKILL.md          # Main instructions (use MCP tools)
│       ├── references/       # Deep dive docs (progressive disclosure)
│       │   ├── security-layers.md
│       │   └── troubleshooting.md
│       └── scripts/          # Utility scripts
│           ├── validate-vpn.sh
│           └── check-ip.sh
├── setup.sh                   # Docker/VPN infrastructure setup
├── test-security.sh           # Security verification (11 tests)
└── mcp-server/               # Docker infrastructure
    ├── server.py             # FastMCP server (3 tools)
    ├── docker-compose.yml    # Gluetun + MCP (5-layer defense)
    ├── Dockerfile            # Container definition
    ├── requirements.txt      # fastmcp>=2.14.1
    ├── .env                  # Your credentials (git-ignored)
    ├── .env.example          # Template with provider configs
    └── data/                 # Gluetun data (git-ignored)
```

## Development

### Running Tests

```bash
# Full security suite
./test-security.sh

# Quick VPN check
curl -x http://localhost:9888 https://ifconfig.me

# Check auto-detection
docker logs vpn-recon-mcp | grep "Real IP blocked"
```

### Debugging

```bash
# Container logs
cd mcp-server && docker-compose logs -f

# Check network isolation
docker inspect vpn-recon-mcp --format '{{.HostConfig.NetworkMode}}'
# Should show: container:vpn-recon-xxxxx

# Verify kill switch
docker exec vpn-recon iptables -L -n | grep REJECT
# Should show multiple REJECT rules
```

### Local Plugin Development

```bash
# Add local marketplace for development
claude plugins marketplace add ./

# Install from local
claude plugins install vpn-recon@vpn-recon

# Make changes to skills/, commands/, .mcp.json

# Reinstall to pick up changes
claude plugins install vpn-recon@vpn-recon --force
```

## Contributing

Contributions welcome! Please:
1. Test changes thoroughly with `./test-security.sh`
2. Ensure all 11 security tests pass
3. Update documentation
4. Verify no credentials committed

## Security & Ethics

### Appropriate Use

- Your own infrastructure
- Authorized penetration testing
- Bug bounty programs (within scope)
- Security research

### Inappropriate Use

- Unauthorized access
- Bypassing authentication
- Ignoring robots.txt
- Aggressive scanning

**VPN provides IP masking, not permission to attack systems.**

## Credits

- **Gluetun** - https://github.com/qdm12/gluetun (VPN client supporting 30+ providers)
- **FastMCP** - https://github.com/jlowin/fastmcp (MCP framework)

## License

MIT License - See LICENSE file for details

## Disclaimer

This software is provided as-is without warranty. While designed with multiple security layers, no software can guarantee complete protection. Users are responsible for verifying VPN functionality and understanding the risks of their activities.

---

**Questions?** Open an issue on GitHub
**Security concerns?** See `./test-security.sh` for verification
