class neutron::neutron_service_management (
    $role         = '',
){
    include neutron::params

    $clone_ovs_agent = "clone_$::neutron::params::ha_ovs_agent"
    $clone_dhcp_agent = "clone_$::neutron::params::ha_dhcp_agent"

    if $role =~ /controller/ {
       exec {"remove-dhcp-ovs-constrain":
            command  => "/usr/sbin/pcs constraint colocation remove $clone_ovs_agent $clone_dhcp_agent",
       } 
       exec {"remove-constrain-order":
            command => "/usr/sbin/pcs constraint order remove $clone_ovs_agent $clone_dhcp_agent",
       }
    }
}
