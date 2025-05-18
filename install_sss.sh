#!/bin/sh

sudo apt update
sudo apt install -y nodejs
sudo apt install -y npm
sudo apt install -y firewalld
sudo firewall-cmd --reload
sudo firewall-cmd --add-port=8394/udp --permanent
sudo firewall-cmd --add-port=8394/tcp --permanent
sudo firewall-cmd --reload
npm install shadowsocks -g
cd /usr/local/lib/node_modules/shadowsocks/
cat > config.json << 'EOF'
{
    "server":"0.0.0.0",
    "server_port":8394,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"ubuntu8888",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
screen -dmS ssserver sh -c 'ssserver -c /usr/local/lib/node_modules/shadowsocks/config.json'