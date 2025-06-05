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

download_model() {
    local model_id="${1:-Qwen/Qwen3-30B-A3B-GGUF}"
    local target_dir="${2:-/data/Qwen3-30B-A3B-GGUF}"

    # 检查目录是否存在
    if [ -d "$target_dir" ]; then
        Warning "[下载模型] 模型文件已存在($target_dir)，跳过下载"
        return 0
    fi

    # 安装/更新 ModelScope 库（若已安装可跳过）
    pip install modelscope -U -i https://mirrors.aliyun.com/pypi/simple/

    Info "[下载模型] 开始下载模型: $model_id → $target_dir"
    modelscope download \
        --model "$model_id" \
        --local_dir "$target_dir"

    # 验证结果
    if [ $? -eq 0 ] && [ -f "$target_dir/*.gguf" ]; then
        Info "[下载模型] ✓ 下载成功!"
        return 0
    else
        Error "[下载模型] ✗ 下载失败!"
        return 1
    fi
}

download_github() {
    local github_url="${1:-https://github.moeyy.xyz/https://github.com/ggml-org/llama.cpp}"
    local target_dir="${2:-/root/llama.cpp}"

    if [ -d "$target_dir" ]; then
        Warning "[下载源代码] 目录已经存在($target_dir),跳过下载"
        return 0
    else
        git clone $github_url $target_dir
        if [ $? -eq 0 ]; then
            Info "[下载源代码] ✓ 下载成功!"
            return 0
        else
            Error "[下载源代码] ✗ 下载失败!"
            return 1
        fi
    fi
}

build_llama_cpp() {
    local src_dir="${1:-/root/llama.cpp}"

    pushd $src_dir
    source /opt/intel/oneapi/setvars.sh --force
    cmake -B build
    cmake --build build --config Release -j8
    if [ $? -eq 0 ]; then
        popd
        Info "[编译源代码] ✓ 编译成功(llama.cpp)!"
        return 0
    else
        popd
        Error "[编译源代码] ✗ 编译失败(llama.cpp)!"
        return 1
    fi
}

run_llama_cpp() {
    local src_dir="${1:-/root/llama.cpp}"
    local local_model_dir="${2:-/data/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-Q4_K_M.gguf}"
    local prompt="${3:-天空为什么是蓝色的?}"

    local bin_dir="$src_dir/build/bin"

    source /opt/intel/oneapi/setvars.sh --force
    pushd $bin_dir/
    #output=$(./llama-cli -m $local_model_dir -p "$prompt" -n 128 -no-cnv 2>&1)
    ./llama-cli -m $local_model_dir -p "$prompt" -n 128 -no-cnv
    if [ $? -eq 0 ]; then
        popd
        Info "[运行] ✓ 运行成功(llama.cpp)!"
        return 0
    else
        popd
        Error "[运行] ✗ 运行失败(llama.cpp)!"
        return 1
    fi
}

run_llama_cpp_qwen3_30b_a3b_quant_models() {
    local quant_types=("$@")
    for qtype in "${quant_types[@]}"; do
        run_llama_cpp "/root/llama.cpp" "/root/models/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-$qtype.gguf" "天空为什么是蓝色的?" || exit 1
    done
}

main() {
    #download_model "Qwen/Qwen3-30B-A3B-GGUF" "/data/Qwen3-30B-A3B-GGUF" || exit 1
    #download_github "https://github.moeyy.xyz/https://github.com/ggml-org/llama.cpp" "/root/llama.cpp" || exit 1
    #build_llama_cpp "/root/llama.cpp" || exit 1

    #run_llama_cpp "/root/llama.cpp" "/root/models/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-Q4_K_M.gguf" "天空为什么是蓝色的?" || exit 1
    #run_llama_cpp "/root/llama.cpp" "/root/models/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-Q5_K_M.gguf" "天空为什么是蓝色的?" || exit 1
    #run_llama_cpp "/root/llama.cpp" "/root/models/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-Q5_0.gguf"   "天空为什么是蓝色的?" || exit 1
    #run_llama_cpp "/root/llama.cpp" "/root/models/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-Q6_K.gguf"   "天空为什么是蓝色的?" || exit 1
    #run_llama_cpp "/root/llama.cpp" "/root/models/Qwen3-30B-A3B-GGUF/Qwen3-30B-A3B-Q8_0.gguf"   "天空为什么是蓝色的?" || exit 1

    run_llama_cpp_qwen3_30b_a3b_quant_models "Q4_K_M" "Q5_K_M" "Q5_0" "Q6_K" "Q8_0"
}

main "$@"
