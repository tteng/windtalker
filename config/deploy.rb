require 'capistrano/ext/multistage'

set :stages, %w(default)
set :default_stage, "default"
set :application, "windtalker"
set :repository, "https://github.com/tteng/windtalker.git"
set :scm, :git
set :sudo, true

set :user, 'lodestone'

set :deploy_via, :copy
set :keep_releases, 5 

after "deploy:finalize_update", "deploy:custom_symlinks"
