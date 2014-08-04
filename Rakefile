require 'chef'
require 'chef/cookbook_site_streaming_uploader'
require 'chef/knife/cookbook_site_share'
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

desc 'Upload a community package'
task :upload => [:metadata, :package] do
  Chef::Config.from_file(File.join('.chef', 'knife.rb'))
  supermarket = Chef::Knife::CookbookSiteShare.new
  begin
    supermarket.do_upload(File.join('pkg', "#{@metadata.name}.tar.gz"), 'Other', Chef::Config[:node_name], Chef::Config[:client_key])
    puts "Uploaded #{@metadata.name} #{@metadata.version} to the Supermarket"
  rescue => e
    puts "Error uploading #{@metadata.name} #{@metadata.version} to the Supermarket: #{e.message}"
    exit(1)
  ensure
    Rake::Task['clobber_package'].invoke
  end
end
