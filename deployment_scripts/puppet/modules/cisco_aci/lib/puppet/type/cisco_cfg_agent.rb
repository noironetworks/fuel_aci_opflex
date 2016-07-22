Puppet::Type.newtype(:cisco_cfg_agent) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from cisco_cfg_agent.ini'
    newvalues(/\S+\/\S+/)
  end

  autorequire(:package) do ['neutron'] end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end
  end
end
