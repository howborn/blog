#!/bin/bash

# 杀掉前台进程后会自动重启
netstat -tnpl | grep :4000 | awk '{print $7}' | awk -F '/' '{print $1}' | xargs kill