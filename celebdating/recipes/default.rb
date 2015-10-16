#
# Cookbook Name:: celebdating
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
chef_gem 'aws'

# Setup users and directories
user "neon" do
  action :create
  system true
end

user node[:celebdating][:runuser] do
  action :create
  system true
  shell "/bin/false"
  gid "neon"
end

directory node[:celebdating][:root_path] do
  user "neon"
  group "neon"
  mode "1755"
  recursive true
end

directory node[:celebdating][:log_dir] do
  user "neon"
  group "neon"
  mode "1775"
  recursive true
end

directory "#{node[:celebdating][:root_path]}/.ssh/" do
  user "neon"
  group "neon"
  mode "0700"
end

# Setup dependencies
include_recipe "apt"
node.default[:python][:version] = '2.7.5'
include_recipe "python"

node.default[:git][:version] = '1.7.9.5'
include_recipe "git"

node[:deploy].each do |app_name, deploy|
  if app_name != "celeb_backend" then
    next
  end

  repo_path = "#{node[:celebdating][:root_path]}/#{node[:deploy][app_name][:document_root]}"

  Chef::Log.info("Deploying app #{app_name} using code path #{repo_path}")

  # Put the ssh key to get to the repo
  ssh_keyfile = "#{node[:celebdating][:root_path]}/.ssh/#{app_name}.pem"

  file ssh_keyfile do
    content deploy[:scm][:ssh_key]
    mode "0600"
    owner "neon"
    group "neon"
  end

  # Create the ssh wrapper to use the ssh key
  template "#{node[:celebdating][:root_path]}/celebdating-wrap-ssh4git.sh" do
    owner "neon"
    group "neon"
    source "wrap-ssh4git.sh.erb"
    mode "0755"
    variables({:ssh_key => ssh_keyfile})
  end

  # Get the code repository
  git repo_path do
    repository deploy[:scm][:repository]
    revision deploy[:scm][:revision]
    enable_submodules true
    action :sync
    user "neon"
    group "neon"
    ssh_wrapper "#{node[:celebdating][:root_path]}/celebdating-wrap-ssh4git.sh"
  end

  # Get the model files
  s3_file "#{repo_path}/faces.model" do
    bucket node[:celebdating][:face_cluster_model_bucket]
    remote_path node[:celebdating][:face_cluster_model_path]
    owner "neon"
    group "neon"
    action :create
    mode "0644"
  end
  s3_file "#{repo_path}/celebrities.model" do
    bucket node[:celebdating][:celebrity_model_bucket]
    remote_path node[:celebdating][:celebrity_model_path]
    owner "neon"
    group "neon"
    action :create
    mode "0644"
  end

  # Create the virtual environment and install python dependencies
  venv = "#{repo_path}/.pyenv"
  python_virtualenv venv do
    interpreter "python2.7"
    owner "neon"
    group "neon"
    action :create
  end
  bash "install_python_deps" do
    cwd repo_path
    user "neon"
    group "neon"
    code <<-EOH
       source .pyenv/bin/activate
       pip install -r requirements.txt
    EOH
  end

  # Write the daemon service wrapper
  template "/etc/init/celeb_backend.conf" do
    source "celeb_backend_service.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables({:repo_root => repo_path,
               :db => deploy[:database],
               :face_model_file => "#{repo_path}/faces.model",
               :celebrity_model_file => "#{repo_path}/celebrities.model",
                :haar_model_file => "#{repo_path}/server/haarcascade_frontalface_alt2.xml"})
  end

  # Define the service
  service "celeb_backend" do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :restart => true, :start => true, :stop => true
    action [:enable, :start]
    subscribes :restart, "git[#{repo_path}]", :delayed
  end
  
end

if ['undeploy', 'shutdown'].include? node[:opsworks][:activity] then
  # Turn off video_client
  service "celeb_backend" do
    action :stop
  end
end

  
