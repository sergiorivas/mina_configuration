require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'



set :development_server              , '104.239.200.81'
set :development_server_user_account , 'dummy_app'

set :production_server               , '104.239.200.812'
set :production_server_user_account  , 'dummy_app'

set :repository, 'https://sergiorivas:aqsw123@github.com/sergiorivas/dummmy_deploy_app.git'

set :restart_on_deploy?, true
set :run_migrations_on_deploy?, false
set :precompile_assets_on_deploy?, false






ENVIRONMENTS_ALLOWED = ["development", "production"]


task :set_default_values do
  set :deploy_to, '-'
  set :branch, 'master'
  set :term_mode, nil
  set :shared_paths, ['config/database.yml', 'log']
end

task :environment do
  invoke :'rvm:use[@global]'
end

task :verify_environment_argument do 
  ARGV.each { |a| task a.to_sym do ; end }
  
  environment_arg = ARGV[1]
  unless environment_arg
    error "You must to specify an environment: development or production"
    exit 1
  end
  environment_arg = environment_arg.strip.downcase
  unless ENVIRONMENTS_ALLOWED.include? environment_arg
    error "You must to specify an valid environment: development or production"
    exit 1
  end  

  if environment_arg == "production"
    set :domain    , production_server
    set :user      , production_server_user_account
  elsif environment_arg == "development"
    set :domain, development_server
    set :user  , development_server_user_account
  end
  set :deploy_to , "/home/#{user}"

end

task :verify_deploy_arguments do 

  branch_arg = ARGV[2]
  if branch_arg
    set :branch, branch_arg
  else
    set :branch, "master"
  end

  commit_arg = ARGV[3]
  if commit_arg
    set :commit, commit_arg
  end
  
end

task :setup => [:set_default_values, :verify_environment_argument, :environment] do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml'."]
end

desc "Deploys the current version to the server."
task :deploy => [:set_default_values, :verify_environment_argument, :verify_deploy_arguments, :environment] do 
  
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    
    if run_migrations_on_deploy?
      invoke :'rails:db_migrate'
    end
    
    if precompile_assets_on_deploy?
      invoke :'rails:assets_precompile'
    end
    invoke :'deploy:cleanup'

    to :launch do
      queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    end
  end
  
  
end


#set :shared_paths, ['config/database.yml', 'log']

# task :deploy => :environment do
#   to :before_hook do
#     # Put things to run locally before ssh
#   end
#   deploy do
#     # Put things that will set up an empty directory into a fully set-up
#     # instance of your project.
#     invoke :'git:clone'
# #    invoke :'deploy:link_shared_paths'
# #    invoke :'bundle:install'
# #    invoke :'rails:db_migrate'
# #    invoke :'rails:assets_precompile'
#  #   invoke :'deploy:cleanup'

#     to :launch do
#       queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
#       queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
#     end
#   end
# end
# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

