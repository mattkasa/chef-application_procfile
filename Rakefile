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

desc 'Run Test Kitchen integration tests'
namespace :integration do
  desc 'Run integration tests with kitchen-docker'
  task :docker, [:instance] do |_t, args|
    args.with_defaults(instance: 'default-ubuntu-1204')
    require 'kitchen'
    Kitchen.logger = Kitchen.default_file_logger
    loader = Kitchen::Loader::YAML.new(local_config: '.kitchen.docker.yml')
    instances = Kitchen::Config.new(loader: loader).instances
    # Travis CI Docker service does not support destroy:
    instances.get(args.instance).verify
  end
end
