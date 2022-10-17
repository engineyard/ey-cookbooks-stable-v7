apt_sources = node["packages"]["apt_sources"]
apt_sources.each do |apt_source|
  apt_source = JSON.parse(apt_source)
  if apt_source != {}
    Chef::Log.info "PACKAGE REPOSITORY: Adding #{apt_source['name']}"
    apt_repository "apt_source['name']" do
      arch apt_source["arch"] unless apt_source["arch"].nil?
      uri apt_source["uri"] unless apt_source["uri"].nil?
      components [apt_source["components"]] unless apt_source["components"].nil?
      key apt_source["key"] unless apt_source["key"].nil?
      keyserver apt_source["keyserver"] unless apt_source["keyserver"].nil?
      distribution apt_source["distribution"] unless apt_source["distribution"].nil?
      action :add
    end
  end
end

install = node["packages"]["install"]
install.each do |package|
  package = JSON.parse(package)
  if package != {}
    Chef::Log.info "PACKAGES: Installing #{package['name']}-#{package['version']}"
    package package["name"] do
      version package["version"] unless package["version"].nil?
      arch package["arch"] unless package["arch"].nil?
      action :install
    end
  end
end

Chef::Log.info "PACKAGES: Removing xserver-xorg-core, gnome-shell and gdm3* as installed on >= stack-v7.1.0.8"
package %w(ubuntu-gnome-desktop libgdm1 xserver-xorg-core gdm3 gnome-shell xserver-xorg-legacy gnome-session gnome) do
  action :remove
  options "--auto-remove"
end

Chef::Log.info "CHECK PACKAGES: #{node['packages'].keys}"
