FROM  ubuntu:saucy
MAINTAINER Alex Dergachev <alex@evolvingweb.ca>

# check if the docker host is running squid-deb-proxy, and use it
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc `cat /tmp/host_ip.txt` 8000 | grep squid-deb-proxy && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) || echo "No squid-deb-proxy detected"

# install misc tools
RUN apt-get update -y && apt-get install -y curl wget git fontconfig make vim

RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
RUN apt-get install -y ruby1.9.3

# get pandocfilters, a helper library for writing pandoc filters in python
RUN apt-get -y install python-pip
RUN pip install pandocfilters

# latex tools
RUN apt-get update -y && apt-get install -y texlive-latex-base texlive-xetex latex-xcolor texlive-math-extra texlive-latex-extra texlive-fonts-extra biblatex rubber latexdiff

# greatly speeds up nokogiri install
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1
# dependencies for nokogiri gem
RUN apt-get install libxml2 libxml2-dev libxslt1-dev -y

# install bundler
RUN (gem list bundler | grep bundler) || gem install bundler

# install gems
ADD Gemfile /tmp/
ADD Gemfile.lock /tmp/
RUN cd /tmp; bundle install

# install pandoc 1.12 by from manually downloaded trusty deb packages (saucy only has 1.11, which is too old)
RUN apt-get install -y liblua5.1-0 libyaml-0-2
ADD docker/ /tmp/docker-trusty-debs/
RUN dpkg -i /tmp/docker-trusty-debs/libicu52_52.1-3_amd64.deb
RUN dpkg -i /tmp/docker-trusty-debs/pandoc-data_1.12.2.1-1build2_all.deb
RUN dpkg -i /tmp/docker-trusty-debs/pandoc_1.12.2.1-1build2_amd64.deb

EXPOSE 12736
WORKDIR /var/gdocs-export/
