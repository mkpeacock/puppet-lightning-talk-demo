class hostname ($hostname = 'server') {
    file { "/etc/hostname":
        ensure => present,
        owner => root,
        group => root,
        mode => 644,
        content => "${hostname}\n",
        notify => Exec["set-hostname"],
    }

    exec { "set-hostname":
        command => "/bin/hostname -F /etc/hostname",
        unless => "/usr/bin/test `hostname` = `/bin/cat /etc/hostname`"
    }
}
