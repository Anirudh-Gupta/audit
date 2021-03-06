# encoding: utf-8
#
# Cookbook Name:: compliance
# Recipe:: interval
#
# Copyright 2016 Chef Software, Inc.
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

interval = node['audit']['interval']['time'] * 60

compliance_cache_directory = ::File.join(Chef::Config[:file_cache_path], 'compliance')
directory compliance_cache_directory

# iterate over all selected profiles

node['audit']['profiles'].each do |owner_profile, enabled|
  next unless enabled
  o, p = owner_profile.split('/')
  # touch a file so we can keep track of when the profile was last executed

  file "#{compliance_cache_directory}/#{p}" do
    action :nothing
  end
  compliance_profile p do
    owner o
    action [:fetch, :execute]
    not_if { last_run(p, interval) && node['audit']['interval']['enabled'] }
    notifies :touch, "file[#{compliance_cache_directory}/#{p}]", :immediately
  end
end

# report the results
compliance_report 'chef-server' if node['audit']['profiles'].values.any?
