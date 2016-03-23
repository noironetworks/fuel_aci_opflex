notice('MODULAR: site.pp')

$roles              = hiera('roles')
$deployment_mode    = hiera('deployment_mode')
$aci_opflex_hash    = hiera('aci_opflex',{})
$access_hash        = hiera('access',{})
$management_vip     = hiera('management_vip')
$neutron_settings   = hiera('quantum_settings',{})
$db_connection      = "mysql://neutron:${neutron_settings['database']['passwd']}@${management_vip}/neutron?&read_timeout=60"
$network_scheme     = hiera('network_scheme', {})

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
}elsif ($aci_opflex_hash['driver_type'] == 'GBP') {
    $install_type = 'GBP'
    $class_name = 'opflex_gbp'
}

case $install_type {
    'ML2', 'GBP': {
       class {"neutron::neutron_service_management":
            roles                                    => $roles,
       } 

       class {"cisco_aci::${class_name}":
            ha_prefix                                => $ha_prefix,
            roles                                    => $roles,
            admin_username                           => $access_hash['user'],
            admin_password                           => $access_hash['password'],
            admin_tenant                             => $access_hash['tenant'],
            use_lldp                                 => $aci_opflex_hash['use_lldp'],
            apic_system_id                           => $aci_opflex_hash['apic_system_id'],
            apic_hosts                               => $aci_opflex_hash['apic_hosts'],
            apic_username                            => $aci_opflex_hash['apic_username'],
            apic_password                            => $aci_opflex_hash['apic_password'],
            static_config                            => $aci_opflex_hash['static_config'],
            additional_config                        => $aci_opflex_hash['additional_config'],
            ext_net_enable                           => $aci_opflex_hash['ext_net_enable'],
            ext_net_name                             => $aci_opflex_hash['ext_net_name'],
            ext_net_switch                           => $aci_opflex_hash['ext_net_switch'],
            ext_net_port                             => $aci_opflex_hash['ext_net_port'],
            ext_net_subnet                           => $aci_opflex_hash['ext_net_subnet'],
            ext_net_gateway                          => $aci_opflex_hash['ext_net_gateway'],
	    ext_net_neutron_subnet                   => $aci_opflex_hash['ext_net_neutron_subnet'],
	    ext_net_neutron_gateway                  => $aci_opflex_hash['ext_net_neutron_gateway'],
	    ext_net_encap		             => $aci_opflex_hash['ext_net_encap'],
            ext_net_router_id                        => $aci_opflex_hash['ext_net_router_id'],
            db_connection                            => $db_connection,
            ext_net_config                           => $aci_opflex_hash['ext_net_enable'],
            pre_existing_vpc                         => $aci_opflex_hash['use_pre_existing_vpc'],
            pre_existing_l3_context                  => $aci_opflex_hash['use_pre_existing_l3context'],
            shared_context_name                      => $aci_opflex_hash['shared_context_name'],
            apic_external_network                    => $aci_opflex_hash['apic_external_network'],
            pre_existing_external_network_on         => $aci_opflex_hash['pre_existing_external_network_on'],
            external_epg                             => $aci_opflex_hash['external_epg'],
            opflex_interface                         => $opflex_interface,
            apic_infra_vlan                          => $aci_opflex_hash['apic_infra_vlan'],
            opflex_encap_type                        => $opflex_encap_type,
            opflex_peer_ip                           => $aci_opflex_hash['apic_infra_subnet_gateway'],
            opflex_remote_ip                         => $aci_opflex_hash['apic_infra_anycast_address'],
            br_to_patch                              => $br_to_patch,
            snat_gateway_mask                        => $aci_opflex_hash['snat_gateway_mask'],
            optimized_dhcp                           => $aci_opflex_hash['optimized_dhcp'],
            optimized_metadata                       => $aci_opflex_hash['optimized_metadata'],
       }

       if "compute" in $roles {
           class {'neutron::compute_neutron_metadata':
                debug          => $debug,
                auth_region    => $auth_region,
                auth_url       => "http://${service_endpoint}:35357/v2.0",
                auth_user      => $neutron_admin_username,
                auth_tenant    => $admin_tenant_name,
                auth_password  => $neutron_user_password, 
                shared_secret  => $neutron_metadata_proxy_secret,
                metadata_ip    => $service_endpoint,
           }
       }
    }
    'US1': {
        class {'cisco_aci::generic_apic_ml2':
            ha_prefix                                => $ha_prefix,
            roles                                    => $role2,
            admin_username                           => $access_hash['user'],
            admin_password                           => $access_hash['password'],
            admin_tenant                             => $access_hash['tenant'],
            use_lldp                                 => $aci_opflex_hash['use_lldp'],
            apic_system_id                           => $aci_opflex_hash['apic_system_id'],
            apic_hosts                               => $aci_opflex_hash['apic_hosts'],
            apic_username                            => $aci_opflex_hash['apic_username'],
            apic_password                            => $aci_opflex_hash['apic_password'],
            static_config                            => $aci_opflex_hash['static_config'],
            additional_config                        => $aci_opflex_hash['additional_config'],
            ext_net_enable                           => $aci_opflex_hash['ext_net_enable'],
            ext_net_name                             => $aci_opflex_hash['ext_net_name'],
            ext_net_switch                           => $aci_opflex_hash['ext_net_switch'],
            ext_net_port                             => $aci_opflex_hash['ext_net_port'],
            ext_net_subnet                           => $aci_opflex_hash['ext_net_subnet'],
            ext_net_gateway                          => $aci_opflex_hash['ext_net_gateway'],
            ext_net_neutron_subnet                   => $aci_opflex_hash['ext_net_neutron_subnet'],
            ext_net_neutron_gateway                  => $aci_opflex_hash['ext_net_neutron_gateway'],
            ext_net_encap                            => $aci_opflex_hash['ext_net_encap'],
            ext_net_router_id                        => $aci_opflex_hash['ext_net_router_id'],
            db_connection                            => $db_connection,
            ext_net_config                           => $aci_opflex_hash['ext_net_enable'],
            pre_existing_vpc                         => $aci_opflex_hash['use_pre_existing_vpc'],
            pre_existing_l3_context                  => $aci_opflex_hash['use_pre_existing_l3context'],
            shared_context_name                      => $aci_opflex_hash['shared_context_name'],
            apic_external_network                    => $aci_opflex_hash['apic_external_network'],
            pre_existing_external_network_on         => $aci_opflex_hash['pre_existing_external_network_on'],
            external_epg                             => $aci_opflex_hash['external_epg'],
        }
    }
    'US2b','US3': {
        class {"cisco_aci::${class_name}":
            ha_prefix                                => $ha_prefix,
            roles                                    => $roles,
            admin_username                           => $access_hash['user'],
            admin_password                           => $access_hash['password'],
            admin_tenant                             => $access_hash['tenant'],
            use_lldp                                 => $aci_opflex_hash['use_lldp'],
            apic_system_id                           => $aci_opflex_hash['apic_system_id'],
            apic_hosts                               => $aci_opflex_hash['apic_hosts'],
            apic_username                            => $aci_opflex_hash['apic_username'],
            apic_password                            => $aci_opflex_hash['apic_password'],
            static_config                            => $aci_opflex_hash['static_config'],
            additional_config                        => $aci_opflex_hash['additional_config'],
            ext_net_enable                           => $aci_opflex_hash['ext_net_enable'],
            ext_net_name                             => $aci_opflex_hash['ext_net_name'],
            ext_net_switch                           => $aci_opflex_hash['ext_net_switch'],
            ext_net_port                             => $aci_opflex_hash['ext_net_port'],
            ext_net_subnet                           => $aci_opflex_hash['ext_net_subnet'],
            ext_net_gateway                          => $aci_opflex_hash['ext_net_gateway'],
            ext_net_neutron_subnet                   => $aci_opflex_hash['ext_net_neutron_subnet'],
            ext_net_neutron_gateway                  => $aci_opflex_hash['ext_net_neutron_gateway'],
            ext_net_encap                            => $aci_opflex_hash['ext_net_encap'],
            ext_net_router_id                        => $aci_opflex_hash['ext_net_router_id'],
            db_connection                            => $db_connection,
            ext_net_config                           => $aci_opflex_hash['ext_net_enable'],
            pre_existing_vpc                         => $aci_opflex_hash['use_pre_existing_vpc'],
            pre_existing_l3_context                  => $aci_opflex_hash['use_pre_existing_l3context'],
            shared_context_name                      => $aci_opflex_hash['shared_context_name'],
            apic_external_network                    => $aci_opflex_hash['apic_external_network'],
            pre_existing_external_network_on         => $aci_opflex_hash['pre_existing_external_network_on'],
            external_epg                             => $aci_opflex_hash['external_epg'],
        }
    }
    'US2a': {
        class {"cisco_aci::${class_name}":
            ha_prefix       => $ha_prefix,
            roles           => $roles,
            db_connection   => $db_connection,
        }
    }
    default: {
        fail("Wrong module ${module_name}")
    }
}

