define :procfile_monitrc, :application_name => nil, :application_path => nil, :type => nil, :number => nil, :command => nil, :options => nil do
  execute 'application_procfile_monit_reload' do
    command 'monit reload'
    action :nothing
  end

  template ::File.join('/etc', 'monit', 'conf.d', "#{params[:application_name]}-#{params[:type]}.conf") do
    source 'procfile.monitrc.erb'
    cookbook 'application_procfile'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :name => params[:application_name],
      :type => params[:type],
      :number => ((ProcfileHelpers.unicorn?(params[:command]) || ProcfileHelpers.thin?(params[:command])) ? 1 : params[:number]),
      :unicorn => ProcfileHelpers.unicorn?(params[:command]),
      :thin => ProcfileHelpers.thin?(params[:command]),
      :options => params[:options],
      :environment_attributes => ProcfileHelpers.environment_attributes(node, params[:application_name]),
      :pid_prefix => ::File.join(ProcfileHelpers.pid_path(params[:application_path]), params[:type]),
      :lock_path => ProcfileHelpers.lock_path(params[:application_name])
    })
    notifies :run, 'execute[application_procfile_monit_reload]', :immediately
  end
end
