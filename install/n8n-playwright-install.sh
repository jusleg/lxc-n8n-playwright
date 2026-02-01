#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts (tteckster) - Modified for Playwright support
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  git \
  make \
  g++ \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing n8n"
$STD npm install -g n8n
msg_ok "Installed n8n"

msg_info "Installing Playwright & Chromium"
$STD npm install -g playwright
$STD npx playwright install chromium --with-deps
msg_ok "Installed Playwright & Chromium"

msg_info "Verifying Chromium Installation"
CHROMIUM_PATH=$(find /root/.cache/ms-playwright -name "chrome" -type f 2>/dev/null | head -1)
if [ -z "$CHROMIUM_PATH" ]; then
  CHROMIUM_PATH=$(find /root/.cache/ms-playwright -name "chromium" -type f 2>/dev/null | head -1)
fi
if [ -n "$CHROMIUM_PATH" ]; then
  msg_ok "Chromium binary found at: ${CHROMIUM_PATH}"
else
  msg_error "Chromium binary not found - browser automation may not work"
fi

msg_info "Creating n8n Environment Configuration"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
mkdir -p /opt
cat <<EOF >/opt/n8n.env
# n8n core settings
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=${LOCAL_IP}

# Playwright / Chromium settings
PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright
PLAYWRIGHT_CHROMIUM_SANDBOX=0

# Node.js memory (Chromium can be memory-hungry)
NODE_OPTIONS=--max-old-space-size=3072
EOF
msg_ok "Created Environment Configuration"

msg_info "Creating n8n Service"
cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n - Workflow Automation
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/n8n.env
ExecStart=n8n start
Restart=on-failure
RestartSec=5
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now n8n
msg_ok "Created n8n Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
