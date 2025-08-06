require 'rails_helper'

describe 'Endpoint POST /service/:service_name/install', type: :request do
  it 'returns a 204 OK status' do
    post '/api/v1/service/web-server/install?version=2.0.3', headers: header_with_admin
    expect(response.status).to eq 204
  end
end

describe 'Endpoint DELETE /service/:service_name', type: :request do
  it 'returns a 204 OK status' do
    delete '/api/v1/service/web-server', headers: header_with_admin
    expect(response.status).to eq 204
  end
end

describe 'Endpoint PUT /service/:service_name/release', type: :request do
  it 'returns a 204 OK status' do
    post '/api/v1/service/web-server/install?version=1.1.2', headers: header_with_admin
    put '/api/v1/service/web-server/release?version=2.0.3', headers: header_with_admin
    expect(response.status).to eq 204
  end
end

describe 'Endpoint PUT /service/:service_name/downgrade', type: :request do
  it 'returns a 204 OK status' do
    put '/api/v1/service/web-server/downgrade/?version=2.0.1', headers: header_with_admin
    expect(response.status).to eq 204
  end
end
