define :procfile_unicorn_rb, :application_name => nil, :application_path => nil, :type => 'web', :workers => 1, :app_unicorn_rb_path => nil do
  execute "application_procfile_reload_#{params[:application_name]}-#{type}" do
    command "touch #{::File.join(ProcfileHelpers.lock_path(params[:application_name]), "#{type}.reload")}"
    action :nothing
  end
  template ProcfileHelpers.shared_unicorn_rb_path(params[:application_path]) do
    source 'unicorn.rb.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '644'
    variables(
      :app_unicorn_rb_path => app_unicorn_rb_path,
      :pid_file => ::File.join(ProcfileHelpers.shared_path(params[:application_path]), 'unicorn.pid'),
      :monit_pid_file => ::File.join(ProcfileHelpers.pid_path(params[:application_name]), "#{type}-0.pid"),
      :workers => workers,
      :environment_sh_path => ProcfileHelpers.environment_sh_path(params[:application_path]),
      :current_path => ProcfileHelpers.current_path(params[:application_path])
    )
    notifies :run, "execute[application_procfile_reload_#{params[:application_name]}-#{type}]", :delayed
  end
end
