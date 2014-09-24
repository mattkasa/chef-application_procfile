#
# Author:: Matt Kasa <mattk@granicus.com>
# Cookbook Name:: application_procfile
# Provider:: procfile
#
# Copyright:: 2014, Granicus Inc. <mattk@granicus.com>
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

action :before_compile do
  unless new_resource.restart_command
    new_resource.restart_command do
      execute "application_procfile_reload_#{new_resource.name}" do
        command "touch /var/local/#{new_resource.name}/*.reload"
      end
    end
  end
end

action :before_deploy do
  new_resource.application.environment.update(ProcfileHelpers.environment_attributes(node, new_resource.name))
  new_resource.application.sub_resources.each do |sub_resource|
    sub_resource.environment.update(ProcfileHelpers.environment_attributes(node, new_resource.name))
  end

  if ::File.exists?(ProcfileHelpers.procfile_path(new_resource.application.path))
    # Load application's Procfile
    pf = ProcfileHelpers.procfile(new_resource.application.path)
    process_types = ProcfileHelpers.procfile_types(pf)

    # Go through the process types we know about
    new_resource.processes.each do |type, options|
      if process_types.include?(type.to_s)
        command = pf[type.to_s]
        if ProcfileHelpers.unicorn?(command)
          if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
            app_unicorn_rb_path = $1
            command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{ProcfileHelpers.shared_unicorn_rb_path(new_resource.application.path)}")
            procfile_unicorn_rb do
              application_name new_resource.name
              application_path new_resource.application.path
              type type.to_s
              workers options[0]
              app_unicorn_rb_path app_unicorn_rb_path
            end
          else
            command.gsub!(/(unicorn\s+)/, "\\1-c #{ProcfileHelpers.shared_unicorn_rb_path(new_resource.application.path)} ")
            procfile_unicorn_rb do
              application_name new_resource.name
              application_path new_resource.application.path
              type type.to_s
              workers options[0]
              app_unicorn_rb_path app_unicorn_rb_path
            end
          end
        elsif ProcfileHelpers.thin?(command)
          command.gsub!(/(?:-P|--pid) [^[:space:]]+[[:space:]]?/, '')
          command.sub!(/thin[[:space:]]/, "\\0-P /dev/null ")
        end

        procfile_lock_directory new_resource.name

        # Migrate pid files from /var/run to /var/local
        ruby_block "migrate_#{new_resource.name}-#{type}_pid_files" do
          block do
            require 'fileutils'
            old_pid_path = ::File.join('/var', 'run', new_resource.name)
            if ::File.exists?(old_pid_path)
              ::Dir.glob(::File.join(old_pid_path, "#{type}*.pid")) do |pid_file|
                ::FileUtils.mv(pid_file, ::File.join(ProcfileHelpers.pid_path(new_resource.name), ::File.basename(pid_file)))
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

        procfile_lock_file "#{type.to_s}.restart" do
          application_name new_resource.name
        end
        procfile_lock_file "#{type.to_s}.reload" do
          application_name new_resource.name
        end
        procfile_environment_sh do
          application_name new_resource.name
          application_path new_resource.application.path
          path_prefix new_resource.application.environment['PATH_PREFIX']
        end
        procfile_initscript do
          application_name new_resource.name
          application_path new_resource.application.path
          type type.to_s
          command command
        end
        procfile_monitrc do
          application_name new_resource.name
          application_path new_resource.application.path
          type type.to_s
          number options[0]
          command command
          options options[1]
        end
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

  directory ProcfileHelpers.lock_path(new_resource.name) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory ProcfileHelpers.pid_path(new_resource.name) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory ProcfileHelpers.log_path(new_resource.name) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  template ::File.join('/usr/local/bin', new_resource.name) do
    source 'wrapper.sh.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :current_path => ProcfileHelpers.current_path(new_resource.application.path),
      :environment_sh_path => ProcfileHelpers.environment_sh_path(new_resource.application.path)
    })
  end

  # Load application's Procfile
  pf = ProcfileHelpers.procfile(new_resource.application.path)
  process_types = ProcfileHelpers.procfile_types(pf)

  # Go through the process types we know about
  new_resource.processes.each do |type, options|
    if process_types.include?(type.to_s)
      command = pf[type.to_s]
      if ProcfileHelpers.unicorn?(command)
        if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
          app_unicorn_rb_path = $1
          command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{ProcfileHelpers.shared_unicorn_rb_path(new_resource.application.path)}")
          procfile_unicorn_rb do
            application_name new_resource.name
            application_path new_resource.application.path
            type type.to_s
            workers options[0]
            app_unicorn_rb_path app_unicorn_rb_path
          end
        else
          command.gsub!(/(unicorn\s+)/, "\\1-c #{ProcfileHelpers.shared_unicorn_rb_path(new_resource.application.path)} ")
          procfile_unicorn_rb do
            application_name new_resource.name
            application_path new_resource.application.path
            type type.to_s
            workers options[0]
            app_unicorn_rb_path app_unicorn_rb_path
          end
        end
      elsif ProcfileHelpers.thin?(command)
        command.gsub!(/(?:-P|--pid) [^[:space:]]+[[:space:]]?/, '')
        command.sub!(/thin[[:space:]]/, "\\0-P /dev/null ")
      end

      procfile_lock_directory new_resource.name
      procfile_lock_file "#{type.to_s}.restart" do
        application_name new_resource.name
      end
      procfile_lock_file "#{type.to_s}.reload" do
        application_name new_resource.name
      end
      procfile_environment_sh do
        application_name new_resource.name
        application_path new_resource.application.path
        path_prefix new_resource.application.environment['PATH_PREFIX']
      end
      procfile_initscript do
        application_name new_resource.name
        application_path new_resource.application.path
        type type.to_s
        command command
      end
      procfile_monitrc do
        application_name new_resource.name
        application_path new_resource.application.path
        type type.to_s
        number options[0]
        command command
        options options[1]
      end
    else
      Chef::Log.warn("Missing Procfile entry for '#{type}'")
    end
  end
end

action :after_restart do
end
