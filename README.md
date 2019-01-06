### Jenkins+Ansible+Gitlab 之 三剑客学习笔记

#### 1-GitLab介绍

1. 什么是GitLab
   + GitLab是一个开源分布式版本控制系统
   + 开发语言：Ruby
   + 功能：可以通过WEB界面管理项目源代码，版本控制，代码复用与查找
2. GitLab与GitHub的不同
   + GitHub分布式在线代码托管仓库，个人版本可直接在线免费使用，企业版本收费且需要服务器安装
   + GitLab分布式在线代码仓库托管软件，分社区免费版与企业收费版本，都需要服务器安装，适合中小型公司免费创建私有仓库
3. GitLab的优势和应用场景
   + 开源免费，适合中小型公司将代码放置在该系统中，如果需要对GitLab进行二次开发，获取一些第三方的一些集成服务以及没有宕机时间的系统升级服务，可以随时购买他的服务许可证，原地无缝的从社区版升级为企业版
   + 差异化的版本管理，离线同步以及强大分支管理功能
   + 便捷的GUI操作界面以及强大账户权限管理功能
   + 集成度很高，能集成觉大部分的开发工具
   + 支持内置HA，保证在高并发下仍旧实现高可用性
4. GitLab主要服务构成
   + Nginx静态Web服务器
   + GitLab-workhorse轻量级的反向代理服务器
   + GitLab-shell 用于处理Git命令和修改authorized keys列表
   + Logrotate 日志文件管理文件
   + Postgresql数据库
   + Redis缓存服务器



#### 2-GitLab的工作流程

1. 创建并克隆项目

2. 创建项目某Feature分支

   在任务初始阶段，项目主管会将任务划分并创建对应的分支，并将分支以任务的形式下发给对应的码农

3. 编写代码并提交至该分支

4. 推送该项目分支至远程GitLab服务器

5. 进行代码检查并提交Master主分支合并申请

6. 项目领导审查代码并确认合并申请



#### 3-GitLab安装配置管理

##### 安装GitLab前系统预配置准备工作（CentOS 7）

1. 关闭firewalld防火墙
   + systemctl stop firewalld
   + systemctl disable firewalld

2. 关闭SELINUX并重启系统

   + vi  /etc/sysconfig/selinux

     ...

     SELINUX=disabled

     ...

     reboot   重启

##### 安装Omnibus GitLab-ce package

1. 安装GitLab组件 

   yum -y install curl policycoreutils openssh-server openssh-clients postfix

2. 配置yum仓库

   curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash

3. 启动postfix邮件服务

   systemctl start postfix && systemctl enable postfix

4. 安装GitLab-ce社区版本

   yum install -y gitlab-ce

##### Omnibus GitLab等相关配置初始化并完成安装

1. 证书创建与配置加载

2. Nginx SSL 代理服务配置

3. 初始化GitLab相关服务并完成安装

   ~~~shell
   mkdir -p /etc/gitlab/ssl
   openssl genrsa -out "/etc/gitlab/ssl/gitlab.example.com.key" 2048
   openssl req -new -key "/etc/gitlab/ssl/gitlab.example.com.key" -out "/etc/gitlab/ssl/gitlab.example.com.csr"
   openssl x509 -req -days 3650 -in "/etc/gitlab/ssl/gitlab.example.com.csr" -signkey "/etc/gitlab/ssl/gitlab.example.com.key" -out "/etc/gitlab/ssl/gitlab.example.com.crt"
   openssl dhparam -out /etc/gitlab/ssl/dhparams.pem 2048
   ~~~



