begin
  require 'foreman/procfile'
rescue LoadError
  Chef::Log.warn("Missing gem 'foreman'")
end

class ProcfileHelpers
  attr_accessor :new_resource
  attr_accessor :node

  def current_path
    @current_path ||= ::File.join(@new_resource.application.path, 'current')
  end

  def shared_path
    @shared_path ||= ::File.join(@new_resource.application.path, 'shared')
  end

  def environment_sh_path
    @environment_sh_path ||= ::File.join(self.shared_path, 'environment.sh')
  end

  def procfile_path
    @procfile_path ||= ::File.join(self.current_path, 'Procfile')
  end

  def lock_path
    @lock_path ||= ::File.join('/var', 'local', @new_resource.name)
  end

  def pid_path
    @pid_path ||= ::File.join('/var', 'local', @new_resource.name)
  end

  def log_path
    @log_path ||= ::File.join('/var', 'log', @new_resource.name)
  end

  def shared_unicorn_rb_path
    @shared_unicorn_rb_path ||= ::File.join(self.shared_path, 'unicorn.rb')
  end

  def unicorn_rb_path
    @unicorn_rb_path ||= ::File.join(self.current_path, 'config', 'unicorn.rb')
  end

  def procfile
    ::Foreman::Procfile.new(self.procfile_path)
  end

  def procfile_types(pf)
    [].tap { |a| pf.entries { |n,c| a << n } }
  end

  def environment_attributes
    @node[@new_resource.name.to_sym].inject({}) { |h, (k, v)| h[k.to_s.upcase] = v.to_s; h }
  end

  def unicorn?(command)
    command.to_s.include?('unicorn')
  end
end
