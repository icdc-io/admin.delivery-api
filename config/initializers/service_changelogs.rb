# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.logger.info { '[Changelog initializer] building services changelogs cache...' }
  Changelog.instance.build_cache
  Rails.logger.info { '[Changelog initializer] cache builded successfully...' }
rescue => e
  Rails.logger.error { "[Changelog initializer] failed to build cache: #{e.class} - #{e.message}" }
  Rails.logger.error { e.backtrace.join("\n") }
  Rails.logger.error { "[Changelog initializer] continue initialization" }
end
