require 'rails_helper'

# describe 'Endpoint GET /services/:service_name/version', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end

# describe 'Endpoint PUT /services/:service_name/version', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end

# describe 'Endpoint GET /services/:service_name/installed_versions', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end

# describe 'Endpoint GET /services/:service_name/service_versions', type: :request do
#     it 'returns available version for install' do   
#       get "/api/v1/services/httpd/service_versions",
#         :params => nil,
#         :headers => {:Authorization => jwt_token_admin}
#       expect("#{(JSON.parse(response.body))[0]}").to eq "httpd"
#     end
# end