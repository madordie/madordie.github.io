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
    echo ' --> 文章URL已校验.\n'
}

# 备份
function backup() {
    echo "最后更新于:" `date` > README.md

    git --git-dir=themes/next/.git --work-tree=themes/next/ rev-parse HEAD > themes/next.commit
    git --git-dir=themes/next/.git --work-tree=themes/next/ diff > themes/next.diff
    cp themes/next/source/images/avatar.gif themes/avatar.gif
    cp themes/next/source/images/favicon-32x32-next.png themes/favicon-32x32-next.png

    git add .
    git commit -am "backup"
    git push https://github.com/madordie/madordie.github.io.git hexo
    echo ' --> 已备份.\n'
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
    hexo clean
    hexo generate --deploy --force --bail
    echo ' --> 已成功部署.\n'
    sleep 1
    # # 这个脚本在这里：https://madordie.github.io/post/use-hexo-setup-blog/
    # python auto-push-sitemap.py
    # echo ' --> 已上传站图.\n'
    backup
    cd ./source
    ruby comment.rb
    echo ' --> 评论已自动创建.\n'
    sitemap=`mktemp`
    curl -s https://raw.githubusercontent.com/madordie/madordie.github.io/master/sitemap.xml | grep madordie.github.io | awk -v FS='<loc>|</loc>' '{print $2}' > sitemap
    curl -H 'Content-Type:text/plain' --data-binary @sitemap "http://data.zz.baidu.com/urls?site=https://madordie.github.io&token=`cat .baidu-token`"
fi

echo ' -->  所有操作已完成.'