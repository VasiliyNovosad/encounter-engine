# config valid only for current version of Capistrano
lock '3.19.1'

set :application, 'encounter-engine'
set :repo_url, 'git@github.com:VasiliyNovosad/encounter-engine.git'
set :format, :pretty

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deploy/encounter-engine'
set :deploy_user, 'deploy'

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', '.env', 'config/secrets.yml', 'config/cloudinary.yml', 'config/master.key')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :default_env, { path: "/usr/lib/fullstaq-ruby/versions/3.3-jemalloc/bin:$PATH" }

namespace :deploy do

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

end