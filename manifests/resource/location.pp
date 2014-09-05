# define: nginx::resource::location
#
# This definition creates a new location entry within a virtual host
#
# Parameters:
#   [*ensure*]               - Enables or disables the specified location (present|absent)
#   [*vhost*]                - Defines the default vHost for this location entry to include with
#   [*location*]             - Specifies the URI associated with this location entry
#   [*www_root*]           - Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy
#   [*alias_root*]         - Specifies a path on disk to the files. Like $www_root, except the location is stripped from the
#                            request.  Cannot be set in conjunction with either $www_root or $proxy.
#   [*index_files*]          - Default index files for NGINX to read when traversing a directory
#   [*proxy*]                - Proxy server(s) for a location to connect to. Accepts a single value, can be used in conjunction
#                              with nginx::resource::upstream
#   [*proxy_read_timeout*]   - Override the default the proxy read timeout value of 90 seconds
#   [*proxy_set_header*]     - Override the default proxy headers
#   [*proxy_buffering*]      - Override the default proxy_buffering configuration of ON
#   [*ssl*]                  - Indicates whether to setup SSL bindings for this location.
#   [*ssl_only*]	     - Required if the SSL and normal vHost have the same port.
#   [*location_alias*]       - Path to be used as basis for serving requests for this location
#   [*stub_status*]          - If true it will point configure module stub_status to provide nginx stats on location
#   [*location_cfg_prepend*] - It expects a hash with custom directives to put before anything else inside location
#   [*location_cfg_append*]  - It expects a hash with custom directives to put after everything else inside location   
#   [*try_files*]            - An array of file locations to try
#   [*websockets*]          - Override the default websockets connection upgrade configuration of OFF
#   [*option*]               - Reserved for future use
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::location { 'test2.local-bob':
#    ensure   => present,
#    www_root => '/var/www/bob',
#    location => '/bob',
#    vhost    => 'test2.local',
#  }
#  
#  Custom config example to limit location on localhost,
#  create a hash with any extra custom config you want.
#  $my_config = {
#    'access_log' => 'off',
#    'allow'      => '127.0.0.1',
#    'deny'       => 'all'
#  }
#  nginx::resource::location { 'test2.local-bob':
#    ensure              => present,
#    www_root            => '/var/www/bob',
#    location            => '/bob',
#    vhost               => 'test2.local',
#    location_cfg_append => $my_config,
#  }

define nginx::resource::location(
  $ensure               = present,
  $vhost                = undef,
  $www_root             = undef,
  $alias_root         = undef,
  $index_files          = ['index.html', 'index.htm', 'index.php'],
  $proxy                = undef,
  $proxy_read_timeout   = $nginx::params::nx_proxy_read_timeout,
  $proxy_set_header     = undef, 
  $proxy_buffering      = undef, 
  $ssl                  = false,
  $ssl_only		= false,
  $location_alias       = undef,
  $option               = undef,
  $stub_status          = undef,
  $location_cfg_prepend = undef,
  $location_cfg_append  = undef,
  $try_files            = undef,
  $websockets           = undef,
  $location
) {
  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Class['nginx::service'],
  }

  ## Shared Variables
  $ensure_real = $ensure ? {
    'absent' => absent,
    default  => file,
  }

  # Use proxy template if $proxy is defined, otherwise use directory template.
  if ($proxy != undef) {
    $content_real = template('nginx/vhost/vhost_location_proxy.erb')
  } elsif ($alias_root != undef) {
    $content_real = template('nginx/vhost/vhost_location_alias.erb')
  } elsif ($location_alias != undef) {
    $content_real = template('nginx/vhost/vhost_location_alias.erb')
  } elsif ($stub_status != undef) {
    $content_real = template('nginx/vhost/vhost_location_stub_status.erb')
  } else {
    $content_real = template('nginx/vhost/vhost_location_directory.erb')
  }

  ## Check for various error condtiions
  if ($vhost == undef) {
    fail('Cannot create a location reference without attaching to a virtual host')
  }

  $location_config = [
    $alias_root ? { undef => 0, default => 1},
    $www_root   ? { undef => 0, default => 1},
    $proxy      ? { undef => 0, default => 1}
  ]
  if $location_config[0] + $location_config[1] + $location_config[2] > 1 {
    fail('Cannot define both directory (www_root or alias_root) and proxy in a virtual host')
  }
  if $location_config[0] + $location_config[1] + $location_config[2] == 0 {
    fail('Cannot create a location reference without a www_root, alias_root, or proxy defined')
  }

  ## Create stubs for vHost File Fragment Pattern
  if ($ssl_only != 'true') {
    file {"${nginx::config::nx_temp_dir}/nginx.d/${vhost}-500-${name}":
      ensure  => $ensure_real,
      content => $content_real,
    }
  }

  ## Only create SSL Specific locations if $ssl is true.
  if ($ssl == 'true') {
    file {"${nginx::config::nx_temp_dir}/nginx.d/${vhost}-800-${name}-ssl":
      ensure  => $ensure_real,
      content => $content_real,
    }
  }
}
