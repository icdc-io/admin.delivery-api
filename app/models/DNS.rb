# frozen_string_literal: true

class DNS
  attr_reader :location_domain, :account, :dns_ttl, :dns_owner, :coredns

  def initialize
    @location_domain = ENV.fetch('LOCATION_DOMAIN')
    @account = ENV.fetch('DNS_ACCOUNT', ENV.fetch('LOCATION_ADMIN_NAME'))
    @dns_ttl = ENV.fetch('DNS_TTL', 3600)
    @dns_owner = ENV.fetch('DNS_OWNER', "admin@#{location_domain}")
    @coredns = CoreDns::Etcd.new(ENV.fetch('DNS_SERVER'))
  end

  def self.create_records(template)
    hostname_params(template).each do |dns_param|
      dns_host = DNS.host(dns_param['name'])
      next unless dns_host

      hostname = dns_param['value']
      DNS.new.create_record(hostname, dns_host)
    end
  end

  def self.delete_records(template)
    hostname_params(template).each do |dns_param|
      hostname = dns_param['value']
      DNS.new.delete_record(hostname)
    end
  end

  def create_record(hostname, dns_host)
    zone_name = normalize("#{hostname}.#{location_domain}")
    return unless coredns.domain(zone_name).list.empty?

    coredns.domain(zone_name)
           .add('ttl' => dns_ttl, 'metadata' => { 'account' => account, 'owner' => dns_owner },
                'group' => zone_name, 'host' => Resolv.getaddress(dns_host))
  end

  def delete_record(hostname)
    zone_name = normalize("#{hostname}.#{location_domain}")
    domain = coredns.domain(zone_name)
    Rails.logger.info { domain.list_all.to_s }
    domain.list_all.each { |record| domain.delete('name' => normalize(record['name'])) }
  end

  def self.host(dns_param)
    case dns_param
    when /HOSTNAME_SYS_*/
      ENV.fetch('DNS_HOST_SYS', "sys.cloudgw-account.#{ENV.fetch('LOCATION_DOMAIN')}")
    when /HOSTNAME_INT_*/
      ENV.fetch('DNS_HOST_INT', "gwint.sys.ocp.#{ENV.fetch('LOCATION_DOMAIN')}")
    when /HOSTNAME_EXT_*/
      ENV.fetch('DNS_HOST_EXT', "gwext.sys.ocp.#{ENV.fetch('LOCATION_DOMAIN')}")
    when /HOSTNAME_VPN_*/
      ENV.fetch('DNS_HOST_VPN', "gwvpn.sys.ocp.#{ENV.fetch('LOCATION_DOMAIN')}")
    end
  end

  def self.hostname_params(template)
    template['parameters'].select { |param| param['name'].include?('HOSTNAME') }
  end

  def normalize(name)
    name.ascii_only? ? name : SimpleIDN.to_ascii(name)
  end
end
