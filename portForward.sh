#!/command/with-contenv bash
# shellcheck shell=bash

# Config variables
INSTALL_DIR="/usr/local/bin"
LOG_FILE="/var/log/proton-port-forward-for-qbittorrent.log"
# Username and password can be left blank if localhost authentication is disabled
QBITTORRENT_USERNAME="admin"
QBITTORRENT_PASSWORD="adminadmin"
QBITTORRENT_BASE_URL="http://localhost:8080"
rm -f "$LOG_FILE"

# Define natpmpc function for easier calls
natpmpc() {
  python3 "$INSTALL_DIR/py-natpmp-master/natpmp/natpmp_client.py" "$@"
}

# echo a log message to stdout and append it to the log file
log() {
  echo "proton-port-forward-for-qbittorrent: [$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Wait for qBittorrent to start and be reachable
iterations=0
max_iterations=6
until (pgrep "qbittorrent-nox" &>/dev/null) && (curl -s "$QBITTORRENT_BASE_URL" &>/dev/null); do
  ((iterations++))
  if ((iterations > max_iterations)); then
    log "qBittorrent is not running!" >&2
    exit 1
  fi
  log "qBittorrent is not running, retrying in 10 seconds..."
  sleep 10
done

# Check if the required commands exist
commands=(curl tar python3 grep timeout)
for command in "${commands[@]}"; do
  if ! command -v "$command" &>/dev/null; then
    log "\"$command\" does not exist!" >&2
    exit 1
  fi
done

log "Checking if py-natpmp exists..."
if [ -f "$INSTALL_DIR/py-natpmp-master/natpmp/natpmp_client.py" ]; then
  log "py-natpmp already exists."
else
  if [ -f "/usr/local/bin/master.tar.gz" ]; then
    log "Local tarball found, performing local install."
    if ! tar xz -C "$INSTALL_DIR" -f "/usr/local/bin/master.tar.gz"; then
      log "Failed to extract local tarball." >&2
      exit 1
    fi
  else
    log "py-natpmp does not exist, downloading..."
    if ! curl -sL https://github.com/yimingliu/py-natpmp/archive/master.tar.gz | tar xz -C "$INSTALL_DIR"; then
      log "Failed to download and extract py-natpmp" >&2
      exit 1
    fi
  fi
  log "py-natpmp installed successfully."
fi

# Function to get the qBittorrent auth cookie
get_qbittorrent_auth_cookie() {
  qbittorrent_auth_cookie=$(curl -si --header "Referer: $QBITTORRENT_BASE_URL" --data "username=$QBITTORRENT_USERNAME&password=$QBITTORRENT_PASSWORD" "${QBITTORRENT_BASE_URL}/api/v2/auth/login" | grep -oP '(?<=set-cookie: )\S*(?=;)')
  if [ -z "$qbittorrent_auth_cookie" ] && { [ -n "$QBITTORRENT_USERNAME" ] && [ -n "$QBITTORRENT_PASSWORD" ]; }; then
    log "Failed to login to qBittorrent" >&2
    return 1
  fi
}

# Save the qBittorrent auth cookie to a variable to prevent multiple calls to the function
get_qbittorrent_auth_cookie

# Function to get the current active ProtonVPN port
get_proton_vpn_port() {
  proton_vpn_port=$(timeout 10 python3 "$INSTALL_DIR"/py-natpmp-master/natpmp/natpmp_client.py -g 10.2.0.1 0 0 | grep -oP '(?<=public port ).*(?=,)')
  if [ -z "$proton_vpn_port" ] || ! [[ "$proton_vpn_port" =~ ^[0-9]+$ ]]; then
    log "Failed to get the active ProtonVPN port" >&2
    return 1
  fi
}

# Function to get the current active qBittorrent port
get_qbittorrent_port() {
  qbittorrent_port=$(curl -s -b "$qbittorrent_auth_cookie" "${QBITTORRENT_BASE_URL}/api/v2/app/preferences" | grep -oP '(?<="listen_port":)\d+(?=,)')
  if [ -z "$qbittorrent_port" ] || ! [[ "$qbittorrent_port" =~ ^[0-9]+$ ]]; then
    log "Failed to get the active qBittorrent port" >&2
    return 1
  fi
}

# Function to check if the ProtonVPN port is different from the qBittorrent port and update if necessary
update_port() {
  get_proton_vpn_port
  get_qbittorrent_port

  if [ -z "$proton_vpn_port" ] || [ -z "$qbittorrent_port" ]; then
    log "Cannot update port: ProtonVPN or qBittorrent port retrieval failed." >&2
    return 1
  fi

  if [ "$proton_vpn_port" != "$qbittorrent_port" ]; then
    log "ProtonVPN port ($proton_vpn_port) is different from qBittorrent port ($qbittorrent_port). Updating..."
    curl -s -b "$qbittorrent_auth_cookie" --data "json={\"listen_port\":$proton_vpn_port}" "${QBITTORRENT_BASE_URL}/api/v2/app/setPreferences"
    log "Updated qBittorrent port to $proton_vpn_port"
  else
    log "ProtonVPN port and qBittorrent port are the same ($proton_vpn_port). No update needed."
  fi
}

# Run this initially before we enter loop
update_port
counter=0

while true; do
  ((counter++))
  # Execute natpmpc commands to keep port open
  if ! natpmpc -g 10.2.0.1 0 0 >/dev/null; then
    log "ERROR with natpmpc command"
  fi
  # If counter reaches 80, roughly one hour has passed (80*45 seconds = 3600 seconds)
  if ((counter >= 80)); then
    update_port
    counter=0
  fi
  sleep 45
done
