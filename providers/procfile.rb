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

include Chef::Mixin::LanguageIncludeRecipe

action :before_compile do
  include_recipe 'monit'

  unless new_resource.restart_command
    new_resource.restart_command do
      execute '/etc/init.d/monit reload' do
        user 'root'
      end
    end
  end
end

action :before_deploy do
end

action :before_migrate do
end

action :before_symlink do
end

action :before_restart do
  include_recipe 'monit'

  new_resource = @new_resource

  directory "/var/lock/subsys/#{new_resource.name}" do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory "/var/run/#{new_resource.name}" do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  directory "/var/log/#{new_resource.name}" do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  # Load application's Procfile
  pf = ::Foreman::Procfile.new(::File.join(new_resource.application.path, 'current', 'Procfile'))
  types = [].tap { |a| pf.entries { |n,c| a << n } }

  # Go through the process types we know about
  new_resource.processes.each do |type, options|
    if types.include?(type.to_s)
      file "/var/lock/subsys/#{new_resource.name}/#{type}.restart" do
        owner 'root'
        group 'root'
        mode '0644'
        action :create_if_missing
      end

      file "/var/lock/subsys/#{new_resource.name}/#{type}.reload" do
        owner 'root'
        group 'root'
        mode '0644'
        action :create_if_missing
      end

      template 'procfile.init' do
        cookbook 'application_procfile'
        path "/etc/init.d/#{new_resource.name}-#{type}"
        owner 'root'
        group 'root'
        mode '0755'
        variables ({
          :name => new_resource.name,
          :type => type,
          :current_path => ::File.join(new_resource.application.path, 'current'),
          :command => pf[type.to_s]
        })
      end

      template 'procfile.monitrc' do
        cookbook 'application_procfile'
        path "/etc/monit/conf.d/#{new_resource.name}-#{type}.conf"
        owner 'root'
        group 'root'
        mode '0644'
        variables ({
          :name => new_resource.name,
          :type => type,
          :number => options[0],
          :options => options[1]
        })
      end
    else
      Chef::Log.warn("Missing Procfile entry for '#{type}'")
    end
  end
end

action :after_restart do
  execute 'application_procfile_reload' do
    command "touch /var/lock/subsys/#{new_resource.name}/*.reload"
    user 'root'
  end
end
