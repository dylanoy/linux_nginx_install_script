mkdir redis && cd redis

#Download Redis package and unpack
wget http://download.redis.io/releases/redis-3.2.1.tar.gz
tar -zxvf redis-3.2.1.tar.gz && cd redis-3.2.1

#Next step is to compile Redis with make utility and install
make && sudo make install clean

#Add user redis
sudo useradd -s /bin/false -d /var/lib/redis -M redis

#create Redis pid file directory
sudo mkdir /var/run/redis/ -p && sudo chown redis:redis /var/run/redis

#create Redis config directory
sudo mkdir /etc/redis && sudo chown redis:redis /etc/redis -Rf

#create Redis logs directory
sudo mkdir /var/log/redis/ -p && sudo chown redis:redis /var/log/redis/ -Rf

#create Redis config and put it to /etc/redis/redis.conf:
sudo cp redis.conf /etc/redis/redis.conf
sudo chown redis:redis /etc/redis/redis.conf

#Change parameters in config 
##start as a daemon in background
#daemonize yes
##where to put pid file
#pidfile /var/run/redis/redis.pid
#loglevel and path to log file
#loglevel warning
#logfile /var/log/redis/redis.log
##set port to listen for incoming connections, by default 6379
#port 6379
##set IP on which daemon will be listening for incoming connections
#bind 127.0.0.1
##where to dump database
#dir /var/lib/redis

#Start server
sudo -u redis /usr/local/bin/redis-server /etc/redis/redis.conf
