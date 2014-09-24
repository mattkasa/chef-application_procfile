define :procfile_environment_sh, :application_name => nil, :application_path => nil, :path_prefix => nil do
  execute "application_procfile_reload_#{params[:application_name]}" do
    command "touch #{::File.join(ProcfileHelpers.lock_path(params[:application_name]), '*.reload')}"
    action :nothing
  end
  template ProcfileHelpers.environment_sh_path(params[:application_path]) do
    source 'environment.sh.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :path_prefix => params[:path_prefix],
      :environment_attributes => ProcfileHelpers.environment_attributes(node, params[:application_name])
    })
    notifies :run, "execute[application_procfile_reload_#{params[:application_name]}]", :delayed
  end
end
