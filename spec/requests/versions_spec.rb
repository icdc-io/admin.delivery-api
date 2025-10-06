require 'rails_helper'

describe 'Endpoint GET /service/:service_name/install', type: :request do
  it 'returns installed version of the service' do
    get '/api/v1/service/web-server/install', headers: header_with_admin
    expect(response.status).to eq 200
  end
end

describe 'Endpoint GET /service/:service_name/downgrade', type: :request do
  it 'returns all installed versions for downgrade for the service' do
    get '/api/v1/service/web-server/downgrade', headers: header_with_admin
    expect(response.status).to eq 200
  end
end

describe 'Endpoint GET /service/:service_name/version', type: :request do
  it 'returns available versions of the service to install' do
    get '/api/v1/service/web-server/version', headers: header_with_admin
    expect(response.status).to eq 200
  end
end
