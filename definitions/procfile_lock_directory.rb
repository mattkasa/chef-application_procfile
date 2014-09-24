define :procfile_lock_directory, :name => nil do
  directory ProcfileHelpers.lock_path(params[:name]) do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
end
