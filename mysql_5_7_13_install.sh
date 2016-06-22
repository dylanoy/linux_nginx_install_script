groupadd -r mysql && useradd -r -g mysql -s /bin/false -M mysql
yum -y install cmake ncurses-devel bison
wget -c http://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
tar -xvf boost_1_59_0.tar.gz && cd boost_1_59_0/
./bootstrap.sh
./b2 stage threading=multi link=shared
./b2 install threading=multi link=shared
cd ..
wget -c http://cdn.mysql.com/Downloads/MySQL-5.7/mysql-5.7.13.tar.gz
cmake \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql  \
-DMYSQL_DATADIR=/usr/local/mysql/data  \
-DSYSCONFDIR=/etc \
-DMYSQL_USER=mysql \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DMYSQL_UNIX_ADDR=/var/run/mysql/mysql.sock \
-DMYSQL_TCP_PORT=3306 \
-DENABLED_LOCAL_INFILE=1 \
-DENABLE_DOWNLOADS=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1  \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_DEBUG=0 \
-DMYSQL_MAINTAINER_MODE=0 \
-DWITH_SSL:STRING=bundled \
-DWITH_ZLIB:STRING=bundled

make && make install
echo -e '\n\nexport PATH=/usr/local/mysql/bin:$PATH\n' >> /etc/profile && source /etc/profile
makdir -p /usr/local/mysql/data
chown -R mysql:mysql /usr/local/mysql/data
chmod -R go-rwx /usr/local/mysql/data
mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
mkdir -p /var/run/mysql && mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql && chown -R mysql:mysql /var/run/mysql
cp /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
