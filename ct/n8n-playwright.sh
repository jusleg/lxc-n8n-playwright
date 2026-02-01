#!/usr/bin/env bash

# Override the repository URL that build.func uses
export GIT_RAW="${GIT_RAW:-https://raw.githubusercontent.com/jusleg/lxc-n8n-playwright/main}"

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts (tteckster) - Modified for Playwright support
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/

APP="n8n"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"
var_install="${var_install:-n8n-playwright}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/n8n.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Migrate to env file if not already done
  if [ ! -f /opt/n8n.env ]; then
    sed -i 's|^Environment="N8N_SECURE_COOKIE=false"$|EnvironmentFile=/opt/n8n.env|' /etc/systemd/system/n8n.service
    mkdir -p /opt
    cat <<EOF >/opt/n8n.env
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=$LOCAL_IP
PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright
PLAYWRIGHT_CHROMIUM_SANDBOX=0
NODE_OPTIONS=--max-old-space-size=3072
EOF
    systemctl daemon-reload
  fi

  NODE_VERSION="22" setup_nodejs

  msg_info "Updating ${APP}"
  rm -rf /usr/lib/node_modules/.n8n-* /usr/lib/node_modules/n8n
  $STD npm install -g n8n --force
  msg_ok "Updated ${APP}"

  msg_info "Updating Playwright & Chromium"
  $STD npm install -g playwright
  $STD npx playwright install chromium --with-deps
  msg_ok "Updated Playwright & Chromium"

  systemctl restart n8n
  msg_ok "Update completed successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5678${CL}"
echo -e "${INFO}${YW} Playwright with Chromium has been installed for browser automation${CL}"
