#!/bin/bash
set -e

# ==== 0. Генерация пароля ====
VNC_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)

echo "[*] Updating system..."
apt update -y && apt upgrade -y

echo "[*] Installing desktop environment + clipboard tools..."
apt install -y xfce4 xfce4-goodies autocutsel xclip curl wget git software-properties-common \
    dbus-x11 libglu1-mesa

echo "[*] Installing TurboVNC + VirtualGL..."
wget -qO- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor > /etc/apt/trusted.gpg.d/turbovnc.gpg
wget -qO /etc/apt/sources.list.d/turbovnc.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list
wget -qO- https://packagecloud.io/dcommander/virtualgl/gpgkey | gpg --dearmor > /etc/apt/trusted.gpg.d/virtualgl.gpg
wget -qO /etc/apt/sources.list.d/virtualgl.list https://raw.githubusercontent.com/VirtualGL/repo/main/VirtualGL.list
apt update -y
apt install -y turbovnc virtualgl

echo "[*] Configuring VirtualGL..."
/opt/VirtualGL/bin/vglserver_config -config +s +f -t </dev/null

echo "[*] Creating VNC startup script..."
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="XFCE"

# Clipboard sync
autocutsel -fork
autocutsel -selection PRIMARY -fork
xfce4-clipman &

# Fix mouse/keyboard grab in Minecraft
xset r rate 200 40
setxkbmap us

exec startxfce4
EOF
chmod +x ~/.vnc/xstartup
touch ~/.Xresources

echo "[*] Setting VNC password automatically..."
mkdir -p ~/.vnc
echo "$VNC_PASS" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

echo "[*] Starting VNC server..."
/opt/TurboVNC/bin/vncserver -kill :1 || true
/opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24

# GPU check
if command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null; then
    echo "[OK] GPU detected."
else
    echo "[WARN] GPU not detected or drivers missing."
fi

IP=$(hostname -I | awk '{print $1}')
echo "===================================="
echo "VNC is running!"
echo "Connect to: ${IP}:5901"
echo "Password:   ${VNC_PASS}"
echo "===================================="
