# require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

# describe 'Any endpoint', type :request do
#   it 'returns you are not authorized if you dont have jwt token' do
#     get "/api/v1/services/httpd/update"
#     expect(response.body).to eq "You're not authorized."
#   end
# end

# describe 'Endpoint GET /services/:service_name/update', type: :request do
#   it 'returns no version for updating if service is not installed' do
#     get "/api/v1/services/httpd/update",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response.body).to eq "No version for updating"
#   end
#
#   it 'returns update version if it exists for service' do
#     Need to install httpd3 2.0.1
#     get "/api/v1/services/httpd/update",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(#{JSON.parse(response.body)["available_service_version"][0]}).to eq "2.1.0"
#   end
# end

# describe 'Endpoint PUT /services/:service_name/update', type: :request do
#   it 'update version from update overview' do
#     Need to install httpd3 2.0.1
#     put "/api/v1/services/httpd3/update",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to eq #
#   end
#
#   it 'returns no available version for update.' do
#     Need to install httpd 1.0.0
#     put "/api/v1/services/httpd/update",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(#{JSON.parse(response.body)}).to eq "No available version for update."
#   end
# end