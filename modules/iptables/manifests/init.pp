class iptables ($file = 'iptables') {
    exec { 'load-rules':
        command => "/sbin/iptables -F && /sbin/iptables-restore < /etc/iptables.up.rules",
        require => File['/etc/iptables.up.rules'],
        refreshonly => true
    }

    file { '/etc/iptables.up.rules':
        source => "puppet:///modules/iptables/${file}",
        owner => 'root',
        group => 'root',
        notify => Exec['load-rules']
    }

    file { '/etc/network/if-pre-up.d/iptables':
        source => 'puppet:///modules/iptables/up',
        owner => 'root',
        group => 'root',
        mode => 755
    }
}
