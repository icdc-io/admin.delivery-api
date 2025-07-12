module Authenticator
  def config_file
    require 'yaml'
    config_template = ERB.new File.new(File.join(Rails.root, 'config/credentials.yml')).read
    YAML.load config_template.result(binding)
  rescue Errno::ENOENT
    raise "File config/credentials.yml didn't created"
  end

  def service_creds(service)
    config_file.dig('environment', ENV.fetch('RAILS_ENV'), service.downcase)
  end

  # TODO: Remove
  def basic_token(service)
    creds = config_file.dig('environment', ENV.fetch('RAILS_ENV'), service.downcase)
    creds['token'] || Base64.encode64("#{creds['username']}:#{creds['password']}").strip!
  end
  # end TODO

  def operator_jwt
    get_jwt_token(ENV.fetch('OPERATOR_USERNAME'), ENV.fetch('OPERATOR_PASSWORD'))
  end

  def get_jwt_token(login, password)
    response = RestClient::Request.execute(
      method: :post,
      url: "#{ENV.fetch('SSO_URL')}/realms/#{ENV.fetch('SSO_REALM')}/protocol/openid-connect/token",
      payload: {
        username: login,
        password:,
        grant_type: 'password',
        client_id: ENV.fetch('SSO_CLIENT_ID')
      },
      verify_ssl: ENV.fetch('VERIFY_SSL', false)
    )
    JSON.parse(response.body)['access_token']
  end
end
