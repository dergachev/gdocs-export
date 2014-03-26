# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "raring64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box"
  config.ssh.forward_agent = true

  # building pandoc needs a lot of RAM (at least 512, the more the better)
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
  end

  # required for lib/authorize.rb
  config.vm.network "forwarded_port", guest: 12736, host: 12736

  if defined? VagrantPlugins::Cachier
    config.cache.auto_detect = true
  end

  config.vm.provision "docker"

  config.vm.provision :shell, :inline => <<-EOT
    # our docker containers expect the host to have squid-deb-proxy
    apt-get install squid-deb-proxy -y
    apt-get update

    # standard utilities
    apt-get install -y build-essential vim curl git
  EOT
end

