require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

# describe 'Any endpoint', type: :request do
#   it 'returns you are not authorized if you dont have jwt token' do
#     get "/api/v1/services/httpd/version"
#     parsed_body = JSON.parse(response.body)
#     expect("#{parsed_body["status"]}").to eq "401"  
#     expect("#{parsed_body["data"]["message"]}").to eq "You're not authorized."
#   end
# end

# describe 'Endpoint GET /services/:service_name/version', type: :request do
#   it 'returns installed version of service' do
#     post "/api/v1/services/httpd",
#       :params => {:version => "1.0.0"}, 
#       :headers => {:Authorization => jwt_token_admin}
#     get "/api/v1/services/httpd/version",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response.status).to eq 200
#   end
# end

# # Необходима возможность устанавливать сервисы с несколькими версиями
# # describe 'Endpoint PUT /services/:service_name/version', type: :request do
# #   it 'downgrade version from version overview if service is installed and version for downgrade exists' do
# #     put "/api/v1/services/httpd/version",
# #       :params => nil,
# #       :headers => {:Authorization => jwt_token_admin}
# #     expect(response).to have_https_status(:ok) #TODO: change to something that can confirm
# #   end
# # end

# describe 'Endpoint GET /services/:service_name/versions', type: :request do

# #   Необходима возможность устанавливать сервисы с несколькими версиями
# #   it 'returns available versions for downgrade if service is installed and versions are availible' do 
# #     # Need to install httpd2 version 2.0.0
# #     get "/api/v1/services/httpd2/versions",
# #       :params => nil,
# #       :headers => {:Authorization => jwt_token_admin}
# #     expect("#{(JSON.parse(response.body))[0]}").to !eq "1.0.0"
# #   end

#   it 'returns no version for downgrade if service is installed and have only one version' do
#     post "/api/v1/services/httpd",
#       :params => {:version => "1.0.0"}, 
#       :headers => {:Authorization => jwt_token_admin} 
#     get "/api/v1/services/httpd/versions",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect("#{response.body}").to eq "No version to downgrade"
#   end
# end

# describe 'Endpoint GET /services/:service_name/latest', type: :request do
#     it 'returns available version for install' do   
#       get "/api/v1/services/httpd/latest",
#         :params => nil,
#         :headers => {:Authorization => jwt_token_admin}
#       expect("#{(JSON.parse(response.body))[0]}").to eq "1.0.0"
#     end
# end