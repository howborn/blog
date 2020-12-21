FROM node:12-alpine

ADD build.sh build.sh
RUN echo "Asia/Shanghai" > /etc/timezone \
    && echo "https://mirrors.ustc.edu.cn/alpine/v3.9/main/" > /etc/apk/repositories  \
    && npm config set registry https://registry.npm.taobao.org \
    && apk add --no-cache git \
    && npm install hexo-cli -g \    
    && chmod 777 /build.sh

EXPOSE 4000

ENTRYPOINT ["sh", "/build.sh"]
