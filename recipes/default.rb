#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright 2014-2016, Bloomberg Finance L.P.
#
include_recipe 'chef-sugar::default'

if rhel?
  include_recipe 'yum-epel::default' if node['platform_version'].to_i == 5
end

node.default['nssm']['install_location'] = '%WINDIR%'

if node['firewall']['allow_consul']
  include_recipe 'firewall::default'

  # Don't open ports that we've disabled
  ports = node['consul']['config']['ports'].select { |_name, port| port != -1 }

  firewall_rule 'consul' do
    protocol :tcp
    port ports.values
    action :create
    command :allow
  end

  firewall_rule 'consul-udp' do
    protocol :udp
    port ports.values_at('serf_lan', 'serf_wan', 'dns')
    action :create
    command :allow
  end
end

unless windows?
  group node['consul']['service_group']
  user node['consul']['service_user'] do
    shell '/bin/bash'
    group node['consul']['service_group']
  end
end

config = consul_config node['consul']['service_name'] do |r|
  unless windows?
    owner node['consul']['service_user']
    group node['consul']['service_group']
  end
  node['consul']['config'].each_pair { |k, v| r.send(k, v) }
end

case node['consul']['install_method']
when 'binary'
  consul_installation_binary 'install consul from binary' do
  end
when 'package'
  consul_installation_package 'install consul from package' do
  end
when 'git'
  consul_installation_git 'install consul from git' do
  end
end

consul_service node['consul']['service_name'] do |r|
  unless windows?
    user node['consul']['service_user']
    group node['consul']['service_group']
  end
  version node['consul']['version']
  config_file config.path
  node['consul']['service'].each_pair { |k, v| r.send(k, v) }
  subscribes :restart, "consul_config[#{config.name}]", :delayed
end
