#!/bin/sh

docker run -d -p 11434:11434 --name ollama --restart always -v ollama:/root/.ollama alpine/ollama
docker exec -it ollama ollama pull qwen2.5:0.5b
