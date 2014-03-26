FROM  jagregory/pandoc

RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
RUN apt-get install -y ruby1.9.3

# get pandocfilters, a helper library for writing pandoc filters in python
RUN apt-get -y install python-pip
RUN pip install pandocfilters

# extra latex tools
RUN apt-get install -y rubber latexdiff

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

EXPOSE 12736
WORKDIR /var/gdocs-export/
CMD []
ENTRYPOINT ["/bin/sh", "-c"]
