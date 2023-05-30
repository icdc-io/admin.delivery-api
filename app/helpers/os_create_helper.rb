module OsCreateHelper
  include OsCommonHelper
  
  def create_image_stream_tag(app_name, version, repository, service_name)
    puts "---CREATE IMAGE STREAM TAG---"
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreamtags", image_stream_tag_body(app_name, version, repository, service_name)) #uncomment
  end

  def create_image_stream_service_tag(service)
    puts "---CREATE IMAGE STREAM SERVICE TAG---"
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service["NAME"])}/imagestreamtags", image_stream_service_tag_body(service)) #uncomment
  end

  def generate_service_template(template, service_name)
    puts "---GENERATE SERVICE TEMPLATE---"
    puts get_os_namespace(service_name)
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
    post_request_api_os("/apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments", source.to_json)# if body
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
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/serviceaccounts", source.to_json)# if body
  end

  def create_config_map(source, service_name)
    puts "---CREATE CM---"
    puts source.to_json
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps", source.to_json)# if body
  end

  def create_persistent_volume_claim(source, service_name)
    puts "---CREATE PVC---"
    puts source.to_json
    post_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims", source.to_json)
  end

  def create_namespace(service_name)
    post_request_api_os("apis/project.openshift.io/v1/projectrequests", create_namespace_body(service_name))
  end
    
  def create_image_stream(source, service_name)
    puts "---CREATE IS---"
    puts source.to_json
    post_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams", source.to_json)
  end

  def create_role(source, service_name)                                                                                        
    puts "---CREATE ROLE---"           
    puts source.to_json                             
    post_request_api_os("apis/rbac.authorization.k8s.io/v1/namespaces/#{get_os_namespace(service_name)}/roles", source.to_json)
  end                                                                                                                          
                       
  def create_role_binding(source, service_name)                                                                                
    puts "---CREATE ROLEBINDING---"
    puts source.to_json            
    post_request_api_os("apis/rbac.authorization.k8s.io/v1/namespaces/#{get_os_namespace(service_name)}/rolebindings", source.to_json)
  end

  def create_cron_job(source, service_name)                                                                                
    puts "---CREATE CRONJOB---"
    puts source.to_json            
    post_request_api_os("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/cronjobs", source.to_json)
  end

  private

  def create_namespace_body(service_name)
    prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'
    {
      "apiVersion": "project.openshift.io/v1",
      "kind": "ProjectRequest",
      "metadata": {
        "name": "#{prefix}-#{service_name}"
      },
      "displayName": "#{service_name.capitalize} Service"
   }.to_json
  end

end
