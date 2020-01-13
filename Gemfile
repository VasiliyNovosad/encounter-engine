source 'https://rubygems.org'
ruby '2.6.5'

gem 'dotenv-rails', require: 'dotenv/rails-now'
gem 'rails', '5.2.4.1'
gem 'pg'

group :development do
  gem 'capistrano', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false
  gem 'listen'
  gem 'puma'
end

group :test do
  gem 'cucumber-rails', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

gem 'passenger_monit', group: :production

# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

gem 'acts_as_list', github: 'swanandp/acts_as_list', require: 'acts_as_list'
gem 'default_value_for'
gem 'devise'
gem 'devise-security'
gem 'tinymce-rails'
gem 'tinymce-rails-langs'
gem 'tinymce-rails-imageupload', github: 'VasiliyNovosad/tinymce-rails-imageupload'
gem 'cloudinary'
gem 'jquery-ui-rails'
gem 'touchpunch-rails', github: 'VasiliyNovosad/touchpunch-rails'
gem 'sentry-raven'
source 'https://rails-assets.org' do
  gem 'rails-assets-datetimepicker'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:x64_mingw, :mingw, :mswin]

gem 'kaminari'
gem 'cocoon'
gem 'friendly_id'
gem 'nokogiri'
gem 'concurrent-ruby', require: 'concurrent'
gem 'concurrent-ruby-ext'
# gem 'anycable-rails'
gem 'redis'