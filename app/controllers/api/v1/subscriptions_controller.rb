# TODO: Remove:
class Api::V1::SubscriptionsController < ApplicationController
  include SystemServices

  before_action :operator_required

  def index
    image_names = list_images
    services = []
    image_names.each do |name|
      begin
        data = image_stream(name)
        data['json'] = name
        services << {name: image_stream_name(data), version:release_version(data)}
      rescue => err
        next
      end
    end
    render json:services
  end

  def show
    metadata = find_metadata(params[:service_name])
    result = {}
    result[:service_name] = metadata.dig('metadata','annotations','openshift.io/display-name')
    result[:description]  = metadata.dig('metadata','annotations','description')
    result[:documentation_url] = metadata.dig('metadata','annotations','openshift.io/documentation-url')
    render json:result
  end

  def create
    if ENV["LOCATION"] == 'central'
    case ENV["LOCATION"]
    when "central"
      update_subscription
    when "customer"
    else
      raise "Wrong location statemant."
    end
    end
  end

  def inform
    render json: Subscription.find_by(service:params[:service_name])
  end

  private
  def update_subscription
    sbscr = Subscription.find_by(service:params[:service_name])
  #  Subscription.create!(params[:])
  end
end
# end TODO