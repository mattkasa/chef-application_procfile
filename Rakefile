require 'chef'

@metadata = Chef::Cookbook::Metadata.new
@metadata.from_file('metadata.rb')

task 'metadata.json' do
  File.open('metadata.json', 'w') do |f|
    f.write(Chef::JSONCompat.to_json_pretty(@metadata))
  end
end

desc 'Build the metadata.json from metadata.rb'
task :metadata => ['metadata.json']

begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
end

begin
  require 'stove/rake_task'
  Stove::RakeTask.new
rescue LoadError
  puts '>>>>> Stove gem not loaded, omitting tasks' unless ENV['CI']
end
