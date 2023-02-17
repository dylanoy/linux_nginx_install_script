#!/bin/bash
yum install openssl openssl-devel libxml2-devel libxslt-devel perl-devel perl-ExtUtils-Embed -y
NGINX_VERSION="1.23.3"
NGINX_INSTALL_PATH="/usr/local/nginx"
NGINX_LOG_PATH="/var/logs/nginx"

rm -rf nginx-${NGINX_VERSION}
if [ ! -f nginx-${NGINX_VERSION}.tar.gz ];then
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
fi
if [ ! -d $NGINX_INSTALL_PATH ];then
    mkdir -p $NGINX_INSTALL_PATH
fi
if [ ! -f pcre-10.42.tar.gz ];then
    wget -c http://git.typecodes.com/libs/php/pcre-10.42.tar.gz && tar -zxf pcre-10.42.tar.gz
fi
if [ ! -f zlib-1.2.13.tar.gz ];then
    wget -c http://git.typecodes.com/libs/nginx/zlib-1.2.13.tar.gz && tar -zxf zlib-1.2.13.tar.gz
fi

groupadd -r www && useradd -r -g www -s /bin/false -M www

tar zxvf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}
./configure --user=www \
--group=www \
--prefix=${NGINX_INSTALL_PATH} \
--with-http_stub_status_module \
--without-http-cache \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_gzip_static_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_xslt_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_random_index_module \
--with-http_degradation_module \
--with-http_secure_link_module \
--with-http_gzip_static_module \
--with-http_perl_module \
--with-pcre=../pcre-10.42 \
--with-zlib=../zlib-1.2.13 \
--with-debug \
--with-file-aio \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-ld-opt="-Wl,-E"
CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)
if [ $CPU_NUM -gt 1 ];then
    make -j$CPU_NUM
else
    make
fi
make install
mkdir -p ${NGINX_LOG_PATH}/access/
chmod 775 ${NGINX_LOG_PATH}
cat > /etc/init.d/nginx <<EOF
#!/bin/bash
# nginx Startup script for the Nginx HTTP Server
# this script create it by Zhi. at 2016.04.27
# if you find any errors on this scripts,please contact Zhi.
# and send mail to zhi@oyzhi.com.

nginxd=${NGINX_INSTALL_PATH}/sbin/nginx
nginx_config=${NGINX_INSTALL_PATH}/conf/nginx.conf
nginx_pid=${NGINX_LOG_PATH}/nginx.pid

RETVAL=0
prog="nginx"
[ -x \$nginxd ] || exit 0
# Start nginx daemons functions.
start() {
    if [ -e \$nginx_pid ] && netstat -tunpl | grep nginx &> /dev/null;then
        echo "nginx already running...."
        exit 1
    fi
    echo -n \$"Starting \$prog!"
    \$nginxd -c \${nginx_config}
    RETVAL=\$?
    echo
    [ \$RETVAL = 0 ] && touch /var/lock/nginx
    return \$RETVAL
}
# Stop nginx daemons functions.
stop() {
    echo -n \$"Stopping \$prog!"
    \$nginxd -s stop
    RETVAL=\$?
    echo
    [ \$RETVAL = 0 ] && rm -f /var/lock/nginx
}
# reload nginx service functions.
reload() {

    echo -n $"Reloading \$prog!"
    #kill -HUP \`cat \${nginx_pid}\`
    \$nginxd -s reload
    RETVAL=\$?
    echo
}
# See how we were called.
case "\$1" in
start)
        start
        ;;

stop)
        stop
        ;;

reload)
        reload
        ;;

restart)
        stop
        start
        ;;

*)
        echo $"Usage: \$prog {start|stop|restart|reload|help}"
        exit 1
esac
exit \$RETVAL
EOF
chmod 755 ${NGINX_INSTALL_PATH}/sbin/nginx
chmod +x /etc/init.d/nginx
mkdir -p ${NGINX_INSTALL_PATH}/conf/vhosts/
