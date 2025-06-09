require "yaml"

module OsCommonHelper
# TODO: Remove  
  def service_config
    file = YAML.load_file("config/services.yaml")
    JSON.parse(file.to_json.to_s.gsub("$","#{ENV["NAMESPACE_PREFIX"].present? ? ENV["NAMESPACE_PREFIX"] : "cloud"}"))
  end
# end TODO
  def get_os_namespace(service_name)
    namespace_prefix = "#{ENV["NAMESPACE_PREFIX"].present? ? ENV["NAMESPACE_PREFIX"] : "cloud"}".downcase
    namespace_prefix + "-" + service_name
  end
end
