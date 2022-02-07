require 'json/jwt'

class ApplicationController < ActionController::API
  include ResponseHelper
  before_action :authorize

  def authorize
    return not_authorized unless auth_header
    auth_method, token = auth_header.split(' ')
    identification_headers
    case auth_method
    when 'Bearer'
      $token = decoded_token token
    when 'Basic'
      login, password = Base64.decode64(token).split(':')
      $token = decoded_token get_jwt_token(login, password)
    end
    unless validate
      $token = nil
      msg = "You don`t have permissions to admit this section."
      forbidden(msg)
    end
  end

  private

  def auth_header
    request.headers['Authorization']
  end

  def validate
return true
    $token.dig("groups").include?("#{$current_admin_group}")
  rescue => e
    false
  end

  def identification_headers
    $current_admin_group = ENV["LOCATION_ADMIN_GROUP"]
  end

  def get_jwt_token(login, password)
    response = RestClient::Request.execute(
      :method => :post,
      :url => "#{config_n[:url]}/auth/realms/#{config_n[:realm]}/protocol/openid-connect/token",
      :payload => {
        :username   => login,
        :password   => password,
        :grant_type => "password",
        :client_id  => config_n[:client_id]
      }
    )
    JSON.parse(response.body)["access_token"]
  end

  def config_n
    YAML.load_file(File.join(Rails.root, "config", "keycloak.yml"))
  end

  def decoded_token(token = nil)
    @@public_key ||= public_key
    JWT.decode(token, @@public_key, false, algorithm: 'RS256')[0]
  rescue JWT::DecodeError
    abort("Unauthorized! Can't decode JWT token!")
  end

  def public_key
    response = RestClient::Request.execute(
      :method => :get,
      :url => "#{config_n[:url]}/auth/realms/#{config_n[:realm]}/protocol/openid-connect/certs"
    )
    JSON.parse(response.body)["keys"].map do |key|
      next unless key["alg"] == "RS256"
      return JSON::JWK.new(key).to_key
    end
    nil
  end
end

