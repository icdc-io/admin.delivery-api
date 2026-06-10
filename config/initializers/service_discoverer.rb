Rails.application.config.after_initialize do
  Rails.logger.info { '[ServiceDiscoverer initializer] building services cache...' }
  ServiceDiscoverer.instance.build_cache
  Rails.logger.info { '[ServiceDiscoverer initializer] cache builded successfully...' }
rescue => e
  Rails.logger.error { "[ServiceDiscoverer initializer] failed to build cache: #{e.class} - #{e.message}" }
  Rails.logger.error { e.backtrace.join("\n") }
  Rails.logger.error { "[ServiceDiscoverer initializer] continue initialization" }
end
