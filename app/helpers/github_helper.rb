module GithubHelper
  include RequestHelper

  def service_repository(data, version)
    request_raw_github("imagestreams/#{name}")["spec"]["tags"].select { |d| d["name"] == version }.first["from"]["name"]
  end

  def list_images
    image_streams  = request_api_github('repos/dmemekh/icdc/contents/imagestreams','ref=main').collect { |is| is['path'] }
    im_str_names = []
    image_streams.map do |stream|
      stream = stream.split('/').last
    end
  end

  def image_stream(name)
    request_raw_github("imagestreams/#{name}")
  end

  def changelog_names
    request_api_github('repos/dmemekh/icdc/contents/changelogs','ref=main').collect { |cl| cl['download_url'] }.map{ |cl| cl.split('/').last }
  end

  def changelog_version(stream_hash)
    names = []
    changelog_names.each do |cl|
      data = request_raw_github("changelogs/#{cl}")
      names << data.dig('name')
      return data.dig('versions') if image_stream_name(stream_hash).eql?(data.dig('name'))
    end
    return nil
  end

  def available_templates
    request_api_github("repos/dmemekh/icdc/contents/templates","ref=main").collect{ |templ| templ['name'] }
  end

  def find_template_name(service_name)
    test = {}
    available_templates.each do |template_name|
       path_to_template = request_api_github("repos/dmemekh/icdc/contents/templates/#{template_name}","ref=main")['download_url'].split('/').last(2).join('/')
      metadata = request_raw_github(path_to_template)
      return path_to_template.split('/').last if metadata.dig('metadata','name').eql?(service_name)
    end
    return nil
  end

  def find_metadata(service_name)
    request_raw_github("templates/#{find_template_name(service_name)}")
  end
end
