module ServiceHelper
    include OsHelper
    def create_dns_record(hostname, dns_host)
      location_domain = "#{ENV["LOCATION_DOMAIN"]}"
      account = ENV["DNS_ACCOUNT"] || ENV["LOCATION_ADMIN_NAME"]
      dns_ttl = ENV["DNS_TTL"].to_i || 3600
      dns_owner = ENV["DNS_OWNER"] || "admin@#{location_domain}"
      puts "---CREATE FQDN---"
      puts "ttl"=>dns_ttl,"metadata"=>{"account"=> account,"owner"=>dns_owner}, "group"=>"#{hostname}.#{location_domain}","host"=>Resolv.getaddress(dns_host)
      # resolve by type CNAME

      existed_records = coredns.domain("#{hostname}.#{location_domain}").list

      existed_records.each do |record|
        delete_dns_record(hostname) unless record["host"] == dns_host  
      end

      if coredns.domain("#{hostname}.#{location_domain}").list.empty?
        coredns.domain("#{hostname}.#{location_domain}").add({"ttl"=>dns_ttl,"metadata"=>{"account"=> account,"owner"=>dns_owner}, "group"=>"#{hostname}.#{location_domain}","host"=>dns_host})
      end
      # resolve by type A
      #coredns.domain("#{hostname}.#{location_domain}").add("ttl"=>dns_ttl,"metadata"=>{"account"=> account,"owner"=>dns_owner}, "group"=>"#{hostname}.#{location_domain}","host"=>Resolv.getaddress(dns_host))
    end


    def delete_dns_record(hostname)
      puts "---DELETE FQDN---"
      location_domain = "#{ENV["LOCATION_DOMAIN"]}"
      domain = coredns.domain("#{hostname}.#{location_domain}")
      domain.list_all.each{ |record| domain.delete("name"=> record["name"]) }
    end

    def coredns
      CoreDns::Etcd.new(ENV['DNS_SERVER'])
    end
end
