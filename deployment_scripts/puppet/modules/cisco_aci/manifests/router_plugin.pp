#Class cisco_aci::router_plugin
class cisco_aci::router_plugin(
    $router_ip         = '',
    $router_user       = '',
    $router_password   = '',
    $internal_intf     = '',
    $external_intf     = '',
    $external_seg_blob = '',
    $template_id      = 119,
    $gbp              = false,
){
    Cisco_device_manager_plugin <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_config <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_plugin_ml2_cisco <| |> ~> Service <| title == 'neutron-server' |>

    package {'networking-cisco':
      ensure => present,
    }

#    if $gbp {
#      neutron_config {
#        "DEFAULT/service_plugins": value => "networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin,group_policy,neutron.services.metering.metering_plugin.MeteringPlugin";
#      }
#    } else {
#      neutron_config {
#        "DEFAULT/service_plugins": value => "networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin,neutron.services.metering.metering_plugin.MeteringPlugin";
#      }
#    }

    $dvs_hash = hiera('fuel-plugin-vmware-dvs', {})
    $domain = $dvs_hash['vmware_dvs_net_maps']
    neutron_plugin_ml2_cisco {
      "ml2_type_opflex/default_opflex_network": value => "physnet2";
      "ml2_cisco_apic/apic_vmm_type": value => "vmware";
      "ml2_cisco_apic/apic_domain_name": value => $domain;
    }

    cisco_cfg_agent {
      "cfg_agent/routing_svc_helper_class":        value => "networking_cisco.plugins.cisco.cfg_agent.service_helpers.routing_svc_helper_aci.RoutingServiceHelperAci";
    }

    cisco_device_manager_plugin {
      "cisco_hosting_device:$template_id/template_id":           value => $template_id;
      "cisco_hosting_device:$template_id/credentials_id":        value => $template_id;
      "cisco_hosting_device:$template_id/device_id":             value => "SN:deadbeef";
      "cisco_hosting_device:$template_id/admin_state_up":        value => True;
      "cisco_hosting_device:$template_id/management_ip_address": value => $router_ip;
      "cisco_hosting_device:$template_id/protocol_port":         value => 22;
      "cisco_hosting_device:$template_id/tenant_bound":          value => '';
      "cisco_hosting_device:$template_id/auto_delete":           value => False;

      "cisco_hosting_device_credential:$template_id/name":        value => "Universal";
      "cisco_hosting_device_credential:$template_id/description": value => "Credential";
      "cisco_hosting_device_credential:$template_id/user_name":   value => $router_user;
      "cisco_hosting_device_credential:$template_id/password":    value => $router_password;
      "cisco_hosting_device_credential:$template_id/type":        value => '';
    
      "HwVLANTrunkingPlugDriver:$template_id/internal_net_interface_1":  value => "*:$internal_intf";
      "HwVLANTrunkingPlugDriver:$template_id/external_net_interface_1":  value => "*:$external_intf";
     
      "general/l3_admin_tenant":                value => "admin";
      "general/aci_transit_nets_config_file":   value => "/etc/neutron/aci_asr_config.ini";

      "cisco_hosting_device_template:$template_id/name":          value => "ASR1k";
      "cisco_hosting_device_template:$template_id/enabled":       value => True;
      "cisco_hosting_device_template:$template_id/host_category":       value => "Hardware";
      "cisco_hosting_device_template:$template_id/service_types":       value => "router:FW:VPN";
      "cisco_hosting_device_template:$template_id/image":       value => "";
      "cisco_hosting_device_template:$template_id/flavor":       value => "";
      "cisco_hosting_device_template:$template_id/default_credentials_id":       value => $template_id;
      "cisco_hosting_device_template:$template_id/configuration_mechanism":       value => "";
      "cisco_hosting_device_template:$template_id/protocol_port":       value => 22;
      "cisco_hosting_device_template:$template_id/booting_time":       value => 360;
      "cisco_hosting_device_template:$template_id/slot_capacity":       value => 2000;
      "cisco_hosting_device_template:$template_id/desired_slots_free":       value => 0;
      "cisco_hosting_device_template:$template_id/tenant_bound":       value => "";
      "cisco_hosting_device_template:$template_id/device_driver":       value => "networking_cisco.plugins.cisco.device_manager.hosting_device_drivers.noop_hd_driver.NoopHostingDeviceDriver";
      "cisco_hosting_device_template:$template_id/plugging_driver":     value => "networking_cisco.plugins.cisco.device_manager.plugging_drivers.aci_vlan_trunking_driver.AciVLANTrunkingPlugDriver";
    }

    cisco_router_plugin {
      "cisco_router_type:$template_id/name":     value => "ASR1k_router";
      "cisco_router_type:$template_id/description":     value => "Neutron";
      "cisco_router_type:$template_id/template_id":     value => $template_id;
      "cisco_router_type:$template_id/shared":     value => True;
      "cisco_router_type:$template_id/slot_need":     value => 2;
      "cisco_router_type:$template_id/scheduler":     value => "networking_cisco.plugins.cisco.l3.schedulers.l3_router_hosting_device_scheduler.L3RouterHostingDeviceHARandomScheduler";
      "cisco_router_type:$template_id/driver":     value => "networking_cisco.plugins.cisco.l3.drivers.asr1k.aci_asr1k_routertype_driver.AciASR1kL3RouterDriver";
      "cisco_router_type:$template_id/cfg_agent_service_helper":     value => "networking_cisco.plugins.cisco.cfg_agent.service_helpers.routing_svc_helper.RoutingServiceHelper";
      "cisco_router_type:$template_id/cfg_agent_driver":     value => "networking_cisco.plugins.cisco.cfg_agent.device_drivers.asr1k.aci_asr1k_routing_driver.AciASR1kRoutingDriver";

    }

    file {'/etc/neutron/aci_asr_config.ini':
      content => $external_seg_blob,
    }
}
