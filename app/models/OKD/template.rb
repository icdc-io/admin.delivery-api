# frozen_string_literal: true

module OKD
  class Template
    def self.deploy(service_name, version)
      template = Github::Template.find_by_service_name(service_name)
      applications = {}
      version['applications'].map { |app| applications[app['name']] = app['tag'] }
      namespace = "#{ENV.fetch('NAMESPACE_PREFIX', 'cloud')}-#{service_name}"
      template = GithubClient::Template.with_updated_params(template, applications, version['version'], namespace)
      create_dns_records(template)
      generated_service_template = OkdClient.generate_service_template(template, service_name, namespace)
      generated_service_template['objects'].map do |obj|
        obj_name = obj.dig('metadata', 'name')
        eval("create_#{obj['kind'].underscore}(#{obj}, '#{service_name}', '#{obj_name}')") # TODO
        puts "debug object #{obj}\n"
      end
    end

    def self.create_dns_records(template)
      dns_params = template['parameters'].select { |param| param['name'].include?('HOSTNAME') }
      dns_params.each do |dns_param|
        dns_host = GithubClient::Template.dns_params(dns_param['name'])
        next unless dns_host

        hostname = dns_param['value']
        create_dns_record(hostname, dns_host)
      end
    end

    def self.create_dns_record(hostname, dns_host)
      location_domain = ENV['LOCATION_DOMAIN'].to_s
      account = ENV['DNS_ACCOUNT'] || ENV['LOCATION_ADMIN_NAME']
      dns_ttl = (ENV['DNS_TTL'] || 3600).to_i
      dns_owner = ENV['DNS_OWNER'] || "admin@#{location_domain}"
      coredns = CoreDns::Etcd.new(ENV['DNS_SERVER'])
      return unless coredns.domain("#{hostname}.#{location_domain}").list.empty?

      coredns.domain("#{hostname}.#{location_domain}").add('ttl' => dns_ttl,
                                                           'metadata' => { 'account' => account, 'owner' => dns_owner }, 'group' => "#{hostname}.#{location_domain}", 'host' => Resolv.getaddress(dns_host))
      existed_records = coredns.domain("#{hostname}.#{location_domain}").list
      p existed_records
      # existed_records.each do |record|
      #  delete_dns_record(hostname) unless record["host"] == dns_host
      # end
    end
  end
end
