require 'dm-core'
require 'dm-migrations'
DataMapper::Logger.new($stdout, :debug)
# You can set up the database.config file like this:
# ---
# user: root
# password: yourpass
database_opts = YAML::load_file("core/database.config") || {:user=>"root", :password=>"yourpass"}

DataMapper.setup(:default, "mysql://#{database_opts[:user]}:#{database_opts[:password]}@localhost/coralmud")

