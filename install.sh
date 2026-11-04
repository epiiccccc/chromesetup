#!/usr/bin/env bash
set -Eeuo pipefail

# Chrome Setup installer for Debian/Ubuntu/Crostini.
# Review this script before running it from the internet.

REPO_DIR="${HOME}/.local/share/chrome-setup"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
SYSTEMD_DIR="${HOME}/.config/systemd/user"
CONFIG_DIR="${HOME}/.config/chrome-setup"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Voer dit script uit als normale gebruiker, niet met sudo."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Deze eerste versie ondersteunt Debian/Ubuntu met apt."
  exit 1
fi

echo "== Chrome Setup =="

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg
sudo chmod 0644 /etc/apt/keyrings/google-chrome.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null

sudo apt-get update
sudo apt-get install -y google-chrome-stable

# Managed Chrome policies: force-install uBlock Origin Lite and set homepage.
sudo install -d -m 0755 /etc/opt/chrome/policies/managed
sudo tee /etc/opt/chrome/policies/managed/chrome-setup.json >/dev/null <<'POLICY'
{
  "ExtensionInstallForcelist": [
    "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx"
  ]
}
POLICY
sudo chmod 0644 /etc/opt/chrome/policies/managed/chrome-setup.json

mkdir -p "$REPO_DIR" "$BIN_DIR" "$APP_DIR" "$SYSTEMD_DIR" "$CONFIG_DIR"
cp -R "$SCRIPT_DIR/homepage" "$REPO_DIR/"
cp "$SCRIPT_DIR/config/config.sh" "$CONFIG_DIR/config.sh"
# Set the custom local page as Chrome's startup page and homepage button target.
HOME_PAGE_URI="file://${REPO_DIR}/homepage/index.html"
sudo HOME_PAGE_URI="$HOME_PAGE_URI" python3 - <<'PY'
import json, os
from pathlib import Path
policy = {
    "ExtensionInstallForcelist": [
        "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx"
    ],
    "HomepageLocation": os.environ["HOME_PAGE_URI"],
    "HomepageIsNewTabPage": False,
    "RestoreOnStartup": 4,
    "RestoreOnStartupURLs": [os.environ["HOME_PAGE_URI"]]
}
Path("/etc/opt/chrome/policies/managed/chrome-setup.json").write_text(
    json.dumps(policy, indent=2) + "\\n", encoding="utf-8"
)
PY
cp "$SCRIPT_DIR/service/device-check.sh" "$REPO_DIR/device-check.sh"
cp "$SCRIPT_DIR/service/chrome-managed" "$BIN_DIR/chrome-managed"
chmod 0755 "$REPO_DIR/device-check.sh" "$BIN_DIR/chrome-managed"

# Per-device random ID; it is not a hardware fingerprint.
if [[ ! -s "$CONFIG_DIR/device-id" ]]; then
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]' > "$CONFIG_DIR/device-id"
  else
    cat /proc/sys/kernel/random/uuid > "$CONFIG_DIR/device-id"
  fi
  chmod 0600 "$CONFIG_DIR/device-id"
fi

# Install user-level systemd service and 15-minute timer.
cat > "$SYSTEMD_DIR/chrome-device-check.service" <<'UNIT'
[Unit]
Description=Chrome Setup device authorization check

[Service]
Type=oneshot
ExecStart=%h/.local/share/chrome-setup/device-check.sh
UNIT

cat > "$SYSTEMD_DIR/chrome-device-check.timer" <<'UNIT'
[Unit]
Description=Check Chrome Setup authorization every 15 minutes

[Timer]
OnBootSec=30s
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
UNIT

# Desktop launcher uses the authorization-aware wrapper.
cat > "$APP_DIR/Chrome Setup.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Chrome
Comment=Google Chrome with Chrome Setup checks
Exec=$BIN_DIR/chrome-managed %U
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF
chmod 0644 "$APP_DIR/Chrome Setup.desktop"

# Ensure local bin is on PATH for interactive shells.
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  touch "$rc"
  if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    printf '\\n# Chrome Setup\\nexport PATH="$HOME/.local/bin:$PATH"\\n' >> "$rc"
  fi
done

systemctl --user daemon-reload
systemctl --user enable --now chrome-device-check.timer

echo
echo "Installatie van Google Chrome is klaar."
echo "Jouw apparaat-ID:"
cat "$CONFIG_DIR/device-id"
echo
echo "BELANGRIJK:"
echo "1. Stel ALLOWLIST_URL in: $CONFIG_DIR/config.sh"
echo "2. Zet daarna deze apparaat-ID als losse regel in jouw allowlist-TXT."
echo "3. Voer uit: ~/.local/bin/chrome-managed"
echo
echo "De timer controleert daarna elke 15 minuten. Zonder internet of zonder"
echo "toestemming wordt Chrome afgesloten. Dit is een beheercontrole, geen"
echo "waterdichte beveiliging: gebruikers met toegang tot Linux kunnen dit omzeilen."
