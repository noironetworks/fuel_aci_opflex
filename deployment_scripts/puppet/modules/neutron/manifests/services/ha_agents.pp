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
    }

    exec { 'Remove l3 dependancy order from CRM':
      command => 'crm configure delete clone_p_neutron-l3-agent-after-clone_p_neutron-plugin-openvswitch-agent',
      path    => '/usr/sbin:/bin:/sbin',
      onlyif  => 'crm configure show | grep clone_p_neutron-l3-agent-after-clone_p_neutron-plugin-openvswitch-agent',
    }

    package { 'neutron-plugin-openvswitch-agent':
      ensure => 'purged',
    }

    package { 'neutron-l3-agent':
      ensure => 'purged',
    }

    service {'neutron-dhcp-agent':
        ensure     => $service_ensure,
        name       => $::neutron::params::ha_dhcp_agent,
        enable     => $enabled,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'pacemaker',
        tag        => 'ha_agents',
    }

    service {'neutron-metadata-agent':
        ensure     => $service_ensure,
        name       => $::neutron::params::ha_metadata_agent,
        enable     => $enabled,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'pacemaker',
        tag        => 'ha_agents',
    }

    service {'neutron-plugin-openvswitch-agent':
        ensure     => stopped,
        name       => $::neutron::params::ha_ovs_agent,
        enable     => false,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'pacemaker',
        tag        => 'ha_agents',
    }

    service {'neutron-l3-agent':
        ensure     => stopped,
        name       => $::neutron::params::ha_l3_agent,
        enable     => false,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'pacemaker',
        tag        => 'ha_agents',
    }
    exec { 'kill p_neutron-l3-agent':
      command => 'killall neutron-l3-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => 'pgrep  -f neutron-l3-agent',
    }

    exec { 'Cleanup p_neutron-l3-agent':
      command => 'pcs resource clear p_neutron-l3-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => 'crm configure show | grep  cli-ban-p_neutron-l3-agent',
    }

    exec { 'Cleanup p_neutron-plugin-openvswitch-agent':
      command => 'pcs resource clear p_neutron-plugin-openvswitch-agent',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => 'crm configure show | grep cli-ban-p_neutron-plugin-openvswitch-agent',
    }

    exec { 'restart openvswitch restart':
      command => 'service openvswitch-switch restart',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => '/etc/init.d/openvswitch-switch status',
    }

    Neutron_config<||>              ~> Service<| tag == 'ha_agents' |>
    Neutron_plugin_ml2<||>          ~> Service<| tag == 'ha_agents' |>
    Neutron_plugin_ml2_cisco<||>    ~> Service<| tag == 'ha_agents' |>
    File_line<||>                   ~> Service<| tag == 'ha_agents' |>

}
