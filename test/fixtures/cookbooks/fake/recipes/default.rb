include_recipe 'git'
include_recipe 'application_procfile'

package 'sqlite3'
package 'libsqlite3-dev'

application 'fake' do
  path '/var/www/fake'
  repository 'https://github.com/Granicus/fake-rails.git'
  revision 'master'
  action :force_deploy

  rails do
    bundler true
  end

  procfile do
    web 10
  end
end
