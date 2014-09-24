begin
  require 'foreman/procfile'
rescue LoadError
  Chef::Log.warn("Missing gem 'foreman'")
end

module ProcfileHelpers
  class << self
    def current_path(path)
      ::File.join(path, 'current')
    end

    def current_release(path)
      ::File.basename(::File.realpath(current_path(path)))[0,7]
    end

    def shared_path(path)
      ::File.join(path, 'shared')
    end

    def environment_sh_path(path)
      ::File.join(shared_path(path), 'environment.sh')
    end

    def procfile_path(path)
      ::File.join(current_path(path), 'Procfile')
    end

    def lock_path(name)
      ::File.join('/var', 'local', name)
    end

    def pid_path(name)
      ::File.join('/var', 'local', name)
    end

    def log_path(name)
      ::File.join('/var', 'log', name)
    end

    def shared_unicorn_rb_path(path)
      ::File.join(shared_path(path), 'unicorn.rb')
    end

    def unicorn_rb_path(path)
      ::File.join(current_path(path), 'config', 'unicorn.rb')
    end

    def procfile(path)
      ::Foreman::Procfile.new(procfile_path(path))
    end

    def procfile_types(pf)
      [].tap { |a| pf.entries { |n,c| a << n } }
    end

    def environment_attributes(node, name)
      (node[name.to_sym] || {}).inject({}) { |h, (k, v)| h[k.to_s.upcase] = v.to_s; h }
    end

    def unicorn?(command)
      command.to_s.include?('unicorn')
    end

    def thin?(command)
      command.to_s.include?('thin')
    end
  end
end
