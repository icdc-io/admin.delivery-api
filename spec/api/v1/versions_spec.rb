require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

# describe 'Any endpoint', type :request do
#   it 'returns you are not authorized if you dont have jwt token' do
#     get "/api/v1/services/httpd/version"
#     expect(response.body).to eq "You're not authorized."
#   end
# end

# describe 'Endpoint GET /services/:service_name/version', type: :request do
#   it 'returns installed version of service' do
#     # Need to install httpd version 1.0.0
#     get "/api/v1/services/httpd/version",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect("#{(JSON.parse(response.body)})["version"]").to eq "1.0.0"
#   end
# end

# describe 'Endpoint PUT /services/:service_name/version', type: :request do
#   it 'downgrade version from version overview if service is installed and version for downgrade exists' do
#     put "/api/v1/services/httpd/version",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to have_https_status(:ok) #TODO: change to something that can confirm
#   end
# end

# describe 'Endpoint GET /services/:service_name/installed_versions', type: :request do
#   it 'returns available versions for downgrade if service is installed and versions are availible' do 
#     # Need to install httpd2 version 2.0.0
#     get "/api/v1/services/httpd2/installed_versions",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect("#{(JSON.parse(response.body))[0]}").to !eq "1.0.0"
#   end

#   it 'returns no version for downgrade if service is installed and have only one version' do 
#     get "/api/v1/services/httpd/installed_versions",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect("#{(JSON.parse(response.body))[0]}").to eq "No version to downgrade"
#   end
# end

# describe 'Endpoint GET /services/:service_name/service_versions', type: :request do
#     it 'returns available version for install' do   
#       get "/api/v1/services/httpd/service_versions",
#         :params => nil,
#         :headers => {:Authorization => jwt_token_admin}
#       expect("#{(JSON.parse(response.body))[0]}").to eq "1.0.0"
#     end
# end