class cisco_aci::disable_openvswitch_agent (
) {

  exec {'disable_openvswitch_plugin':
     command  => "/usr/sbin/pcs resource disable clone_p_neutron-openvswitch-agent",
     onlyif => "/usr/sbin/pcs resource show | grep -q clone_p_neutron-openvswitch-agent",
  }
  exec {'delete_openvswitch_plugin':
     command  => "/usr/sbin/pcs resource delete clone_p_neutron-openvswitch-agent",
     onlyif => "/usr/sbin/pcs resource show | grep -q clone_p_neutron-openvswitch-agent",
     require => Exec['disable_openvswitch_plugin'],
  }
  exec {'disable_openvswitch_plugin2':
     command  => "/usr/sbin/pcs resource disable clone_neutron-openvswitch-agent",
     onlyif => "/usr/sbin/pcs resource show | grep -q clone_neutron-openvswitch-agent",
  }
  exec {'delete_openvswitch_plugin2':
     command  => "/usr/sbin/pcs resource delete clone_neutron-openvswitch-agent",
     onlyif => "/usr/sbin/pcs resource show | grep -q clone_neutron-openvswitch-agent",
     require => Exec['disable_openvswitch_plugin2'],
  }
         
}
