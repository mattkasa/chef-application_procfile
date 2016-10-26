include_recipe 'apt'
include_recipe 'git'
include_recipe 'rvm::system'
include_recipe 'application_procfile'

package 'sqlite3'
package 'libsqlite3-dev'

application 'fakier' do
  path '/var/www/fakier'
  repository 'https://github.com/Granicus/fake-rails.git'
  revision 'master'
  action :force_deploy

  rails do
    bundler true
  end

  procfile do
    web node[:fakier][:web], :stop => 'USR1'
  end
end
