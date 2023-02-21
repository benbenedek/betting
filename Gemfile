source 'https://rubygems.org'
ruby '3.2.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '7.0.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', :group => [:development, :test]
# Use SCSS for stylesheets
gem 'sass-rails', '6.0.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'bootstrap-sass',       '3.2.0.4'
gem 'activerecord', '7.0.1'
# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-turbolinks'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
gem 'json', '2.3.1'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Used for html parsing
gem 'nokogiri'
gem 'rest-client'

gem 'tzinfo'
gem 'tzinfo-data'
gem 'sprockets-rails'
gem 'sprockets', '~> 3.7.2'
gem 'pg'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

gem 'sprockets_better_errors'

group :production do
  gem 'thin', '1.8.0'
  gem 'rails_12factor'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
