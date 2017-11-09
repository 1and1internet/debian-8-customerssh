FROM 1and1internet/debian-8:latest as ruby23
MAINTAINER brian.wilkinson@fasthosts.com
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get install -y curl gcc make && \
  RUBY23TARGZ=$(curl -s --compressed https://cache.ruby-lang.org/pub/ruby/2.3/ | \
              sed 's/.*a href="\(.*\)\">.*<.a>.*/\1/' | \
              grep "ruby-2.3.*.tar.gz" | \
              grep -v preview | \
              sort | \
              tail -1 ) && \
  RUBY23=$(echo $RUBY23TARGZ | sed 's/\(.*\).tar.gz/\1/') && \
  curl -g https://cache.ruby-lang.org/pub/ruby/2.3/${RUBY23TARGZ} | tar zxvf - && \
  mv /$RUBY23 /ruby23 && \
  cd /ruby23 && ./configure && make


FROM 1and1internet/debian-8:latest
MAINTAINER brian.wilkinson@fasthosts.com
ARG DEBIAN_FRONTEND=noninteractive
COPY files /
COPY --from=ruby23 /ruby23 /ruby23

RUN \
  apt-get update && \
  apt-get install -y python-software-properties software-properties-common && \
  apt-get update && \
  apt-get install -y \
    libapache2-mod-php7.0 mysql-client libmysqlclient-dev perl zlib1g-dev sqlite sqlite3 \
    git vim traceroute telnet nano dnsutils curl wget iputils-ping openssh-client openssh-sftp-server \
    virtualenv python3-venv python3-virtualenv python3-all python3-setuptools python3-pip python-dev python3-dev python-pip \
    gnupg build-essential libsqlite3-dev && \
  cd /ruby23 && make install && cd - && rm -rf /ruby23 && \
	update-alternatives --install /usr/bin/erb erb  /usr/local/bin/erb 1 && \
	update-alternatives --install /usr/bin/gem gem  /usr/local/bin/gem 1 && \
	update-alternatives --install /usr/bin/irb irb  /usr/local/bin/irb 1 && \
	update-alternatives --install /usr/bin/rake rake  /usr/local/bin/rake 1 && \
	update-alternatives --install /usr/bin/rdoc rdoc  /usr/local/bin/rdoc 1 && \
	update-alternatives --install /usr/bin/ri ri  /usr/local/bin/ri 1 && \
	update-alternatives --install /usr/bin/ruby ruby  /usr/local/bin/ruby 1 && \
  apt-get install -y imagemagick graphicsmagick && \
  apt-get install -y php5.6-bcmath php5.6-bz2 php5.6-cli php5.6-common php5.6-curl php5.6-dba php5.6-gd php5.6-gmp php5.6-imap php5.6-intl php5.6-ldap php5.6-mbstring php5.6-mcrypt php5.6-mysql php5.6-odbc php5.6-pgsql php5.6-recode php5.6-snmp php5.6-soap php5.6-sqlite php5.6-tidy php5.6-xml php5.6-xmlrpc php5.6-xsl php5.6-zip && \
  apt-get install -y php7.0-bcmath php7.0-bz2 php7.0-cli php7.0-common php7.0-curl php7.0-dba php7.0-gd php7.0-gmp php7.0-imap php7.0-intl php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-odbc php7.0-pgsql php7.0-recode php7.0-snmp php7.0-soap php7.0-sqlite php7.0-tidy php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-zip && \
  apt-get install -y php7.1-bcmath php7.1-bz2 php7.1-cli php7.1-common php7.1-curl php7.1-dba php7.1-gd php7.1-gmp php7.1-imap php7.1-intl php7.1-ldap php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-odbc php7.1-pgsql php7.1-recode php7.1-snmp php7.1-soap php7.1-sqlite php7.1-tidy php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip && \
  apt-get install -y php-imagick php-mongodb php-fxsl && \
  apt-get install -y apt-transport-https ca-certificates lsb-release && \
  DISTRO=$(lsb_release -c -s) && \
  NODEREPO="node_6.x" && \
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo "deb https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" > /etc/apt/sources.list.d/nodesource.list && \
  echo "deb-src https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" >> /etc/apt/sources.list.d/nodesource.list && \
  apt-get update -q && \
  apt-get install -y build-essential nodejs && \
  apt-get remove -y python-software-properties software-properties-common && \
  apt-get autoremove -y && apt-get autoclean -y && \
  chmod 0777 /var/www && \
  mkdir /tmp/composer/ && \
  cd /tmp/composer && \
  curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer && \
  rm -rf /tmp/composer && \
  rm -rf /var/lib/apt/lists/* && \
  chmod 0755 /usr/local/bin/composer && \
  chmod 0755 -R /hooks /init && \
  chmod 0777 /etc/passwd /etc/group && \
  mkdir --mode 0777 /usr/local/composer && \
  COMPOSER_HOME=/usr/local/composer /usr/local/bin/composer --no-ansi --no-interaction global require drush/drush:8.* && \
  COMPOSER_HOME=/usr/local/composer /usr/local/bin/composer --no-ansi --no-interaction global clearcache && \
  mv /usr/bin/cpan /usr/bin/cpan_disabled && \
  mv /usr/bin/cpan_override /usr/bin/cpan && \
  rm -f /etc/ssh/ssh_host_* && \
  rm -f /hooks/supervisord-pre.d/20_configurability && \
  chmod -R 0777 /etc/supervisor/conf.d

ENV COMPOSER_HOME=/var/www \
    HOME=/var/www

WORKDIR /var/www

# Install and configure the cron service
ENV EDITOR=/usr/bin/vim \
	CRON_LOG_FILE=/var/spool/cron/cron.log \
	CRON_LOCK_FILE=/var/spool/cron/cron.lock \
	CRON_ARGS=""
RUN \
  apt-get update && apt-get install -y -o Dpkg::Options::="--force-confold" logrotate man && \
  cd /src/cron-3.0pl1 && \
  make install && \
  mkdir -p /var/spool/cron/crontabs && \
  chmod -R 777 /var/spool/cron && \
  cp debian/crontab.main /etc/crontab && \
  cd - && \
  rm -rf /src && \
  find /etc/cron.* -type f | egrep -v 'logrotate|placeholder' | xargs -i rm -f {} && \
  chmod 666 /etc/logrotate.conf && \
  chmod -R 777 /var/lib/logrotate && \
  rm -rf /var/lib/apt/lists/*
