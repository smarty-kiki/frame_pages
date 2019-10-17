# 开发环境
框架中内置了一套基于 [debian_php_dev_env](https://github.com/smarty-kiki/debian_php_dev_env) 的 `docker` 的开发环境，对 `linux`、`mac` 用户格外友好，使用有如下两个步骤：

## 1. 安装 Docker 环境
安装包及过程参考 [Docker 官网](https://hub.docker.com/search/?type=edition&offering=community)

## 2. 开发机上安装 git
建议网上自行搜索，`mac` 操作系统自带

## 3. 在开发机执行框架目录中的环境启动脚本
```bash
sh project/tool/start_dev_server.sh
```
这个脚本会自动拉取项目依赖的框架、`pull` 开发环境镜像、启动开发环境容器最终进入到开发环境中的 `tmux` 窗口

此步骤完毕就可以在浏览器中打开 [http://127.0.0.1/](http://127.0.0.1/) 看到 'hello world' 了，容器同时映射了 `3306` 端口到开发机，可以直接使用客户端工具连接 `127.0.0.1` 的 `3306` 端口来操作数据库。如果需要停止开发环境的使用，直接在该脚本终端按 `ctrl+c` 终止脚本，每次脚本启动是一个全新的容器，如若需要进入容器进行操作，可使用 `docker exec` 命令，如:
```bash
docker exec -ti api_frame /bin/bash
```
其中 `api_frame` 为容器名
