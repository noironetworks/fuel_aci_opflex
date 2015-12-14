#Class neutron::services::ovs_agent
class neutron::services::ovs_agent (
    $enabled        = false,
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

#    service { 'neutron-ovs-agent':
#        ensure     => 'stopped',
#        name       => $::neutron::params::service_ovs_agent,
#        enable     => false,
#        hasstatus  => true,
#        hasrestart => true,
#    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure => 'purged',
    }

    package { 'neutron-metadata-agent':
        ensure => 'present',
    }

    service { 'neutron-metadata-agent':
        ensure     => 'stopped',
        name       => $::neutron::params::service_metadata_agent,
        enable     => false,
        hasstatus  => true,
        hasrestart => true,
    }

#    service {'agent-ovs':
#        ensure     => 'running',
#        name       => 'agent-ovs',
#        enable     => true,
#        hasstatus  => true,
#        hasrestart => false,
#    }

    #Neutron_config<||>              ~> Service['neutron-ovs-agent']
    #Neutron_plugin_ml2<||>          ~> Service['neutron-ovs-agent']
    #Neutron_plugin_ml2_cisco<||>    ~> Service['neutron-ovs-agent']
    #File_line<||>                   ~> Service['neutron-ovs-agent']

}
