class nginx ($file = 'default') {
  package { "nginx":
    ensure => present
  }

  file { '/etc/nginx/sites-available/default':
    source => "puppet:///modules/nginx/${file}",
    owner => 'root',
    group => 'root',
    notify => Service['nginx'],
    require => Package['nginx']
  }

  service { "nginx":
    ensure => running,
    require => Package["nginx"]
  }
}
