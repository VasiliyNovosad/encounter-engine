source 'https://rubygems.org'

gem 'dotenv-rails', require: 'dotenv/rails-now'

gem 'rails', '4.2.4'

group :production do
  gem 'pg'
  gem 'rails_12factor'
  gem 'sendgrid-rails'
end

gem 'puma'
# Use sqlite3 as the database for Active Record
group :development do
  gem 'sqlite3', '~> 1.3', '>=1.3.10'
  gem 'capistrano', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false
end

group :test do
  gem 'cucumber-rails', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'
gem 'coffee-script-source'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '3.1.2'
# gem 'bcrypt'
gem 'devise'
gem 'acts_as_list', git: 'https://github.com/swanandp/acts_as_list.git', require: 'acts_as_list'
gem 'default_value_for', '~> 3.0.0'
gem 'tinymce-rails'
gem 'tinymce-rails-langs'
gem 'tinymce-rails-imageupload', github: 'PerfectlyNormal/tinymce-rails-imageupload'
gem 'paperclip'
gem 'carrierwave'
gem 'cloudinary'
gem 'jquery-ui-rails'
gem 'rails-jquery-autocomplete'
source 'https://rails-assets.org' do
  gem 'rails-assets-datetimepicker'
end
# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin]
