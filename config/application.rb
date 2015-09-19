require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Betting
  class Application < Rails::Application
    config.active_record.raise_in_transactional_callbacks = true

    config.serve_static_files = false
    config.assets.enabled = true
    config.assets.initialize_on_precompile = false
  end
end
