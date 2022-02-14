# require 'rails_helper'

describe 'Endpoint GET /services/:service_name/status', type: :request do
  it 'returns no option for check status if service is not installed' do
    get "/api/v1/services/httpd/status",
    :params => nil,
    :headers => {:Authorization => jwt_token_admin}
    expect(response.body).to eq "No option for check status"
  end
end

# describe 'Endpoint GET /services/:service_name/update', type: :request do
#   it 'returns a 200 OK status' do
#     get "/api/v1/services"
#     expect(response).to have_https_status(:ok)
#   end
# end