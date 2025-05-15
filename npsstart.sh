#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

ALLOW_POSTS=$ALLOW_POSTS,$FILE_PORT

if [ ! -f "/conf/auth_key" ]; then
AUTH_KEY=`cat /proc/sys/kernel/random/uuid | cut -c1-8`
echo 1 > /conf/auth_key
export AUTH_KEY
fi

if [ ! -f "/conf/auth_crypy_key" ]; then
AUTH_CRYPT_KEY=`cat /proc/sys/kernel/random/uuid | cut -c1-16`
echo 1 > /conf/auth_crypy_key
export AUTH_CRYPT_KEY
fi;ntp &

if [ -f "/etc/envfile" ]; then
export $(grep -v '^#' /etc/envfile | xargs)
fi

create_config() {

if [ ! -f "/conf/clients.json" ]; then
  touch /conf/clients.json
fi

if [ ! -f "/conf/tasks.json" ]; then
  touch /conf/tasks.json
fi

if [ ! -f "/conf/hosts.json" ]; then
  touch /conf/hosts.json
fi


cat > /conf/nps.conf<< TEMPEOF
appname = nps
#Boot mode(dev|pro)
runmode = pro

#HTTP(S) proxy port, no startup if empty
http_proxy_ip=0.0.0.0
http_proxy_port=$HTTP_PROXY_PORT
https_proxy_port=$HTTPS_PROXY_PORT
https_just_proxy=true
#default https certificate setting
https_default_cert_file=/conf/server.crt
https_default_key_file=/conf/server.key

##bridge
bridge_type=tcp
bridge_port=$BRIDGE_PORT
bridge_ip=0.0.0.0

# Public password, which clients can use to connect to the server
# After the connection, the server will be able to open relevant ports and parse related domain names according to its own configuration file.
public_vkey=$PUBLIC_VKEY

#Traffic data persistence interval(minute)
#Ignorance means no persistence
flow_store_interval=1

# log level LevelEmergency->0  LevelAlert->1 LevelCritical->2 LevelError->3 LevelWarning->4 LevelNotice->5 LevelInformational->6 LevelDebug->7
log_level=7
#log_path=nps.log

#Whether to restrict IP access, true or false or ignore
#ip_limit=true

#p2p
#p2p_ip=127.0.0.1
#p2p_port=6000

#web
web_host=$HOSTNAME.$DOMAIN
web_username=admin
web_password=$WEB_PASSWORD
web_port = $WEB_PORT
web_ip=0.0.0.0
web_base_url=
web_open_ssl=false
web_cert_file=/conf/server.crt
web_key_file=/conf/server.key
# if web under proxy use sub path. like http://host/nps need this.
#web_base_url=/nps

#Web API unauthenticated IP address(the len of auth_crypt_key must be 16)
auth_key=$AUTH_KEY
auth_crypt_key =$AUTH_CRYPT_KEY

allow_ports=$ALLOW_POSTS

#Web management multi-user login
allow_user_login=true
allow_user_register=false
allow_user_change_username=false


#extension
allow_flow_limit=true
allow_rate_limit=true
allow_tunnel_num_limit=true
allow_local_proxy=true
allow_connection_num_limit=true
allow_multi_ip=false
system_info_display=true

#cache
http_cache=true
http_cache_length=100

#get origin ip
http_add_origin_header=true

#pprof debug options
#pprof_ip=0.0.0.0
#pprof_port=9999

#client disconnect timeout
disconnect_timeout=60

TEMPEOF

if [ ! -d "/conf/file" ]; then
  mkdir -p /conf/file
  COUNTRY=`curl ipinfo.io/country  2>/dev/null || curl ipinfo.io/country 2>/dev/null`
  if [ "$COUNTRY" == "CN" ]; then
    GHPROXY=https://ghproxy.com/
  fi 
  wget -O /conf/file/windows_386_client.tar.gz ${GHPROXY}https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/windows_386_client.tar.gz
  wget -O /conf/file/windows_amd64_client.tar.gz ${GHPROXY}https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/windows_amd64_client.tar.gz
fi

cat > /conf/npc.conf<< TEMPEOF
[common]
server_addr=127.0.0.1:$BRIDGE_PORT
conn_type=$MODE
vkey=$PUBLIC_VKEY
auto_reconnection=true
remark=nps

[nps-web-file]
mode=https
host=$HOSTNAME.$DOMAIN
target_addr=127.0.0.1:$WEB_PORT

[file]
mode=file
server_port=$FILE_PORT
local_path=/conf/file/
TEMPEOF

}

# 创建配置文件
create_config


install_cert() {
mkdir -p /etc/cert/$DOMAIN
openssl genrsa 1024 > /etc/cert/$DOMAIN/private.key
openssl req -new -key /etc/cert/$DOMAIN/private.key -subj "/C=CN/ST=GD/L=SZ/O=$DOMAIN/CN=$HOSTNAME" > /etc/cert/$DOMAIN/private.csr
openssl req -x509 -days 3650 -key /etc/cert/$DOMAIN/private.key -in /etc/cert/$DOMAIN/private.csr > /etc/cert/$DOMAIN/fullchain.crt
}

# 查看证书，没有就自动创建
if [ ! -f "/etc/cert/$DOMAIN/fullchain.crt" ]; then
  install_cert
fi

if [ ! -f "/conf/server.crt" ]; then
  echo ln -s /etc/cert/$DOMAIN/fullchain.crt to /conf/server.crt
  echo ln -s /etc/cert/$DOMAIN/private.key to /conf/server.key
  ln -s /etc/cert/$DOMAIN/fullchain.crt /conf/server.crt
  ln -s /etc/cert/$DOMAIN/private.key /conf/server.key
fi

if [ $CROND = "1" ]; then
/usr/sbin/crond
fi

/nps >& /dev/stdout | tee /conf/nps.log &
sleep 2
if [ $NPC = "1" ]; then
 /npc >& /dev/stdout | tee /conf/nps.log
else
 ping 127.0.0.1 > /dev/null
fi