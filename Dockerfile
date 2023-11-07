FROM centos:7.2.1511
MAINTAINER li191384269@gmail.com

RUN yum update -y
RUN groupadd -r php && useradd -r -g php -s /bin/false -d /usr/local/php -M php
RUN yum install -y epel-release && yum clean all
RUN yum -y install libxml2 libxml2-devel oniguruma oniguruma-devel sqlite-devel libsqlite3-dev openssl openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel libmcrypt-devel wget autoconf gcc bison vim git zip unzip php-zip

ADD /src/php-7.4.30.tar.gz /
RUN cd /php-7.4.30 && ./buildconf --force
RUN cd /php-7.4.30 && ./configure --prefix=/usr/local/php --exec-prefix=/usr/local/php --bindir=/usr/local/php/bin --sbindir=/usr/local/php/sbin --includedir=/usr/local/php/include --libdir=/usr/local/php/lib/php --mandir=/usr/local/php/php/man --with-config-file-path=/usr/local/php/etc --with-mysql-sock=/var/run/mysql/mysql.sock --with-mcrypt=/usr/include --with-mhash --with-openssl --with-mysql=shared,mysqlnd --with-mysqli=shared,mysqlnd --with-pdo-mysql=shared,mysqlnd  --with-iconv --with-zlib --enable-zip --enable-inline-optimization --disable-rpath --enable-shared --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-mbregex --enable-mbstring --enable-ftp --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --without-pear --with-gettext --enable-session --with-curl --enable-gd --with-jpeg --with-freetyp --enable-opcache --enable-fpm --enable-fastcgi --with-fpm-user=php --with-fpm-group=php --without-gdbm --enable-fileinfo --enable-embed --enable-dl
RUN cd /php-7.4.30 && make clean && make && make install && cp php.ini-production /usr/local/php/etc/php.ini
RUN cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
RUN cp /php-7.4.30/sapi/fpm/init.d.php-fpm /usr/local/bin/php-fpm.sh && chmod +x /usr/local/bin/php-fpm.sh
RUN echo 'extension=pdo_mysql.so' >> /usr/local/php/etc/php.ini
RUN ln -s /usr/local/php/bin/* /usr/local/bin
Run ln -s /usr/local/php/sbin/* /usr/local/bin

COPY src/php-psr-master/* /tmp/php-psr-master/
RUN cd /tmp/php-psr-master && phpize && ./configure && make && make test && make install && \
echo 'extension=psr.so' >> /usr/local/php/etc/php.ini

ADD src/cphalcon-4.1.2.tar.gz /
RUN cd /cphalcon-4.1.2/build &&\
./install &&\
echo 'extension=phalcon.so' >> /usr/local/php/etc/php.ini

# 安装zip扩展所需扩展libzip
ADD src/libzip-1.2.0.tar.gz /
RUN cd /libzip-1.2.0 && ./configure && make && make install
RUN cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h

# 安装zip扩展
ADD src/zip-1.21.1.tgz /
RUN cd /zip-1.21.1 && phpize && ./configure && make && make install
RUN echo 'extension=zip.so' >> /usr/local/php/etc/php.ini

# 安装chilkat扩展
ADD src/chilkat-9.5.0-php-7.4-x86_64-linux.tar.gz /
RUN cd /chilkat-9.5.0-php-7.4-x86_64-linux && cp chilkat_9_5_0.so /usr/local/php/lib/php/extensions/no-debug-non-zts-20190902
RUN echo 'extension=chilkat_9_5_0.so' >> /usr/local/php/etc/php.ini
# version `CXXABI_1.3.8' not found
ADD src/libstdc++.so.6.0.22 /usr/lib64/
RUN cd /usr/lib64/ && rm -rf libstdc++.so.6
RUN ln -s libstdc++.so.6.0.22 libstdc++.so.6
ADD src/chilkat-9.5.0-php-7.4-x86_64-linux.tar.gz /
# version `GLIBC_2.18` not found
ADD src/glibc-2.18.tar.gz /
RUN cd /glibc-2.18 && mkdir build && cd build && ../configure --prefix=/usr && make -j4 && make install

COPY src/composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

RUN yum install -y gcc-c++ lua-devel
ADD src/v0.3.0.tar.gz /
ADD src/v0.10.13.tar.gz /
ADD src/nginx-1.12.2.tar.gz /
ADD src/openssl-1.1.0e.tar.gz /
ADD src/pcre-8.41.tar.gz /
ADD src/zlib-1.2.11.tar.gz /
ADD src/v0.61.tar.gz /
RUN cd /nginx-1.12.2 && ./configure --prefix=/usr/local/nginx --sbin-path=/usr/local/nginx/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --pid-path=/usr/local/nginx/logs/nginx.pid --error-log-path=/usr/local/nginx/logs/error.log --http-log-path=/usr/local/nginx/logs/access.log --with-http_ssl_module --with-pcre=/pcre-8.41 --with-zlib=/zlib-1.2.11 --with-openssl=/openssl-1.1.0e --add-module=/echo-nginx-module-0.61 && make -j2 && make install

RUN rm -rf /nginx-1.12.2 /openssl-1.1.0e /openssl-1.1.0e /zlib-1.2.11 /pcre-8.41 /cphalcon-4.1.2 /php-7.4.30 /tmp/php-psr-master

ADD src/openresty-1.21.4.1.tar.gz /
RUN cd /openresty-1.21.4.1 && ./configure && make && make install

COPY conf/nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY conf/nginx/conf.d/navigation.conf /usr/local/openresty/nginx/conf/conf.d/navigation.conf
COPY conf/nginx/fiery_fastcgi_params /usr/local/openresty/nginx/conf/fiery_fastcgi_params

RUN yum -y install supervisor
COPY scripts/nginx.ini /etc/supervisord.d/nginx.ini
COPY scripts/php-fpm.ini /etc/supervisord.d/php-fpm.ini

RUN sed -i "s/nodaemon=false/nodaemon=true/g" /etc/supervisord.conf

RUN bash -c "mkdir -p /log/laravel" && bash -c "mkdir -p /log/misc" && bash -c "mkdir -p /log/phalcon" && bash -c "chmod 0777 -R /log"

RUN yum clean all

#RUN echo '127.0.0.1 local.navigation.com' >> /etc/hosts

EXPOSE 8001

CMD /usr/bin/supervisord && tail -f
