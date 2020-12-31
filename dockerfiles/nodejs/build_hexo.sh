#!/bin/bash

cd /var/www/blog

# 更新代码
git pull && git submodule foreach git pull origin master

# 生成静态资源
npm install --force
# hexo clean
hexo g