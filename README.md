# n8n + Playwright LXC Scripts for Proxmox VE

Custom Proxmox VE helper scripts that install **n8n** with **Playwright + Chromium** pre-configured for browser automation inside an LXC container.

**Single-command deployment** - ready to use!

## Files

| File | Purpose |
|------|---------|
| `ct/n8n-playwright.sh` | Runs on the **Proxmox host** — creates the LXC and handles updates |
| `install/n8n-playwright-install.sh` | Runs **inside the LXC** — installs n8n, Playwright, Chromium, and configures the systemd service |

## What's Different from the Upstream n8n Script

- **More RAM** — defaults to 4096 MiB (upstream uses 2048). Chromium is memory-hungry.
- **More disk** — defaults to 12 GB (upstream uses 10). Chromium binaries take ~500 MB+.
- **Debian 12** — uses Bookworm for best Playwright compatibility.
- **Playwright + Chromium** — installed globally via npm with `--with-deps` (auto-installs all system libraries like libnss3, libgbm1, etc.).
- **Sandbox disabled** — `PLAYWRIGHT_CHROMIUM_SANDBOX=0` in the env file, required for unprivileged LXC containers.
- **`NODE_OPTIONS`** — sets `--max-old-space-size=3072` so Node doesn't OOM when Chromium is active.
- **Environment file** — all config lives in `/opt/n8n.env` from the start (upstream migrates to this on first update).

## Usage

### Installation

Run this **single command** from your Proxmox VE shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jusleg/lxc-n8n-playwright/main/ct/n8n-playwright.sh)"
```

The script will:
- Create a Debian 12 LXC container with 4GB RAM and 12GB disk
- Install Node.js 22, n8n, Playwright, and Chromium
- Configure the systemd service with browser automation support
- Display the access URL when complete (typically `http://<container-ip>:5678`)

### Updating

Run the same script again against an existing n8n container. It detects the installation and runs the `update_script()` function, which updates both n8n and Playwright/Chromium.

## Configuration

All environment variables live in `/opt/n8n.env` inside the container:

```
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=<container IP>
PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright
PLAYWRIGHT_CHROMIUM_SANDBOX=0
NODE_OPTIONS=--max-old-space-size=3072
```

Edit this file and restart n8n to apply changes:

```bash
nano /opt/n8n.env
systemctl restart n8n
```

### Adding Webhook URL (for OAuth / reverse proxy)

Append to `/opt/n8n.env`:

```
WEBHOOK_URL=https://n8n.yourdomain.com
```

### Enabling MCP Community Packages

Append to `/opt/n8n.env`:

```
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
```

Then install `n8n-nodes-mcp` from the n8n Community Nodes settings.

## Using Playwright in n8n Workflows

### Via the Code Node

```javascript
const { chromium } = require('playwright');

const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox']
});

const page = await browser.newPage();
await page.goto('https://example.com');
const title = await page.title();
await browser.close();

return [{ json: { title } }];
```

### Via Community Node

Install [n8n-nodes-playwright](https://github.com/toema/n8n-playwright) from **Settings → Community Nodes** for a GUI-based Playwright node.

## Troubleshooting

### "Chromium sandbox is not supported"
Expected in unprivileged LXC. The env file sets `PLAYWRIGHT_CHROMIUM_SANDBOX=0` and you should pass `args: ['--no-sandbox']` when launching Chromium in code.

### Out of memory
Increase container RAM (recommended: 4 GB+). If still OOM, raise `--max-old-space-size` in `/opt/n8n.env`.

### Browser binary not found
Run inside the container:
```bash
npx playwright install chromium --with-deps
```

### Checking Chromium works
```bash
npx playwright screenshot --browser chromium https://example.com /tmp/test.png
```

## License

MIT — same as the upstream community-scripts project.
