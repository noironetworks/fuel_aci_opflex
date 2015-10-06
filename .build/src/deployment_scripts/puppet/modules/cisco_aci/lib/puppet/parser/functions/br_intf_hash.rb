Puppet::Parser::Functions::newfunction(:br_intf_hash, :type => :rvalue) do |argv|
    brctl_show = `brctl show`.split(/\n+/).select{|l| l.match(/^[\w\-]+\s+\d+/) or l.match(/^\s+[\w\.\-]+/)}
    port_mappings = {}
    br_name = nil
    brctl_show.each do |line|
      line.rstrip!
      case line
        when /^([\w\-]+)\s+[\d\.abcdef]+\s+(yes|no)\s+([\w\-\.]+$)/i
          br_name = $1
          port_name = $3
        when /^\s+([\w\.\-]+)$/
          #br_name using from previous turn
          port_name = $1
        else
          next
      end
      if br_name
        port_mappings[port_name] = {
          'bridge'  => br_name,
          'br_type' => :lnx
        }
      end
    end
    #debug("LNX ports to bridges mapping: #{port_mappings.to_yaml.gsub('!ruby/sym ',':')}")
    return port_mappings
end
