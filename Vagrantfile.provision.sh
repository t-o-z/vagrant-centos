#filename: Vagrantfile.provision.sh
#!/usr/bin/env bash

# yumで必要なものインストール(mariadbは削除)
sudo yum remove mariadb-libs
sudo rm -rf /var/lib/mysql/
sudo yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
sudo yum -y install httpd mysql-community-server php php-mysql wget git curl vim
  
# ポート開放(SELinux無効化)
sudo systemctl restart firewalld
sudo firewall-cmd --permanent --zone=public --add-service=http 
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
sudo setenforce 0

# Apacheの起動、自動起動設定
sudo systemctl start httpd
sudo chkconfig httpd on

# PHPの設定ファイルのバックアップ、timezoneの設定
cp /etc/php.ini /etc/php.ini.org
sed -i -e "s/date\.timezone =/date\.timezone = Asia\/Tokyo/g" /etc/php.ini

# /etc/httpd/conf/httpd.confのバックアップと編集
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.org
sed -i -e "s/AllowOverride None/AllowOverride All/g" /etc/httpd/conf/httpd.conf

#Apachenのバージョン非表示
sed -i -e "s/ServerTokens OS/ServerTokens Prod/g" /etc/httpd/conf/httpd.conf 
lineNum=`sudo grep "AddType application/x-gzip .gz .tgz" -n /etc/httpd/conf/httpd.conf | cut -d ":" -f 1`
if [ $lineNum ]; then
  sudo sed -i -e "${lineNum}a \    AddType application/x-httpd-php .php" /etc/httpd/conf/httpd.conf
  lineNum=$((lineNum+1))
  sudo sed -i -e "${lineNum}a \    AddType application/x-httpd-php-source .phps" /etc/httpd/conf/httpd.conf
fi

# MySQLの起動と設定
sudo systemctl restart mysqld
 
# 必要最小限のMySQLの設定内容を書き込む
cat << __CONF__ >> /etc/my.cnf
character-set-server = utf8
default_password_lifetime = 0
__CONF__

# MySQLの自動起動を有効化し起動する
sudo systemctl enable mysqld
sudo systemctl start mysqld

# 変数定義 => MySQLの設定で必須
database=test_db
user=db_user
host_name=localhost
# 初期パスワードを取得する
password=`cat /var/log/mysqld.log | grep "A temporary password" | tr ' ' '\n' | tail -n1`
new_password=passwordPASSWORD@999

#sudo mysql -u root -p${password} --connect-expired-password -e "UPDATE mysql.user SET authentication_string=password('$new_password') WHERE user='root'"
sudo mysql -u root -p${password} --connect-expired-password -e "set password for root@localhost=password('${new_password}')"
sudo mysql -u root -p${new_password} --connect-expired-password -e "create database $database"
sudo mysql -u root -p${new_password} --connect-expired-password -e "grant all privileges on $database.* to $user@$host_name identified by '$new_password'"
sudo mysql -u root -p${new_password} --connect-expired-password < /vagrant/db/database.sql
 
# httpd.confの反映
sudo systemctl restart httpd
