#
# Author:: Matt Kasa <mattk@granicus.com>
# Cookbook Name:: application_procfile
# Provider:: procfile
#
# Copyright:: 2013, Granicus Inc. <mattk@granicus.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

begin
  require 'foreman/procfile'
rescue LoadError
  Chef::Log.warn("Missing gem 'foreman'")
end

include Chef::DSL::IncludeRecipe

def create_unicorn_rb(helpers, type = 'web', workers = 1, app_unicorn_rb_path)
  execute "application_procfile_reload_#{type}" do
    command "touch #{::File.join(helpers.lock_path, "#{type}.reload")}"
    action :nothing
  end
  template helpers.shared_unicorn_rb_path do
    source 'unicorn.rb.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '644'
    variables(
      :app_unicorn_rb_path => app_unicorn_rb_path,
      :pid_file => ::File.join(helpers.shared_path, 'unicorn.pid'),
      :monit_pid_file => ::File.join(helpers.pid_path, "#{type}-0.pid"),
      :workers => workers,
      :environment_sh_path => helpers.environment_sh_path,
      :current_path => helpers.current_path
    )
    notifies :run, "execute[application_procfile_reload_#{type}]", :delayed
  end
end

def create_lock_file(helpers, type, suffix)
  file ::File.join(helpers.lock_path, "#{type}.#{suffix}") do
    owner 'root'
    group 'root'
    mode '0644'
    action :create_if_missing
  end
end

def create_lock_directory(helpers)
  directory helpers.lock_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
end

def create_environment_sh(helpers)
  execute "application_procfile_reload" do
    command "touch #{::File.join(helpers.lock_path, '*.reload')}"
    action :nothing
  end
  template helpers.environment_sh_path do
    source 'environment.sh.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :path_prefix => new_resource.application.environment['PATH_PREFIX'],
      :environment_attributes => helpers.environment_attributes
    })
    notifies :run, "execute[application_procfile_reload]", :delayed
  end
end

def create_initscript(helpers, type, command)
  template 'procfile.init' do
    cookbook 'application_procfile'
    path ::File.join('/etc', 'init.d', "#{new_resource.name}-#{type}")
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :name => new_resource.name,
      :type => type,
      :command => command,
      :environment_sh_path => helpers.environment_sh_path,
      :pid_path => helpers.pid_path,
      :log_path => helpers.log_path,
      :current_path => helpers.current_path
    })
  end
end

def create_monitrc(helpers, type, number, command, options)
  execute 'application_procfile_monit_reload' do
    command 'monit reload'
    action :nothing
  end

  template 'procfile.monitrc' do
    cookbook 'application_procfile'
    path ::File.join('/etc', 'monit', 'conf.d', "#{new_resource.name}-#{type}.conf")
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :name => new_resource.name,
      :type => type,
      :number => (helpers.unicorn?(command) ? 1 : number),
      :unicorn => helpers.unicorn?(command),
      :options => options,
      :environment_attributes => helpers.environment_attributes,
      :pid_prefix => ::File.join(helpers.pid_path, type),
      :lock_path => helpers.lock_path
    })
    notifies :run, 'execute[application_procfile_monit_reload]', :immediately
  end
end

action :before_compile do
  unless new_resource.restart_command
    new_resource.restart_command do
      execute 'application_procfile_reload' do
        command "touch /var/local/#{new_resource.name}/*.reload"
      end
    end
  end
end

action :before_deploy do
  @helpers = ProcfileHelpers.new(new_resource.application.path, new_resource.name, node)

  new_resource.application.environment.update(@helpers.environment_attributes)
  new_resource.application.sub_resources.each do |sub_resource|
    sub_resource.environment.update(@helpers.environment_attributes)
  end

  if ::File.exists?(@helpers.procfile_path)
    # Load application's Procfile
    pf = @helpers.procfile
    process_types = @helpers.procfile_types(pf)

    # Go through the process types we know about
    new_resource.processes.each do |type, options|
      if process_types.include?(type.to_s)
        command = pf[type.to_s]
        if @helpers.unicorn?(command)
          if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
            app_unicorn_rb_path = $1
            command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{@helpers.shared_unicorn_rb_path}")
            create_unicorn_rb(@helpers, type.to_s, options[0], app_unicorn_rb_path)
          else
            command.gsub!(/(unicorn\s+)/, "\\1-c #{@helpers.shared_unicorn_rb_path} ")
            create_unicorn_rb(@helpers, type.to_s, options[0], app_unicorn_rb_path)
          end
        end

        create_lock_directory(@helpers)

        # Migrate pid files from /var/run to /var/local
        ruby_block "migrate_#{type}_pid_files" do
          block do
            require 'fileutils'
            old_pid_path = ::File.join('/var', 'run', new_resource.name)
            if ::File.exists?(old_pid_path)
              ::Dir.glob(::File.join(old_pid_path, "#{type}*.pid")) do |pid_file|
                ::FileUtils.mv(pid_file, ::File.join(@helpers.pid_path, ::File.basename(pid_file)))
              end
            end
          end
        end

        # Remove old lock files
        ['restart', 'reload'].each do |suffix|
          file ::File.join('/var', 'lock', 'subsys', new_resource.name, "#{type}.#{suffix}") do
            action :delete
          end
        end

        create_lock_file(@helpers, type.to_s, 'restart')
        create_lock_file(@helpers, type.to_s, 'reload')
        create_environment_sh(@helpers)
        create_initscript(@helpers, type.to_s, command)
        create_monitrc(@helpers, type.to_s, options[0], command, options[1])
      else
        Chef::Log.warn("Missing Procfile entry for '#{type}'")
      end
    end
  end
end

action :before_migrate do
end

action :before_symlink do
end

action :before_restart do
  include_recipe 'monit'

  new_resource = @new_resource

  @helpers = ProcfileHelpers.new(new_resource.application.path, new_resource.name, node)

  directory @helpers.lock_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory @helpers.pid_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory @helpers.log_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  # Load application's Procfile
  pf = @helpers.procfile
  process_types = @helpers.procfile_types(pf)

  # Go through the process types we know about
  new_resource.processes.each do |type, options|
    if process_types.include?(type.to_s)
      command = pf[type.to_s]
      if @helpers.unicorn?(command)
        if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
          app_unicorn_rb_path = $1
          command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{@helpers.shared_unicorn_rb_path}")
          create_unicorn_rb(@helpers, type.to_s, options[0], app_unicorn_rb_path)
        else
          command.gsub!(/(unicorn\s+)/, "\\1-c #{@helpers.shared_unicorn_rb_path} ")
          create_unicorn_rb(@helpers, type.to_s, options[0], app_unicorn_rb_path)
        end
      end

      create_lock_directory(@helpers)
      create_lock_file(@helpers, type.to_s, 'restart')
      create_lock_file(@helpers, type.to_s, 'reload')
      create_environment_sh(@helpers)
      create_initscript(@helpers, type.to_s, command)
      create_monitrc(@helpers, type.to_s, options[0], command, options[1])
    else
      Chef::Log.warn("Missing Procfile entry for '#{type}'")
    end
  end
end

action :after_restart do
end
