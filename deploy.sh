#!/bin/bash

# ***
# 原本使用Xcode进行的工程管理，但是发现好坑。。Xcode的自动格式化代码复制的东西都乱掉了 55555
# 无奈我还是用脚本吧～ 反正运行也是贼方便
# ***

# ----------- OPT ------------
opt='p'
# s: 本地server
# p: 部署远端server
# b: 备份
# ----------------------------

# 设置VPN
function setproxy() {
    # export {HTTP,HTTPS,FTP}_PROXY="http://127.0.0.1:3128" 也可以设置http代理
    export ALL_PROXY=socks5://127.0.0.1:1081
    echo "当前IP：`curl -s ip.sb`"
}

# 取消VPN
function unsetproxy() {
    # unset {HTTP,HTTPS,FTP}_PROXY
    unset ALL_PROXY
    echo "当前IP：`curl -s ip.sb`"
}

# 确认文章URL没有重复
function checkout_URLs() {
    rm -rf .tmp-*
    find `(pwd)`/_posts/* -name "*.md" > .tmp-md_paths
    cat .tmp-md_paths | while read line; do
        sed -n '/url: /p' ${line} | awk 'NR==1{print $2}' >> .tmp-urls
    done
    sort .tmp-urls | uniq > .tmp-uniq_urls
    mv .tmp-uniq_urls .tmp-urls

    if [ `cat .tmp-md_paths|wc -l` -ne `cat .tmp-urls|wc -l` ]; then
        echo "url可能有重复，请核对"
        cat .tmp-urls
        exit 1
    fi
    rm -rf .tmp-*
    echo -e ' --> 文章URL已校验.\n'    
}

# 备份
function backup() {
    echo "最后更新于:" `date` > README.md
    git add .
    git commit -am "backup"
    git push https://github.com/madordie/madordie.github.io.git hexo
    echo -e ' --> 已备份.\n'
}


# 操作序列
checkout_URLs
cd ./../
if [ $opt = 's' ]; then
    hexo clean
    hexo s -g 
elif [ $opt = 'b' ]; then
    backup
elif [ $opt = 'p' ]; then
    setproxy
    hexo clean
    hexo generate -d
    echo -e ' --> 已成功部署.\n'
    sleep 1
    unsetproxy
    python auto-push-sitemap.py
    echo -e ' --> 已上传站图.\n'
    setproxy
    backup
    cd ./source
    ruby comment.rb
    echo -e ' --> 评论已自动创建.\n'
fi

echo -e ' -->  所有操作已完成.'