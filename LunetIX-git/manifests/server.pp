class git::server (
  $git_puppet_project = 'puppet-modules',
  $git_repodir =  '/srv/git',
  $gituser = 'git',
  $gitgroup = 'git',
  $gitpackage = 'git',
  $package_ensure = 'installed',
){

exec { "selinux_prepare_git":
    require => [ Package["$gitpackage"], Package['policycoreutils-python'], File["$git_repodir"] ],
    command => "semanage fcontext -a -t ssh_home_t '/var/www/git/.ssh/authorized_keys' &&
		semanage fcontext -a -e /var/www/git /srv/git &&
		restorecon -R /srv/git",
    unless => "ls -Zd /srv/git/|grep -q git_content_t",
    path => [ "/usr/bin/", "/usr/sbin/" ],
}


package { "$gitpackage":
    ensure => $package_ensure,
}

package { "httpd":
    ensure => $package_ensure,
}

package { "policycoreutils-python":
    ensure => $package_ensure,
}

service { "httpd":
    ensure => "running",
    require => Package["httpd"],
}

file { "/var/www/html/$git_puppet_project":
    ensure => directory,
    owner => $gituser,
    group => $gitgroup,
    mode => "775",
}

file { "$git_repodir":
    ensure => directory,
    owner => $gituser,
    group => $gitgroup,
    mode => "775",
}

file { "$git_repodir/.ssh":
    ensure => directory,
    owner => $gituser,
    group => $gitgroup,
    mode => "700",
}

exec { "git_init_bare":
    command => "git init --bare ${git_repodir}/${git_puppet_project}.git",
    path => [ '/bin/', '/usr/bin/' ],
    unless => "test -d ${git_repodir}/${git_puppet_project}.git/objects",
    require => [ Package["$gitpackage"], File["$git_repodir"], Exec["selinux_prepare_git"] ],
    before => File["${git_repodir}/${git_puppet_project}.git/hooks/post-receive"],
}

file { "${git_repodir}/${git_puppet_project}.git/hooks/post-receive":
    ensure => file,
    owner => $gituser,
    group => $gitgroup,
    mode => "755",
    source => "puppet:///modules/git/post-receive",
}
}
