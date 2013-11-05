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
        command "touch /var/local/#{new_resource.name}/*.reload"
      end
    end
  end
end

action :before_deploy do
  new_resource.application.environment.update(environment_attributes)
  new_resource.application.sub_resources.each do |sub_resource|
    sub_resource.environment.update(environment_attributes)
  end

  if ::File.exists?(procfile_path)
    # Load application's Procfile
    pf = procfile
    process_types = procfile_types(pf)

    # Go through the process types we know about
    new_resource.processes.each do |type, options|
      if process_types.include?(type.to_s)
        command = pf[type.to_s]
        if unicorn?(command)
          if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
            app_unicorn_rb_path = $1
            command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{unicorn_rb_path}")
            create_unicorn_rb(type.to_s, options[0], app_unicorn_rb_path)
          else
            command.gsub!(/(unicorn\s+)/, "\\1-c #{unicorn_rb_path} ")
            create_unicorn_rb(type.to_s, options[0])
          end
        end

        create_lock_directory

        # Migrate pid files from /var/run to /var/local
        ruby_block "migrate_#{type}_pid_files" do
          block do
            require 'fileutils'
            old_pid_path = ::File.join('/var', 'run', new_resource.name)
            if ::File.exists?(old_pid_path)
              ::Dir.glob(::File.join(old_pid_path, "#{type}*.pid")) do |pid_file|
                ::FileUtils.mv(pid_file, ::File.join(pid_path, ::File.basename(pid_file)))
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

        create_lock_file(type.to_s, 'restart')
        create_lock_file(type.to_s, 'reload')
        create_environment_sh
        create_initscript(type.to_s, command)
        create_monitrc(type.to_s, options[0], command, options[1])
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
        if command =~ /(?:-c|--config-file) ([^[:space:]]+)/
          app_unicorn_rb_path = $1
          command.gsub!(/(-c|--config-file) [^[:space:]]+/, "\\1 #{unicorn_rb_path}")
          create_unicorn_rb(type.to_s, options[0], app_unicorn_rb_path)
        else
          command.gsub!(/(unicorn\s+)/, "\\1-c #{unicorn_rb_path} ")
          create_unicorn_rb(type.to_s, options[0])
        end
      end

      create_lock_directory
      create_lock_file(type.to_s, 'restart')
      create_lock_file(type.to_s, 'reload')
      create_environment_sh
      create_initscript(type.to_s, command)
      create_monitrc(type.to_s, options[0], command, options[1])
    else
      Chef::Log.warn("Missing Procfile entry for '#{type}'")
    end
  end
end

action :after_restart do
end

protected

def current_path
  @current_path ||= ::File.join(new_resource.application.path, 'current')
end

def shared_path
  @shared_path ||= ::File.join(new_resource.application.path, 'shared')
end

def environment_sh_path
  @environment_sh_path ||= ::File.join(shared_path, 'environment.sh')
end

def procfile_path
  @procfile_path ||= ::File.join(current_path, 'Procfile')
end

def lock_path
  @lock_path ||= ::File.join('/var', 'local', new_resource.name)
end

def pid_path
  @pid_path ||= ::File.join('/var', 'local', new_resource.name)
end

def log_path
  @log_path ||= ::File.join('/var', 'log', new_resource.name)
end

def unicorn_rb_path
  @unicorn_rb_path ||= ::File.join(shared_path, 'unicorn.rb')
end

def procfile
  ::Foreman::Procfile.new(procfile_path)
end

def procfile_types(pf=procfile)
  [].tap { |a| pf.entries { |n,c| a << n } }
end

def environment_attributes
  mash = (m = node[new_resource.name.to_sym] and m.has_key?(:env) ? m[:env] : m)
  mash.inject({}) { |h, (k, v)| h[k.to_s.upcase] = v.to_s; h }
end

def unicorn?(command)
  command.to_s.include?('unicorn')
end

def create_unicorn_rb(type='web', workers=1, app_unicorn_rb_path="#{::File.join(current_path, 'config', 'unicorn.rb')}")
  execute "application_procfile_reload_#{type}" do
    command "touch #{::File.join(lock_path, "#{type}.reload")}"
    action :nothing
  end
  template unicorn_rb_path do
    source 'unicorn.rb.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '644'
    variables(
      :app_unicorn_rb_path => app_unicorn_rb_path,
      :pid_file => ::File.join(shared_path, 'unicorn.pid'),
      :monit_pid_file => ::File.join(pid_path, "#{type}-0.pid"),
      :workers => workers,
      :environment_sh_path => environment_sh_path,
      :current_path => current_path
    )
    notifies :run, "execute[application_procfile_reload_#{type}]", :delayed
  end
end

def create_lock_file(type, suffix)
  file ::File.join(lock_path, "#{type}.#{suffix}") do
    owner 'root'
    group 'root'
    mode '0644'
    action :create_if_missing
  end
end

def create_lock_directory
  directory lock_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
end

def create_environment_sh
  execute "application_procfile_reload" do
    command "touch #{::File.join(lock_path, '*.reload')}"
    action :nothing
  end
  template environment_sh_path do
    source 'environment.sh.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :path_prefix => new_resource.application.environment['PATH_PREFIX'],
      :environment_attributes => environment_attributes
    })
    notifies :run, "execute[application_procfile_reload]", :delayed
  end
end

def create_initscript(type, command)
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
      :environment_sh_path => environment_sh_path,
      :pid_path => pid_path,
      :log_path => log_path,
      :current_path => current_path
    })
  end
end

def create_monitrc(type, number, command, options)
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
      :number => (unicorn?(command) ? 1 : number),
      :unicorn => unicorn?(command),
      :options => options,
      :pid_path => pid_path,
      :lock_path => lock_path
    })
    notifies :run, 'execute[application_procfile_monit_reload]', :immediately
  end
end
