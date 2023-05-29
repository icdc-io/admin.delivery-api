module ServiceHelper
    include OsHelper
    def create_dns_record(service_name)                                                               
        location_domain = "#{ENV["LOCATION_DOMAIN"]}"
        account = ENV["SYS_ACCOUNT"] || "sys"
        dns_ttl = ENV["DNS_TTL"].to_i || 600
        dns_owner = ENV["DNS_OWNER"] || "admin@#{location_domain}"
        puts "---CREATE FQDN---"
        puts "ttl"=>dns_ttl,"metadata"=>{"account"=> account,"owner"=>dns_owner}, "group"=>"#{hostname}.#{location_domain}","host"=>Resolv.getaddress(dns_host)                                                            
        coredns.domain("#{hostname}.#{location_domain}").add("ttl"=>dns_ttl,"metadata"=>{"account"=> account,"owner"=>dns_owner}, "group"=>"#{hostname}.#{location_domain}","host"=>Resolv.getaddress(dns_host))       
    end                                                                      


    def delete_dns_record(service_name)
        puts "---DELETE FQDN---"
        location_domain = "#{ENV["LOCATION_DOMAIN"]}"
        domain = coredns.domain("#{hostname}.#{location_domain}")
        domain.list_all.each{|record| domain.delete("name"=> record["name"])}
    end                                     

    def coredns
        CoreDns::Etcd.new(ENV['DNS_SERVER'])
    end
end
