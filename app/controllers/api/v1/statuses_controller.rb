# frozen_string_literal: true

module Api
  module V1
    class StatusesController < ApplicationController
      # TODO: Remove
      include SystemServices
      include OsCommonHelper
      include ResponseHelper
      # end TODO

      before_action :setup_prefix, only: %i[apps show]

      def apps
        mock_data = Rails.root.join(ENV.fetch('MOCKDATA_FILENAME', 'config/extra/apps.json'))
        resp = if File.exist?(mock_data)
                 JSON.parse(File.read(mock_data)).map(&:deep_symbolize_keys)
               else
                 ServiceDiscoverer.instance.get_cached
               end

        filtered_resp = apply_rbac(resp.dup)
        render json: filtered_resp, status: :ok
      end

      def show
        status = Status.new
        response = OkdClient.namespaces(@prefix).map do |namespace|
          status.get_info(namespace)
        end
        render json: response, status: :ok
      end

      private

      def apply_rbac(data)
        return unless data

        data.each_with_object([]) do |d, result|
          next if !d[:roles].to_s.empty? && User.current.role != 'operator' && !d[:roles].include?(User.current.role)

          filtered_entry = d.dup
          filtered_entry[:apps] = apply_rbac(d[:apps].dup) if d[:apps]
          result << filtered_entry
        end
      end

      def setup_prefix
        @prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'
      end
    end
  end
end
