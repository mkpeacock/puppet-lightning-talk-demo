class mail {

  package { "postfix":
    ensure => present
  }

  package { "mailutils":
    ensure => present
  }

}
