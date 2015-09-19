require 'active_support/all'
require 'migration'

namespace :create_production_db do
  desc "Migration"
  task :migration => :environment do
    Migration.run_migration
  end
end
