server "114.80.67.227", :app, :web, :db, :primary => true
set :stage, "production"
set :deploy_to, "/var/www/apps/windtalker"
set :npm, "/usr/local/node103/bin/npm"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && #{npm} install "
    run "cd #{release_path} && bin/forever_stop"
    sleep 3
    run "touch #{release_path}/pids/windtalker.pid"
    run "cd #{release_path} && bin/forever_start"
  end

  task :custom_symlinks, :roles => :app do
    run "ln -nfs /var/www/apps/windtalker/shared/log/ #{release_path}/logs"
    run "ln -nfs /var/www/apps/windtalker/shared/pids/ #{release_path}/pids"
  end

end
