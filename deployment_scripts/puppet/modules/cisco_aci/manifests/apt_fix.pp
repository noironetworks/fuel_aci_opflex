class cisco_aci::apt_fix (
){
  apt::conf {'unauth':
    priority => 99,
    content => 'APT::Get::AllowUnauthenticated 1;',
    notify_update => false
  }
}
