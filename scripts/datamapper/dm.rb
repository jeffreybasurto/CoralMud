require 'dm-core'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'mysql://root:plokij098@localhost/roar')

class Player
  include DataMapper::Resource
  property :id,         Serial   # An auto-increment integer key
  property :name,       String   # A varchar type string, for short strings
  property :profession, String, :default=>"none"
  property :level,     Integer, :default=>1

  before :create do 
    puts "ROAR!"
  end

  before :save do
    puts "Test!"
  end

  def to_s
    "#{@id}: #{@name} #{@profession} L#{@level}"
  end
end
DataMapper.auto_upgrade!

r = Player.new
r.name = "Retnur"
r.save
r.save
players = Player.all.each do |p|
  puts p
end
