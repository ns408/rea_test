#!/usr/bin/env bash
# Author: nitinsharma408@gmail.com
# This script will:
# - install puppet, facter, git on a Debian or RHEL based system.
# - will checkout rbenv, apache puppet modules
# - will install concat and stdlib
# - should be run as root

if [ -f '/etc/debian_version' -a -x '/usr/bin/apt-get' ]
then
  apt-get -y install puppet facter git libcurl4-openssl-dev
elif [ '/etc/redhat-release' -a -x '/usr/bin/yum' ]
then
  yum -y install puppet facter git
else
  echo -e "Unable to recognize the OS"
fi

# Modules needed for simple-sinatra-app
Module_dir='/etc/puppet/modules'
test -d $Module_dir && mkdir -p $Module_dir
cd $Module_dir
test -d ${Module_dir}/rbenv || git clone https://github.com/alup/puppet-rbenv rbenv
test -d ${Module_dir}/apache || git clone https://github.com/puppetlabs/puppetlabs-apache apache
test -d ${Module_dir}/concat || puppet module install puppetlabs-concat
