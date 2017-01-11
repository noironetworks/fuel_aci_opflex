#Class cisco_aci::router_plugin
class cisco_aci::router_plugin(
    $router_ip         = '',
    $router_user       = '',
    $router_password   = '',
    $internal_intf     = '',
    $external_intf     = '',
    $external_seg_blob = '',
    $template_id      = 119,
    $template_id1     = 219,
    $gbp              = false,
){
    Cisco_device_manager_plugin <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_config <| |> ~> Service <| title == 'neutron-server' |>
    Neutron_plugin_ml2_cisco <| |> ~> Service <| title == 'neutron-server' |>

    package {'networking-cisco':
      ensure => present,
    }
  
    service {'neutron-cisco-cfg-agent':
       ensure => running,
       enable => true,
       require => Package['networking-cisco'],
    }  
 
    if $gbp {
       $splugin = "networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin,group_policy,servicechain,neutron.services.metering.metering_plugin.MeteringPlugin"
    } else {
       $splugin = "networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin,neutron.services.metering.metering_plugin.MeteringPlugin"
    }
    neutron_config {
      "DEFAULT/service_plugins": value => $splugin;
    }

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
     
      "general/l3_admin_tenant":                value => "services";
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

      "cisco_hosting_device_template:$template_id1/name":        value => "NetworkNode";
      "cisco_hosting_device_template:$template_id1/enabled":     value => True;
      "cisco_hosting_device_template:$template_id1/host_category":     value => "Network_Node";
      "cisco_hosting_device_template:$template_id1/service_types":     value => "router:FW:VPN";
      "cisco_hosting_device_template:$template_id1/image":     value => "";
      "cisco_hosting_device_template:$template_id1/flavor":     value => "";
      "cisco_hosting_device_template:$template_id1/default_credentials_id":     value => "1";
      "cisco_hosting_device_template:$template_id1/configuration_mechanism":     value => "";
      "cisco_hosting_device_template:$template_id1/protocol_port":     value => "22";
      "cisco_hosting_device_template:$template_id1/booting_time":     value => "360";
      "cisco_hosting_device_template:$template_id1/slot_capacity":     value => "2000";
      "cisco_hosting_device_template:$template_id1/desired_slots_free":     value => "0";
      "cisco_hosting_device_template:$template_id1/tenant_bound":     value => "";
      "cisco_hosting_device_template:$template_id1/device_driver":     value => "networking_cisco.plugins.cisco.device_manager.hosting_device_drivers.noop_hd_driver.NoopHostingDeviceDriver";
      "cisco_hosting_device_template:$template_id1/plugging_driver":     value => "networking_cisco.plugins.cisco.device_manager.plugging_drivers.noop_plugging_driver.NoopPluggingDriver";

    }

    cisco_router_plugin {
      "routing/default_router_type":             value => "ASR1k_router";
      "cisco_router_type:$template_id/name":     value => "ASR1k_router";
      "cisco_router_type:$template_id/description":     value => "Neutron";
      "cisco_router_type:$template_id/template_id":     value => $template_id;
      "cisco_router_type:$template_id/shared":     value => True;
      "cisco_router_type:$template_id/slot_need":     value => 2;
      "cisco_router_type:$template_id/scheduler":     value => "networking_cisco.plugins.cisco.l3.schedulers.l3_router_hosting_device_scheduler.L3RouterHostingDeviceHARandomScheduler";
      "cisco_router_type:$template_id/driver":     value => "networking_cisco.plugins.cisco.l3.drivers.asr1k.aci_asr1k_routertype_driver.AciASR1kL3RouterDriver";
      "cisco_router_type:$template_id/cfg_agent_service_helper":     value => "networking_cisco.plugins.cisco.cfg_agent.service_helpers.routing_svc_helper.RoutingServiceHelper";
      "cisco_router_type:$template_id/cfg_agent_driver":     value => "networking_cisco.plugins.cisco.cfg_agent.device_drivers.asr1k.aci_asr1k_routing_driver.AciASR1kRoutingDriver";

      "cisco_router_type:$template_id1/name":     value => "Namespace_Neutron_router";
      "cisco_router_type:$template_id1/description":     value => "\"Neutron router implemented in Linux network namespace\"";
      "cisco_router_type:$template_id1/template_id":     value => $template_id1;
      "cisco_router_type:$template_id1/ha_enabled_by_default":     value => False;
      "cisco_router_type:$template_id1/shared":     value => True;
      "cisco_router_type:$template_id1/slot_need":     value => 0;
      "cisco_router_type:$template_id1/scheduler":     value => "";
      "cisco_router_type:$template_id1/driver":     value => "";
      "cisco_router_type:$template_id1/cfg_agent_service_helper":     value => "";
      "cisco_router_type:$template_id1/cfg_agent_driver":     value => "";

    }

    file {'/etc/neutron/aci_asr_config.ini':
      content => $external_seg_blob,
    }
}
