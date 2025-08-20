#!/bin/bash

#
# 描述: 一个用于从 OpenWrt 仓库批量查找并下载软件包的脚本。
#       通过命令行参数传入一个以空格分隔的软件包列表字符串。
# 用法: ./download_packages.sh "package1 package2 package3"
# 示例: ./download_packages.sh "luci-app-netspeedtest luci-i18n-netspeedtest-zh-cn"
#

# --- 配置 ---

# 目标仓库 URL
REPO_URL="https://dllkids.xyz/packages/x86_64/"

# 定义用于存放下载的 .ipk 文件的文件夹名称
DOWNLOAD_DIR="/home/build/immortalwrt/packages/"

# --- 参数检查 ---

# 检查用户是否提供了软件包列表字符串
if [ -z "$1" ]; then
  # 如果未提供参数，则打印用法说明并退出
  echo "错误: 请提供一个以空格分隔的软件包列表字符串。"
  echo "用法: $0 \"package1 package2 package3\""
  echo "示例: $0 \"luci-app-netspeedtest luci-i18n-netspeedtest-zh-cn\""
  exit 1
fi

# 将第一个参数（软件包列表字符串）赋值给 PACKAGE_STRING 变量
PACKAGE_STRING=$1

# --- 准备工作 ---

# 创建下载目录，如果它不存在的话
# 使用 -p 选项可以确保在父目录不存在时一并创建
mkdir -p "$DOWNLOAD_DIR"
echo "软件包将被下载到 '$DOWNLOAD_DIR' 文件夹中。"
echo "========================================"

# --- 主逻辑 ---

# 遍历传入的软件包列表字符串中的每一个软件包
# Bash 会自动根据空格将字符串分割成独立的包名
for PACKAGE_NAME in $PACKAGE_STRING; do
  echo "正在处理软件包: $PACKAGE_NAME"

  # 使用 curl 获取仓库页面的 HTML 内容，然后通过管道进行处理：
  # 1. `curl -s "$REPO_URL"`: 静默模式下获取 URL 内容。
  # 2. `grep -o 'href="[^"]*\.ipk"'`: 使用正则表达式提取所有指向 .ipk 文件的链接 (href 属性)。
  # 3. `sed 's/href="//;s/"//'`: 清理提取出的字符串，去掉 'href="' 和结尾的 '"'，只保留文件名。
  # 4. `grep "^${PACKAGE_NAME}_"`: 从所有 .ipk 文件名中，筛选出以您提供的软件包名开头（后跟下划线）的条目。
  # 5. `head -n 1`: 如果有多个匹配的版本，默认选择第一个（通常是最新的）。
  FULL_PKG_FILENAME=$(curl -s "$REPO_URL" | grep -o 'href="[^"]*\.ipk"' | sed 's/href="//;s/"//' | grep "^${PACKAGE_NAME}_" | head -n 1)

  # --- 结果处理 ---
  # 检查是否找到了匹配的软件包文件名
  if [ -n "$FULL_PKG_FILENAME" ]; then
    # 如果找到了，构建完整的下载 URL
    DOWNLOAD_URL="${REPO_URL}${FULL_PKG_FILENAME}"
    
    # 打印查找成功的信息
    echo "  ✅ 成功找到: $FULL_PKG_FILENAME"
    echo "     下载链接: $DOWNLOAD_URL"
    
    # 使用 wget 下载文件到指定的目录
    # -q: 静默模式
    # -P: 指定下载目录
    # -nc: 如果文件已存在，则不重新下载
    echo "     正在下载..."
    wget -q -nc -P "$DOWNLOAD_DIR" "$DOWNLOAD_URL"
    echo "     下载完成。"

  else
    # 如果没有找到匹配的软件包，打印错误信息
    echo "  ❌ 错误: 在仓库中未找到名为 '$PACKAGE_NAME' 的软件包。"
  fi
  echo "----------------------------------------"
done

echo "所有任务已完成。"
exit 0
