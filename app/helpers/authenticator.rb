module Authenticator
  def service_creds(service)
    Rails.application.credentials.environment[:"#{ENV["RAILS_ENV"]}"][:"#{service.downcase}"]
  end

  def basic_token(service)
    creds = Rails.application.credentials.environment[:"#{ENV["RAILS_ENV"]}"][:"#{service.downcase}"]
    creds["token"] ? creds["token"] : Base64.encode64("#{creds["username"]}:#{creds["password"]}").strip!
  end
end
