# require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

describe 'Endpoint GET /services/:service_name/release', type: :request do
  it 'returns no version for release if service is not installed' do
    get "/api/v1/services/httpd/release",
    :params => nil,
    :headers => {:Authorization => jwt_token_admin}
    expect(response.body).to eq "No version for release"
  end
end

# describe 'Endpoint GET /services/:service_name/update', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end

# describe 'Endpoint PUT /services/:service_name/update', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end