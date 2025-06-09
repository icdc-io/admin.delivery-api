# frozen_string_literal: true

class DNS
  attr_reader :location_domain, :account, :dns_ttl, :dns_owner

  def initialize
    @location_domain = ENV['LOCATION_DOMAIN'].to_s
    @account = ENV['DNS_ACCOUNT'] || ENV['LOCATION_ADMIN_NAME']
    @dns_ttl = (ENV['DNS_TTL'] || 3600).to_i
    @dns_owner = ENV['DNS_OWNER'] || "admin@#{location_domain}"
  end

  def self.create_dns_records(template)
    dns_params(template).each do |dns_param|
      dns_host = DNS.host(dns_param['name'])
      next unless dns_host

      hostname = dns_param['value']
      DNS.new.create_record(hostname, dns_host)
    end
  end

  def self.delete_dns_records(template)
    dns_params(template).each do |dns_param|
      hostname = dns_param['value']
      DNS.delete_record(hostname)
    end
  end

  def create_record(hostname, dns_host)
    coredns = CoreDns::Etcd.new(ENV['DNS_SERVER'])
    return unless coredns.domain("#{hostname}.#{location_domain}").list.empty?

    coredns.domain("#{hostname}.#{location_domain}")
           .add('ttl' => dns_ttl, 'metadata' => { 'account' => account, 'owner' => dns_owner },
                'group' => "#{hostname}.#{location_domain}", 'host' => Resolv.getaddress(dns_host))
  end

  def self.delete_record(hostname)
    domain = coredns.domain("#{hostname}.#{ENV['LOCATION_DOMAIN']}")
    Rails.logger.info { "#{domain.list_all}" }
    domain.list_all.each { |record| domain.delete('name' => record['name']) }
  end

  def self.host(dns_param)
    case dns_param
    when /HOSTNAME_SYS_*/
      ENV.fetch('DNS_HOST_SYS', "sys.cloudgw-account.#{ENV['LOCATION_DOMAIN']}")
    when /HOSTNAME_INT_*/
      ENV.fetch('DNS_HOST_INT', "gwint.sys.ocp.#{ENV['LOCATION_DOMAIN']}")
    when /HOSTNAME_EXT_*/
      ENV.fetch('DNS_HOST_EXT', "gwext.sys.ocp.#{ENV['LOCATION_DOMAIN']}")
    when /HOSTNAME_VPN_*/
      ENV.fetch('DNS_HOST_VPN', "gwvpn.sys.ocp.#{ENV['LOCATION_DOMAIN']}")
    end
  end

  def self.dns_params(template)
    template['parameters'].select { |param| param['name'].include?('HOSTNAME') }
  end
end
