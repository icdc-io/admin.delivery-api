class Api::V1::VersionsController < ApplicationController
  include SystemServices
  before_action :login
  
  def show
    service = get_installed_service(params[:service_name])
    version = service["spec"]["tags"].collect{|tag| tag["from"]["name"] if tag["name"] == "latest"}
    success(version.compact.first)
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    stream_hash[:version] = params[:version]
    render json:  downgrade_service_version(stream_hash)
  end

  def get_downgrade_versions
    service = get_installed_service(params[:service_name])
    versions = service["spec"]["tags"].collect{|tag| tag["name"] if tag["name"] != "latest"}
    success(versions.compact)
  end

  def get_installed_github_versions
    versions = []
    stream_hash = get_services_changelogs(params[:service_name]).map do |service|
      service if service["download_url"].split("/").last.include?("release")
    end.compact!
    stream_hash.map do |sh|
      uri = URI.parse(sh["download_url"])
      request = Net::HTTP::Get.new(uri)
      response = do_request(request, uri)
      next if response == '400'
      puts response.inspect
      versions << response.map{|resp| resp if resp["tag"] == "latest"}
    end
    render json: versions.flatten.compact.sort_by { |hash| hash['version'] }.reverse
  end
end
