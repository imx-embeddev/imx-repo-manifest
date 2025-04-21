#!/bin/bash

# 自动安装 Repo 工具（支持多镜像源 + 自动生效环境变量）
# 作者: sumu
# 版本: 1.3

set -e

# 颜色和日志标识
# ========================================================
# |  ---  | 黑色  | 红色 |  绿色 |  黄色 | 蓝色 |  洋红 | 青色 | 白色  |
# | 前景色 |  30  |  31  |  32  |  33  |  34  |  35  |  35  |  37  |
# | 背景色 |  40  |  41  |  42  |  43  |  44  |  45  |  46  |  47  |
# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 可用的emoji符号
# ========================================================
function usage_emoji()
{
    echo -e "⚠️ ✅ 🚩 📁 🕣️"
}

# 功能实现
# ========================================================
# 定义下载源列表（按优先级排序）
REPO_SOURCES=(
    "https://storage.googleapis.com/git-repo-downloads/repo"      # 官方源
    "https://mirrors.tuna.tsinghua.edu.cn/git/git-repo"          # 清华源
)

# 检查 repo 是否安装
if command -v repo &> /dev/null; then
    echo -e "✅ repo 已安装，版本如下:${NC}"
    repo --version
    exit 1
fi

# 检查 Git 是否安装
if ! command -v git &> /dev/null; then
    echo -e "${RED}错误: Git 未安装！${NC}"
    echo "请先安装 Git: "
    echo "  Ubuntu/Debian: sudo apt install git"
    exit 1
fi

# 创建 bin 目录
REPO_BIN_DIR="$HOME/2software/repo_bin"
mkdir -pv "$REPO_BIN_DIR"
REPO_PATH="$REPO_BIN_DIR/repo"

# 智能下载函数
download_repo() {
    local attempt=1
    for url in "${REPO_SOURCES[@]}"; do
        echo -e "${YELLOW}尝试下载源 [$attempt/${#REPO_SOURCES[@]}]: ${url}${NC}"
        
        if curl -L --connect-timeout 30 --retry 2 "$url" -o "$REPO_PATH"; then
            echo -e "✅ ${GREEN}√ 下载成功${NC}"
            return 0
        else
            echo -e "${RED}× 下载失败，尝试下一个源...${NC}"
            ((attempt++))
            sleep 1
        fi
    done
    
    echo -e "\n${RED}所有下载源均失败！已尝试以下地址: ${NC}"
    printf "  - %s\n" "${REPO_SOURCES[@]}"
    return 1
}

# 执行下载
if ! download_repo; then
    echo -e "\n${RED}错误: Repo 工具下载失败！${NC}"
    echo "可能原因: "
    echo "1. 网络连接问题"
    echo "2. 所有镜像源暂时不可用"
    echo "3. 防火墙限制（请检查公司/校园网络）"
    exit 1
fi

# 设置可执行权限
chmod a+x "$REPO_PATH"
echo -e "${GREEN}Repo 已安装至: ${REPO_PATH}${NC}"

# 配置环境变量（兼容多 Shell）
SHELL_CONFIGS=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")
modified_configs=()  # 记录被修改的配置文件

for config in "${SHELL_CONFIGS[@]}"; do
    if [[ -f "$config" ]] && ! grep -q "$REPO_BIN_DIR" "$config"; then
        echo "export PATH=\"$REPO_BIN_DIR:\$PATH\"" >> "$config"
        modified_configs+=("$config")
        echo -e "${YELLOW}已更新环境变量: $config${NC}"
    fi
done

# 自动加载更新的环境变量
if [ ${#modified_configs[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}正在激活新环境变量...${NC}"
    for config in "${modified_configs[@]}"; do
        # 安全加载: 仅导入 PATH 变量，避免执行其他代码
        if grep -q "export PATH=.*$REPO_BIN_DIR" "$config"; then
            source "$config"
            echo -e "✅ ${GREEN}已生效: $config${NC}"
        else
            echo -e "${RED}警告: $config 中未找到有效 PATH 配置，请手动检查！${NC}"
        fi
    done
else
    echo -e "${YELLOW}环境变量无需修改，直接使用当前配置${NC}"
fi

# 验证安装（最终检查）
echo -e "\n${YELLOW}验证安装...${NC}"
if repo --version &> /dev/null; then
    echo -e "✅ ${GREEN}Repo 安装成功！${NC}"
else
    echo -e "${RED}安装验证失败，请检查: ${NC}"
    echo "1. 手动执行命令临时生效: export PATH=\"$REPO_BIN_DIR:\$PATH\""
    echo "2. 重启终端或运行: source ~/.bashrc 或 source ~/.zshrc"
    exit 1
fi
