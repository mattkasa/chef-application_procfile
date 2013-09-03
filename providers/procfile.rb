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

action :before_compile do
  unless new_resource.restart_command
    new_resource.restart_command do
      execute 'application_procfile_reload' do
        command "touch /var/lock/subsys/#{new_resource.name}/*.reload"
      end
    end
  end
end

action :before_deploy do
  if node[new_resource.name.to_sym].has_key?(:env)
    node[new_resource.name.to_sym][:env].each do |k,v|
      ENV[k.to_s.upcase] = v.to_s
    end
  else
    node[new_resource.name.to_sym].each do |k,v|
      ENV[k.to_s.upcase] = v.to_s
    end
  end

  if ::File.exists?(unicorn_rb_path) && ::File.exists?(procfile_path)
    # Load application's Procfile
    pf = procfile
    process_types = procfile_types(pf)

    # Go through the process types we know about
    new_resource.processes.each do |type, options|
      if process_types.include?(type.to_s)
        execute "application_procfile_reload_#{type.to_s}" do
          command "touch #{::File.join(lock_path, "#{new_resource.name}#{type.to_s}.reload")}"
          action :nothing
        end
        # Create a unicorn.rb if one of the process types we know about is running unicorn
        template unicorn_rb_path do
          only_if do unicorn?(pf[type.to_s]) end
          source 'unicorn.rb.erb'
          cookbook 'application_procfile'
          owner 'root'
          group 'root'
          mode '644'
          variables(
            :current_path => ::File.join(new_resource.path, 'current'),
            :pid_file => ::File.join(new_resource.path, 'shared', 'unicorn.pid'),
            :monit_pid_file => ::File.join(pid_path, "#{type.to_s}-0.pid"),
            :workers => options[0]
          )
          notifies :run, "execute[application_procfile_reload_#{type.to_s}]", :delayed
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

  directory lock_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory pid_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory log_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  # Load application's Procfile
  pf = procfile
  process_types = procfile_types(pf)

  # Go through the process types we know about
  new_resource.processes.each do |type, options|
    if process_types.include?(type.to_s)
      command = pf[type.to_s]
      if unicorn?(command)
        command.gsub!(/-c [^[:space:]]+/, "-c #{unicorn_rb_path}")
        template unicorn_rb_path do
          source 'unicorn.rb.erb'
          cookbook 'application_procfile'
          owner 'root'
          group 'root'
          mode '644'
          variables(
            :current_path => ::File.join(new_resource.path, 'current'),
            :pid_file => ::File.join(new_resource.path, 'shared', 'unicorn.pid'),
            :monit_pid_file => ::File.join(pid_path, "#{type.to_s}-0.pid"),
            :workers => options[0]
          )
          notifies :run, "execute[application_procfile_reload_#{type.to_s}]", :delayed
        end
      end

      file ::File.join(lock_path, "#{type}.restart") do
        owner 'root'
        group 'root'
        mode '0644'
        action :create_if_missing
      end

      file ::File.join(lock_path, "#{type}.reload") do
        owner 'root'
        group 'root'
        mode '0644'
        action :create_if_missing
      end

      template 'procfile.init' do
        cookbook 'application_procfile'
        path ::File.join('/etc', 'init.d', "#{new_resource.name}-#{type}")
        owner 'root'
        group 'root'
        mode '0755'
        variables ({
          :name => new_resource.name,
          :type => type,
          :current_path => ::File.join(new_resource.application.path, 'current'),
          :pid_path => pid_path,
          :log_path => log_path,
          :command => command
        })
      end

      execute 'application_procfile_monit_reload' do
        command '/etc/init.d/monit reload'
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
          :number => (unicorn?(command) ? 1 : options[0]),
          :options => options[1],
          :lock_path => lock_path,
          :pid_path => pid_path
        })
        notifies :run, 'execute[application_procfile_monit_reload]', :immediately
      end
    else
      Chef::Log.warn("Missing Procfile entry for '#{type}'")
    end
  end
end

action :after_restart do
end

protected

def procfile_path
  @procfile_path ||= ::File.join(new_resource.application.path, 'current', 'Procfile')
end

def lock_path
  @lock_path ||= ::File.join('/var', 'lock', 'subsys', new_resource.name)
end

def pid_path
  @pid_path ||= ::File.join('/var', 'run', new_resource.name)
end

def log_path
  @log_path ||= ::File.join('/var', 'log', new_resource.name)
end

def unicorn_rb_path
  @unicorn_rb_path ||= ::File.join(new_resource.path, 'shared', 'unicorn.rb')
end

def procfile
  ::Foreman::Procfile.new(procfile_path)
end

def procfile_types(pf=procfile)
  [].tap { |a| pf.entries { |n,c| a << n } }
end

def unicorn?(command)
  command.to_s.include?('unicorn')
end
