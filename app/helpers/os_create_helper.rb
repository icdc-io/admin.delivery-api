module OsCreateHelper
include OsCommonHelper
  
  def create_image_stream_tag(name, version, repository, service_name)
    puts "---CREATE IMAGE STREAM TAG---"
    puts get_os_namespace(service_name)
    puts image_stream_tag_body(name, version, repository)
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreamtags", image_stream_tag_body(name, version, repository)) #uncomment
  end

  def create_image_stream_service_tag(service)
    puts "---CREATE IMAGE STREAM SERVICE TAG---"
    puts get_os_namespace(service["NAME"])
    puts image_stream_service_tag_body(service)
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service["NAME"])}/imagestreamtags", image_stream_service_tag_body(service)) #uncomment
  end

  def generate_service_template(template, service_name)
    puts "---GENERATE SERVICE TEMPLATE---"
    puts get_os_namespace(service_name)
    # puts template["parameters"]
    post_request_api_os("apis/template.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/processedtemplates", template.to_json)
  end

  def create_service(source, service_name)
    puts "---CREATE SERVICE---"
    puts source.to_json

    # body = source["objects"].select { |s| s["kind"].eql?("Service") }.first
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/services", source.to_json)# if body
  end

  def create_deployment_config(source, service_name)
    puts "---CREATE DEPLOYMENT CONFIG---"
    puts source.to_json

    # body = source["objects"].select { |s| s["kind"].eql?("DeploymentConfig") }.first
    post_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs", source.to_json)# if body
  end

  def create_deployment(source, service_name)
    puts "---CREATE DEPLOYMENT---"
    # body = source["objects"].select { |s| s["kind"].eql?("Deployment") }.first
    puts source.to_json
    post_request_api_os("/apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments", source.to_json) if body
  end

  def create_route(source, service_name)
    puts "---CREATE ROUTE---"
    puts source.to_json

    # body = source["objects"].select { |s| s["kind"].eql?("Route") }.first
    post_request_api_os("apis/route.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/routes", source.to_json)# if body
  end

  def create_secret(source, service_name)
    puts "---CREATE SECRET---"
    # body = source["objects"].select { |s| s["kind"].eql?("Secret") }.first
    puts source.to_json

    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/secrets", source.to_json)# if body
  end

  def create_service_account(source, service_name)
    puts "---CREATE SA---"    
    puts source.to_json
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/serviceaccounts", body.to_json) if body
  end

  def create_configmap(source, service_name)
    puts "---CREATE CM---"
    puts source.to_json
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps", source.to_json) if body
  end

  def create_persistent_volume_claim(source, service_name)
    puts "---CREATE PVC---"
    puts source.to_json
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims", source.to_json)
  end

  def create_namespace(service_name)
    post_request_api_os("apis/project.openshift.io/v1/projects", create_namespace_body(service_name))
  end
    
  def create_image_stream(source, service_name)
    puts "---CREATE IS---"
    puts source.to_json
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams", source.to_json)
  end

end