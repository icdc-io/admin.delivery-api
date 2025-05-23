# frozen_string_literal: true

require './lib/okd_api'
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
      image_stream_list = list
      prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
      namespaces = OkdApi.get_all_namespaces.select { |ns| ns.start_with?(prefix) }
      namespaces.map do |namespace|
        service_name = namespace.gsub("#{prefix}-", '')
        image_stream = find(image_stream_list, service_name, namespace)
        next unless image_stream

        new(service_data(image_stream, service_name, namespace))
      end.compact
    end

    def self.get(name)
      image_stream_list = list
      namespace = "#{(ENV['NAMESPACE_PREFIX'].present? ? ENV['NAMESPACE_PREFIX'] : 'cloud').to_s.downcase}-#{name}"
      image_stream = find(image_stream_list, name, namespace)
      return unless image_stream

      new(service_data(image_stream, name, namespace))
    end

    def self.list
      OkdApi.get_resource('apis/image.openshift.io/v1/imagestreams')
    end

    def self.find(imagestreams, service_name, namespace)
      imagestreams['items'].find do |item|
        item.dig('metadata', 'name') == service_name && item.dig('metadata', 'namespace') == namespace
      end
    end

    def self.service_data(image_stream, name, namespace)
      tags = image_stream.dig('spec', 'tags')
      current_version = tags.find { |tag| tag['name'] == 'latest' }&.dig('from', 'name')
      versions = tags.map { |tag| tag['name'] if tag['name'] != 'latest' }.compact
      downgrade_versions = versions.take_while { |version| version != current_version }
      current_release_version = current_version.split('.')[0...2].join('.')
      { name:, namespace:, current_version:, versions:, downgrade_versions:, current_release_version: }
    end
  end
end
