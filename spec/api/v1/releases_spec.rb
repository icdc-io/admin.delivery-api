# require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

# describe 'Any endpoint', type :request do
#   it 'returns you are not authorized if you dont have jwt token' do
#     get "/api/v1/services/httpd/release"
#     expect(response.body).to eq "You're not authorized."
#   end
# end

# describe 'Endpoint GET /services/:service_name/release', type: :request do
#   it 'returns no version for release if service is not installed' do
#     get "/api/v1/services/httpd/release",
#     :params => nil,
#     :headers => {:Authorization => jwt_token_admin}
#     expect(response.body).to eq "No version for release"
#   end
#
#   it 'returns service release version if it is installed' do
#     get "/api/v1/services/httpd/release",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to eq #TODO: change to something to equal
#   end
# end

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