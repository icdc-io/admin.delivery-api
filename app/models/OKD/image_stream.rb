# frozen_string_literal: true

module OKD
  class ImageStream
    attr_accessor :name, :namespace, :current_version, :current_release_version, :downgrade_versions

    def initialize(opts)
      @name = opts[:name]
      @namespace = opts[:namespace]
      @current_version = opts[:current_version]
      @current_release_version = opts[:current_release_version]
      @downgrade_versions = opts[:downgrade_versions]
    end

    def self.all
      image_stream_list = OkdClient.get_resource('apis/image.openshift.io/v1/imagestreams')
      prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
      OkdClient.namespaces(prefix).map do |namespace|
        service_name = namespace.gsub("#{prefix}-", '')
        image_stream = image_stream_list['items'].find do |item|
          item.dig('metadata', 'name') == service_name && item.dig('metadata', 'namespace') == namespace
        end
        next unless image_stream

        new(service_data(image_stream, service_name, namespace))
      end.compact
    end

    def self.get(service_name)
      image_stream_list = OkdClient.get_resource('apis/image.openshift.io/v1/imagestreams')
      namespace = "#{ENV.fetch('NAMESPACE_PREFIX', 'cloud').to_s.downcase}-#{service_name}"
      image_stream = image_stream_list['items'].find do |item|
        item.dig('metadata', 'name') == service_name && item.dig('metadata', 'namespace') == namespace
      end
      return unless image_stream

      new(service_data(image_stream, service_name, namespace))
    end

    def self.service_data(image_stream, name, namespace)
      tags = image_stream.dig('spec', 'tags')
      current_version = tags.find { |tag| tag['name'] == 'latest' }&.dig('from', 'name')
      versions = tags.map { |tag| tag['name'] if tag['name'] != 'latest' }.compact
      downgrade_versions = versions.take_while do |version|
        version != current_version
      end.sort { |a, b| Gem::Version.new(b) <=> Gem::Version.new(a) }
      current_release_version = current_version.split('.')[0...2].join('.')
      { name:, namespace:, current_version:, versions:, downgrade_versions:, current_release_version: }
    end

    def self.find_from_list(list, service_name, namespace)
      list.find do |item|
        item.dig('metadata', 'name') == service_name && item.dig('metadata', 'namespace') == namespace
      end
    end
  end
end
