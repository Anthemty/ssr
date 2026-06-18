#!/bin/bash

# 设置工作目录
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ROOT_DIR="$(pwd)"

# 创建根目录下的链接
create_root_links() {
    ln -sf scripts/shadowsocks.sh run.sh
    ln -sf scripts/shadowsocks.sh stop.sh
    echo '#!/bin/bash' > logrun.sh
    echo 'exec ./scripts/shadowsocks.sh start -m m -l' >> logrun.sh
    echo '#!/bin/bash' > tail.sh
    echo 'exec ./scripts/shadowsocks.sh log -m m' >> tail.sh
    chmod +x *.sh
}

# 创建 shadowsocks 目录下的链接
create_shadowsocks_links() {
    cd shadowsocks
    ln -sf ../scripts/shadowsocks.sh run.sh
    ln -sf ../scripts/shadowsocks.sh stop.sh
    echo '#!/bin/bash' > logrun.sh
    echo 'exec ../scripts/shadowsocks.sh start -m a -l' >> logrun.sh
    echo '#!/bin/bash' > tail.sh
    echo 'exec ../scripts/shadowsocks.sh log -m a' >> tail.sh
    chmod +x *.sh
    cd ..
}

# 主函数
main() {
    # 创建脚本目录（如果不存在）
    mkdir -p scripts/lib
    
    # 设置权限
    chmod +x scripts/shadowsocks.sh
    chmod +x scripts/lib/common.sh
    
    # 创建链接
    create_root_links
    create_shadowsocks_links
    
    echo "Links created successfully."
}

main
