

# Jenkins+Ansible+Gitlab 之 三剑客学习笔记

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



#### 4-Ansible简介

+ Ansible是一个开源部署工具
+ 开发语言：Python
+ 特点：SSH协议通讯，全平台，无需编译，模块化部署管理
+ 作用：推送playbook进行远程节点快速部署

不同

+ Chef

  Ruby语言编写，C/S架构，配置需要Git依赖，Recipe脚本编写规范，需要编程经验

+ Saltstack

  Python语言编写，C/S架构，模块化配置管理，YAML脚本编写规范，适合大规模集群部署

+ Ansible

  Python语言编写，无Client，模块化配置管理，PlayBook脚本编写规范，易于上手，适合中小规模快速部署





#### 5-Ansible的优势和应用场景

+ 轻量级无客户端
+ 开源免费，学习成本低，快速上手
+ 使用PlayBook作为核心配置架构，统一脚本格式批量化部署
+ 完善的模块化拓展，支持目前主流的开发场景
+ 强大的稳定性和兼容性（其开发语言为Linux自带的Python与SSH通信）
+ 活跃的官方社区问题讨论，方便Trubleshooting与DEBUG问题



#### 6-Ansible配合virtualenv安装配置

Python3.6+Ansible2.5

1. 预先安装Python3.6版本

   ~~~shell
   wget http://www.python.org/ftp/python/3.6.5/Python-3.6.5.tar.xz
   tar xf Python-3.6.5.tar.xz
   ~~~

   配置编译环境

   在运行下面这条命令时需保证机器具有gcc套件，如若没有则执行这条命令：yum install gcc

   ~~~shell
   [root@localhost Python-3.6.5]# ./configure --prefix=/usr/local --with-ensurepip=install --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
   ~~~

   编译,并将Python安装到/user/local目录下

   在编译成功之前遇到了一个问题，[解决办法](https://blog.csdn.net/u014749862/article/details/54430022)

   ~~~shell
   [root@localhost Python-3.6.5]# make && make altinstall
   ~~~

2. 安装virtualenv

   给pip做一个软链接

   ~~~shell
   [root@localhost Python-3.6.5]# which pip3.6
   /usr/local/bin/pip3.6
   [root@localhost bin]# ln -s /usr/local/bin/pip3.6 /usr/local/bin/pip
   ~~~

   在使用pip的时候报了这个错误：**pip is configured with locations that require TLS/SSL, however the ssl module in Python is not available.**

   [解决办法](https://blog.csdn.net/qq_25560423/article/details/62055497)

   解决之后现在就可以使用pip了

   ~~~shell
   [root@localhost Python-3.6.5]# pip install virtualenv
   ~~~

3. 创建Ansible账户并安装Python3.6版本virtualenv实例

   添加deploy用户并切换到该用户

   ~~~shell
   [root@localhost Python-3.6.5]# useradd deploy && su - deploy
   ~~~

   在该用户下创建virtualenv实例

   ~~~shell
   [deploy@localhost ~]$ virtualenv -p /usr/local/bin/python3.6 .py3-a2.5-env
   ~~~

4. Git源代码安装Ansible2.5

   ~~~shell
   [deploy@localhost ~]$ cd /home/deploy/.py3-a2.5-env/
   ~~~

   在使用Git之前要保证Git已经安装

   1. 检查Git是否安装

      which git

   2. 安装Git（在root用户下安装：切换用户 ：su - root）

      [root@localhost ~]# yum -y install git nss curl

   克隆源代码

   ~~~shell
   [deploy@localhost ~]$ git clone https://github.com/ansible/ansible.git
   ~~~

   cd ansible && git checkout stable-2.5

5. 加载Python3.6 virtualenv环境

   ~~~shell
   [deploy@localhost ~]$ source /home/deploy/.py3-a2.5-env/bin/activate
   ~~~

6. 安装Ansible依赖包

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ pip install paramiko PyYAML jinja2
   ~~~

   将Ansible移动到虚拟目录下

   ~~~java
   (.py3-a2.5-env) [deploy@localhost ~]$ pip install paramiko PyYAML jinja2
   ~~~

   将Ansible切换到2.5分支

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ cd .py3-a2.5-env/ansible/
   (.py3-a2.5-env) [deploy@localhost ansible]$ git checkout stable-2.5
   分支 stable-2.5 设置为跟踪来自 origin 的远程分支 stable-2.5。
   切换到一个新分支 'stable-2.5
   ~~~

7. 在Python3.6虚拟环境下加载Ansible2.5

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ansible]$ source /home/deploy/.py3-a2.5-env/ansible/hacking/env-setup -q
   ~~~

8. 验证Ansible

   ansible --version





#### 7-Ansible playbooks框架格式

+ Playbooks框架与格式

  inventory/	：Service详细清单目录

  ​	testenv	：具体清单与变量声明文件

  roles/	：roles任务列表

  ​	testbox/	：testbox详细任务

  ​		tasks/

  ​			main.yml	：testbox主任务文件

  deploy.yml	：Playbook任务入口文件

  + 详细目录testenv

    [testservers]		：Server组列表

    test.example.com

     

    [testservers:vars]	：Server组列表参数

    server_name=test.example.com

    user=root	：目标主机key/value参数

    output=/root/test.txt

  + 主任务文件main.yml

    name:Print server name and user to remote testbox	：任务名称

    shell:"echo 'Currently {{user}} is logging {{server_name}}' > {{output}}"

  + 任务入口文件deploy.yml

    hosts:"testservers"	：Server列表

    gather_facts:true		：获取Server基本信息

    remote_user			：目标服务器系统用户指定

    roles:

    -testbox				：进入roles/testbox任务目录




#### 8-Ansible使用入门

1. 切换为deploy用户

   ~~~shell
   [root@localhost ~]# su - deploy
   ~~~

2. 加载Python3.6的虚拟环境

   ~~~shell
   [deploy@localhost ~]$ source .py3-a2.5-env/bin/activate
   ~~~

3. 加载Ansible2.5到当前deploy用户

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ source .py3-a2.5-env/ansible/hacking/env-setup -q
   ~~~

4. 验证加载效果

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ ansible-playbook --version
   ~~~

5. 编写playbook框架

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ mkdir test_playbooks
   (.py3-a2.5-env) [deploy@localhost ~]$ cd test_playbooks/
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ mkdir inventory
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ mkdir roles
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ cd inventory/
   (.py3-a2.5-env) [deploy@localhost inventory]$ vi testenv
   ~~~

   testenv内容

   ~~~shell
   [testservers]
   test.example.com
   
   [testservers:vars]
   server_name=test.example.com
   user=root
   output=/root/test.txt
   ~~~

   编写main.yml

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost inventory]$ cd ..
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ ll
   总用量 0
   drwxrwxr-x 2 deploy deploy 21 1月   8 14:55 inventory
   drwxrwxr-x 2 deploy deploy  6 1月   8 14:52 roles
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ cd roles/
   (.py3-a2.5-env) [deploy@localhost roles]$ mkdir testbox
   (.py3-a2.5-env) [deploy@localhost roles]$ cd testbox/
   (.py3-a2.5-env) [deploy@localhost testbox]$ mkdir tasks
   (.py3-a2.5-env) [deploy@localhost testbox]$ cd tasks/
   (.py3-a2.5-env) [deploy@localhost tasks]$ vi main.yml
   ~~~

   main.yml内容

   ~~~yaml
   - name: Print server name and user to remote testbox
     shell: "echo 'Currently {{user}} is logining {{server_name}}' > {{output}}"
   ~~~

   编写deploy.yml文件内容

   ~~~yaml
   - hosts: "testservers"
     gather_facts: true
     remote_user: root
     roles:
       - testbox
   ~~~

   最终的playbook架构

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ tree .
   .
   ├── deploy.yml
   ├── inventory
   │   └── testenv
   └── roles
       └── testbox
           └── tasks
               └── main.yml
   
   ~~~

6. 手动添加dns解析：[root@localhost ~]# vi /etc/hosts

   ~~~shell
   127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
   ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
   192.168.25.140  test.example.com
   ~~~

7. 给deploy用户创建本地秘钥对

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ ssh-keygen -t rsa
   Generating public/private rsa key pair.
   Enter file in which to save the key (/home/deploy/.ssh/id_rsa): 
   Created directory '/home/deploy/.ssh'.
   Enter passphrase (empty for no passphrase): 
   Enter same passphrase again: 
   Your identification has been saved in /home/deploy/.ssh/id_rsa.
   Your public key has been saved in /home/deploy/.ssh/id_rsa.pub.
   The key fingerprint is:
   SHA256:48D0m+h52KfJtlXSSQGpTGxuzgH+Eisazbug9gYFeUQ deploy@localhost.localdomain
   The key's randomart image is:
   +---[RSA 2048]----+
   |  +E   .  .o.    |
   | o .  . + .  .   |
   |  o  ..* .  .    |
   |   . oo.*  o .   |
   |  .o  oBS.. +    |
   | .. + o+++ o     |
   |  oo o.++ .      |
   | o.o...o+o.      |
   |o o...oo=+       |
   +----[SHA256]-----+
   ~~~

   将公钥传送给远程部署机器，这要就可以免密码的远程部署

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ ssh-copy-id -i /home/deploy/.ssh/id_rsa.pub root@test.example.com
   /bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/deploy/.ssh/id_rsa.pub"
   The authenticity of host 'test.example.com (192.168.25.140)' can't be established.
   ECDSA key fingerprint is SHA256:J2giYr+TJ/DOpdnVdwve1mzQuCvoBJq9f2hPsEn9IK4.
   ECDSA key fingerprint is MD5:42:64:b6:d9:9e:ad:a5:3d:95:e1:94:1a:7e:6b:f1:b5.
   Are you sure you want to continue connecting (yes/no)? yes
   /bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
   /bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
   root@test.example.com's password: 
   
   Number of key(s) added: 1
   
   Now try logging into the machine, with:   "ssh 'root@test.example.com'"
   and check to make sure that only the key(s) you wanted were added.
   ~~~

   测试免密码登录

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost ~]$ ssh root@test.example.com
   Last login: Tue Jan  8 14:39:13 2019 from 192.168.25.1
   [root@localhost ~]# exit
   登出
   Connection to test.example.com closed.
   ~~~

8. 最终使用Ansible将指定内容部署到远程主机

   ~~~shell
   (.py3-a2.5-env) [deploy@localhost test_playbooks]$ ansible-playbook -i inventory/testenv ./deploy.yml 
   ~~~

9. 远程主机的部署效果

   ~~~shell
   [root@localhost ~]# ll
   总用量 8
   -rw-------. 1 root root 1241 1月   8 14:32 anaconda-ks.cfg
   -rw-r--r--. 1 root root   44 1月   8 15:43 test.txt
   [root@localhost ~]# cat test.txt 
   Currently root is logining test.example.com
   ~~~





#### 8-Ansible Playbooks常用模块

1. File模块

   在目标主机创建文件或目录，并赋予系统权限

   ~~~yaml
   - name:create a file
     file: 'path=/root/foo.txt state=touch mode=0755 owner=foo group=foo'
   ~~~

   name：定义任务名称，这里的任务名称是create a file

   file：表明调用的是file这个模块

   path：表示文件的具体路径及名称

   state=touch：表示要创建文件

   mode：对这个文件指定权限

   owner=foo：表示文件属于foo用户

   group=foo：表示文件是foo这个属组

2. Copy模块

   实现Ansible服务端到目标主机的文件传送

   ~~~yaml
   - name:copy a file
     copy: 'remote_scr=no src=roles/testbox/files/foo.sh dest=/root/foo.sh mode=0644 force=yes'
   ~~~

   copy：调用copy模块

   remote_src=no：表示将Ansible源主机的文件推送到远程目标主机

   src：源文件路径

   dest：目标主机文件路径

   mode：权限

   force=yes：定义当前这个copy任务强制执行

3. Stat模块

   获取远程文件状态信息，并保存到某个环境变量中供随后使用

   ~~~yaml
   - name: check if foo.sh exits
     stat: 'path=/root/foo.sh'
     register: script_sate
   ~~~

   stat：调用stat模块

   path：文件路径

   register：将获取到的文件信息赋值给环境变量script_stat

4. Debug模块

   打印语句到Ansible执行输出

   ~~~yaml
   - debug: msg=foo.sh exits
     when: script_stat.stat.exists
   ~~~

   msg：定义输出的语句

   上面这段脚本具体当script_stat所代表的文件存在时就输出语句 “foo.sh exits”

5. Command/Shell模块

   用来执行Linux目标主机命令行

   不同之处在于Shell模块可以调用Linux系统下的bin.bash

   推荐使用shell模块

   ~~~yaml
   - name: run the script
     command: "sh /root/foo.sh"
     
   - name: run the script
     shell: "echo 'test' > /root/test.txt"
   ~~~

6. Template模块

   实现Ansible服务端到目标主机的jinja2模板传送

   ~~~yaml
   - name: write the nginx config file
     template: scr=roles/testbox/templates/nginx.conf.j2 dest=/etc/nginx/nginx.conf
   ~~~

7. Packaging模块

   调用目标主机系统包管理工具（yum，apt）进行安装



   CentOS/Redhat系统

   ~~~yaml
   - name: ensure nginx is at the latest version
     yum: pkg=nginx state=latest
   ~~~

   Debain/Ubuntu系统

   ~~~yaml
   - name: ensure nginx is at the latest version
     apt: pkg=nginx state=latest
   ~~~

8. Service模块

   管理目标主机系统服务，通过调用系统的systemctl命令或者server

   ~~~yaml
   - name: start nginx service
     service: name=nginx state=started
   ~~~





#### 9-Jenkins安装配置管理

安装Jenkins前的环境准备

1. 添加yum仓库源，下载key验证仓库的安全性

   ~~~shell
   wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo
   rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
   ~~~

2. 保证系统java版本为8.0或以上

   ~~~shell
   yum -y install java
   ~~~

3. 关闭系统防火墙

4. 关闭SELINUX并重启系统



Jenkins安装与初始化配置

1. Yum源安装Jenkins最新版本

   ~~~shell
   yum install jenkins -y
   ~~~

2. 创建Jenkins系统用户

   ~~~shell
   useradd deploy
   ~~~

3. 更改Jenkins启动用户与端口

   ~~~shell
   vi /etc/sysconfig/jenkins 
   ~~~

   更改如下参数

   ~~~shell
   JENKINS_USER="deploy"
   JENKINS_PORT="8080"
   ~~~

   更改日志属组

   ~~~shell
   chown -R deploy:deploy /var/lib/jenkins/
   chown -R deploy:deploy /var/log/jenkins/
   ~~~

4. 启动Jenkins

   按上述步骤配置好后发现启动失败，查看日志有如下信息

   ~~~
   一月 11, 2019 11:23:29 上午 winstone.Logger logInternal
   严重: Container startup failed
   java.io.FileNotFoundException: /var/cache/jenkins/war/META-INF/MANIFEST.MF (权限不够)
   	at java.io.FileOutputStream.open0(Native Method)
   	at java.io.FileOutputStream.open(FileOutputStream.java:270)
   	at java.io.FileOutputStream.<init>(FileOutputStream.java:213)
   	at java.io.FileOutputStream.<init>(FileOutputStream.java:162)
   	at winstone.HostConfiguration.getWebRoot(HostConfiguration.java:278)
   	at winstone.HostConfiguration.<init>(HostConfiguration.java:81)
   	at winstone.HostGroup.initHost(HostGroup.java:66)
   	at winstone.HostGroup.<init>(HostGroup.java:45)
   	at winstone.Launcher.<init>(Launcher.java:169)
   	at winstone.Launcher.main(Launcher.java:354)
   	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
   	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
   	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
   	at java.lang.reflect.Method.invoke(Method.java:498)
   	at Main._main(Main.java:344)
   	at Main.main(Main.java:160)
   
   ~~~

   查看[博客](https://cloudofnines.blogspot.com/2014/09/jenkins-service-failed-to-startup-as.html)，添加如下命令：

   ~~~shell
   chown -R deploy:deploy /var/cache/jenkins/
   ~~~

   问题解决，成功启动



#### 10-Jenkins Job构建配置

+ 环境准备

  1. 配置Jenkins server本地GitLab DNS

  2. 安装git client，curl工具依赖

     yum install git curl -y

  3. 关闭Git http.sslVerify安全认证

     git config --system http.sslVerify false

  4. 添加Jenkins后台Git client user与email

  5. 添加Jenkins后台Git Credential凭据

+ Jenkins Freestyle与Pipeline Job区别

  + Freestyle Job：
    1. 需在页面添加模块配置项与参数完成配置
    2. 每个Job仅能实现一个开发功能
    3. 无法将配置代码化，不利于Job配置迁移与版本控制
    4. 逻辑相对简单，无需额外的学习成本
  + Pipeline Job
    1. 所有模块，参数配置都可以体现为一个pipeline脚本
    2. 可以定义多个stage构建一个管道工作集
    3. 所有配置代码化，方便job配置迁移与版本控制
    4. 需要pipeline语法基础



#### 11-Jenkins Pipeline Job编写规范

![Pipeline1](https://github.com/gangan786/JAG/blob/master/Image/Pipeline1.png?raw=true)

![2](https://github.com/gangan786/JAG/blob/master/Image/Pipeline2.png?raw=true)

![3](https://github.com/gangan786/JAG/blob/master/Image/Pipeline3.png?raw=true)

![4](https://github.com/gangan786/JAG/blob/master/Image/Pipeline4.png?raw=true)

![5](https://github.com/gangan786/JAG/blob/master/Image/Pipeline5.png?raw=true)

