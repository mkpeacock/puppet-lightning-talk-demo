class composer {

    package { "curl":
        ensure => present
    }

    package { "git-core":
        ensure => present
    }

    # Does the initial composer install
    exec { "compose":
        command => '/bin/rm -rfv /var/www/repo/vendor/* && /bin/rm -f /var/www/repo/composer.lock && cd /var/www/repo && /usr/bin/curl -s http://getcomposer.org/installer | /usr/bin/php && COMPOSER_HOME="/var/www" /usr/bin/php /var/www/repo/composer.phar install',
        require => [ Package['curl'], Package['git-core'], Vcsrepo['/var/www/repo'] ],
        creates => "/var/www/repo/composer.lock",
        timeout => 0
    }

    # Does a composer update
    exec { "composer-update":
        command => '/bin/touch /var/www/repo/composer.lock && cd /var/www/repo && COMPOSER_HOME="/var/www" /usr/bin/php /var/www/repo/composer.phar update',
        timeout => 0,
        onlyif => '/usr/bin/test -f /var/www/repo/composer.lock',
        notify => Exec['deploy']
    }
}
