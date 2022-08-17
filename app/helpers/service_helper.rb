module ServiceHelper
    include OsHelper
    def create_dns_record(service_name)
        location_platform_io = "#{get_location}.#{ENV["PLATFORM_NAME"]}.io"
        account = ENV["SYS_ACCOUNT"]
        puts "---CREATE FQDN---"
        puts "ttl"=>3600,"metadata"=>{"account"=> account}, "group"=>"#{service_name}.#{location_platform_io}","host"=>Resolv.getaddress("api.#{location_platform_io}")
        coredns.domain("#{service_name}.#{location_platform_io}").add("ttl"=>3600,"metadata"=>{"account"=> account}, "group"=>"#{service_name}.#{location_platform_io}","host"=>Resolv.getaddress("api.#{location_platform_io}"))
    end

    def delete_dns_record(service_name)
        puts "---DELETE FQDN---"
        location_platform_io = "#{get_location}.#{ENV["PLATFORM_NAME"]}.io"
        domain = coredns.domain("#{service_name}.#{location_platform_io}")
        domain.list_all.each{|record| domain.delete("name"=> record["name"])}
    end

    def coredns
        CoreDns::Etcd.new(ENV['DNS_SERVER'])
    end
end