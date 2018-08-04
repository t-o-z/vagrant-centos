# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.vm.network "private_network", ip: "192.168.33.101"
  config.vm.synced_folder "../", "/var/www/html/", :mount_options => ["dmode=777","fmode=666"]
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 1
  end

  config.ssh.insert_key = false
  config.vm.provision :shell, keep_color: true, path: "Vagrantfile.provision.sh"
end