class Api::V1::VersionsController < ApplicationController
  include SystemServices
  include GithubHelper
  before_action :login
  
  def show
    service = get_installed_service(params[:service_name])
    version = service["spec"]["tags"].collect{|tag| tag["from"]["name"] if tag["name"] == "latest"}
    success(version.compact.first)
  rescue
    nil
  end

  def create
    stream_hash = image_stream_by_service(params[:service_name])
    stream_hash[:version] = params[:version]
    render json:  downgrade_service_version(stream_hash)
  end

  def get_downgrade_versions
    service = get_installed_service(params[:service_name])
    versions = service["spec"]["tags"].collect{|tag| tag["name"] if tag["name"] != "latest"}
    success(versions.compact.reverse)
  end

  def get_installed_github_versions
    versions = get_latest_versions(params[:service_name])
    render json: versions.flatten.compact.sort_by { |hash| hash['version'] }.reverse
  end
end
