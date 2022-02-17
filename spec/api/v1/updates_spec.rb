require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

describe 'Any endpoint', type: :request do
  it 'returns you are not authorized if you dont have jwt token' do
    get "/api/v1/services/httpd/update"
    parsed_body = JSON.parse(response.body)
    expect("#{parsed_body["status"]}").to eq "401"  
    expect("#{parsed_body["data"]["message"]}").to eq "You're not authorized."
  end
end

describe 'Endpoint GET /services/:service_name/update', type: :request do
  it 'returns no version for updating if service is not installed' do
    get "/api/v1/services/httpd/update",
      :params => nil,
      :headers => {:Authorization => jwt_token_admin}
    expect(response.body).to eq "No version for updating"
  end
#   Необходима возможность установки сервисов с несколькими версиями
#   it 'returns update version if it exists for service' do
#     Need to install httpd3 2.0.1
#     get "/api/v1/services/httpd/update",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(#{JSON.parse(response.body)["available_service_version"][0]}).to eq "2.1.0"
#   end
end

describe 'Endpoint PUT /services/:service_name/update', type: :request do
#   Необходима возможность установки сервисов с несколькими версиями
#   it 'update version from update overview' do
#     Need to install httpd3 2.0.1
#     put "/api/v1/services/httpd3/update",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to eq #
#   end
end