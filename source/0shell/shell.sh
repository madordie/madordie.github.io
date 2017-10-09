#!/bin/bash

# ***
# 原本使用Xcode进行的工程管理，但是发现好坑。。Xcode的自动格式化代码复制的东西都乱掉了 55555
# 无奈我还是用脚本吧～ 反正运行也是贼方便
# ***

rm -rf .tmp-*
find `(pwd)`/../_posts/* -name "*.md" > .tmp-md_paths
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

cd ../../

opt='p'

if [ $opt = 's' ]; then
    hexo clean
    hexo s -g 
elif [ $opt = 'p' ]; then
    hexo clean
    hexo d -g
    python auto-push-sitemap.py
    git add .
    git commit -am "backup"
    git push https://github.com/madordie/madordie.github.io.git hexo
fi
