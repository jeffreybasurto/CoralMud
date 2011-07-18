DataMapper::Logger.new($stdout, :debug)

DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(File.expand_path(__FILE__)) + '/../data/data.db')}")

