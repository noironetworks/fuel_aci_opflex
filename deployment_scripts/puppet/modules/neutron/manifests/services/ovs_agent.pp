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

    exec { 'restart neutron-cisco-apic-host-agent restart':
      command => 'service neutron-cisco-apic-host-agent restart',
      path    => '/usr/sbin:/bin:/sbin:/usr/bin',
      onlyif  => 'service neutron-cisco-apic-host-agent  status',
    }

}
