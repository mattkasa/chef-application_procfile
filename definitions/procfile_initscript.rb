define :procfile_initscript, :application_name => nil, :application_path => nil, :type => nil, :command => nil, :options => nil do
  template ::File.join('/etc', 'init.d', "#{params[:application_name]}-#{params[:type]}") do
    source 'procfile.init.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :name => params[:application_name],
      :type => params[:type],
      :command => params[:command],
      :puma => ProcfileHelpers.puma?(params[:command]),
      :options => params[:options],
      :environment_sh_path => ProcfileHelpers.environment_sh_path(params[:application_path]),
      :pid_path => ProcfileHelpers.pid_path(params[:application_name]),
      :log_path => ProcfileHelpers.log_path(params[:application_name]),
      :current_path => ProcfileHelpers.current_path(params[:application_path])
    })
  end
end
