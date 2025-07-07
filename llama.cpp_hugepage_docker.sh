#!/bin/bash

function Info() {
  echo -e "\033[32m[Info] $@ \033[0m"
}

function Warning() {
  echo -e "\033[33;3m[Warning] $@ \033[0m"
}

function Error() {
  echo -e "\033[31m[Error] $@ \033[0m" >&2
}

function download_llama_cpp() {
    local dist_dir=${1:-}
    git clone https://github.moeyy.xyz/https://github.com/ggml-org/llama.cpp
    return $?
}

LLAMA_CPP_ROOT="/Users/adam/ai_envs/llama.cpp"

if [ -d "$LLAMA_CPP_ROOT" ]; then
    Warning "目录已经存在(llama.cpp),跳过下载..."
    Warning "如果需要使用最新代码，请运行 git pull"
else
    download_llama_cpp "$LLAMA_CPP_ROOT"
fi