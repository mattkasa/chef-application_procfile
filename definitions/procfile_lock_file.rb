define :procfile_lock_file, :name => nil, :application_name => nil do
  directory ProcfileHelpers.lock_path(params[:application_name]) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
  file ::File.join(ProcfileHelpers.lock_path(params[:application_name]), params[:name]) do
    owner 'root'
    group 'root'
    mode '0644'
    action :create_if_missing
  end
end
