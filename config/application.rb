require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Betting
  class Application < Rails::Application
  	config.active_job.queue_adapter = :delayed_job
    config.active_record.raise_in_transactional_callbacks = true
    config.assets.precompile += %w( graphs.js )
  end
end
