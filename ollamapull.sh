#!/bin/sh

apk add netcat-openbsd
apk add screen

# 定义 screen 会话名称
SCREEN_SESSION="ollama"

echo "进入 screen 会话：$SCREEN_SESSION"
screen -R "$SCREEN_SESSION" << EOF
/usr/bin/ollama serve
sleep 10
EOF
# 使用 screen -d 命令分离会话
screen -d "$SCREEN_SESSION"

ps aux | grep ollama

# 设置 Ollama 服务的检测地址及端口
HOST="localhost"
PORT="11434"

# 拉取模型名称
MODEL_NAME="qwen2.5:0.5b"

# 检测间隔（以秒为单位）
CHECK_INTERVAL=5

# 检查服务是否启动函数
function is_ollama_running {
    # 使用 nc 检测服务是否可以连接
    nc -z $HOST $PORT
    return $?
}



# 循环检测 ollama 是否启动
echo "正在检测 Ollama 服务是否已启动..."
while true; do
    if is_ollama_running; then
        echo "Ollama 服务已启动，开始拉取模型 $MODEL_NAME..."
        
        # 拉取模型
        ollama pull "$MODEL_NAME"
        if [ $? -eq 0 ]; then
            echo "模型 $MODEL_NAME 拉取成功！"
        else
            echo "模型 $MODEL_NAME 拉取失败，请检查日志。"
        fi

        # 跳出循环
        break
    else
        echo "Ollama 服务尚未启动，将在 $CHECK_INTERVAL 秒后重新检查..."
        sleep $CHECK_INTERVAL
    fi
done
