module Authenticator
  def config_file
    require 'yaml'
    config_template = ERB.new File.new(File.join(Rails.root, "config/credentials.yml")).read
    YAML.load config_template.result(binding)
  rescue Errno::ENOENT
    raise "File config/credentials.yml didn't created"
  end

  def service_creds(service)
    config_file.dig("environment", ENV["RAILS_ENV"], service.downcase)
  end

  def basic_token(service)
    creds = config_file.dig("environment", ENV["RAILS_ENV"], service.downcase)
    creds["token"] ? creds["token"] : Base64.encode64("#{creds["username"]}:#{creds["password"]}").strip!
  end
end
