#Class neutron::config

class neutron::config (
    $service_plugins    = 'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',
    $mechanism_drivers  = 'openvswitch',
    $db_connection      = '',
    $opflex_encap_type  = 'vlan',

){
    file_line {'neutron_nopasswd':
        ensure => present,
        line => 'neutron ALL=(ALL) NOPASSWD: ALL',
        path => '/etc/sudoers',
    }
    exec {'neutron_rootwrap':
        command => 'ln -s /usr/bin/neutron-rootwrap /usr/local/bin/neutron-rootwrap',
        path    => '/usr/local/bin/:/bin/',
        creates => '/usr/local/bin/neutron-rootwrap',
    }

    $service_plugin_set = neutron_service_plugins('r', "neutron.services.l3_router.l3_router_plugin.L3RouterPlugin:${service_plugins}")

    $aci_hash = hiera('aci_opflex', {})
    $router_enabled = $aci_hash['router_plugin']
    $driver_type = $aci_hash['driver_type']
 
    if $router_enabled {
       #dont set the service plugin, it will be done at router_config. else it will be duplicate declaration
    } else {
       neutron_config {
         'DEFAULT/service_plugins': value => $service_plugin_set
       }
    }

    neutron_config {
        'DEFAULT/core_plugin':      value => 'neutron.plugins.ml2.plugin.Ml2Plugin';
        'database/connection':      value => $db_connection;
    }
    neutron_plugin_ml2 {
        'ml2/type_drivers':                     value => 'opflex,local,flat,vlan,gre,vxlan';
        'ml2/tenant_network_types':             value => 'opflex';
        'ml2/mechanism_drivers':                value => $mechanism_drivers;
        'securitygroup/enable_security_group':  value => 'True';
        'agent/polling_interval':               value => '2';
        'agent/l2_population':                  value => 'False';
        'agent/arp_responder':                  value => 'False';
    }

    ini_setting {'no_flat_network':
        ensure        => absent,
        section       => 'ml2_type_flat',
        setting       => 'flat_networks',
        path          => '/etc/neutron/plugin.ini',
    }

    if ($opflex_encap_type == "vxlan") {
        ini_setting {'no_vlan_network':
            ensure        => absent,
            section       => 'ml2_type_vlan',
            setting       => 'network_vlan_ranges',
            path          => '/etc/neutron/plugin.ini',
        }
    }
}
