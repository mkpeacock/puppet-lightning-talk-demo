class deployment ($environment = 'production', $new_relic_api_key = '', $new_relic_app_name = 'PHP Application') {

    # Originally I had Puppet create timestamped deployment folders for me and recursively copy out the repo
    # This was both slow, and tbt, inappropriate for puppet, and was moved to a deployment script
    # This is left as reference for me
    $raw_timestamp = generate('/bin/date', '+%Y%m%d%H%M%S')
    $timestamp = inline_template('<%= @raw_timestamp.chomp %>')

    $application_directories = ["/var/www/deployments/", "/var/www/deployment/", "/var/www/backups/", "/var/www/backups/database/"]

    file {'/var/www':
        ensure => "directory",
        owner => "www-data",
        group => "www-data"
    }

    file { $application_directories:
        ensure  => "directory",
        owner   => "www-data",
        group   => "www-data",
        mode    => 755,
        require => File['/var/www']
    }

    # Stupid newrelic module doesn't do this!
    file {'/var/log/newrelic':
        ensure => "directory",
        owner => "root",
        group => "root"
    }

    file { '/var/www/deploy.sh':
        source => 'puppet:///modules/deployment/deploy.sh',
        owner => root,
        group => root,
        require => File['/var/www'],
        mode => 0755
    }

    # Run the deploy script, but only when told to by another resource
    exec { "deploy":
        command => "/var/www/deploy.sh 0 1 ${environment} ${new_relic_api_key} ${new_relic_app_name}"
        require => [Class['mysql::server'], Class['mysql::client'], Vcsrepo["/var/www/repo"], Class['php'], File["/var/www/deploy.sh"]],
        refreshonly => true
    }

  }

}
