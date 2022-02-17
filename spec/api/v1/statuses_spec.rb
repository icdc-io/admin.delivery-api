# require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

# describe 'Any endpoint', type :request do
#   it 'returns you are not authorized if you dont have jwt token' do
#     get "/api/v1/services/httpd/update"
#     expect(response.body).to eq "You're not authorized."
#   end
# end

describe 'Endpoint GET /services/:service_name/status', type: :request do
#   it 'returns no option for check status if service is not installed' do
#     get "/api/v1/services/httpd/status",
#       :params => nil,
#       :headers => {:Authorization => jwt_toke n_admin}
#     expect(response.body).to eq "No option for check status"
#   end
  
  it 'returns status depended on option' do
    get "/api/v1/services/httpd/status",
      :params => {:status_check => "check"},
      :headers => {:Authorization => jwt_token_admin}
    expect(response.body).to eq "OK"
  end

  # TODO:Need to check other status_check options, when they will be ready
end