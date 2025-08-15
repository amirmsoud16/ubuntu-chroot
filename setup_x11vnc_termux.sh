#!/data/data/com.termux/files/usr/bin/bash
# setup_x11vnc_termux.sh
# Installs and configures x11vnc on Termux to share an existing X display (Termux:X11 / XServer XSDL).
# One server/port. Creates a termux-services entry for auto-start.
set -euo pipefail

# Config (override via env before running)
VNC_PASS="${VNC_PASS:-changeme}"     # Strongly change this!
VNC_PORT="${VNC_PORT:-5900}"
DISPLAY_NUM="${DISPLAY_NUM:-:0}"     # For Termux:X11 typically :0
ALLOW_EXTERNAL="${ALLOW_EXTERNAL:-1}" # 1: listen on all interfaces, 0: localhost only

echo "[*] Updating and installing packages ..."
pkg update -y
pkg install -y x11-repo
pkg install -y x11vnc xorg-xhost termux-services

# Paths
CONF_DIR="${HOME}/.config/x11vnc"
PASSFILE="${CONF_DIR}/passwd"
LOGFILE="${CONF_DIR}/x11vnc.log"
mkdir -p "${CONF_DIR}"

# Create VNC password file if missing
if [ ! -f "${PASSFILE}" ]; then
  echo "[*] Creating VNC password file ..."
  x11vnc -storepasswd "${VNC_PASS}" "${PASSFILE}" >/dev/null
  chmod 600 "${PASSFILE}"
else
  echo "[=] Password file exists: ${PASSFILE}"
fi

# Ensure DISPLAY is set to your X server
export DISPLAY="${DISPLAY_NUM}"
echo "[*] Using DISPLAY=${DISPLAY}"
# Allow local clients to access the X server (harmless if it fails)
if command -v xhost >/dev/null 2>&1; then
  ( xhost +local: >/dev/null 2>&1 ) || true
fi

# Create termux-services entry
SV_DIR="${HOME}/.config/termux-services/x11vnc"
mkdir -p "${SV_DIR}"

cat > "${SV_DIR}/run" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# termux-services run script for x11vnc
export PATH=/data/data/com.termux/files/usr/bin:$PATH

# Load env if present
[ -f "$HOME/.config/x11vnc/env" ] && . "$HOME/.config/x11vnc/env"

# Defaults (in case env is absent)
export DISPLAY="${DISPLAY:-:0}"
VNC_PORT="${VNC_PORT:-5900}"
ALLOW_EXTERNAL="${ALLOW_EXTERNAL:-1}"

# Try to allow local X access (won't fail script)
if command -v xhost >/dev/null 2>&1; then
  xhost +local: >/dev/null 2>&1 || true
fi

# Bind address
if [ "${ALLOW_EXTERNAL}" = "1" ]; then
  BIND="0.0.0.0"
else
  BIND="127.0.0.1"
fi

# Run x11vnc in background with logging
exec x11vnc \
  -display "${DISPLAY}" \
  -rfbport "${VNC_PORT}" \
  -rfbauth "$HOME/.config/x11vnc/passwd" \
  -forever -shared -noxdamage -repeat -cursor arrow \
  -listen "$BIND" -bg -o "$HOME/.config/x11vnc/x11vnc.log"
EOF
chmod +x "${SV_DIR}/run"

# Environment file for the service
cat > "${CONF_DIR}/env" <<EOF
VNC_PORT=${VNC_PORT}
ALLOW_EXTERNAL=${ALLOW_EXTERNAL}
DISPLAY=${DISPLAY_NUM}
EOF

# Enable and start the service
echo "[*] Enabling and starting service ..."
sv-enable x11vnc || true
sv up x11vnc

# Best-effort IP detection (Termux has `ip` inside pkg net-tools or iproute2)
IP=$(ip -o -4 addr show 2>/dev/null | awk '{gsub(/\/.*/,"",$4); print $4; exit}')
IP=${IP:-127.0.0.1}

echo
echo "====================================================="
echo " x11vnc is set up on Termux."
echo " Connect with a VNC client to: ${IP}:${VNC_PORT}"
echo " Password: ${VNC_PASS}"
echo " Log: ${LOGFILE}"
echo
echo " Notes:"
echo " 1) Ensure your X server (e.g., Termux:X11) is running and your desktop uses DISPLAY=${DISPLAY_NUM}."
echo " 2) If X access is denied, inside your X session run:  xhost +local:"
echo " 3) Change settings in ${CONF_DIR}/env and restart:    sv restart x11vnc"
echo " 4) For LAN-only, set ALLOW_EXTERNAL=0."
echo "====================================================="
