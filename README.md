## linux_nginx_install_script
>centos nginx install shell script
>centos nginx 1.10.0 安装脚本

## if you need install other version. you can edit NGINX_VERSION
`vim nginx_install.sh`
*chang NGINX_VERSION="1.19.0"*

## you can change install path
`vim nginx_install.sh`
*chang NGINX_INSTALL_PATH="/your/path"*

oyzhi.conf config https and http/2.0
自带配置文件 oyzhi.com.conf 配置了https和http/2.0

## install 安装
```bash
chmod +x nginx_install.sh
sh ginx_install.sh
```

## go to /user/local/nginx 
`cd /user/local/nginx` 

## config file oyzhi.com.conf  
*using https and http/2 *
*根据自己喜好配置 这里默认带HTTPS HHTP/2*

## start nginx  启动nginx
`/etc/init.d/nginx start`

## cat lient prot  查看启动监听端口
`netstat -lnpt | grep nginx`
