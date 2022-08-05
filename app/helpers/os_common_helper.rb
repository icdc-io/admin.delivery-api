require "yaml"

module OsCommonHelper
  def service_config
    file = YAML.load_file("config/services.yaml")
    JSON.parse(file.to_json.to_s.gsub("$","#{ENV["PLATFORM_NAME"]}"))
  end


  def get_os_namespace(service_name)
    sc = service_config
    nmsp = nil
    sc.keys.map do |namespace|
      return namespace if sc[namespace].include?(service_name)
    end
    return abort("No such namespace for this service. Check services config.")
    nmsp
    end
end
