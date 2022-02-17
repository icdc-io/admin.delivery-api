require 'rails_helper'

jwt_token_admin = "Bearer REDACTED"

describe 'Any endpoint if user is not authorized', type: :request do
  it 'returns 401 if user is not authorized' do   
    get "/api/v1/services/httpd"
    parsed_body = JSON.parse(response.body)
    expect("#{parsed_body["status"]}").to eq "401"  
    expect("#{parsed_body["data"]["message"]}").to eq "You're not authorized."
  end
end

describe 'Endpoint GET /services', type: :request do
  it 'returns a 200 OK status' do
    get "/api/v1/services",
      :params => nil,
      :headers => {:Authorization => jwt_token_admin}
    expect(response.status).to eq 200
  end
end

describe 'Endpoint GET /services/:service_name', type: :request do
  it 'returns service name and service_installed if service exists' do   
    get "/api/v1/services/httpd",
      :params => nil,
      :headers => {:Authorization => jwt_token_admin}
    expect("#{JSON.parse(response.body)["service_name"]}").to eq "httpd"
  end
end

describe 'Endpoint GET /services/:service_name/overview', type: :request do
  it 'returns service description if service exists' do
    get "/api/v1/services/httpd/overview",
    :params => nil,
    :headers => {:Authorization => jwt_token_admin}
    parsed_body=JSON.parse(response.body)
    expect("#{parsed_body["service_name"]} #{parsed_body["description"]} #{parsed_body["documentation_url"]}").to eq "Apache HTTP Server An example Apache HTTP Server (httpd) application that serves static content. For more information about using this template, including OpenShift considerations, see https://github.com/sclorg/httpd-ex/blob/master/README.md. https://github.com/sclorg/httpd-ex"
  end
end

describe 'Endpoint POST /services/:service_name', type: :request do
  it 'should create service if it exists' do
    post "/api/v1/services/httpd",
      :params => {:version => "1.0.0"}, 
      :headers => {:Authorization => jwt_token_admin}
    expect(response.status).to eq 204
  end
end

# Необходим сервис с возможностью установки нескольких версий
# describe 'Endpoint PUT /services/:service_name', type: :request do
#   it 'should upgrade service if it is installed and have version for upgrade' do
#   end
# end

describe 'Endpoint DELETE /services/:service_name', type: :request do
  it 'delete service' do
    delete "/api/v1/services/httpd",
      :params => nil, 
      :headers => {:Authorization => jwt_token_admin}
    expect(response.status).to eq 204
  end
end
