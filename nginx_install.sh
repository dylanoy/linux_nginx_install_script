#!/bin/bash
yum install openssl openssl-devel libxml2-devel libxslt-devel perl-devel perl-ExtUtils-Embed -y
NGINX_VERSION="1.10.0"
NGINX_INSTALL_PATH="/usr/local/nginx"
NGINX_LOG_PATH="/var/logs/nginx"

rm -rf nginx-${NGINX_VERSION}
if [ ! -f nginx-${NGINX_VERSION}.tar.gz ];then
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
fi
if [ ! -d $NGINX_INSTALL_PATH ];then
    mkdir -p $NGINX_INSTALL_PATH
fi
if [ ! -f pcre-8.36.tar.gz ];then
    wget -c http://git.typecodes.com/libs/php/pcre-8.36.tar.gz && tar -zxf pcre-8.36.tar.gz
fi
if [ ! -f zlib-1.2.8.tar.gz ];then
    wget -c http://git.typecodes.com/libs/nginx/zlib-1.2.8.tar.gz && tar -zxf zlib-1.2.8.tar.gz
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
--with-pcre=../pcre-8.36 \
--with-zlib=../zlib-1.2.8 \
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

cat > ${NGINX_INSTALL_PATH}/conf/nginx.conf <<EOF
user www www;
worker_processes auto;
worker_rlimit_nofile 8192;
events {
  worker_connections 8000;
}
error_log  ${NGINX_LOG_PATH}/error.log warn;

# The file storing the process ID of the main process
pid        /var/run/nginx.pid;

http {

  # Hide nginx version information.
  server_tokens off;

  # Specify MIME types for files.
  include       mime.types;
  default_type  application/octet-stream;

  server_names_hash_bucket_size 128;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  client_max_body_size 8m;

  fastcgi_connect_timeout 300;
  fastcgi_send_timeout 300;
  fastcgi_read_timeout 300;
  fastcgi_buffer_size 64k;
  fastcgi_buffers 4 64k;
  fastcgi_busy_buffers_size 128k;
  fastcgi_temp_file_write_size 128k;

  # Update charset_types to match updated mime.types.
  # text/html is always included by charset module.
  charset_types text/css text/plain text/vnd.wap.wml application/javascript application/json application/rss+xml application/xml;

  # Include \$http_x_forwarded_for within default format used in log files
  log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

  # Log access to this file
  # This is only used when you don't override it on a server{} level
  access_log ${NGINX_LOG_PATH}/access/access.log main;

  # How long to allow each connection to stay idle.
  # Longer values are better for each individual client, particularly for SSL,
  # but means that worker connections are tied up longer.
  keepalive_timeout 20s;

  # Speed up file transfers by using sendfile() to copy directly
  # between descriptors rather than using read()/write().
  # For performance reasons, on FreeBSD systems w/ ZFS
  # this option should be disabled as ZFS's ARC caches
  # frequently used files in RAM by default.
  sendfile        on;

  # Don't send out partial frames; this increases throughput
  # since TCP frames are filled up before being sent out.
  tcp_nopush      on;

  # Enable gzip compression.
  gzip on;
  gzip_buffers     4 16k;
  gzip_disable msie6;

  # Compression level (1-9).
  # 5 is a perfect compromise between size and CPU usage, offering about
  # 75% reduction for most ASCII files (almost identical to level 9).
  gzip_comp_level    5;

  # Don't compress anything that's already small and unlikely to shrink much
  # if at all (the default is 20 bytes, which is bad as that usually leads to
  # larger files after gzipping).
  gzip_min_length    256;

  # Compress data even for clients that are connecting to us via proxies,
  # identified by the "Via" header (required for CloudFront).
  gzip_proxied       any;

  # Tell proxies to cache both the gzipped and regular version of a resource
  # whenever the client's Accept-Encoding capabilities header varies;
  # Avoids the issue where a non-gzip capable client (which is extremely rare
  # today) would display gibberish if their proxy gave them the gzipped version.
  gzip_vary          on;

  # Compress all output labeled with one of the following MIME-types.
  gzip_types
    application/atom+xml
    application/javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rss+xml
    application/vnd.geo+json
    application/vnd.ms-fontobject
    application/x-font-ttf
    application/x-web-app-manifest+json
    application/xhtml+xml
    application/xml
    font/opentype
    image/bmp
    image/svg+xml
    image/x-icon
    text/cache-manifest
    text/css
    text/plain
    text/vcard
    text/vnd.rim.location.xloc
    text/vtt
    text/x-component
    text/x-cross-domain-policy;

  include vhosts/*.conf
}
EOF
cat >> ${NGINX_INSTALL_PATH}/conf/mime.types <<EOF
types {

  # Data interchange

    application/atom+xml                  atom;
    application/json                      json map topojson;
    application/ld+json                   jsonld;
    application/rss+xml                   rss;
    application/vnd.geo+json              geojson;
    application/xml                       rdf xml;


  # JavaScript

    # Normalize to standard type.
    # https://tools.ietf.org/html/rfc4329#section-7.2
    application/javascript                js;


  # Manifest files

    application/manifest+json             webmanifest;
    application/x-web-app-manifest+json   webapp;
    text/cache-manifest                   appcache;


  # Media files

    audio/midi                            mid midi kar;
    audio/mp4                             aac f4a f4b m4a;
    audio/mpeg                            mp3;
    audio/ogg                             oga ogg opus;
    audio/x-realaudio                     ra;
    audio/x-wav                           wav;
    image/bmp                             bmp;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    image/png                             png;
    image/svg+xml                         svg svgz;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/webp                            webp;
    image/x-jng                           jng;
    video/3gpp                            3gp 3gpp;
    video/mp4                             f4p f4v m4v mp4;
    video/mpeg                            mpeg mpg;
    video/ogg                             ogv;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-mng                           mng;
    video/x-ms-asf                        asf asx;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;

    # Serving \`.ico\` image files with a different media type
    # prevents Internet Explorer from displaying then as images:
    # https://github.com/h5bp/html5-boilerplate/commit/37b5fec090d00f38de64b591bcddcb205aadf8ee

    image/x-icon                          cur ico;


  # Microsoft Office

    application/msword                                                         doc;
    application/vnd.ms-excel                                                   xls;
    application/vnd.ms-powerpoint                                              ppt;
    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;


  # Web fonts

    application/font-woff                 woff;
    application/font-woff2                woff2;
    application/vnd.ms-fontobject         eot;

    # Browsers usually ignore the font media types and simply sniff
    # the bytes to figure out the font type.
    # https://mimesniff.spec.whatwg.org/#matching-a-font-type-pattern
    #
    # However, Blink and WebKit based browsers will show a warning
    # in the console if the following font types are served with any
    # other media types.
    application/x-font-ttf                ttc ttf;
    font/opentype                         otf;
  # Other
    application/java-archive              ear jar war;
    application/mac-binhex40              hqx;
    application/octet-stream              bin deb dll dmg exe img iso msi msm msp safariextz;
    application/pdf                       pdf;
    application/postscript                ai eps ps;
    application/rtf                       rtf;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/vnd.wap.wmlc              wmlc;
    application/x-7z-compressed           7z;
    application/x-bb-appworld             bbaw;
    application/x-bittorrent              torrent;
    application/x-chrome-extension        crx;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-opera-extension         oex;
    application/x-perl                    pl pm;
    application/x-pilot                   pdb prc;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            crt der pem;
    application/x-xpinstall               xpi;
    application/xhtml+xml                 xhtml;
    application/xslt+xml                  xsl;
    application/zip                       zip;
    text/css                              css;
    text/html                             htm html shtml;
    text/mathml                           mml;
    text/plain                            txt;
    text/vcard                            vcard vcf;
    text/vnd.rim.location.xloc            xloc;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/vtt                              vtt;
    text/x-component                      htc;
}
EOF
mkdir -p ${NGINX_INSTALL_PATH}/conf/vhosts/
cat > ${NGINX_INSTALL_PATH}/conf/vhosts/oyzhi.con.conf <<EOF
    #
    # Redirect all www to non-www
    #
    server {
            listen               *:80;
            listen               *:443 ssl http2;
            server_name www.oyzhi.com;
            ssl_certificate ${NGINX_INSTALL_PATH}/nginx/ssl/oyzhi.com.crt;
            ssl_certificate_key ${NGINX_ISNTALL_PATH}/nginx/ssl/oyzhi.com.key;
            access_log off;

            #do not gen log accessing favicon.ico and robots.txt
            location = /favicon.ico {
                root html;
                expires max;
                log_not_found off;
                break;
            }
            location = /robots.txt {
                root html;
                expires max;
                log_not_found off;
                break;
            }

            location / {
                return 301 https://oyzhi.com\$request_uri;
            }
    }

    #
    # Redirect all non-encrypted to encrypted
    #
    server {
            listen               *:80;
            server_name          oyzhi.com;
            access_log off;

            #do not gen log accessing favicon.ico and robots.txt
            location = /favicon.ico {
                root html;
                expires max;
                log_not_found off;
                break;
            }
            location = /robots.txt {
                root html;
                expires max;
                log_not_found off;
                break;
            }

            location / {
                return 301 https://oyzhi.com\$request_uri;
            }
    }

    #
    # HTTPS server
    #
    server {
            listen               *:443 ssl http2;
            server_name          oyzhi.com;

            ssl_certificate /myService/server/nginx/ssl/oyzhi.com.crt;
            ssl_certificate_key /myService/server/nginx/ssl/oyzhi.com.key;
            ssl_session_cache shared:SSL:10m;
            ssl_session_timeout 10m;


            # proxy to Nodejs listening on 127.0.0.1:8000
            #
            location / {
            proxy_pass   http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            }

    }
EOF
