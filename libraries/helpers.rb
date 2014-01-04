begin
  require 'foreman/procfile'
rescue LoadError
  Chef::Log.warn("Missing gem 'foreman'")
end

class Chef
  class Application
    module Procfile
      module Helpers
        extend self

        def current_path(new_resource)
          @current_path ||= ::File.join(new_resource.application.path, 'current')
        end

        def shared_path(new_resource)
          @shared_path ||= ::File.join(new_resource.application.path, 'shared')
        end

        def environment_sh_path(new_resource)
          @environment_sh_path ||= ::File.join(self.shared_path(new_resource), 'environment.sh')
        end

        def procfile_path(new_resource)
          @procfile_path ||= ::File.join(self.current_path(new_resource), 'Procfile')
        end

        def lock_path(new_resource)
          @lock_path ||= ::File.join('/var', 'local', new_resource.name)
        end

        def pid_path(new_resource)
          @pid_path ||= ::File.join('/var', 'local', new_resource.name)
        end

        def log_path(new_resource)
          @log_path ||= ::File.join('/var', 'log', new_resource.name)
        end

        def unicorn_rb_path(new_resource)
          @unicorn_rb_path ||= ::File.join(self.shared_path(new_resource), 'unicorn.rb')
        end

        def app_unicorn_rb_path(new_resource)
          @app_unicorn_rb_path ||= ::File.join(self.current_path(new_resource), 'config', 'unicorn.rb')
        end

        def procfile(new_resource)
          ::Foreman::Procfile.new(self.procfile_path(new_resource))
        end

        def procfile_types(pf)
          [].tap { |a| pf.entries { |n,c| a << n } }
        end

        def environment_attributes(node, new_resource)
          node[new_resource.name.to_sym].inject({}) { |h, (k, v)| h[k.to_s.upcase] = v.to_s; h }
        end

        def unicorn?(command)
          command.to_s.include?('unicorn')
        end

        def create_unicorn_rb(new_resource, type = 'web', workers = 1, app_unicorn_rb_path)
          execute "application_procfile_reload_#{type}" do
            command "touch #{::File.join(self.lock_path(new_resource), "#{type}.reload")}"
            action :nothing
          end
          template self.unicorn_rb_path(new_resource) do
            source 'unicorn.rb.erb'
            cookbook 'application_procfile'
            owner 'root'
            group 'root'
            mode '644'
            variables(
              :app_unicorn_rb_path => app_unicorn_rb_path,
              :pid_file => ::File.join(self.shared_path(new_resource), 'unicorn.pid'),
              :monit_pid_file => ::File.join(self.pid_path(new_resource), "#{type}-0.pid"),
              :workers => workers,
              :environment_sh_path => self.environment_sh_path(new_resource),
              :current_path => self.current_path(new_resource)
            )
            notifies :run, "execute[application_procfile_reload_#{type}]", :delayed
          end
        end

        def create_lock_file(new_resource, type, suffix)
          file ::File.join(self.lock_path(new_resource), "#{type}.#{suffix}") do
            owner 'root'
            group 'root'
            mode '0644'
            action :create_if_missing
          end
        end

        def create_lock_directory(new_resource)
          directory self.lock_path(new_resource) do
            owner 'root'
            group 'root'
            mode '0755'
            recursive true
            action :create
          end
        end

        def create_environment_sh(node, new_resource)
          execute "application_procfile_reload" do
            command "touch #{::File.join(self.lock_path(new_resource), '*.reload')}"
            action :nothing
          end
          template self.environment_sh_path(new_resource) do
            source 'environment.sh.erb'
            cookbook 'application_procfile'
            owner 'root'
            group 'root'
            mode '0755'
            variables ({
              :path_prefix => new_resource.application.environment['PATH_PREFIX'],
              :environment_attributes => self.environment_attributes(node, new_resource)
            })
            notifies :run, "execute[application_procfile_reload]", :delayed
          end
        end

        def create_initscript(new_resource, type, command)
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
              :environment_sh_path => self.environment_sh_path(new_resource),
              :pid_path => self.pid_path(new_resource),
              :log_path => self.log_path(new_resource),
              :current_path => self.current_path(new_resource)
            })
          end
        end

        def create_monitrc(new_resource, type, number, command, options)
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
              :number => (self.unicorn?(command) ? 1 : number),
              :unicorn => self.unicorn?(command),
              :options => options,
              :pid_path => self.pid_path(new_resource),
              :lock_path => self.lock_path(new_resource)
            })
            notifies :run, 'execute[application_procfile_monit_reload]', :immediately
          end
        end
      end
    end
  end
end
