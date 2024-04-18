FROM node:16-alpine

RUN echo "Asia/Shanghai" > /etc/timezone \
    && echo "https://mirrors.ustc.edu.cn/alpine/v3.9/main/" > /etc/apk/repositories
RUN npm config set registry https://registry.npm.taobao.org \
    && npm config set strict-ssl false \
    && apk add --no-cache git bash

RUN npm install hexo-cli -g \
    && npm install webhook-cli -g

ADD *.sh /
RUN chmod 777 /*.sh

EXPOSE 4000

ENTRYPOINT ["sh", "/start.sh"]
