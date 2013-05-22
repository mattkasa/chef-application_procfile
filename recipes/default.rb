#
# Author:: Matt Kasa <mattk@granicus.com>
# Cookbook Name:: application_procfile
# Recipe:: procfile
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

include_recipe 'monit'

chef_gem 'foreman' do
  action :install
end

require 'foreman/procfile'
