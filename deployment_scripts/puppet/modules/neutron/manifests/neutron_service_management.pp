class neutron::neutron_service_management (
    $roles         = [''],
){
    include neutron::params

    $clone_ovs_agent = "clone_$::neutron::params::ha_ovs_agent"
    $clone_dhcp_agent = "clone_$::neutron::params::ha_dhcp_agent"

    if "controller" in $roles or "primary-controller" in $roles {
       exec {"remove-dhcp-ovs-constrain":
            command  => "/usr/sbin/pcs constraint colocation remove $clone_ovs_agent $clone_dhcp_agent",
       } 
       exec {"remove-constrain-order":
            command => "/usr/sbin/pcs constraint order remove $clone_ovs_agent $clone_dhcp_agent",
       }
    }
}
