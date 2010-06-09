require 'rake/rdoctask'
require 'rake/packagetask'

# get version 
Version = 0.3

# files to distribute
PKG_FILES = FileList[
  'rocket.rb', 'event.rb', 'help.rb', 'mobile.rb', 'sockdesc.rb', 'utils.rb', 'constants.rb',
  'README', 'Rakefile',
  'log', 'log/README', 
  'players', 'players/One.yml',
  'help', 'help/**/*'
]

desc "Make documentation"
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README'
  rd.title = "RocketMUD #{Version} Mud Server"
  rd.template = 'kilmer'
  rd.rdoc_files.include('README', 'rocket.rb', 'event.rb', 'help.rb', 'mobile.rb', 'constants.rb',
    'sockdesc.rb', 'utils.rb')
  rd.options << '-d' 
end

desc "Package up a distribution"
Rake::PackageTask.new("RocketMUD", Version) do |p|
    p.need_tar_gz = true
    p.need_zip = true
    p.package_files.include(PKG_FILES)
    p.package_files.exclude(/\.svn/)
end
