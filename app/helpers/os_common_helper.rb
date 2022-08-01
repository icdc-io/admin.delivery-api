module OsCommonHelper
  def get_os_namespace(service_name)
      case service_name
      when "compute"
        return "icdc-compute"
      when "artifactory"
        return "icdc-extra"
      else
        return "icdc-test"
      end
    end
end
