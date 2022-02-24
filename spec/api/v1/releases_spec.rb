require 'rails_helper'

jwt_token_admin = "Bearer " + JWT.encode({
  "external": {
    "accounts": {
      "test": {
        "roles": ["admin"]
      },
    }
  },
  "groups": ["test.admin"],
  "user_id": "test_admin@test.com",
  "name": "Test Admin"
}, nil)

describe 'Any endpoint', type: :request do
  it 'returns you are not authorized if you dont have jwt token' do
    get "/api/v1/services/httpd/release"
    parsed_body = JSON.parse(response.body)
    expect("#{parsed_body["status"]}").to eq "401"  
    expect("#{parsed_body["data"]["message"]}").to eq "You're not authorized."
  end
end

describe 'Endpoint GET /services/:service_name/release', type: :request do
  it 'returns no version for release if service is not installed' do
    get "/api/v1/services/httpd/release",
    :params => nil,
    :headers => {:Authorization => jwt_token_admin}
    expect(response.body).to eq "No version for release"
  end   
#   Необходим сервис с возможностью установки нескольких версий
#   it 'returns service release version if it is installed' do
#   Установить сервис httpd3 2.0.1
#     get "/api/v1/services/httpd3/release",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to eq #TODO: change to something to equal
#   end
end

# Необходим сервис с возможностью установки нескольких версий
# describe 'Endpoint PUT /services/:service_name/release', type: :request do
#   it 'should return no available version for upgrade if the latest version is installed' do
#     put "/api/v1/services/httpd/release",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to eq #TODO: change to something to equal
#   end
#
#   it 'should update version from update overview' do
#     put "/api/v1/services/httpd/release",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to eq #TODO: change to something to equal
#   end
# end