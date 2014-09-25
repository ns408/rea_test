#!/usr/bin/env bash
# Author: nitinsharma408@gmail.com
# This script will:
# - install puppet, facter, git on a Debian or RHEL based system.
# - will checkout rbenv, apache puppet modules
# - will install concat and stdlib
# - should be run as root

if [ -f '/etc/debian_version' -a -x '/usr/bin/apt-get' ]
then
  echo -e "#Debian family\n"
  apt-get -y install puppet facter git 
  apt-get -y install apache2-threaded-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev build-essential apache2-mpm-worker
elif [ '/etc/redhat-release' -a -x '/usr/bin/yum' ]
then
  echo -e "#RHEL family\n"
  yum -y install puppet facter git 
  yum -y install httpd-devel apr-util-devel libcurl-devel openssl-devel apr-devel
else
  echo -e "Unable to recognize the OS"
fi

# Modules needed for simple-sinatra-app
Module_dir='/etc/puppet/modules'
test -d $Module_dir || mkdir -p $Module_dir
cd $Module_dir
test -d ${Module_dir}/rbenv || git clone https://github.com/ns408/puppet-rbenv rbenv
test -d ${Module_dir}/apache || git clone https://github.com/puppetlabs/puppetlabs-apache apache
test -d ${Module_dir}/firewall || git clone https://github.com/puppetlabs/puppetlabs-firewall firewall
test -d ${Module_dir}/concat || puppet module install puppetlabs-concat # Installing concat installs puppetlabs-stdlib, needed for apache.
cd -

`which puppet` apply rea_test.pp
