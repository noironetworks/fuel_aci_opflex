#Class neutron::services::apic_server
class neutron::services::apic_server (
    $enabled        = true,
    $manage_service = true,
){
    include neutron::params
    include neutron::services::server

    File['neutron_initd']   ~> Service['neutron-server']

    $aci_opflex_hash    = hiera('aci_opflex',{})
    $router_plugin_enabled = $aci_opflex_hash['router_plugin']
    if $router_plugin_enabled {
        $template = $::neutron::params::initd_file_template_with_router
    } else {
        $template = $::neutron::params::initd_file_template
    }

    file {'neutron_initd':
        ensure => 'present',
        path   => $::neutron::params::initd_file_path,
        source => $template,
    }
}
