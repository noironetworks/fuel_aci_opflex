#Class neutron::services::ha_agents
class neutron::services::ha_agents (
    $enabled        = true,
    $manage_service = true,
){
    include neutron::params

    if $manage_service {
        if $enabled {
            $service_ensure = 'running'
        } else {
            $service_ensure = 'stopped'
        }
    }

    exec { 'Remove l3 dependancy colocation from CRM':
      command => 'crm configure delete clone_p_neutron-l3-agent-with-clone_p_neutron-plugin-openvswitch-agent',
      path    => '/usr/sbin:/bin:/sbin',
      onlyif  => 'crm configure show | grep clone_p_neutron-l3-agent-with-clone_p_neutron-plugin-openvswitch-agent',
    } ~>

    exec { 'Remove l3 dependancy order from CRM':
      command => 'crm configure delete clone_p_neutron-l3-agent-after-clone_p_neutron-plugin-openvswitch-agent',
      path    => '/usr/sbin:/bin:/sbin',
      onlyif  => 'crm configure show | grep clone_p_neutron-l3-agent-after-clone_p_neutron-plugin-openvswitch-agent',
    } ~>

   service {'neutron-ovs-agent-service':
        ensure     => stopped,
        name       => 'neutron-plugin-openvswitch-agent',
        enable     => false,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'pacemaker',
        tag        => 'ha_agents',
    } ~>

    service {'neutron-l3-agent':
        ensure     => stopped,
        name       => 'p_neutron-l3-agent',
        enable     => false,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'pacemaker',
        tag        => 'ha_agents',
    } ~>

    exec { 'kill p_neutron-l3-agent':
      command => 'killall neutron-l3-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => 'pgrep  -f neutron-l3-agent',
    } ~>

    exec { 'kill neutron-openvswitch-agent':
      command => 'killall neutron-openvswitch-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => 'pgrep  -f neutron-openvswitch-agent',
    } ~>

    exec { 'Cleanup p_neutron-l3-agent':
      command => 'pcs resource clear p_neutron-l3-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
    } ~>

    exec { 'Cleanup p_neutron-plugin-openvswitch-agent':
      command => 'pcs resource clear p_neutron-plugin-openvswitch-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
    } ~>

    package { 'neutron-plugin-openvswitch-agent':
      ensure => 'purged',
    }

    package { 'neutron-l3-agent':
      ensure => 'purged',
    } ~>

    exec { 'restart openvswitch restart':
      command => 'service openvswitch-switch restart',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => '/etc/init.d/openvswitch-switch status',
    }

    service {'neutron-opflex-agent':
        ensure     => 'running',
        name       => 'neutron-opflex-agent',
        enable     => true,
        hasstatus  => true,
        hasrestart => false,
    }

    Neutron_config<||>              ~> Service<| tag == 'ha_agents' |>
    Neutron_plugin_ml2<||>          ~> Service<| tag == 'ha_agents' |>
    Neutron_plugin_ml2_cisco<||>    ~> Service<| tag == 'ha_agents' |>
    File_line<||>                   ~> Service<| tag == 'ha_agents' |>

}
