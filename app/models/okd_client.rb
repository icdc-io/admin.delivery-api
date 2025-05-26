# frozen_string_literal: true

include Authenticator
class OkdClient
  def self.all_namespaces
    get_resource('api/v1/namespaces')['items'].map { |namespace| namespace.dig('metadata', 'name') }
  end

  def self.get_resource(resource, options = nil)
    os_creds = service_creds('os_api')
    uri = URI.parse("#{os_creds['url']}/#{resource}?#{options}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{os_creds['token']}"
    response = Net::HTTP.start(uri.hostname, uri.port,
                               { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end
end
