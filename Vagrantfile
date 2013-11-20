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

  # requires vagrant-cachier
  config.cache.auto_detect = true
  
  config.vm.provision :shell, :inline => <<-EOT
    apt-get update

    apt-get install -y build-essential
    apt-get install -y vim

    apt-get -y install python-pip
    pip install pandocfilters

    # pip install sphinx

    # install pdflatex and dependencies
    apt-get install -y texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended

    # install pandoc from source (apt-get install pandoc gets pandoc-1.9, we need 1.12)
    apt-get install haskell-platform -y
    cabal update
    cabal install pandoc --global
    
    # install nokogiri 1.5.9 (1.6 requires ruby 1.9+)
    apt-get install libxml2 libxml2-dev libxslt1-dev -y
    gem install nokogiri -v 1.5.9
  EOT
end

