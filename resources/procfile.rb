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

include ApplicationCookbook::ResourceBase

# Handle any process types
# TODO: restrict these to only the process types in the Procfile
def method_missing(name, *args)
  @processes ||= {}
  @processes[name.to_sym] = args
end

# Expose the instance variable
def processes
  @processes
end
