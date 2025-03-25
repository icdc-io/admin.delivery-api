Rails.application.config.after_initialize do
  Rails.logger.info { '[ServiceDiscoverer initializer] building services cache...'}
  ServiceDiscoverer.instance.build_cache
  Rails.logger.info { '[ServiceDiscoverer initializer] cache builded successfully...'}
end
