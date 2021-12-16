module GithubHelper
  include RequestHelper

  def service_repository(data, version)
    data.dig("spec","tags").select { |d| d["name"] == version }.first.dig("from","name")
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
    available_templates.each do |template_name|
       path_to_template = request_api_github("repos/dmemekh/icdc/contents/templates/#{template_name}","ref=main")['download_url'].split('/').last(2).join('/')
      metadata = request_raw_github(path_to_template)
      return path_to_template.split('/').last if metadata.dig('metadata','name').eql?(service_name)
    end
    return nil
  end

  def find_template(service_name)
    request_raw_github("templates/#{find_template_name(service_name)}")
  end

  def get_application_domain(template_hash, location)
     source_appl_domain = template_hash.dig("parameters").select { |d| d.dig("name") == "APPLICATION_DOMAIN" }.first.dig("value").split('.').drop(1).join('.')
     location + '.' + source_appl_domain
  end

  def service_versions(data)
    data["spec"]["tags"].select { |d| d.dig("from", "kind") == "DockerImage" }.first.dig("name")
  end

  def update_template(template, params, location)
    template['parameters'].select { |tm| tm.dig('name').eql?('VERSION') }.first['value'] = params[:version]
    template['parameters'].select { |tm| tm.dig('name').eql?('NAME') }.first['value'] = params[:service_name]
    template['parameters'].select { |tm| tm.dig('name').eql?('APPLICATION_DOMAIN') }.first['value'] = get_application_domain(template, location)
    template
  end
end
