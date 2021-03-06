#BEGIN

#Resolve virtual_packages warning
if versioncmp($::puppetversion,'3.6.1') >= 0 {
  $allow_virtual_packages = hiera('allow_virtual_packages',false)
  Package {
    allow_virtual => $allow_virtual_packages,
  }
}

$deploy_user            = 'appuser1'
$sitename               = 'localhost.localdomain' # Replace this with actual domain
$application             = 'simple-sinatra'

$main_ruby               = '1.9.3-p484'
$passenger_version       = '4.0.52'
$sinatra_version         = '1.4.5'
$rack_version            = '1.5.2'
$rack_protection_version = '1.5.3'
$tilt_version		 = '1.4.1'
$deploy_to               = "/home/${deploy_user}/${sitename}"
$main_ruby_location      = "/home/${deploy_user}/.rbenv/versions/${main_ruby}"
$passenger_location      = "${main_ruby_location}/lib/ruby/gems/1.9.1/gems/passenger-${passenger_version}"
$mod_passenger_location  = "${passenger_location}/buildout/apache2/mod_passenger.so"

# Check passenger requisites here
case "$::osfamily" {
  "Debian" : { 
     package { ['apache2-threaded-dev', 'libcurl4-openssl-dev', 'build-essential']:
       before => EXEC["passenger-install-apache2-module -a"],
     }
     exec { "rm -f '/etc/apache2/mods-enabled/passenger.load'":
       path   => [ '/usr/bin', '/bin', '/usr/local/bin' ],
       before => EXEC["passenger-install-apache2-module -a"],
     }
  }
  "RedHat" : {
     package { ['apr-util-devel','libcurl-devel','openssl-devel','apr-devel']: 
       before => EXEC["passenger-install-apache2-module -a"],
     }
  }
  default : { notify{ "Unsupported OS":} }
}

user { "$deploy_user":
  ensure     => present,
  managehome => true,
} ->
rbenv::install { "$deploy_user":
  group  => "$deploy_user",
} ->
rbenv::compile { "$main_ruby":
  user   => "$deploy_user",
  global => true,
} ->
rbenv::gem { "rake":
  user   => "$deploy_user",
  ruby   => "$main_ruby",
  ensure => present;
 "passenger":
  user   => "$deploy_user",
  ruby   => "$main_ruby",
  ensure => "$passenger_version";
 "sinatra":
  user   => "$deploy_user",
  ruby   => "$main_ruby",
  ensure => "$sinatra_version";
 "rack":
  user   => "$deploy_user",
  ruby   => "$main_ruby",
  ensure => "$rack_version";
 "rack-protection":
  user   => "$deploy_user",
  ruby   => "$main_ruby",
  ensure => "$rack_protection_version";
 "tilt":
  user   => "$deploy_user",
  ruby   => "$main_ruby",
  ensure => "$tilt_version";
} ->
exec { "passenger-install-apache2-module -a":
  user    => "$deploy_user",
  path    => [ "/home/${deploy_user}/.rbenv/shims", "/home/${deploy_user}/.rbenv/bin", "/home/${deploy_user}/.rbenv/versions/${main_ruby}/bin" , '/usr/bin', '/bin', '/usr/local/bin', '/usr/local/sbin', '/sbin', '/usr/sbin' ],
  unless  => "[ -f ${mod_passenger_location} ]",
  require => Rbenvgem["${deploy_user}/${main_ruby}/passenger/${passenger_version}"],
  timeout => 600,
} ->
class { 'apache': } ->
class { "apache::dev": } ->
apache::vhost { "${sitename}":
  serveraliases => [
    "www.${sitename}",
  ],
  options         => ['-Indexes','+FollowSymLinks','-MultiViews'],
  priority        => '10',
  port            => '80',
  docroot         => "${deploy_to}/${application}/public",
  serveradmin     => "webmaster@${sitename}",
  ensure          => present,
  docroot_owner   => "$deploy_user",
  docroot_group   => "$deploy_user",
  rack_base_uris  => ['/'],
}

class { "apache::mod::passenger":  
  mod_package_ensure          => absent,
  mod_path                    => "$mod_passenger_location",
  passenger_root              => "$passenger_location",
  passenger_ruby              => "${main_ruby_location}/bin/ruby",
  require                     => EXEC["passenger-install-apache2-module -a"],
}


# The following is required for apache::vhost to work since it needs the
# docroot parent hierarchy to be created. 
file {
  [ "/home/${deploy_user}",
    "$deploy_to",
    "${deploy_to}/logs",
    "${deploy_to}/${application}",
  ]:
  ensure  => directory,
  mode    => 0755,
  replace => false,
  owner   => $deploy_user,
  group   => $deploy_user,
  require => User["$deploy_user"],
} ->
exec { "appclone":
  user    => "$deploy_user",
  command => "git clone https://github.com/tnh/simple-sinatra-app ${deploy_to}/${application}/",
  path    => [ '/usr/bin', '/bin', '/usr/local/bin', '/usr/local/sbin', '/sbin', '/usr/sbin' ],
  creates => "${deploy_to}/${application}/config.ru",
  require => Rbenvgem["$deploy_user/$main_ruby/passenger/$passenger_version"],
  timeout => 600,
} ->
file { "$deploy_to/$application/public":  
  ensure  => directory,
  mode    => 0755,
  replace => false,
  owner   => $deploy_user,
  group   => $deploy_user,
}

#To restrict access, simply uncomment this
#firewall { '100 allow http and ssh access':
#    port   => [80, 22],
#    proto  => tcp,
#    action => accept;
# "999 drop all other requests":
#  action => "drop";
#}

#END
