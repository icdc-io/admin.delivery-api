module Authenticator
  def config_file
    File.read File.join(Rails.root, "config/systems_credentials.json")
  rescue Errno::ENOENT
    raise "File config/github_credentials.json didn't created"
  end

  def service_creds(service)
    JSON.parse(config_file).dig("environment", ENV["RAILS_ENV"], service.downcase)
  end

  def basic_token(service)
    creds = JSON.parse(config_file).dig("environment", ENV["RAILS_ENV"], service.downcase)
    creds["token"] ? creds["token"] : Base64.encode64("#{creds["username"]}:#{creds["password"]}").strip!
  end
end
