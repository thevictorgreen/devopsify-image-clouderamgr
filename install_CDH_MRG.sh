#!/bin/bash

#### THESE COMMANDS INSTALL CLOUDERA MANAGER 6.3.1 ON A UBUNTU INSTANCE
#### RUN THE COMMANDS SEQUENTIALLY BY SECTION BY SECTION

#[ SECTION 1]
# Install Repository
wget -q --show-progress --https-only --timestamping https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/cloudera-manager.list
mv cloudera-manager.list /etc/apt/sources.list.d/
wget -q --show-progress --https-only --timestamping https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/archive.key
apt-key add archive.key
apt-get update

#[ SECTION 2]
# Install JDK
apt-get install oracle-j2sdk1.8
cat <<EOF > /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/jvm/java-8-oracle-cloudera/bin"
export JAVA_HOME=/usr/lib/jvm/java-8-oracle-cloudera
EOF
source /etc/environment

#[ SECTION 3]
# Install Clouder Manager Server
apt-get install cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

#[ SECTION 4]
# Enable Auto-TLS
#JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
/opt/cloudera/cm-agent/bin/certmanager setup --configure-services
ls /var/lib/cloudera-scm-server/certmanager

#[ SECTION 5]
# Install Databases
apt-get install mysql-server

#[ SECTION 6]
# Configure Database
systemctl stop mysql
mv /var/lib/mysql/ib_logfile0 /tmp
mv /var/lib/mysql/ib_logfile1 /tmp

cat <<EOF > /etc/mysql/my.cnf
[mysqld]
datadir=/var/lib/mysql
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0

key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MySQL, if you enable the binary log and do not set
#a server_id, MySQL will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

sql_mode=STRICT_ALL_TABLES
EOF

systemctl start mysql
systemctl status -l mysql

# Run Secure Server Installation
# Respond to the prompts bellow
#/usr/bin/mysql_secure_installation
#N
#pwd
#pwd
#Y
#N
#Y
#Y

#[ SECTION 7]
# Install Mysql Database Driver
apt-get install libmysql-java
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
/usr/share/java

#[ SECTION 8]
# Create Databases
mysql -uroot -p

CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON metastore.* TO 'hive'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY 'PASSWORD-HERE';

CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 'PASSWORD-HERE';

show databases;

SHOW GRANTS FOR 'oozie'@'%';

#/opt/cloudera/cm/schema/scm_prepare_database.sh <databaseType> <databaseName> <databaseUser> <password>
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm

# Install other Software
systemctl start cloudera-scm-server
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

#[ SECTION 9]
# Access Server Here
# server-fqdn:7180
