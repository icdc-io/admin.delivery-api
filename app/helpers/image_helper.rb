# TODO Remove:
module ImageHelper
  include OsHelper

  def image_stream_by_service(service_name)
    list_images.each do |image|
      is = image_stream(image)
      name = image_stream_name(is)
      return is if name.eql?(service_name)
    end
    return nil
  end

  def image_stream_name(stream_hash)
    stream_hash.dig('metadata','name')
  end

  def image_stream_version(stream_hash)
    stream_hash.dig('spec','tags').select { |tag| tag['name'] == 'latest' }.first.dig('from','name')
  end

  def image_streams(service_name)
    get_image_streams(service_name)
  end

  def get_latest_image_version(service_name)
    image_streams(service_name)["spec"]["tags"].each do |image|
      if image["name"] == "latest"
        return image["from"]["name"]
      end
    end
    return nil
  rescue
    nil
  end

end
# end TODO