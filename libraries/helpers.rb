class Chef
  class Application
    module Procfile
      module Helpers
        extend self

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
          node[new_resource.name.to_sym].inject({}) { |h, (k, v)| h[k.to_s.upcase] = v.to_s; h }
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
      end
    end
  end
end
