#!/bin/bash

# ***
# 原本使用Xcode进行的工程管理，但是发现好坑。。Xcode的自动格式化代码复制的东西都乱掉了 55555
# 无奈我还是用脚本吧～ 反正运行也是贼方便
# ***

cd ../../

opt='p'

if [ $opt = 's' ]; then
    hexo clean
    hexo s -g 
elif [ $opt = 'n' ]; then
    hexo n 'mac-high-sierra-open-with-external'
elif [ $opt = 'p' ]; then
    hexo clean
    hexo d -g
    python auto-push-sitemap.py
    git add .
    git commit -am "backup"
    git push https://github.com/madordie/madordie.github.io.git hexo
fi
