#
# Author:: Matt Kasa <mattk@granicus.com>
# Cookbook Name:: application_procfile
# Provider:: procfile
#
# Copyright:: 2013, Granicus Inc. <mattk@granicus.com>
#
# This file is part of application_procfile.
#
# application_procfile is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# application_procfile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with application_procfile.  If not, see <http://www.gnu.org/licenses/>.
#

begin
  require 'foreman/procfile'
rescue LoadError
  Chef::Log.warn("Missing gem 'foreman'")
end

include Chef::DSL::IncludeRecipe

module Helpers
  extend Chef::Application::Procfile::Helpers
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
  new_resource.application.environment.update(Helpers.environment_attributes(node, new_resource))
  new_resource.application.sub_resources.each do |sub_resource|
    sub_resource.environment.update(Helpers.environment_attributes(node, new_resource))
  end

  if ::File.exists?(Helpers.procfile_path(new_resource))
    # Load application's Procfile
    pf = Helpers.procfile(new_resource)
    process_types = Helpers.procfile_types(pf)

    # Go through the process types we know about
    new_resource.processes.each do |type, options|
      if process_types.include?(type.to_s)
        command = pf[type.to_s]
        if Helpers.unicorn?(command)
          if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
            app_unicorn_rb_path = $1
            command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{Helpers.unicorn_rb_path(new_resource)}")
            Helpers.create_unicorn_rb(type.to_s, options[0], app_unicorn_rb_path)
          else
            command.gsub!(/(unicorn\s+)/, "\\1-c #{Helpers.unicorn_rb_path(new_resource)} ")
            Helpers.create_unicorn_rb(type.to_s, options[0], Helpers.app_unicorn_rb_path(new_resource))
          end
        end

        Helpers.create_lock_directory(new_resource)

        # Migrate pid files from /var/run to /var/local
        ruby_block "migrate_#{type}_pid_files" do
          block do
            require 'fileutils'
            old_pid_path = ::File.join('/var', 'run', new_resource.name)
            if ::File.exists?(old_pid_path)
              ::Dir.glob(::File.join(old_pid_path, "#{type}*.pid")) do |pid_file|
                ::FileUtils.mv(pid_file, ::File.join(Helpers.pid_path(new_resource), ::File.basename(pid_file)))
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

        Helpers.create_lock_file(new_resource, type.to_s, 'restart')
        Helpers.create_lock_file(new_resource, type.to_s, 'reload')
        Helpers.create_environment_sh(node, new_resource)
        Helpers.create_initscript(new_resource, type.to_s, command)
        Helpers.create_monitrc(new_resource, type.to_s, options[0], command, options[1])
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

  directory Helpers.lock_path(new_resource) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory Helpers.pid_path(new_resource) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory Helpers.log_path(new_resource) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  # Load application's Procfile
  pf = Helpers.procfile(new_resource)
  process_types = Helpers.procfile_types(pf)

  # Go through the process types we know about
  new_resource.processes.each do |type, options|
    if process_types.include?(type.to_s)
      command = pf[type.to_s]
      if Helpers.unicorn?(command)
        if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
          app_unicorn_rb_path = $1
          command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{Helpers.unicorn_rb_path(new_resource)}")
          Helpers.create_unicorn_rb(type.to_s, options[0], app_unicorn_rb_path)
        else
          command.gsub!(/(unicorn\s+)/, "\\1-c #{Helpers.unicorn_rb_path(new_resource)} ")
          Helpers.create_unicorn_rb(type.to_s, options[0], Helpers.app_unicorn_rb_path(new_resource))
        end
      end

      Helpers.create_lock_directory(new_resource)
      Helpers.create_lock_file(new_resource, type.to_s, 'restart')
      Helpers.create_lock_file(new_resource, type.to_s, 'reload')
      Helpers.create_environment_sh(node, new_resource)
      Helpers.create_initscript(new_resource, type.to_s, command)
      Helpers.create_monitrc(new_resource, type.to_s, options[0], command, options[1])
    else
      Chef::Log.warn("Missing Procfile entry for '#{type}'")
    end
  end
end

action :after_restart do
end
