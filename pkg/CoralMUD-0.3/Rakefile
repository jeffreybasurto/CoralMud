
### To generate your backup
### rake package
require 'rake/rdoctask'
require 'rake/packagetask'

# get version 
Version = 0.26

# files to distribute
PKG_FILES = FileList[
  'lib', 'lib/**/*',
  'INSTALL', 'Rakefile',
  'data', 'data/*', 'data/socials/*', 'data/help/*', 'help/areas/*',
  'coral.rb',
  'core', 'core/*',
  'scripts',
  'log', 
  'doc', 'doc/*'
]

desc "Make documentation"
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README'
  rd.title = "Coral #{Version} Mud Server"
  rd.template = 'kilmer'
  rd.rdoc_files.include('INSTALL', 'coral.rb', 'core/*', 'lib/*')
  rd.options << '-d' 
end

desc "Package up a distribution"
Rake::PackageTask.new("CoralMUD", Version) do |p|
    p.need_tar_gz = true
    p.need_zip = true
    p.package_files.include(PKG_FILES)
    p.package_files.exclude(/\.svn/)
end
