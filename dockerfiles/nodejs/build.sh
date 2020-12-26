#!/bin/bash

cd /var/www/blog

npm install --force
hexo clean
hexo g
hexo s