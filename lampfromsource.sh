#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  RedHat 6.4
#   Description:  Install LAMP(Linux + Apache + MySQL + PHP ) for Redhat
#===============================================================================================

clear
echo "#############################################################"
echo "# LAMP Auto Install Script Redhat"
echo "#############################################################"
echo ""

# Install time state
StartDate='';
StartDateSecond='';
# Get IP address
IP=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.*' | cut -d: -f2 | awk '{ print $1}' | head -1`;
# Version
MySQLVersion='mysql-5.6.19';
PHPVersion='php-5.4.29';
ApacheVersion='httpd-2.4.9';
#phpMyAdminVersion='phpMyAdmin-4.2.2-all-languages';
aprVersion='apr-1.5.1';
aprutilVersion='apr-util-1.5.3';
libiconvVersion='libiconv-1.14';
libmcryptVersion='libmcrypt-2.5.8';
mhashVersion='mhash-0.9.9.9';
mcryptVersion='mcrypt-2.6.8';
re2cVersion='re2c-0.13.6';
pcreVersion='pcre-8.35';
libeditVersion='libedit-20140213-3.1';

#===============================================================================================
#Description:Install LAMP Script.
#Usage:install_lamp
#===============================================================================================
function install_lamp(){
    rootness
    disable_selinux
    add_repo
    pre_installation_settings
    download_files "${MySQLVersion}.tar.gz"
    download_files "${PHPVersion}.tar.gz"
    download_files "${ApacheVersion}.tar.gz"
    #download_files "${phpMyAdminVersion}.tar.gz"
    download_files "${aprVersion}.tar.gz"
    download_files "${aprutilVersion}.tar.gz"
    download_files "${libiconvVersion}.tar.gz"
    download_files "${libmcryptVersion}.tar.gz"
    download_files "${mhashVersion}.tar.gz"
    download_files "${mcryptVersion}.tar.gz"
    download_files "${re2cVersion}.tar.gz"
    download_files "${pcreVersion}.tar.gz"
    download_files "${libeditVersion}.tar.gz"
    #Untar all files
    if [ -d $cur_dir/untar ]; then
        rm -rf $cur_dir/untar
    fi
    mkdir -p $cur_dir/untar
    echo "Untar all files, please wait a moment......"
    for file in `ls *.tar.gz` ;
    do
        tar -zxf $file -C $cur_dir/untar
    done
    echo "Untar all files completed!"
    install_pcre
    install_apache
    install_mysql
    install_libiconv
    install_libmcrypt
    install_mhash
    install_mcrypt
    install_re2c
    install_libedit
    install_php
    #install_phpmyadmin
    vhost_add
    cp -f $cur_dir/lamp.sh /usr/bin/lamp
    cp -f $cur_dir/conf/httpd.logrotate /etc/logrotate.d/httpd
    sed -i '/Order/,/All/d' /usr/bin/lamp
    sed -i "/AllowOverride All/i\Require all granted" /usr/bin/lamp
    #Clean up
    rm -rf $cur_dir/untar
    add
    clear
    #Install completed or not 
    if [ -s /usr/local/apache ] && [ -s /usr/local/php ] && [ -s /usr/local/mysql ]; then
        echo ""
        echo 'Congratulations, LAMP install completed!'
        echo "Your Default Website: http://${IP}"
        echo 'Default WebSite Root Dir: /data/www/default'
        echo 'Apache Dir: /usr/local/apache'
        echo 'PHP Dir: /usr/local/php'
        echo "MySQL root password:$mysqlrootpwd"
        echo "MySQL data location:$mysqldata"
        echo -e "Installed Apache version:\033[41;37m ${ApacheVersion} \033[0m"
        echo -e "Installed MySQL version:\033[41;37m ${MySQLVersion} \033[0m"
        echo -e "Installed PHP version:\033[41;37m ${PHPVersion} \033[0m"
        echo -e "Installed phpMyAdmin version:\033[41;37m ${phpMyAdminVersion} \033[0m"
        echo ""
        echo "Start time: ${StartDate}"
        echo -e "Completion time: $(date) (Use:\033[41;37m $[($(date +%s)-StartDateSecond)/60] \033[0m minutes)"
        echo "Enjoy it! ^_^"
        echo ""
    else
        echo ""
        echo 'Sorry, Failed to install LAMP!';
    fi
}

#===============================================================================================
#Description:Make sure only root can run our script
#Usage:rootness
#===============================================================================================
function rootness(){
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}

#===============================================================================================
#Description:Disable selinux
#Usage:disable_selinux
#===============================================================================================
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

#===============================================================================================
#Description:Pre-installation settings.
#Usage:pre_installation_settings
#===============================================================================================
function pre_installation_settings(){
    #Set MySQL root password
    echo "Please input the root password of MySQL:"
    read -p "(Default password: root):" mysqlrootpwd
    if [ "$mysqlrootpwd" = "" ]; then
        mysqlrootpwd="root"
    fi
    echo "MySQL password:$mysqlrootpwd"
    echo "####################################"
    #Define the MySQL data location.
    echo "Please input the MySQL data location:"
    read -p "(leave blank for /usr/local/mysql/data):" mysqldata
    [ "$mysqldata" = "" ] && mysqldata="/usr/local/mysql/data"
    echo "MySQL data location:$mysqldata"
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    #CPU Number
    Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`;
    #Remove Packages
    rpm -e --nodeps httpd
    rpm -e --nodeps mysql
    rpm -e --nodeps php
    yum -y remove httpd
    yum -y remove mysql
    yum -y remove php
    #Set timezone
    #rm -f /etc/localtime
    #ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    yum -y install ntp
    #ntpdate -d cn.pool.ntp.org
    StartDate=$(date);
    StartDateSecond=$(date +%s);
    echo "Start time: ${StartDate}";
    #Install necessary tools
    if [ ! -s /etc/yum.conf.bak ]; then
        cp /etc/yum.conf /etc/yum.conf.bak
    fi
    sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
    packages="wget autoconf automake bison bzip2 bzip2-devel curl curl-devel cmake cpp crontabs diffutils elinks e2fsprogs-devel expat-devel file flex freetype-devel gcc gcc-c++ gd glibc-devel glib2-devel gettext-devel gmp-devel icu kernel-devel libaio libtool-libs libjpeg-devel libpng-devel libxslt libxslt-devel libxml2 libxml2-devel libidn-devel libcap-devel libtool-ltdl-devel libmcrypt-devel libc-client-devel libicu libicu-devel zip zlib-devel unzip patch mlocate make ncurses-devel readline readline-devel vim-minimal sendmail pam-devel pcre pcre-devel openldap openldap-devel openssl openssl-devel perl-DBD-MySQL"
    for package in $packages;
    do yum -y install $package; done
    #Current folder
    cur_dir=`pwd`
    cd $cur_dir
}

#===============================================================================================
#Description:download files.
#Usage:download_files [filename]
#===============================================================================================
function download_files(){
if [ -s $1 ]; then
    echo "$1 [found]"
else
    echo "$1 not found!!!download now......"
    if ! wget -c https://s3-eu-west-1.amazonaws.com/panda-req-redhat/$1;then
        echo "Failed to download $1,please download it to "$cur_dir" directory manually and try again."
        exit 1
    fi
fi
}

#===============================================================================================
#Description:Install Apache.
#Usage:install_apache
#===============================================================================================
function install_apache(){
    if [ ! -d /usr/local/apache/bin ];then
        #Install Apache
        echo "Start Installing ${ApacheVersion}"
        mv $cur_dir/untar/$aprVersion $cur_dir/untar/$ApacheVersion/srclib/apr
        mv $cur_dir/untar/$aprutilVersion $cur_dir/untar/$ApacheVersion/srclib/apr-util
        cd $cur_dir/untar/$ApacheVersion
        ./configure \
        --prefix=/usr/local/apache \
        --with-pcre=/usr/local/pcre \
        --with-mpm=prefork \
        --with-included-apr \
        --enable-so \
        --enable-dav \
        --enable-deflate=shared \
        --enable-ssl=shared \
        --enable-expires=shared  \
        --enable-headers=shared \
        --enable-rewrite=shared \
        --enable-static-support \
        --enable-modules=all \
        --enable-mods-shared=all
        make -j $Cpunum
        make install
        if [ $? -ne 0 ]; then
            echo "Installing Apache failed."
            exit 1
        fi
        cp -f $cur_dir/conf/httpd.init /etc/init.d/httpd
        chmod +x /etc/init.d/httpd
        chkconfig --add httpd
        chkconfig httpd on
        rm -rf /etc/httpd
        ln -s /usr/local/apache/ /etc/httpd
        cd /usr/sbin/
        ln -fs /usr/local/apache/bin/httpd
        ln -fs /usr/local/apache/bin/apachectl
        cd /var/log
        rm -rf httpd/
        ln -s /usr/local/apache/logs httpd
        groupadd apache
        useradd -g apache apache
        mkdir -p /data/www/default/
        chmod -R 755 /data/www/default/
        #Copy to config files
        cp -f $cur_dir/conf/httpd2.4.conf /usr/local/apache/conf/httpd.conf
        cp -f $cur_dir/conf/httpd-vhosts.conf /usr/local/apache/conf/extra/httpd-vhosts.conf
        cp -f $cur_dir/conf/httpd-default.conf /usr/local/apache/conf/extra/httpd-default.conf
        mkdir -p /usr/local/apache/conf/vhost/
        touch /usr/local/apache/conf/vhost/none.conf
        cp -f $cur_dir/conf/index.html /data/www/default/index.html
        cp -f $cur_dir/conf/lamp.gif /data/www/default/lamp.gif
        cp -f $cur_dir/conf/p.php /data/www/default/p.php
        cp -f $cur_dir/conf/jquery-1.11.1.min.js /data/www/default/jquery-1.11.1.min.js
        cp -f $cur_dir/conf/phpinfo.php /data/www/default/phpinfo.php
        echo "${ApacheVersion} Install completed!"
    else
        echo "Apache had been installed!"
    fi
}
#===============================================================================================
#Description:install mysql.
#Usage:install_mysql
#===============================================================================================
function install_mysql(){
    if [ ! -d /usr/local/mysql ];then
        #install MySQL
        echo "Start Installing ${MySQLVersion}"
        cd $cur_dir/
        /usr/sbin/groupadd mysql
        /usr/sbin/useradd -s /sbin/nologin -M -g mysql mysql
        cd $cur_dir/untar/$MySQLVersion
        cmake \
        -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
        -DDEFAULT_CHARSET=utf8 \
        -DDEFAULT_COLLATION=utf8_general_ci \
        -DWITH_EXTRA_CHARSETS=complex \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_READLINE=1 \
        -DENABLED_LOCAL_INFILE=1
        make -j $Cpunum
        make install
        if [ $? -ne 0 ]; then
            echo "Installing MySQL failed."
            exit 1
        fi
        chmod +w /usr/local/mysql
        chown -R mysql:mysql /usr/local/mysql
        cd support-files/
        cp -f $cur_dir/conf/my5.6.cnf /etc/my.cnf
        cp -f mysql.server /etc/init.d/mysqld
        sed -i "s:^datadir=.*:datadir=$mysqldata:g" /etc/init.d/mysqld
        /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=$mysqldata --user=mysql
        chmod +x /etc/rc.d/init.d/mysqld
        chkconfig --add mysqld
        chkconfig  mysqld on
        cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
        ldconfig
        if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
            ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql
        else
            ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
        fi
        for i in `ls /usr/local/mysql/bin`
        do
            if [ ! -L /usr/bin/$i ]; then
                ln -s /usr/local/mysql/bin/$i /usr/bin/$i
            fi
        done
        #Start mysqld service
        service mysqld start
        /usr/local/mysql/bin/mysqladmin password $mysqlrootpwd
        mysql -uroot -p$mysqlrootpwd <<EOF
drop database if exists test;
delete from mysql.user where user='';
update mysql.user set password=password('$mysqlrootpwd') where user='root';
delete from mysql.user where not (user='root') ;
flush privileges;
exit
EOF
        echo "${MySQLVersion} Install completed!"
    else
        echo "MySQL had been installed!"
    fi
}

#===============================================================================================
#Description:install pcre.
#Usage:install_pcre
#===============================================================================================
function install_pcre(){
    cd $cur_dir/untar/$pcreVersion
    ./configure --prefix=/usr/local/pcre
    make && make install
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        ln -s /usr/local/pcre/lib /usr/local/pcre/lib64
    fi
    [ -d "/usr/local/pcre/lib" ] && export LD_LIBRARY_PATH=/usr/local/pcre/lib:$LD_LIBRARY_PATH
    [ -d "/usr/local/pcre/bin" ] && export PATH=/usr/local/pcre/bin:$PATH
    echo "${pcreVersion} install completed!"
}

#===============================================================================================
#Description:install libiconv.
#Usage:install_libiconv
#===============================================================================================
function install_libiconv(){
    cd $cur_dir/untar/$libiconvVersion
    ./configure --prefix=/usr/local
    make && make install
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        ln -s /usr/local/lib/libiconv.so.2 /usr/lib64/libiconv.so.2
    fi
    ln -s /usr/local/lib/libiconv.so.2 /usr/lib/libiconv.so.2
    echo "${libiconvVersion} install completed!"
}

#===============================================================================================
#Description:install libmcrypt.
#Usage:install_libmcrypt
#===============================================================================================
function install_libmcrypt(){
    cd $cur_dir/untar/$libmcryptVersion
    ./configure
    make && make install
    echo "${libmcryptVersion} install completed!"
}

#===============================================================================================
#Description:install mhash.
#Usage:install_mhash
#===============================================================================================
function install_mhash(){
    cd $cur_dir/untar/$mhashVersion
    ./configure
    make && make install
    echo "${mhashVersion} install completed!"
}

#===============================================================================================
#Description:install mcrypt.
#Usage:install_mcrypt
#===============================================================================================
function install_mcrypt(){
    /sbin/ldconfig
    cd $cur_dir/untar/$mcryptVersion
    ./configure
    make && make install
    echo "${mcryptVersion} install completed!"
}

#===============================================================================================
#Description:install re2c.
#Usage:install_re2c
#===============================================================================================
function install_re2c(){
    cd $cur_dir/untar/$re2cVersion
    ./configure
    make && make install
    echo "${re2cVersion} install completed!"
}

#===============================================================================================
#Description:install_libedit.
#Usage:install_libedit
#===============================================================================================
function install_libedit(){
    cd $cur_dir/untar/$libeditVersion
    ./configure
    make && make install
    echo "${libeditVersion} install completed!"
}

#===============================================================================================
#Description:install php.
#Usage:install_php
#===============================================================================================
function install_php(){
    if [ ! -d /usr/local/php ];then
        #install PHP
        echo "Start Installing ${PHPVersion}"
        #ldap module 
        if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
            cp -frp /usr/lib64/libldap* /usr/lib/
            ln -s /usr/lib64/libc-client.so /usr/lib/libc-client.so
        fi
        cd $cur_dir/untar/$PHPVersion
        ./configure --prefix=/usr/local/php --with-apxs2=/usr/local/apache/bin/apxs --with-config-file-path=/usr/local/php/etc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-pcre-dir=/usr/local/pcre --with-iconv-dir=/usr/local --with-mysql-sock=/usr/local/mysql/mysql.sock --with-config-file-scan-dir=/usr/local/php/php.d --with-mhash=/usr --with-icu-dir=/usr --with-bz2 --with-curl --with-freetype-dir --with-gd --with-gettext --with-gmp --with-jpeg-dir --with-kerberos --with-ldap --with-mcrypt --with-openssl --with-pear --with-pdo-mysql --with-png-dir --with-readline --with-xmlrpc --with-xsl --with-zlib --enable-bcmath --enable-calendar --enable-ctype --enable-dom --enable-exif --enable-ftp --enable-gd-native-ttf --enable-intl --enable-json --enable-mbstring --enable-pcntl --enable-session --enable-shmop --enable-simplexml --enable-soap --enable-sockets --enable-tokenizer --enable-wddx --enable-xml --enable-zip --disable-fileinfo
        if [ $? -ne 0 ]; then
            echo "Installing PHP failed."
            exit 1
        fi
        make ZEND_EXTRA_LIBS='-liconv'
        make install
        mkdir -p /usr/local/php/etc
        mkdir -p /usr/local/php/php.d
        cp -f $cur_dir/conf/php5.4.ini /usr/local/php/etc/php.ini
        rm -f /etc/php.ini
        ln -s /usr/local/php/etc/php.ini  /etc/php.ini
        ln -s /usr/local/php/bin/php /usr/bin/php
        ln -s /usr/local/php/bin/php-config /usr/bin/php-config
        ln -s /usr/local/php/bin/phpize /usr/bin/phpize
        echo "${PHPVersion} install completed!"
    else
        echo "PHP had been installed!"
    fi
}

#===============================================================================================
#Description:uninstall lamp.
#Usage:uninstall_lamp
#===============================================================================================
function uninstall_lamp(){
    echo "Are you sure uninstall LAMP? (y/n)"
    read -p "(Default: n):" uninstall
    if [ -z $uninstall ]; then
        uninstall="n"
    fi
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        clear
        echo "==========================="
        echo "Yes, I agreed to uninstall!"
        echo "==========================="
        echo ""
    else
        echo ""
        echo "============================"
        echo "You cancelled the uninstall!"
        echo "============================"
        exit
    fi

    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo "Press any key to start uninstall LAMP...or Press Ctrl+c to cancel"
    char=`get_char`
    echo ""
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        killall httpd
        killall mysqld
        chkconfig httpd off
        chkconfig mysqld off
        rm -rf /etc/init.d/httpd /usr/local/apache /usr/sbin/httpd /usr/sbin/apachectl /var/log/httpd /var/lock/subsys/httpd /var/spool/mail/apache /etc/logrotate.d/httpd
        for tmp in `ls /usr/local/mysql/bin`
        do
            rm -f /usr/bin/$tmp
        done
        rm -rf /usr/local/mysql/ /etc/my.cnf /etc/rc.d/init.d/mysqld /etc/ld.so.conf.d/mysql.conf /var/lock/subsys/mysql /var/spool/mail/mysql
        rm -rf /usr/local/php/ /usr/lib/php /usr/bin/php /usr/bin/php-config /usr/bin/phpize /etc/php.ini
        rm -rf /data/www/default/phpmyadmin
        rm -f /etc/pure-ftpd.conf
        rm -f /usr/bin/lamp
        echo "Successfully uninstall LAMP!!"
    else
        echo "Uninstall cancelled, nothing to do"
    fi
}

#===============================================================================
#Description:Add apache virtualhost.
#Usage:vhost_add
#===============================================================================
function vhost_add(){
    #Define domain name
    read -p "(Please input domains such as:www.example.com):" domains
    if [ "$domains" = "" ]; then
        echo "You need input a domain."
        exit 1
    fi
    domain=`echo $domains | awk '{print $1}'`
    if [ -f "/usr/local/apache/conf/vhost/$domain.conf" ]; then
        echo "$domain is exist!"
        exit 1
    fi
    #Create database or not    
    while true
    do
    read -p "(Do you want to create database?[y/N]):" create
    case $create in
    y|Y|YES|yes|Yes)
    read -p "(Please input your MySQL root password):" mysqlroot_passwd
    mysql -uroot -p$mysqlroot_passwd <<EOF
exit
EOF
    if [ $? -eq 0 ]; then
        echo "MySQL root password is correct.";
    else
        echo "MySQL root password incorrect! Please check it and try again!"
        exit 1
    fi
    read -p "(Please input the database name):" dbname
    read -p "(Please set the password for mysql user $dbname):" mysqlpwd
    create=y
    break
    ;;
    n|N|no|NO|No)
    echo "Not create database, you entered $create"
    create=n
    break
    ;;
    *) echo Please input only y or n
    esac
    done

    #Create database
    if [ "$create" == "y" ];then
    mysql -uroot -p$mysqlroot_passwd  <<EOF
CREATE DATABASE IF NOT EXISTS \`$dbname\`;
GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'localhost' IDENTIFIED BY '$mysqlpwd';
GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'127.0.0.1' IDENTIFIED BY '$mysqlpwd';
FLUSH PRIVILEGES;
EOF
    fi
    #Define website dir
    webdir="/data/www/$domain"
    DocumentRoot="$webdir/web"
    logsdir="$webdir/logs"
    mkdir -p $DocumentRoot $logsdir
    chown -R apache:apache $webdir
    #Create vhost configuration file
    cat >/usr/local/apache/conf/vhost/$domain.conf<<EOF
<virtualhost *:80>
ServerName  $domain
ServerAlias  $domains 
DocumentRoot  $DocumentRoot
CustomLog $logsdir/access.log combined
DirectoryIndex index.php index.html
<Directory $DocumentRoot>
Options +Includes -Indexes
AllowOverride All
Order Deny,Allow
Allow from All
php_admin_value open_basedir $DocumentRoot:/tmp
</Directory>
</virtualhost>
EOF
    service httpd reload > /dev/null 2>&1
    echo "Successfully create $domain vhost"
    echo "######################### information about your website ############################"
    echo "The DocumentRoot:$DocumentRoot"
    echo "The Logsdir:$logsdir"
    [ "$create" == "y" ] && echo "MySQL dbname and user:$dbname and password:$mysqlpwd"
}

#===============================================================================
#Description:Remove apache virtualhost.
#Usage:vhost_del
#===============================================================================
function vhost_del(){
    read -p "(Please input a domain you want to delete):" vhost_domain
    if [ "$vhost_domain" = "" ]; then
        echo "You need input a domain."
        exit 1
    fi
    echo "---------------------------"
    echo "vhost account = $vhost_domain"
    echo "---------------------------"
    echo ""
    get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
    }
    echo "Press any key to start delete vhost..."
    echo "or Press Ctrl+c to cancel"
    echo ""
    char=`get_char`

    if [ -f "/usr/local/apache/conf/vhost/$vhost_domain.conf" ]; then
        rm -rf /usr/local/apache/conf/vhost/$vhost_domain.conf
        rm -rf /data/www/$vhost_domain
    else
        echo "Error!!No such domain file.Please check your input domain again..."
        exit 1
    fi

    service httpd reload > /dev/null 2>&1
    echo "Successfully delete $vhost_domain vhost"
    echo "You need to remove site directory manually!"
}

#===============================================================================
#Description:List apache virtualhost.
#Usage:vhost_list
#===============================================================================
function vhost_list(){
    ls /usr/local/apache/conf/vhost/ | cut -f 1,2,3 -d "."
}

#===============================================================================================
#Description:Initialization step
#Usage:none
#===============================================================================================
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_lamp
    ;;
uninstall)
    uninstall_lamp
    ;;
add)
   vhost_add
    ;;
del)
   vhost_del
    ;;
list)
   vhost_list
    ;;
ftp)
  faction=$2
    ftp
        ;;
*)
    echo "Usage: `basename $0` {install|uninstall|add|del|list|ftp(add,del,list))"
    ;;
esac