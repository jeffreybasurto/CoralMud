require 'dm-core'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'mysql://root:plokij098@localhost/coralmud')

