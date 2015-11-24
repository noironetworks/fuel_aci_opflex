#Class lldp

class lldp (
        $ensure       = 'present',
        $autoupdate   = true,
        $package_name = 'lldpd',
        $service_name = 'lldpd',
    ){

    $aci_opflex_hash    = hiera('aci_opflex',{})
    $opflex_encap_type = $aci_opflex_hash['opflex_encap_type']

    include lldp::params
    case $ensure {
        'present': {
            if $autoupdate {
                $pkg_ensure = 'latest'
            } else {
                $pkg_ensure = 'present'
            }
            $svc_ensure   = 'running'
            $svc_enable   = true
            $file_ensure  = 'present'
        }
        'absent': {
            $pkg_ensure   = 'absent'
            $svc_ensure   = 'stopped'
            $svc_enable   = false
            $file_ensure  = 'absent'
        }
        'purged': {
            $pkg_ensure   = 'purged'
            $svc_ensure   = 'stopped'
            $svc_enable   = false
            $file_ensure  = 'absent'
        }
        default: {
        }
    }

    package {$package_name:
        ensure => $pkg_ensure,
    }

    if $opflex_encap_type == "vxlan" {
       $content = inline_template($::lldp::params::config_file_data_vxlan)
    }

    if $opflex_encap_type == "vlan" {
       $content = inline_template($::lldp::params::config_file_data_vlan)
    }

    file {$::lldp::params::config_file_path:
        ensure  => $file_ensure,
        content => $content,
        require => Package[$package_name],
        notify  => Service[$service_name],
    }

    service {$service_name:
        ensure     => $svc_ensure,
        enable     => $svc_enable,
        require    => File[$::lldp::params::config_file_path],
        hasstatus  => false,
        hasrestart => true,
    }

}

