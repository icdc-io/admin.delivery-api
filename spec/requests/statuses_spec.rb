require 'rails_helper'

describe 'Endpoint GET /services/status', type: :request do
  it 'returns no option for check status if service is not installed' do
    get '/api/v1/services/status', headers: header_with_admin
    expect(response.status).to eq 200
  end
end
