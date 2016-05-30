#Class neutron::compute_neutron_metadata
class neutron::compute_neutron_metadata (
    $auth_password,
    $shared_secret,
    $debug                                = false,
    $auth_region                          = '',
    $auth_url                             = 'http://localhost:35357/v2.0',
    $auth_user                            = 'neutron',
    $auth_tenant                          = 'services',
    $metadata_ip                          = '',
    $auth_insecure                        = false,
    $auth_ca_cert                         = undef,
    $metadata_port                        = '8775',
    $metadata_workers                     = '2',
    $metadata_backlog                     = '4096',
){

  neutron_metadata_agent_config {
    'DEFAULT/debug':                          value => $debug;
    'DEFAULT/auth_url':                       value => $auth_url;
    'DEFAULT/auth_insecure':                  value => $auth_insecure;
    'DEFAULT/auth_region':                    value => $auth_region;
    'DEFAULT/admin_tenant_name':              value => $auth_tenant;
    'DEFAULT/admin_user':                     value => $auth_user;
    'DEFAULT/admin_password':                 value => $auth_password, secret => true;
    'DEFAULT/nova_metadata_ip':               value => $metadata_ip;
    'DEFAULT/nova_metadata_port':             value => $metadata_port;
    'DEFAULT/metadata_proxy_shared_secret':   value => $shared_secret;
    'DEFAULT/metadata_workers':               value => $metadata_workers;
    'DEFAULT/metadata_backlog':               value => $metadata_backlog;
  }

  if $auth_ca_cert {
    neutron_metadata_agent_config {
      'DEFAULT/auth_ca_cert':                 value => $auth_ca_cert;
    }
  } else {
    neutron_metadata_agent_config {
      'DEFAULT/auth_ca_cert':                 ensure => absent;
    }
  }

}
