# frozen_string_literal: true

module OkdApi
  def self.get_resource(resource, options = nil)
    os_creds = credentials
    uri = URI.parse("#{os_creds['url']}/#{resource}?#{options}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{os_creds['token']}"
    response = Net::HTTP.start(uri.hostname, uri.port,
                               { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end

  def self.get_all_namespaces
    get_resource('api/v1/namespaces')['items'].map { |namespace| namespace.dig('metadata', 'name') }
  end

  private

  def self.credentials
    config_template = ERB.new File.new(File.join(Rails.root, 'config/credentials.yml')).read
    config_file = YAML.load config_template.result(binding)
    os_creds = config_file.dig('environment', ENV['RAILS_ENV'], 'os_api')
  end
end
