#
# Author:: Matt Kasa <mattk@granicus.com>
# Cookbook Name:: application_procfile
# Recipe:: procfile
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

include_recipe 'monit'

chef_gem 'foreman' do
  action :install
end

begin
  require 'foreman/procfile'
rescue LoadError
end

ruby_block 'require-foreman' do
  block do
    require 'foreman/procfile'
  end
end
