class cisco_aci::disable_openvswitch_agent (
) {

  exec {'disable_openvswitch_plugin':
     command  => "/usr/sbin/pcs resource disable clone_p_neutron-plugin-openvswitch-agent",
     onlyif => "/usr/sbin/pcs resource show | grep -q clone_p_neutron-plugin-openvswitch-agent",
  }
  exec {'delete_openvswitch_plugin':
     command  => "/usr/sbin/pcs resource delete clone_p_neutron-plugin-openvswitch-agent",
     onlyif => "/usr/sbin/pcs resource show | grep -q clone_p_neutron-plugin-openvswitch-agent",
     require => Exec['disable_openvswitch_plugin'],
  }
         
}
