# Run with: rackup private_pub.ru -s thin -E production
require "bundler/setup"
require "yaml"
require "faye"
require "private_pub"

Faye::WebSocket.load_adapter('thin')
Faye.logger = Logger.new(Logdna::RailsLogger.new(ENV['LOGDNA_KEY'] || Rails.application.secrets.LOGDNA_KEY, {
    hostname: 'quest.wtf',
    level: 'DEBUG',
    app: 'faye',
    env: 'PRODUCTION'
}))

PrivatePub.load_config(File.expand_path("../config/private_pub.yml", __FILE__), ENV["RAILS_ENV"] || "development")

run PrivatePub.faye_app()
