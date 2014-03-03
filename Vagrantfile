# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.provider :virtualbox do |vb|
    # building pandoc needs a lot of RAM (at least 512)
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    # not sure if this helps, but why not...
    vb.customize ["modifyvm", :id, "--cpus", "2"]
  end

  config.vm.network "forwarded_port", guest: 80, host: 8080

  if defined? VagrantPlugins::Cachier
    config.cache.auto_detect = true
  end

  # fixes utf8 encoding issues in ruby1.9; see https://github.com/mitchellh/vagrant/issues/1188
  config.vm.provision :shell, :inline => <<-EOT
    echo 'LC_ALL="en_US.UTF-8"'  >  /etc/default/locale
  EOT

  config.vm.provision :shell, :inline => <<-EOT
    apt-get update

    apt-get install -y ruby1.9.3
    (gem list bundler | grep bundler) || gem install bundler

    apt-get install -y build-essential
    apt-get install -y vim

    # get pandocfilters, a helper library for writing pandoc filters in python
    apt-get -y install python-pip
    pip install pandocfilters

    # install pdflatex and dependencies
    apt-get install -y texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended

    # extra latex tools
    apt-get install -y rubber latexdiff

    # install pandoc from source (apt-get install pandoc gets pandoc-1.9, we need 1.12)
    apt-get install haskell-platform -y
       # cabal update  # dont think this is necessary on new install
    cabal install pandoc --global

    # dependencies for nokogiri gem
    apt-get install libxml2 libxml2-dev libxslt1-dev -y

    # install jq (json query) binary; see http://stedolan.github.io/jq/tutorial/
    install_jq() {
      wget http://stedolan.github.io/jq/download/linux64/jq
      chmod ugo+x jq
      mv jq /usr/local/bin
    }
    which jq || install_jq

    cd /vagrant
    export NOKOGIRI_USE_SYSTEM_LIBRARIES=1  # makes nokogiri 1.6 not take 10 minutes to install
    bundle install --path vendor/bundle
  EOT
end

