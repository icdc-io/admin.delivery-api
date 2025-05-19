# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.logger.info { '[ServiceChangelogs initializer] building services changelogs cache...' }
  ServiceChangelogs.instance.build_cache
  Rails.logger.info { '[ServiceChangelogs initializer] cache builded successfully...' }
end
