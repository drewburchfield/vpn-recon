# Troubleshooting Guide

Common issues and solutions for VPN Recon skill.

## VPN Containers Not Running

**Symptom:**
```
❌ VPN containers not running
```

**Solution:**
```bash
cd ~/dev/projects/vpn-recon/mcp-server
docker-compose up -d

# Wait 20 seconds for VPN connection
sleep 20

# Verify
docker-compose ps
```

## Real IP Detected

**Symptom:**
```
🚨 REAL IP DETECTED! VPN is NOT working. Request BLOCKED.
```

**Cause:** VPN connection failed or not established

**Solution:**
1. Check container status:
   ```bash
   docker-compose ps
   # vpn-recon should show (healthy)
   ```

2. Check logs:
   ```bash
   docker logs vpn-recon | tail -50
   ```

3. Look for errors:
   - Authentication failed → Check credentials in .env
   - Connection timeout → Check internet
   - Server unavailable → Try different country

4. Restart:
   ```bash
   docker-compose restart
   ```

5. Verify:
   ```bash
   curl -x http://localhost:9888 https://ifconfig.me
   # Should show VPN IP, not your real IP
   ```

## VPN Proxy Not Responding

**Symptom:**
```
❌ VPN proxy not responding
```

**Cause:** Gluetun container down or proxy port issue

**Solution:**
```bash
# Check Gluetun is running
docker ps | grep vpn-recon

# Check logs
docker logs vpn-recon

# Verify proxy port
curl -x http://localhost:9888 https://ifconfig.me

# If port changed, update in .env:
PROXY_PORT=9888
```

## Wrong VPN Location

**Symptom:** VPN connects but shows wrong country

**Solution:**
1. Edit `mcp-server/.env`:
   ```bash
   VPN_COUNTRY=United Kingdom
   ```

2. Restart:
   ```bash
   docker-compose restart
   ```

3. Verify:
   ```bash
   curl -x http://localhost:9888 https://ipinfo.io
   # Check country field
   ```

## Auto-Detection Fails

**Symptom:**
```
Real IP blocked: None
```

**Cause:** Cannot detect real IP (no internet or ifconfig.me down)

**Solution:**
Real IP is auto-detected at runtime. If detection fails:
1. Check your internet connection (without VPN)
2. Try: `curl https://ifconfig.me`
3. If ifconfig.me is down, try restarting containers later

## Security Tests Fail

**Symptom:**
```
❌ FAIL: ...
Passed: X, Failed: Y
```

**Solution:**

1. Run tests to see which layer failed:
   ```bash
   ~/dev/projects/vpn-recon/test-security.sh
   ```

2. Fix based on failure:
   - **Kill switch:** Restart Gluetun
   - **Pre-flight:** Check VPN connection
   - **Network isolation:** Rebuild containers
   - **Integration:** Check proxy accessibility

3. Re-run tests until all pass

## Docker Issues

### Containers Won't Start

```bash
# Check Docker is running
docker info

# Check port conflicts
lsof -i :9888
lsof -i :3100

# Clean restart
docker-compose down -v
docker-compose up -d
```

### Network Mode Error

If you see: `network mode not compatible with port publishing`

This is expected - mcp-server shares vpn-recon's network, so ports are published on vpn-recon container.

## Still Having Issues?

1. Run security tests: `./test-security.sh`
2. Check all containers: `docker-compose ps`
3. View all logs: `docker-compose logs`
4. Verify .env configuration: `cat mcp-server/.env`
5. Check GitHub issues for similar problems
