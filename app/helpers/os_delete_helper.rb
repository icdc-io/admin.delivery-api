module OsDeleteHelper
  include OsCommonHelper

  def delete_os_namespace(service_name)
    puts "---DELETE NAMESPACE---"
    prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'
    delete_request_api_os("apis/project.openshift.io/v1/projects/#{prefix}-#{service_name}")
  end
  
  def delete_os_image_stream(service_name)
    puts "---DELETE IMAGE STREAM---"
    delete_request_api_os("apis/image.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/imagestreams?labelSelector=service=#{service_name}")
  end  

  def delete_os_pods(service_name)
    puts "---DELETE PODS---"
    delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/pods?labelSelector=service=#{service_name}")
  end

  def delete_os_service(service_name)
    puts "---DELETE OS SERVICE---"
    services = get_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/services?labelSelector=service=#{service_name}")
    services["items"].each do |item|
        delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/services/#{item["metadata"]["name"]}")
    end
  end

  def delete_os_replications_controller(service_name)
    puts "---DELETE OS REPLICATION CONTROLLERS---"
    delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/replicationcontrollers?labelSelector=service=#{service_name}")
  end
  
  def delete_os_demon_set(service_name)
    puts "---DELETE OS DS---"
    delete_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/daemonsets?labelSelector=service=#{service_name}")
  end
  
  def delete_os_deployment_config(service_name)
    puts "---DELETE DEPLOYMENT CONFIG---"
    dcs = get_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs?labelSelector=service=#{service_name}")
    dcs["items"].each do |item|
      delete_request_api_os("apis/apps.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/deploymentconfigs/#{item["metadata"]["name"]}")
    end
  end  
  
  def delete_os_deployment(service_name)
    puts "---DELETE DEPLOYMENT---"
    delete_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/deployments?labelSelector=service=#{service_name}")
  end  

  def delete_os_replica_set(service_name)
    puts "---DELETE RS---"
    delete_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/replicasets?labelSelector=service=#{service_name}")
  end  

  def delete_os_route(service_name)
    puts "---DELETE ROUTE---"
    delete_request_api_os("apis/route.openshift.io/v1/namespaces/#{get_os_namespace(service_name)}/routes?labelSelector=service=#{service_name}")
  end  

  def delete_os_secret(service_name)
    puts "---DELETE SECRET---"
    delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/secrets?labelSelector=service=#{service_name}")
  end  

  def delete_os_service_account(service_name)
    puts "---DELETE SERVICE ACCOUNT---"
    delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/serviceaccounts?labelSelector=service=#{service_name}")
  end  

  def delete_os_config_map(service_name)
    puts "---DELETE CONFIG MAP---"
    delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/configmaps?labelSelector=service=#{service_name}")
  end  

  def delete_os_pvc(service_name)
    puts "---DELETE PVC---"
    delete_request_api_os("api/v1/namespaces/#{get_os_namespace(service_name)}/persistentvolumeclaims?labelSelector=service=#{service_name}")
  end

  def delete_os_stateful_set(service_name)
    puts "---DELETE SS---"
    delete_request_api_os("apis/apps/v1/namespaces/#{get_os_namespace(service_name)}/statefulsets?labelSelector=service=#{service_name}")
  end

  def delete_os_horizontal_pod_auto_scaler(service_name)
    puts "---DELETE HPAS---"
    delete_request_api_os("apis/autoscaling/v1/namespaces/#{get_os_namespace(service_name)}/horizontalpodautoscalers?labelSelector=service=#{service_name}")
  end 

  def delete_os_job(service_name)
    puts "---DELETE JOB---"
    delete_request_api_os("apis/batch/v1/namespaces/#{get_os_namespace(service_name)}/jobs?labelSelector=service=#{service_name}")
  end 

  def delete_os_cron_job(service_name)
    puts "---DELETE CJ---"
    delete_request_api_os("apis/batch/v1beta1/namespaces/#{get_os_namespace(service_name)}/cronjobs?labelSelector=service=#{service_name}")
  end 
end