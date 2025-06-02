# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.logger.info { '[Changelog initializer] building services changelogs cache...' }
  Github::Changelog.instance.build_cache
  Rails.logger.info { '[Changelog initializer] cache builded successfully...' }
end
