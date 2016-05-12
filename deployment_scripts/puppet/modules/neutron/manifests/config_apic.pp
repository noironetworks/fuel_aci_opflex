#Class neutron::config_apic
class neutron::config_apic (
    $apic_system_id                     = '',
    $apic_hosts                         = '10.0.0.1',
    $apic_username                      = 'admin',
    $apic_password                      = 'password',
    $static_config                      = '',
    $additional_config                  = '',
    $apic_external_network              = '',
    $external_epg                       = '',
    $gbp                                = true,
    $snat_gateway_mask                  = '',
    $optimized_dhcp                     = true,
    $optimized_metadata                 = true,
){

    $additional_config_hash = hash(split($additional_config, '[\n=]'))
    $additional_config_options = keys($additional_config_hash)

    define additional_configuration($option = $name) {
        neutron_plugin_ml2_cisco {
            $option: value => $neutron::config_apic::additional_config_hash[$option];
        }
    }

    $static_config_hash = hash(split($static_config, '[\n=]'))
    $static_config_options = keys($static_config_hash)

    define static_configuration($option = $name) {
        neutron_plugin_ml2_cisco {
            $option: value => $neutron::config_apic::static_config_hash[$option];
        }
    }

    $apic_ext_net = $apic_external_network
 
    $apic_provision_infra_on       = 'False'
    $apic_provision_hostlinks_on   = 'False'

    neutron_plugin_ml2_cisco {
        'DEFAULT/apic_system_id':                              value => $apic_system_id;
        'ml2_cisco_apic/apic_hosts':                           value => $apic_hosts;
        'ml2_cisco_apic/apic_username':                        value => $apic_username;
        'ml2_cisco_apic/apic_password':                        value => $apic_password;
        'ml2_cisco_apic/apic_name_mapping':                    value => 'use_name' ;
        'ml2_cisco_apic/root_helper':                          value => 'sudo';
        'ml2_cisco_apic/apic_provision_infra':                 value => $apic_provision_infra_on;
        'ml2_cisco_apic/apic_provision_hostlinks':             value => $apic_provision_hostlinks_on;
        'ml2_cisco_apic/use_vmm':                              value => 'True';
        'ml2_cisco_apic/enable_aci_routing':                   value => 'True'; 
        'ml2_cisco_apic/enable_optimized_dhcp':                value => $optimized_dhcp;
        'ml2_cisco_apic/enable_optimized_metadata':            value => $optimized_metadata;
        'ml2_cisco_apic/single_tenant_mode':                   value => 'False';
        "apic_external_network:${apic_ext_net}/preexisting":   value => 'True';
        "apic_external_network:${apic_ext_net}/external_epg":  value => $external_epg;
        "apic_external_network:${apic_ext_net}/host_pool_cidr":  value => $snat_gateway_mask;
        "opflex/networks":                                     value => '*';
    }

    if ($gbp == true) {
       neutron_plugin_ml2_cisco {
           'group_policy/policy_drivers':                       value => 'implicit_policy,apic';
           'group_policy_implicit_policy/default_ip_pool':      value => '192.168.0.0/16';
       }
    }

    additional_configuration { $additional_config_options: }
    static_configuration { $static_config_options: }

}
