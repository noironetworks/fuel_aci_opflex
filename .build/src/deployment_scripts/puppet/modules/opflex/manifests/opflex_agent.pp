class opflex::opflex_agent (
     $opflex_log_level = 'debug2',
     $opflex_peer_ip = '10.0.0.30',
     $opflex_peer_port = '8009',
     $opflex_ssl_mode = 'enabled',
     $opflex_endpoint_dir = '/var/lib/opflex-agent-ovs/endpoints',
     $opflex_ovs_bridge_name = 'br-int',
     $opflex_uplink_iface = '',
     $opflex_uplink_vlan = '',
     $opflex_remote_ip = '10.0.0.32',
     $opflex_remote_port = '8472',
     $opflex_virtual_router = 'true',
     $opflex_router_advertisement = 'false',
     $opflex_virtual_router_mac = '00:22:bd:f8:19:ff',
     $opflex_virtual_dhcp_enabled = 'true',
     $opflex_virtual_dhcp_mac = '00:22:bd:f8:19:ff',
     $opflex_cache_dir = '/var/lib/opflex-agent-ovs/ids',
     $opflex_apic_domain_name = '',
     $opflex_encap_type = 'vlan',
     $br_to_patch = '',
) {

    include opflex::params

    if ($opflex_encap_type == "vxlan") {
        firewall { '000 accept 8472 for vxlan ':
           action   => 'accept',
           proto    => 'udp',
           dport    => 8472,
           chain    => 'INPUT',
        }
    }

    define line($file, $line, $ensure = 'present') {
       case $ensure {
           default : { err ( "unknown ensure value ${ensure}" ) }
           present: {
               exec { "/bin/echo '${line}' >> '${file}'":
                   unless => "/bin/grep -qFx '${line}' '${file}'"
               }
           }
           absent: {
               exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
                   onlyif => "/bin/grep -qFx '${line}' '${file}'"
               }
           }
       }
    }

    $xxstr = "macaddress_${opflex_uplink_iface}"
    $macaddr = inline_template("<%= scope.lookupvar(@xxstr) %>")
    $dstr = "interface \"$opflex_uplink_iface.$opflex_uplink_vlan\" {send host-name \"$::fqdn\"; send dhcp-client-identifier 01:$macaddr; }"
 
    package { 'neutron-opflex-agent':
        ensure  => 'present',
        name    => $::opflex::params::package_neutron_opflex,
    }
 
    package { 'agent-ovs':
        ensure  => 'present',
        name    => $::opflex::params::package_agent_ovs,
    }
    
    if ($opflex_encap_type == "vxlan") {
        $opflex_encap_iface = 'br-int_vxlan0'
        file {'agent-conf':
           path => '/etc/opflex-agent-ovs/opflex-agent-ovs.conf',
           mode => '0644',
           content => template('opflex/opflex-agent-ovs.conf.erb'),
           require => Package['agent-ovs'],
        }
    }else {
        $opflex_encap_iface = "p_opflex"
        file {'agent-conf':
           path => '/etc/opflex-agent-ovs/opflex-agent-ovs.conf',
           mode => '0644',
           content => template('opflex/opflex-agent-ovs-vlan.conf.erb'),
           require => Package['agent-ovs'],
        }
    }

    service {'agent-ovs':
       ensure => running,
       enable => true,
       require => File['agent-conf'],
    }

    if ($opflex_encap_type == "vxlan") {
        exec {'add_vxlan_port':
           command => "/usr/bin/ovs-vsctl add-port $opflex_ovs_bridge_name $opflex_encap_iface -- set Interface $opflex_encap_iface type=vxlan options:remote_ip=flow options:key=flow options:dst_port=$opflex_remote_port",
           unless => "/usr/bin/ovs-vsctl list-ports $opflex_ovs_bridge_name | /bin/grep -qFx $opflex_encap_iface",
           returns => [0,1,2],
           require => File['agent-conf'],
        }
    }

    file {'opflex-interface':
       path    => "/etc/network/interfaces.d/ifcfg-${opflex_uplink_iface}.${opflex_uplink_vlan}",
       mode    => '0644',
       content => template('opflex/interface.erb'),
    }

    line { dummy:
       file => "/etc/dhcp/dhclient.conf",
       line => $dstr,
       ensure => present,
    }

    exec {'up-interface':
       command => "/sbin/ifup ${opflex_uplink_iface}.${opflex_uplink_vlan}",
       unless  => "/sbin/ifconfig ${opflex_uplink_iface}.${opflex_uplink_vlan}",
       require => [File['opflex-interface'], Line['dummy']],
       notify  => Service['agent-ovs'],
    }

    ###
    if ($opflex_encap_type == "vlan") {
        file {'p_opflex_interface':
           path    => '/etc/network/interfaces.d/ifcfg-p_opflex',
           mode    => '0644',
           content => template('opflex/opflex-interface.erb'),
        }
    
        exec {'ifup_opflex_interface':
           command  => "/sbin/ifup p_opflex",
           unless   => "/sbin/ifconfig p_opflex",
           require  => File['p_opflex_interface'],
        }
    
        exec {'brctl_add_p_opflex':
           command => "/sbin/brctl addif ${br_to_patch} p_opflex",
           unless  => '/sbin/brctl show ${br_to_patch} | /bin/grep -q p_opflex',
           require => Exec['ifup_opflex_interface', 'persist_p_opflex'],
        }
    
        exec {'persist_p_opflex':
           command => "/bin/sed -i '/^bridge_ports.*$/  s/$/ p_opflex/' /etc/network/interfaces.d/ifcfg-${br_to_patch}",
           unless  => '/bin/grep -q p_opflex /etc/network/interfaces.d/ifcfg-${br_to_patch}',
        }
    }
}
