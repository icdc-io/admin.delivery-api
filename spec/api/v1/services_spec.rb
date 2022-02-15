require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"


# describe 'Endpoint GET /services', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end

# describe 'Endpoint GET /services', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect(response).to have_https_status(:ok)
#   end
# end

# describe 'Endpoint GET /services/:service_name', type: :request do
#   it 'returns service name and service_installed if service exists' do   
#     get "/api/v1/services/httpd",
#       :params => nil,
#       :headers => {:Authorization => jwt_token_admin}
#     expect("#{JSON.parse(response.body)}").to eq "httpd"
#   end
# end

#   it 'returns \'500\' if service doesn\'t exist' do
#     get "/api/v1/services/dsagdhasgdgahds"
#     expect(response).to have_https_status(500)
#   end
# end

# describe 'Endpoint GET /services/:service_name/overview', type: :request do
#   it 'returns service description if service exists' do
#     get "/api/v1/services/httpd/overview"
#     parsed_body=JSON.parse(response.body)
#     expect("#{parsed_body[service_name]} #{parsed_body[description]} #{parsed_body[documentation_url]}").to eq "Apache HTTP Server An example Apache HTTP Server (httpd) application that serves static content. For more information about using this template, including OpenShift considerations, see https://github.com/sclorg/httpd-ex/blob/master/README.md. https://github.com/sclorg/httpd-ex"
#   end

#   it 'returns \'500\' if service doesn\'t exist' do
#     get "/api/v1/services/dsagdhasgdgahds/overview"
#     parsed_body=JSON.parse(response.body)
#     expect(response).to have_https_status(500)
#   end
# end

describe 'Endpoint POST /services/:service_name', type: :request do
  it 'should create service if it exists' do
    post "/api/v1/services/httpd",
      :params => {:version => "1.0.0"}, 
      :headers => {:Authorization => jwt_token_admin}
    expect(response).to eq "httpd"
  end
end

# describe 'Endpoint PUT /services/:service_name', type: :request do
#   it 'upgrade service' do
#   end
# end

# describe 'Endpoint DELETE /services/:service_name', type: :request do
#   it 'delete service' do

#   end
# end
