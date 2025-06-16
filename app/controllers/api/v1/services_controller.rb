# frozen_string_literal: true

require 'yaml'

module Api
  module V1
    class ServicesController < ApplicationController
      # TODO: Remove
      include SystemServices
      include OsCommonHelper
      include OsHelper
      include OsCreateHelper
      include OsDeleteHelper
      include ServiceHelper
      # end TODO
      before_action :operator_required
      before_action :find_service, only: %i[downgrade upgrade update delete]
      before_action :check_downgrade_version, only: [:downgrade]
      before_action :check_upgrade_version, only: [:upgrade]
      before_action :check_update_version, only: [:update]
      after_action :invalidate_cache, only: [:create, :downgrade, :upgrade, :update, :delete]

      def index
        services = Service.all
        render json: services
      end

      def show
        service = Service.find_by_name(params[:service_name])
        return render json: { message: 'Bad request, service not found', code: 404 }, status: :not_found unless service

        render json: service, status: :ok
      end
      # TODO: Remove

      # def index
      #   image_names = list_images
      #   services = []
      #   image_names.each do |name|
      #     begin
      #       data = image_stream(name)
      #       data['json'] = name
      #       services << {name: image_stream_name(data), release_version:release_version(data), update_version:updated_version(data), installed_version:installed_version(data)}
      #     rescue => err
      #       next
      #     end
      #   end
      #   render json:services
      # end

      def overview
        service = get_installed_service(params[:service_name])
        latest_version = service.dig('spec', 'tags').collect do |tag|
          tag.dig('from', 'name') if tag['name'] == 'latest'
        end.compact.first
        service_version = describe_service_version(params[:service_name], latest_version)[0]

        render json: service_version, status: :ok
      rescue StandardError
        nil
      end

      def create_old
        prefix = ENV['NAMESPACE_PREFIX'] || 'cloud'
        create_namespace(params[:service_name]) unless get_all_namespaces.include?("#{prefix}-#{params[:service_name]}")
        service_name = params[:service_name]
        service = get_latest_versions(service_name).select { |service| service['version'] == params['version'] }.first
        # required_services = service["required"]
        # installed_version = get_installed_service(service_name)
        # required_services.keys.each do |required_service|
        #   installed_version = get_installed_service(required_service)
        #   next if installed_version == "404"
        #   if installed_version.split(".").join.to_i <  required_service["version"].split(".").join.to_i
        #     update_service(service_name, required_service) if installed_version.split(".").join.to_i != 0
        #   end
        # end
        deploy_template(service_name, service)
        # update
        service_name = params[:service_name]
        update_service(service_name, service)
        ServiceDiscoverer.instance.invalidate_cache
        no_content
      end

      def downgrade_old
        required_version = get_required_version(params[:service_name], params[:version]).select do |tst|
          tst if tst['version'] == params[:version]
        end.first
        update_service(params[:service_name], required_version)
        ServiceDiscoverer.instance.invalidate_cache
        no_content
      end

      def upgrade_old
        return abort('No such namespace') unless get_all_namespaces.include?(get_os_namespace(params[:service_name]))

        service_name = params[:service_name]
        service = get_latest_versions(service_name).select { |service| service['version'] == params[:version] }.first
        deploy_template(service_name, service)
        service_name = params[:service_name]
        update_service(service_name, service)
        ServiceDiscoverer.instance.invalidate_cache
        no_content
      end

      def delete_old
        $deleting[params[:service_name]] = 'deleting'
        10.times do
          delete_code = delete_service(params[:service_name], params[:delete_persistent_data],
                                       params[:delete_backup_data])
          if delete_code.to_i == 204
            $deleting.delete(params[:service_name])
            # delete_dns_record(params[:service_name])
            template = get_service_repository(params[:service_name])
            delete_dns_records(template)
            ServiceDiscoverer.instance.invalidate_cache

            return '204'
          end
          sleep 5
        end
      end
      # end TODO

      def create
        version = Changelog.find_version(params[:service_name], params[:version])
        return render json: { message: 'Bad request, version not found', code: 404 }, status: :not_found unless version

        service_name = params[:service_name]
        Service.install(service_name, params[:version])
        render json: Service.find_by_name(service_name), status: :ok
      end

      def downgrade
        downgrade_version = Changelog.find_version(@service.name, params[:version])
        @service.update_service_version(downgrade_version)
        render json: Service.find_by_name(@service.name), status: :ok
      end

      def upgrade
        Template.deploy(@service_name, @upgrade_version)
        Service.find_by_name(@service_name).update_service_version(@upgrade_version)
        render json: Service.find_by_name(@service_name), status: :ok
      end

      def update
        @service.update_service_version(@service.update_version)
        render json: Service.find_by_name(@service_name), status: :ok
      end

      def delete
        @service.delete(params[:delete_persistent_data], params[:delete_backup_data])
        render json: nil, status: :no_content
      end

      private

      def find_service
        @service_name = params[:service_name]
        @service = Service.find_by_name(@service_name)
        render json: { message: 'Bad request, service not found', code: 404 }, status: :not_found unless @service
      end

      def check_downgrade_version
        return if @service.downgrade_versions.include?(params[:version])

        render json: { message: 'Bad request, version for downgrade is incorrect', code: 400 },
               status: :bad_request
      end

      def check_upgrade_version
        @upgrade_version = Changelog.find_version(@service_name, params[:version])
        current_release = @service.release
        new_relese = params[:version].split('.')[0...2].join('.')
        if (Gem::Version.new(new_relese) <= Gem::Version.new(current_release)) || @upgrade_version.nil?
          return render json: { message: 'Bad request, version for upgrade is incorrect', code: 400 },
                        status: :bad_request
        end

        prefix = ENV.fetch('NAMESPACE_PREFIX', 'cloud')
        return if OkdClient.namespaces.include?("#{prefix}-#{@service_name}")

        render json: { message: 'Bad request, namespace for this service not found', code: 404 },
               status: :not_found
      end

      def check_update_version
        versions_from_release = Changelog.versions_from_release(@service_name, @service.release)
        if (Gem::Version.new(params[:version]) <= Gem::Version.new(@service.current_version)) ||
           !versions_from_release.map { |v| v['version'] }.include?(params[:version])
          render json: { message: 'Bad request, version for update is incorrect', code: 400 }, status: :bad_request
        end
      end

      def invalidate_cache
        ServiceDiscoverer.instance.invalidate_cache
      end
    end
  end
end
