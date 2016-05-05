#Class apic::api
class apic::api (
  $package_ensure  = 'present',
) {

    include apic::params
    package { 'apic_api':
        ensure => $package_ensure,
        name   => $::apic::params::package_apic_api,
    }

    package { 'apic_ml2_driver':
        ensure => $package_ensure,
        name   => $::apic::params::package_neutron_ml2_driver_apic,
    }

}
