mkdir -p /var/www/blog/themes
cd /var/www/blog
git clone https://github.com/fan-haobai/hexo-theme-yilia.git themes/yilia
cd themes && git pull && cd ..

npm install --force
hexo clean
hexo g
hexo s
