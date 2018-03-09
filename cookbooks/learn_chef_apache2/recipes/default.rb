#
# Cookbook:: learn_chef_apache2
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

apt_update 'Update the cache daily' do
  frequency 86_400
  action :periodic
end

package 'apache2' # Don't need to specify an action because :install is the default for the `package` resource

service 'apache2' do
  supports status: true
  action [:enable, :start] # Enable the apache webserver, then start it
end

template '/var/www/html/index.html' do
  source 'index.html.erb' # In the templates folder
end
