#Class neutron::config_dhcp
class neutron::config_dhcp (
){

    neutron_dhcp_agent_config {
        "DEFAULT/dhcp_driver":      value => 'apic_ml2.neutron.agent.linux.apic_dhcp.ApicDnsmasq';
        "DEFAULT/ovs_integration_bridge": value => 'br-int';
        'DEFAULT/enable_isolated_metadata': value => True;
    }

}
