# config valid only for current version of Capistrano
lock '3.11.2'

set :application, 'encounter-engine'
set :repo_url, 'git@github.com:VasiliyNovosad/encounter-engine.git'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deploy/encounter-engine'
set :deploy_user, 'deploy'

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', '.env', 'config/secrets.yml', 'config/cloudinary.yml', 'config/private_pub.yml', 'config/private_pub_thin.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :default_env, { path: "/usr/lib/fullstaq-ruby/versions/2.6-jemalloc/bin:$PATH" }

namespace :deploy do

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

end

namespace :private_pub do
  desc 'Start private_pub server'
  task :start do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "/usr/lib/fullstaq-ruby/versions/2.6-jemalloc/bin/bundle exec thin -C config/private_pub_thin.yml start"
        end
      end
    end
  end

  desc 'Stop private_pub server'
  task :stop do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "/usr/lib/fullstaq-ruby/versions/2.6-jemalloc/bin/bundle exec thin -C config/private_pub_thin.yml stop"
        end
      end
    end
  end

  desc 'Restart private_pub server'
  task :restart do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "/usr/lib/fullstaq-ruby/versions/2.6-jemalloc/bin/bundle exec thin -C config/private_pub_thin.yml restart"
        end
      end
    end
  end
end

after 'deploy:restart', 'private_pub:restart'