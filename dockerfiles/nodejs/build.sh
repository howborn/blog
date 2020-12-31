#!/bin/bash

cd /var/www/blog

/bin/sh /build_hexo.sh
# webhook自动部署
webhook-cli --port 4000 --hooks hooks.json --verbose