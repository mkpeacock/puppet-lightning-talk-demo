import "composer" # crappy module which installs and updates composer when required
include composer

import "mail" # install and enable outbound email services
include mail

# A Michael module which runs deploy script and setups the deployment folders
class {
    'deployment':
        environment => 'staging',
        new_relic_api_key => 'key',
        new_relic_app_name => 'AppName'
}

# Server density
# Submodule: https://github.com/serverdensity/puppet-serverdensity
class {
    'serverdensity':
        sd_url => 'url',
        agent_key => 'key',
}


# New relic
# Submodule: https://github.com/fsalum/puppet-newrelic
newrelic::server {
    'srvPuppetDemo':
        newrelic_license_key      => '',
        require => File['/var/log/newrelic']
}

newrelic::php {
    'appPuppetDemo':
        newrelic_license_key      => '',
        newrelic_php_conf_appname => '',
        require => File['/var/log/newrelic']
}

# Another Michael Module
class {
    'nginx':
        file => 'staging'
}

# Michael module; needs to know if the box has nginx installed (i.e. isn't a worker machine)
# as if nginx is installed it will notify php-fpm when new php modules are installed
class {
    'php':
        nginx => true
}

# Michael module: just specify a file. Ideally this would use templates
class {
    'iptables':
        file => 'staging'
}

class {
    'hostname':
        hostname => 'box.infrastructure.hostname.com'
}

cron { 'empty-baskets':
    command => '/usr/bin/php /var/www/deployment/console flush:expired_baskets',
    user => 'root',
    minute => [0,15,30,45],
    require => [ Package['php5-cli'], Class['deployment'], Vcsrepo['/var/www/repo'] ]
}

#Beanstalk
# Submodule: https://bitbucket.org/mkpeacock/puppet-beanstalkd.git
import "beanstalkd"
include beanstalkd

# Supervisord
# Submodule: https://github.com/plathrop/puppet-module-supervisor
include supervisor

# Install a supervisor service.
supervisor::service {
  'email':
    ensure      => present,
    command     => '/usr/bin/php /var/www/deployment/console email:sender',
    user        => 'root',
    group       => 'root',
    autorestart => true,
    startsecs => 0,
    require     => [ Package['php5-cli'], Package['beanstalkd'], Class['deployment'] ],
    subscribe => Exec['deploy'],
    notify => Service['beanstalkd']
}

# Checkout a git repo
# Submodule: https://github.com/puppetlabs/puppetlabs-vcsrepo
vcsrepo { "/var/www/repo":
    ensure => latest, # ensure the required branch is the latest from the remote
    provider => git,
    source => 'my-git-remote-url',
    revision => 'staging',
    user => 'root',
    #require => [Sshkey['codebasehq.com'], File['/root/.ssh/deployment_key'], File['/root/.ssh/deployment_key.pub'], File['/root/.ssh/config']], In production I actually tell Puppet about the ssh host, and install keys
    notify => [Exec['deploy'], Exec['composer-update']] # When commits are pulled, notify these chumps
}

# Databases we want to have on our box
$databases = {
  'staging' => {
    ensure  => 'present',
    charset => 'utf8'
  },
}

# MySQL users for the box
$users = {
  'staging@localhost' => {
    ensure                   => 'present',
    max_connections_per_hour => '0',
    max_queries_per_hour     => '0',
    max_updates_per_hour     => '0',
    max_user_connections     => '0',
    password_hash            => 'some-hash',
  },
}

# MySQL server
# Submodule: https://github.com/puppetlabs/puppetlabs-mysql.git
class { '::mysql::server':
  root_password    => 'some-password',
  override_options => { 'mysqld' => { 'max_connections' => '1024', 'bind_address' => '0.0.0.0' } },
  databases => $databases,
  users => $users,
  grants => $grants,
  restart => true # IMPORTANT! because we are letting MySQL in this instance listen on remote connections (as its copied from a networked example I have, we need to restart MySQL after setting it)
}

include '::mysql::client'

class { '::mysql::bindings':
  php_enable => true
}
