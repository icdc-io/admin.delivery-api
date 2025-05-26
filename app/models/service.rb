# frozen_string_literal: true

class Service
  attr_accessor :image_stream, :name, :current_version, :downgrade_versions, :update_version, :upgrade_version

  def initialize(name, image_stream = nil)
    image_stream ||= OKD::ImageStream.get(name)
    return unless image_stream

    @name = image_stream.name
    @current_version = image_stream.current_version
    @downgrade_versions = image_stream.downgrade_versions
    @update_version = ServiceChangelogs.last_update_version(name, image_stream.current_version)
    @upgrade_version = ServiceChangelogs.last_upgrade_version(name, image_stream.current_release_version)
  end

  def self.all
    OKD::ImageStream.all.map do |image_stream|
      next unless image_stream

      new(image_stream.name, image_stream)
    end
  end

  def self.find_by_name(name)
    service = new(name)
    return if service.instance_variables.empty?

    service
  end
end
