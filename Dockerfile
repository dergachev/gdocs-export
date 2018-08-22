FROM  ubuntu:bionic
MAINTAINER Alex Dergachev <alex@evolvingweb.ca>

# check if the docker host is running squid-deb-proxy, and use it
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc `cat /tmp/host_ip.txt` 8000 | grep squid-deb-proxy && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) || echo "No squid-deb-proxy detected"

# install misc tools
RUN apt-get update -y && apt-get install -y curl wget git fontconfig make vim

RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
RUN apt-get install -y ruby2.5

# get pandocfilters, a helper library for writing pandoc filters in python
RUN apt-get -y install python-pip
RUN pip install pandocfilters

# latex tools
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y apt-utils && apt-get install -y texlive-latex-base texlive-xetex texlive-pstricks texlive-science texlive-latex-extra texlive-fonts-extra rubber latexdiff

# greatly speeds up nokogiri install
# dependencies for nokogiri gem
RUN apt-get install libxml2-dev libxslt1-dev pkg-config -y

# install bundler
RUN (gem list bundler | grep bundler) || gem install bundler

# install gems
ADD Gemfile /tmp/
ADD Gemfile.lock /tmp/
RUN apt-get install -y build-essential patch ruby-dev zlib1g-dev liblzma-dev
RUN cd /tmp && bundle config build.nokogiri --use-system-libraries --with-xml2-include=/usr/include/libxml2 --with-xml2-lib=/usr/lib/ && bundle install

# install pandoc 1.12 by from manually downloaded trusty deb packages (saucy only has 1.11, which is too old)
#RUN apt-get install -y pandoc
RUN mkdir -p /tmp/debs/ && cd /tmp/debs && \
    wget https://github.com/jgm/pandoc/releases/download/2.2.3.2/pandoc-2.2.3.2-1-amd64.deb && \
    dpkg -i *.deb

EXPOSE 12736
WORKDIR /var/gdocs-export/
