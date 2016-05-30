notice('MODULAR: reload.pp')

$roles              = hiera('roles')

if "controller" in $roles or "primary-controller" in $roles {
    exec { 'restart neutron-server restart':
        command => 'service neutron-server restart',
        path    => '/usr/sbin:/bin:/sbin:/usr/bin',
        onlyif  => 'service neutron-server status',
    }
} 

if "compute" in $roles {
    exec { 'restart neutron-opflex-agent restart':
        command => 'service neutron-opflex-agent restart',
        path    => '/usr/sbin:/bin:/sbin:/usr/bin',
        onlyif  => 'service  neutron-opflex-agent status',
    }
}

exec { 'restart agent-ovs restart':
    command => 'service agent-ovs restart',
    path    => '/usr/sbin:/bin:/sbin:/usr/bin',
    onlyif  => 'service  agent-ovs status',
}

