## Modify OS Conf

```shell
# Use root account

useradd aioa
passwd aioa

chmod 640 /etc/sudoers
echo "aioa ALL=(ALL)   ALL" >> /etc/sudoers
chmod 440 /etc/sudoers


echo "net.ipv4.tcp_max_syn_backlog=2048" >> /etc/sysctl.conf
echo "net.core.somaxconn=2048" >> /etc/sysctl.conf
echo "vm.max_map_count=655360" >> /etc/sysctl.conf
echo "aioa soft nofile 655350" >> /etc/security/limits.conf
echo "aioa hard nofile 655350" >> /etc/security/limits.conf
echo "aioa soft memlock unlimited" >> /etc/security/limits.conf
echo "aioa hard memlock unlimited" >> /etc/security/limits.conf

sysctl -p


systemctl enable --now firewalld


# firewall-cmd --list-all
#
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.1" port protocol="tcp" port="3306" accept"
# firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="192.168.1.1" port protocol="tcp" port="3306" accept"
#
# firewall-cmd --reload
# firewall-cmd --list-all
```

## Install MySql

```shell
# Use root account

yum install mysql-server mysql-devel

systemctl enable --now mysqld

# sql: ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
# sql: CREATE DATABASE aioa;
# sql: CREATE USER 'aioa'@'localhost' IDENTIFIED BY 'aioa';
# sql: GRANT ALL PRIVILEGES ON aioa.* TO 'aioa'@'localhost';
```

* Add file [/etc/my.cnf.d/my.cnf](./config/my.cnf)

## Install Redis

```shell
# Use root account

yum install redis

systemctl enable --now redis
```

* Modify file [/etc/redis.conf](./config/redis.conf)

## Install Nginx

```shell
# Use root account

yum install nginx

systemctl enable --now nginx
```

* Modify file [/etc/nginx/nginx.conf](./config/nginx.conf)

## Install Python

```shell
# Use aioa account

curl -O https://repo.anaconda.com/archive/Anaconda3-2021.11-Linux-x86_64.sh
bash Anaconda3-2021.11-Linux-x86_64.sh
...

bash
conda create -n aioa python=3.9
conda env list
conda activate aioa
```

## Init env

```shell
# Use root account

cd /srv
mkdir aioa
chown -R aioa:aioa aioa

su aioa

conda activate aioa

cd /srv/aioa

# copy code .

pip install -r requirements
pip install gunicorn gevent

# modify setting.py(DATABASES, CACHES, ...)
# python manage.py makemigrations
python manage.py migrate

# modify setting.py DEBUG = False
python manage.py collectstatic

# exec init.sql

# start
gunicorn -c gunicorn.py aioa.wsgi

# stop
pstree -ap | grep gunicorn
kill -9 pid
```

* Add file [/srv/aioa/gunicorn.py](./config/gunicorn.py)

## Init DB

* See [init.sql](init.sql)
