require 'chef'
require 'zlib'
require 'rake/packagetask'

@metadata = Chef::Cookbook::Metadata.new
@metadata.from_file('metadata.rb')

task 'metadata.json' do
  File.open('metadata.json', 'w') do |f|
    f.write(Chef::JSONCompat.to_json_pretty(@metadata))
  end
end

desc 'Build the metadata.json from metadata.rb'
task :metadata => ['metadata.json']

Rake::PackageTask.new(@metadata.name, :noversion) do |p|
  p.need_tar_gz = true
  p.package_files.include(Dir['**/*'].delete_if { |v| v =~ %r{(?:tmp|test|cookbooks)/?} || File.directory?(v) })
end

desc 'Build a community package'
task :build => [:metadata, :package] do
  cp(File.join('pkg', "#{@metadata.name}.tar.gz"), "#{@metadata.name}_#{@metadata.version}.tar.gz")
  Rake::Task['clobber_package'].invoke
end
