require 'json'

module OsHelper
  include RequestHelper
  include GithubHelper 

  include OsCreateHelper
  include OsDeleteHelper
  include OsCommonHelper

  def login
    os_creds = service_creds("os_api")
    system("oc login #{os_creds['url']} --token=#{os_creds['token']} --insecure-skip-tls-verify")
  end

  def installed_service_version(service_name)
    response = get_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams/#{service_name}")
    unless response == "404"
      response.dig("spec", "tags")&.select{ |d| d["name"] == "latest"}.first.dig("from", "name")
    else
      nil
    end
  end

  def installed_release_version(data)
    installed_service_version(data)[0..2]
  end

  def all_installed_version(data)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(data["name"])}/imagestreams/#{data["name"]}")["spec"]["tags"].select { |d| d["from"]["kind"] == "DockerImage" }.collect { |streams| streams["name"] }
  end

  def set_image_tag(data, version, service_name)
    puts "---SET IMAGE TAG---"
    put_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreamtags/#{data}:latest",
                                                                set_latest_image_stream_tag(data, version)).dig('tag','from','name')
  end

  def get_namespace_services
    service_config.keys.map do |namespace|
      get_all_services(namespace)
    end.flatten
  end

  def get_all_services(namespace)
    get_request_api_os("api/v1/namespaces/#{namespace}/services")["items"].map{|service| service["metadata"]["name"]}
  end

  def get_deployment_config_revision(service_name)
    out = {}
    response = get_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs?labesSelector=service=#{service_name}")["items"]
    response.map{|resp| out[resp.dig('metadata', 'name')] = resp.dig('status', 'latestVersion')}
    out
  rescue => e
    puts "Something went wrong #{e.message}"
  end

  def get_replication_controller_status(service_name, revision, namespace)
    get_request_api_os("api/v1/namespaces/#{namespace}/replicationcontrollers/#{service_name}-#{revision}").dig('metadata','annotations','openshift.io/deployment.phase')
  rescue => e
    puts "Something went wrong in controller status: #{e.message}"
  end

  def image_stream_exists?(service, namespace)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{namespace}/imagestreams/#{service}") != "404"
  end

  def get_image_streams(service_name)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams/#{service_name}")
  end

  def delete_service(service_name, delete_persistent_data)
    deleted_check = []
    deleted_check << delete_os_image_stream(service_name).to_s
    deleted_check << delete_os_route(service_name).to_s
    deleted_check << delete_os_service(service_name).to_s
    deleted_check << delete_os_deployment_config(service_name).to_s
    deleted_check << delete_os_deployment(service_name).to_s
    deleted_check << delete_os_stateful_set(service_name).to_s
    deleted_check << delete_os_job(service_name).to_s
    deleted_check << delete_os_cron_job(service_name).to_s

    deleted_check << delete_os_secret(service_name).to_s if delete_persistent_data == "true"
    deleted_check << delete_os_service_account(service_name).to_s
    deleted_check << delete_os_config_map(service_name).to_s

    deleted_check << delete_os_pods(service_name).to_s
    deleted_check << delete_os_replications_controller(service_name).to_s
    deleted_check << delete_os_demon_set(service_name).to_s
    deleted_check << delete_os_replica_set(service_name).to_s
    deleted_check << delete_os_horizontal_pod_auto_scaler(service_name).to_s
    
    deleted_check << delete_os_pvc(service_name).to_s if delete_persistent_data == "true"
    #deleted_check << delete_os_namespace(service_name).to_s if delete_persistent_data == "true"
    return 204 unless deleted_check.include?("400")
  rescue => e
    puts "Something wrong #{e.message}"
    return 400
  end

   def check_deleted_status(service_name, delete_persistent_data)
    return_codes = []
    return_codes << check_image_stream(service_name)
    return_codes << check_os_service(service_name)
    return_codes << check_deployment_config(service_name)
    return_codes << check_deployment(service_name)
    return_codes << check_route(service_name)
    return_codes << check_secret(service_name) if delete_persistent_data
    return_codes << check_service_account(service_name)
    return_codes << check_config_map(service_name)
    return_codes << check_pvc(service_name) if delete_persistent_data
    #return_codes << check_namespace(service_name) if delete_persistent_data
    return true if return_codes.uniq.count > 1
    return false
  end

  def check_namespace(service_name)
    get_request_api_os("apis/project.openshift.io/v1/projects/#{get_os_namespace(service_name)}")
  end

  def check_image_stream(service_name)
    is_name = image_stream_by_service(service_name).dig('metadata', 'name')
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams/#{is_name}")
  end

  def get_all_namespaces
    get_request_api_os("api/v1/namespaces")['items'].map{|nsp| nsp.dig("metadata", "name") }
  end

  def get_namespaces_by_label(label)
    get_request_api_os("api/v1/namespaces?labelSelector=#{label}")['items'].map{|nsp| nsp.dig("metadata", "name") }
  end

  def get_deployment_configs(namespace)
    get_request_api_os("apis/apps.openshift.io/v1/namespaces/#{namespace}/deploymentconfigs").dig("items")
  end

  def get_installed_service(service_name)
    get_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams/#{service_name}")
  end

  def check_os_service(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/services/#{service_name}")
  end

  def check_deployment_config(service_name)
    get_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs/#{service_name}")
  end

  def check_deployment(service_name)
    get_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments/#{service_name}")
  end

  def check_route(service_name)
    get_request_api_os("apis/route.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/routes/#{service_name}")
  end

  def check_secret(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/secrets/#{service_name}")
  end

  def check_service_account(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/serviceaccounts/#{service_name}")
  end

  def check_config_map(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps/#{service_name}")
  end

  def check_config_map_env_loc(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps/env-loc")
  end

  def check_pvc(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims/#{service_name}")
  end

  def get_pvc(service_name)
    get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims?labelSelector=service=#{service_name}")
  end

  def get_location
    return ENV["OPENSHIFT_SERVER"].split(".")[-3] unless ENV["OPENSHIFT_SERVER"].split(".")[-3].nil?
    return service_creds('os_api')["url"].split(".")[-3]
  end

  def rollout_deployment_config(service_name)
    puts "---ROLLOUT DEPLOYMENT CONFIG---"
    post_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs/#{service_name}/instantiate",
      rollout_dc_template(service_name)
    )
  end

  def update_service(service_name, required_service)
    service_repository = get_service_repository(service_name)["parameters"].map{ |param| param["value"] if param["name"] == "SERVICE_REPOSITORY"}.compact.first
    applications = required_service["applications"].compact.map do |app|
      create_image_stream_tag(app['name'], app["tag"], service_repository, service_name)
      set_image_tag("#{service_name}-#{app['name']}", app["tag"], service_name)
    end
    create_image_stream_service_tag({"NAME" => service_name, "VERSION" => required_service["version"]})
    set_image_tag(service_name, required_service["version"], service_name)

    #sleep 3
    #rollout_deployment_config(service_name)
  end

  def deploy_template(service, required_service)
    applications = {}
    template = get_service_repository(service)
    required_service["applications"].map{|app| applications[app["name"]] = app["tag"]}
    template = update_template_parametrs(template, applications, service, required_service["version"], get_os_namespace(service))
    create_dns_records(template)
    generated_service_template = generate_service_template(template, service)
    generated_service_template["objects"].map do |obj|
      eval("create_#{obj['kind'].underscore}(#{obj}, '#{service}')")
    end
    # rollout_deployment_config(service)
  end


  private

  def create_dns_records(template)
    dns_params = template.dig("parameters").select { |param| param["name"] =~ /HOSTNAME/ }
    
    dns_params.each do |dns_param|
      case dns_param["name"]
      when /HOSTNAME_SYS_*/
        dns_host = ENV["DNS_HOST_SYS"] || "sys.cloudgw-account.#{ENV['LOCATION_DOMAIN']}"
      when /HOSTNAME_EXT_*/
        dns_host = ENV["DNS_HOST_EXT"] || "gw.ext.sys.ocp.#{ENV['LOCATION_DOMAIN']}"
      when /HOSTNAME_VPN_*/
        dns_host = ENV["DNS_HOST_VPN"] || "gw.vpn.sys.ocp.#{ENV['LOCATION_DOMAIN']}"
      else
        next
      end

      hostname = dns_param["value"]

      create_dns_record(hostname, dns_host)
    end
  end

  def delete_dns_records(template)
    dns_params = template.dig("parameters").select { |param| param["name"] =~ /HOSTNAME/ }
    dns_params.each do |dns_param|
      hostname = dns_param["value"]
      delete_dns_record(hostname)
    end
  end

  def update_template_parametrs(template, applications, service, version, namespace)
    white_list = ["VERSION", "APPLICATION_DOMAIN", "NAMESPACE", "REGISTRY_SERVER", "REGISTRY_PROXY_SERVER", "NAMESPACE_PREFIX"]
    white_list << "LOCATION_DOMAIN" unless check_config_map_env_loc(service).dig("data", "location_domain").empty?
    applications.keys.map{|a| white_list.append "TAG_#{a.underscore.upcase}"}
    template["parameters"].map do |param|
      next unless white_list.include?(param["name"])
      case param["name"]
      when "VERSION"
        param["value"] = version
      when "NAMESPACE"
        param["value"] = namespace
      when "APPLICATION_DOMAIN"
        param["value"] = "#{ENV["LOCATION_DOMAIN"]}"
      when "LOCATION_DOMAIN"
        param["value"] = check_config_map_env_loc(service).dig("data", "location_domain")
      when "REGISTRY_SERVER"
        param["value"] = ENV["REGISTRY_SERVER"] if ENV["REGISTRY_SERVER"]
      when "REGISTRY_PROXY_SERVER"
        param["value"] = ENV["REGISTRY_PROXY_SERVER"] if ENV["REGISTRY_PROXY_SERVER"]
      when "NAMESPACE_PREFIX"
        param["value"] = ENV["NAMESPACE_PREFIX"] if ENV["NAMESPACE_PREFIX"]
      else
        param["value"] = applications[param["name"].split("_")[1..].join('-').downcase]
      end
    end

    template
  end

  def set_latest_image_stream_tag(name, version)
    {
      "kind": "ImageStreamTag",
      "apiVersion": "image.openshift.io/v1",
      "metadata": {
      "name": "#{name}:latest"
      },
      "tag": {
        "name": "latest",
        "annotations": nil,
        "from": {
          "kind": "ImageStreamTag",
          "name": "#{version}"
        },
        "importPolicy": {},
        "referencePolicy": {
          "type": "Local"
        }
      },
      "lookupPolicy": {
        "local": false
      }
    }.to_json
  end

  def image_stream_tag_body(app_name, version, repository, service_name)
    {
      "kind": "ImageStreamTag",
      "apiVersion": "image.openshift.io/v1",
      "metadata": {
        "name": "#{service_name}-#{app_name}:#{version}"
      },
      "tag": {
        "name": "",
        "annotations": {},
        "from": {
          "kind": "DockerImage",
          "name": "#{repository}/#{app_name}:#{version}"
        },
      "importPolicy": {},
      "referencePolicy": {
        "type": "Local"
        }
      },
      "lookupPolicy": {
        "local": false
      }
    }.to_json
  end

  def image_stream_service_tag_body(body)
    {
      "kind": "ImageStreamTag",
      "apiVersion": "image.openshift.io/v1",
      "metadata": {
        "name": "#{body["NAME"]}:#{body["VERSION"]}"
      },
      "tag": {
        "name": "",
        "annotations": {},
        "importPolicy": {},
        "referencePolicy": {
          "type": "Source"
        }
      },
      "lookupPolicy": {
        "local": false
      }
    }.to_json
  end

  def rollout_dc_template(service_name)
    {
      "kind": "DeploymentRequest",
      "apiVersion": "apps.openshift.io/v1",
      "name": "#{service_name}",
      "latest": true,
      "force": true
    }.to_json
  end
end
