class Admin::V1::ServicesController < ApplicationController
  include SystemServices 
  before_action :login

  def index
    image_names = list_images
    services = []
    image_names.each do |name|
      begin
        data = image_stream(name)
        data['json'] = name
        services << {name: image_stream_name(data), release_version:release_version(data)}, update_version:update_version(data), installed_version:installed_version(data)}
      rescue => err
        next
      #  raise "#{err}__#{name}"
      end
    end
    render json:services
  end
end
