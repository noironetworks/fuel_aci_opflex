$roles              = hiera('roles')
$deployment_mode    = hiera('deployment_mode')
$aci_opflex_hash    = hiera('aci_opflex',{})
$access_hash        = hiera('access',{})
$management_vip     = hiera('management_vip')
$neutron_settings   = hiera('quantum_settings',{})
$db_connection      = "mysql://neutron:${neutron_settings['database']['passwd']}@${management_vip}/neutron?&read_timeout=60"
$network_scheme     = hiera_hash('network_scheme', {})

$debug                         = hiera('debug', true)
$auth_region                   = 'RegionOne'
$admin_tenant_name             = 'services'
$neutron_admin_username        = 'neutron' 
$neutron_config                = hiera('quantum_settings')
$neutron_user_password         = $neutron_config['keystone']['admin_password']
$service_endpoint              = hiera('management_vip')
$neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']

prepare_network_config($network_scheme)
$intf   = get_network_role_property('neutron/private', 'phys_dev')
$opflex_interface   = $intf[0]

$br_intf_hash = br_intf_hash()

$br_to_patch = $br_intf_hash[$opflex_interface][bridge]

validate_hash($aci_opflex_hash)
if has_key($aci_opflex_hash, 'opflex_encap_type') {
    $opflex_encap_type = $aci_opflex_hash['opflex_encap_type']
} else {
    $opflex_encap_type = 'vlan'
}

$ha_prefix = $deployment_mode ? {
    'ha_compact'    => 'ha_',
    default         => '',
}

if ($aci_opflex_hash['driver_type'] == 'ML2') {
    $install_type = 'ML2'
    $class_name = 'opflex_ml2'
    $gbp = false
}elsif ($aci_opflex_hash['driver_type'] == 'GBP') {
    $install_type = 'GBP'
    $class_name = 'opflex_gbp'
    $gbp = true
}

if member($roles, 'primary-controller') {
   $role = "primary-controller"
} elsif member($roles, 'controller') {
   $role = "controller"
} elsif member($roles, 'compute') {
   $role = "compute"
} else {
   $role = hiera('role')
}

$edgenat = $aci_opflex_hash['edgenat']
if $edgenat {
    $edgenat_vlan_range = $aci_opflex_hash['edgenat_vlan_range']
} else {
    $edgenat_vlan_range = ''
}

$enable_router_plugin = $aci_opflex_hash['router_plugin']

case $install_type {
    'ML2', 'GBP': {
       if $role == "primary-controller" {
          class {'cisco_aci::disable_openvswitch_agent':
                require   => Class['opflex::opflex_agent'],
          }
       }

       class {"cisco_aci::apt_fix": }

       class {"cisco_aci::${class_name}":
            ha_prefix                                => $ha_prefix,
            role                                     => $role,
            admin_username                           => $access_hash['user'],
            admin_password                           => $access_hash['password'],
            admin_tenant                             => $access_hash['tenant'],
            use_lldp                                 => "true",
            apic_system_id                           => $aci_opflex_hash['apic_system_id'],
            apic_hosts                               => $aci_opflex_hash['apic_hosts'],
            apic_username                            => $aci_opflex_hash['apic_username'],
            apic_password                            => $aci_opflex_hash['apic_password'],
            static_config                            => $aci_opflex_hash['static_config'],
            additional_config                        => $aci_opflex_hash['additional_config'],
            db_connection                            => $db_connection,
            apic_external_network                    => $aci_opflex_hash['apic_external_network'],
            external_epg                             => $aci_opflex_hash['external_epg'],
            opflex_interface                         => $opflex_interface,
            apic_infra_vlan                          => $aci_opflex_hash['apic_infra_vlan'],
            opflex_encap_type                        => $opflex_encap_type,
            opflex_peer_ip                           => $aci_opflex_hash['apic_infra_subnet_gateway'],
            opflex_remote_ip                         => $aci_opflex_hash['apic_infra_anycast_address'],
            br_to_patch                              => $br_to_patch,
            snat_gateway_mask                        => $aci_opflex_hash['snat_gateway_mask'],
            optimized_dhcp                           => "true",
            optimized_metadata                       => "true",
            edgenat                                  => $edgenat,
            edgenat_vlan_range                       => $edgenat_vlan_range,
            require                                  => Class['cisco_aci::apt_fix'],
       }

       case $role {
        /controller/: {
          if ($enable_router_plugin == true) {
             class {"cisco_aci::router_plugin":
               router_ip          => $aci_opflex_hash['router_mgmt_ip'],
               router_user        => $aci_opflex_hash['router_user'],
               router_password    => $aci_opflex_hash['router_password'],
               internal_intf      => $aci_opflex_hash['router_internal_interface'],
               external_intf      => $aci_opflex_hash['router_external_interface'],
               external_seg_blob  => $aci_opflex_hash['external_segments'],
               gbp                => $gbp,
             }
          }
        }
       }

       if $role == "compute" {
           service {'neutron-opflex-agent':
              ensure => running,
              enable => true,
           }

           class {'neutron::compute_neutron_metadata':
                debug          => $debug,
                auth_region    => $auth_region,
                auth_url       => "http://${service_endpoint}:35357/v2.0",
                auth_user      => $neutron_admin_username,
                auth_tenant    => $admin_tenant_name,
                auth_password  => $neutron_user_password, 
                shared_secret  => $neutron_metadata_proxy_secret,
                metadata_ip    => $service_endpoint,
                notify         => Service['neutron-opflex-agent'],
           }
       }
    }
    default: {
        fail("Wrong module ${module_name}")
    }
}
