require 'rails_helper'

describe 'Endpoint GET /service/:service_name/update', type: :request do
  it 'returns update version' do
    get "/api/v1/service/web-server/update", :headers => header_with_admin
    expect(response.status).to eq 200
  end
end

describe 'Endpoint PUT /service/:service_name/update', type: :request do
  it 'returns 200 if OK' do
    put "/api/v1/service/web-server/update?version=2.0.3", :headers => header_with_admin
    expect(response.status).to eq 204
  end
end