# Gateway Watchdog Skill

Monitor and auto-restart OpenClaw Gateway (Node) when it disconnects.

## PM2 Configuration

OpenClaw Node is managed by PM2 with these settings:
- **Name:** openclaw-node
- **Script:** C:\Program Files\nodejs\node.exe
- **Args:** C:\Users\ZhangJiayuan\AppData\Roaming\npm\node_modules\openclaw\dist\index.js node run --host 127.0.0.1 --port 18789
- **PM2_HOME:** C:\Users\ZhangJiayuan\.openclaw\.pm2
- **Config file:** C:\Users\ZhangJiayuan\.openclaw\ecosystem.config.json

## Commands

### Check Gateway Status

```bash
# Check if openclaw-node is running
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 jlist | ConvertFrom-Json | Where-Object { $_.name -eq "openclaw-node" }
```

Or check last log:
```bash
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 logs openclaw-node --lines 20 --nostream
```

### Start Gateway

```bash
# Start using ecosystem config
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 start C:\Users\ZhangJiayuan\.openclaw\ecosystem.config.json
```

Or use the full command directly:
```bash
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 start "C:\Program Files\nodejs\node.exe" --name openclaw-node -- "C:\Users\ZhangJiayuan\AppData\Roaming\npm\node_modules\openclaw\dist\index.js" node run --host 127.0.0.1 --port 18789
```

### Restart Gateway

```bash
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 restart openclaw-node
```

### Stop Gateway

```bash
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 stop openclaw-node
```

### Delete Gateway (from PM2)

```bash
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 delete openclaw-node
```

## Auto-Start Workflow

If the gateway disconnects, use this sequence:

1. **Check status first:**
   ```bash
   $env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 jlist | ConvertFrom-Json | Where-Object { $_.name -eq "openclaw-node" }
   ```

2. **If not running (no output), start it:**
   ```bash
   $env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 start C:\Users\ZhangJiayuan\.openclaw\ecosystem.config.json
   ```

3. **Wait a few seconds, then verify:**
   ```bash
   $env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"; pm2 jlist | ConvertFrom-Json | Where-Object { $_.name -eq "openclaw-node" } | Select-Object name, status
   ```

## Common Issues

### "Access is denied" when deleting/restarting
PM2 processes may be locked. Stop the services first:
```bash
# Find and kill related processes
Get-Process | Where-Object { $_.Name -like "*node*" -or $_.Name -like "*openclaw*" -or $_.Name -like "*qdrant*" -or $_.Name -like "*cortex*" } | Stop-Process -Force
```

### PM2_HOME not found
Always set the environment variable before PM2 commands:
```powershell
$env:PM2_HOME = "C:\Users\ZhangJiayuan\.openclaw\.pm2"
```

## Quick Health Check

To verify the gateway is responding:
```bash
curl -s http://127.0.0.1:18789/health 2>$null | Select-String -Pattern "ok" -Quiet
```

If it returns true, the gateway is healthy. If not, restart it.
