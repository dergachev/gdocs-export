FROM  ubuntu:trusty
MAINTAINER Alex Dergachev <alex@evolvingweb.ca>

EXPOSE 12736
WORKDIR /var/gdocs-export/

############################################################
# Gdocs export dependencies (Ruby, Pandoc, Latex)
############################################################

# check if the docker host is running squid-deb-proxy, and use it
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc `cat /tmp/host_ip.txt` 8000 | grep squid-deb-proxy && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) || echo "No squid-deb-proxy detected"

# install misc tools
RUN apt-get update -y && apt-get install -y curl wget git fontconfig make vim dialog apt-utils apache2 php5 nano
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
# Set locale variables
RUN apt-get install -y locales
RUN locale-gen en_US en_US.UTF-8
RUN dpkg-reconfigure locales

RUN apt-get install -y ruby1.9.3

#### RVM
# RUN apt-get install software-properties-common -y
# RUN apt-add-repository -y ppa:rael-gc/rvm -y
# RUN apt-get update -y
# RUN apt-get install rvm -y

# get pandocfilters, a helper library for writing pandoc filters in python
RUN apt-get -y install python-pip
RUN pip install pandocfilters

# latex tools
RUN apt-get update -y && apt-get install -y texlive-latex-base texlive-xetex latex-xcolor texlive-math-extra texlive-latex-extra texlive-fonts-extra rubber latexdiff

# greatly speeds up nokogiri install
# dependencies for nokogiri gem
RUN apt-get install libxml2-dev libxslt1-dev pkg-config -y

# install bundler
RUN (gem list bundler | grep bundler) || gem install bundler

# install gems
ADD Gemfile /tmp/
ADD Gemfile.lock /tmp/
RUN cd /tmp && bundle config build.nokogiri --use-system-libraries && bundle install

# install pandoc 1.12 by from manually downloaded trusty deb packages (saucy only has 1.11, which is too old)
RUN apt-get install -y pandoc

############################################################
# Gdocs export server dependencies (Apache, PHP)
############################################################
RUN useradd -m -g www-data gdocs
# Update the default apache site with the config we created.
COPY server/apache-config.conf /etc/apache2/sites-available/000-default.conf
COPY server/envvars /etc/apache2/envvars

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD apachectl -D FOREGROUND

# allow gdocs to run script as root
RUN printf "\ngdocs ALL=(root) NOPASSWD: /var/gdocs-export/server/scripts/web-convert-gdoc.sh" > /etc/sudoers
