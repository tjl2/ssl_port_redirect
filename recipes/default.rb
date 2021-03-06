#
# Cookbook Name:: ssl_port_redirect
# Recipe:: default
#

if ['app_master','app'].include?(node[:instance_role])
  ey_cloud_report "ssl port redirect" do
    message "configuring redirection of SSL traffic to port 444"
  end

  execute "restart-nginx" do
    command "/etc/init.d/nginx reload"
    action :nothing
  end
  
  # Drop in a replacement nginx ssl config
  node["applications"].each_key do |app_name|
    # SSL apps have 2 vhosts configured
    if node["applications"][app_name]["vhosts"].length == 2
      template "/data/nginx/servers/#{app_name}.ssl.conf" do
        owner   node[:owner_name]
        group   node[:group_name]
        mode    0644
        source  "custom_ssl.conf.erb"

        variables({
          :app_name => app_name,
          :server_names =>
            node[:applications][app_name][:vhosts].first[:name].empty? ? [] : [node[:applications][app_name][:vhosts].first[:name]],
        })
        notifies :run, resources(:execute => "restart-nginx"), :delayed
      end
    end
  end

  # Add our iptables redirection
  execute "iptables preroute redirect 443 to 444" do
    command "iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 444"
    action :run
    not_if do
      `/sbin/iptables -L PREROUTING -n -t nat`.match(
        /REDIRECT\s.*tcp\s.*\-\-\s.*[0\.]{3}0\/0\s.*[0\.]{3}0\/0\s.*tcp\s.*dpt\:443\s.*redir\s.*ports\s.*444/)
    end
  end

  # Save the iptables settings so we persist a reboot
  execute "iptables save" do
    command "/etc/init.d/iptables save"
    action :run
  end

  # Ensure that the iptables init script is set to start on boot
  service "iptables" do
    action [:enable, :start]
  end

  # Add a MOTD, reminding support staff that this is in place
  remote_file "/etc/motd" do
    owner "root"
    group "root"
    mode  "0644"
    source "motd.txt"
    action :create
  end
end
