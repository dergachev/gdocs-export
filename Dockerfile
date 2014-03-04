FROM  ubuntu:12.04

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse" > /etc/apt/sources.list
RUN apt-get update

# assumes your docker HOST ran "apt-get install -y squid-deb-proxy"
RUN /sbin/ip route | awk '/default/ { print "Acquire::http::Proxy \"http://"$3":8000\";" }' > /etc/apt/apt.conf.d/30proxy

# hijack /sbin/initctl
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s -f /bin/true /sbin/initctl

RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
RUN apt-get install -y ruby1.9.3
RUN (gem list bundler | grep bundler) || gem install bundler

RUN apt-get install -y build-essential
RUN apt-get install -y vim

# get pandocfilters, a helper library for writing pandoc filters in python
RUN apt-get -y install python-pip
RUN pip install pandocfilters

# install pdflatex and dependencies
RUN apt-get install -y texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended

# extra latex tools
RUN apt-get install -y rubber latexdiff

# install pandoc from source (apt-get install pandoc gets pandoc-1.9, we need 1.12)
RUN apt-get install haskell-platform -y

RUN cabal update
RUN cabal install pandoc --global

# dependencies for nokogiri gem
RUN apt-get install libxml2 libxml2-dev libxslt1-dev -y

# install jq (json query) binary; see http://stedolan.github.io/jq/tutorial/
# RUN which jq || (wget http://stedolan.github.io/jq/download/linux64/jq ; chmod ugo+x jq ; mv jq /usr/local/bin)

# install gems
ADD Gemfile /tmp/
ADD Gemfile.lock /tmp/
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1  # greatly speeds up nokogiri install
RUN cd /tmp; bundle install

# install the app
ADD . /var/gdocs-export/

EXPOSE 12736

WORKDIR /var/gdocs-export/
CMD ["/bin/bash"]
