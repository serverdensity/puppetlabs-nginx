# define: nginx::resource::upstream
#
# This definition creates a new upstream proxy entry for NGINX
#
# Parameters:
#   [*ensure*]      - Enables or disables the specified location (present|absent)
#   [*members*]     - Array of member URIs for NGINX to connect to. Must follow valid NGINX syntax.
#   [*target_port*] - Target port for the upstream (default:80)
#   [*ip_hash*]     - Enables or disables the ip_hash for the upstream
#   [*backup_port*] - Defines the backup backend port
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::upstream { 'proxypass':
#    ensure  => present,
#    members => [
#      'localhost:3000',
#      'localhost:3001',
#      'localhost:3002',
#    ],
#  }
define nginx::resource::upstream (
  $ensure  = 'present',
  $target_port = 80,
  $ip_hash = undef,
  $backup_port = undef,
  $members
) {
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  file { "/etc/nginx/conf.d/${name}-upstream.conf":
    ensure   => $ensure ? {
      'absent' => absent,
      default  => 'file',
    },
    content  => template('nginx/conf.d/upstream.erb'),
    notify   => Class['nginx::service'],
  }
}
