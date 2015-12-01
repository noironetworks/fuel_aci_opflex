#Class neutron::config_dhcp
class neutron::config_dhcp (
){
    exec { 'Remove dhcp dependancy colocation from CRM':
        command => 'crm configure delete clone_p_neutron-dhcp-agent-with-clone_p_neutron-plugin-openvswitch-agent',
        path    => '/usr/sbin:/bin:/sbin',
        onlyif  => 'crm configure show | grep clone_p_neutron-dhcp-agent-with-clone_p_neutron-plugin-openvswitch-agent',
    }

    exec { 'Remove dhcp dependancy order from CRM':
        command => 'crm configure delete clone_p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent',
        path    => '/usr/sbin:/bin:/sbin',
        onlyif  => 'crm configure show | grep clone_p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent',
    }

    neutron_dhcp_agent_config {
        "DEFAULT/dhcp_driver":      value => 'apic_ml2.neutron.agent.linux.apic_dhcp.ApicDnsmasq';
        "DEFAULT/ovs_integration_bridge": value => 'br-int';
        'DEFAULT/enable_isolated_metadata': value => True;
    }

}
