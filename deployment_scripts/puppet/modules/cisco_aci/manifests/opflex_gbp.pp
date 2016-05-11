#Class cisco_aci::opflex_gbp
class cisco_aci::opflex_gbp (
    $ha_prefix                          = '',
    $role                               = 'compute',
    $use_lldp                           = true,
    $apic_system_id                     = '',
    $apic_hosts                         = '10.0.0.1',
    $apic_username                      = 'admin',
    $apic_password                      = 'password',
    $static_config                      = '',
    $additional_config                  = '',
    $service_plugins                    = 'apic_gbp_l3,group_policy,neutron.services.metering.metering_plugin.MeteringPlugin',
    $mechanism_drivers                  = 'apic_gbp',
    $admin_username                     = 'admin',
    $admin_password                     = 'admin',
    $admin_tenant                       = 'admin',
    $db_connection                      = '',
    $apic_external_network              = '',
    $external_epg                       = '',
    $opflex_interface                   = '',
    $apic_infra_vlan                    = '',
    $opflex_encap_type                  = 'vxlan',
    $opflex_peer_ip                     = '',
    $opflex_remote_ip                   = '',
    $br_to_patch                        = '',
    $snat_gateway_mask                  = '',
    $optimized_dhcp                     = true,
    $optimized_metadata                 = true,
){
    include 'apic::params'
    include 'apic::api'

    if $use_lldp {
        class {'apic::svc_agent':
            role    => $role
        }
    }

    case $role {
        /controller/: {
            if $use_lldp {
                include 'apic::svc_agent'
            }
            include 'neutron::services::apic_server'
            #include "neutron::services::${ha_prefix}agents"

            class {'neutron::config_auth':
                admin_username => $admin_username,
                admin_password => $admin_password,
                admin_tenant   => $admin_tenant,
            }

            $gbp_pkgs = ["group-based-policy", "group-based-policy-automation", "group-based-policy-ui", "python-group-based-policy-client"]
            package {$gbp_pkgs:
               ensure => installed,
            }

        }
        'compute': {
            class {'neutron::services::ovs_agent':
                enabled        => false,
                manage_service => true,
            }
            class {'neutron::services::server':
                enabled        => false,
                manage_service => true,
            }
        }
        default: {
        }
    }

    Neutron_config <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_plugin_ml2 <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_plugin_ml2_cisco <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_dhcp_agent_config <| |> ~> Service <| title == 'neutron-dhcp-agent' |>

    #KVR: comment out next 3 lines, dont need neutron-ovs-agent
    #Neutron_config <| |> ~> Service <| title == 'neutron-ovs-agent' |>
    #Neutron_plugin_ml2 <| |> ~> Service <| title == 'neutron-ovs-agent' |>
    #Neutron_plugin_ml2_cisco <| |> ~> Service <| title == 'neutron-ovs-agent' |>
    File <| title == 'neutron_initd' |> ~> Service <| title == 'neutron-server' |>
    Heat_config <| |> ~> Service['heat-api', 'heat-engine', 'heat-api-cloudwatch', 'heat-api-cfn']

    if $use_lldp {
        include 'lldp'
        include 'apic::host_agent'

    }

    case $role {
        /controller/: {

            class {'neutron::config':
                service_plugins   => $service_plugins,
                mechanism_drivers => $mechanism_drivers,
                db_connection     => $db_connection,
                opflex_encap_type => $opflex_encap_type,
            }
            
            class {'neutron::config_dhcp':}
        
            class {'neutron::config_apic':
                apic_system_id                     => $apic_system_id,
                apic_hosts                         => $apic_hosts,
                apic_username                      => $apic_username,
                apic_password                      => $apic_password,
                static_config                      => $static_config,
                additional_config                  => $additional_config,
                apic_external_network              => $apic_external_network,
                external_epg                       => $external_epg,
                gbp                                => true,
                snat_gateway_mask                  => $snat_gateway_mask,
                optimized_dhcp                     => $optimized_dhcp,
                optimized_metadata                 => $optimized_metadata,
            }

            service {'heat-api':
              ensure => 'running',
              enable => 'true',
            }
        
            service {'heat-api-cloudwatch':
              ensure => 'running',
              enable => 'true',
            }
        
            service {'heat-api-cfn':
              ensure => 'running',
              enable => 'true',
            }
        
            service {'heat-engine':
              ensure => 'running',
              enable => 'true',
            }

            heat_config {
               'DEFAULT/plugin_dirs': value => "/usr/lib/python2.7/site-packages/gbpautomation/heat";
            }
        }
        default: {
        }
    }

    class {'opflex::opflex_agent':
        role                               => $role,
        ha_prefix                          => $ha_prefix,
        opflex_ovs_bridge_name             => 'br-int',
        opflex_uplink_iface                => $opflex_interface,
        opflex_uplink_vlan                 => $apic_infra_vlan,
        opflex_apic_domain_name            => $apic_system_id,
        opflex_encap_type                  => $opflex_encap_type,
        opflex_peer_ip                     => $opflex_peer_ip,
        opflex_remote_ip                   => $opflex_remote_ip,
        br_to_patch                        => $br_to_patch,
    }
}
