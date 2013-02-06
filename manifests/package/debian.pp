# Class: nginx::package::debian
#
# This module manages NGINX package installation on debian based systems
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::package::debian {
  exec
    {
      'add-apt-repository ppa:chris-lea/nginx-devel':
        command     => '/usr/bin/add-apt-repository ppa:chris-lea/nginx-devel',
        creates     => '/etc/apt/sources.list.d/chris-lea-nginx-devel-precise.list',
    }

  package { 'nginx':
    ensure => present,
    require     => Exec['add-apt-repository ppa:chris-lea/nginx-devel']
  }
}
