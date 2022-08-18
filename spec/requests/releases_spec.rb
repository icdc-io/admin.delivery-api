require 'rails_helper'

describe 'Any endpoint', type: :request do
  it 'returns you are not authorized if you dont have jwt token' do
    get "/api/v1/services/status"
    parsed_body = JSON.parse(response.body)
    expect("#{parsed_body["status"]}").to eq "401"  
    expect("#{parsed_body["data"]["message"]}").to eq "You're not authorized."
  end
end

describe 'Endpoint GET /service/:service_name/release', type: :request do
  it 'returns available versions to install' do
    delete "/api/v1/service/web-server", :headers => header_with_admin
    post "/api/v1/service/web-server/install?version=1.1.2", :headers => header_with_admin
    get "/api/v1/service/web-server/release", :headers => header_with_admin
    version = JSON.parse(response.body)["data"]["version"]
    expect(version).to eq "2.0.3"
    expect(response.status).to eq 200
  end

  it 'returns release is actual if service has actual release' do
    put "/api/v1/service/web-server/release?version=2.0.3", :headers => header_with_admin
    get "/api/v1/service/web-server/release", :headers => header_with_admin
    message = JSON.parse(response.body)["data"]
    expect(message).to eq "release is actual"
    expect(response.status).to eq 200
  end
end