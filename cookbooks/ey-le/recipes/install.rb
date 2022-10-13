# Add logentries for package repository
# As logentries still doesn't have a release for Ubuntu 20.04, 
# The package would be built upon releases for Ubuntu 18.04
apt_repository "logentries" do
  uri "http://rep.logentries.com/"
  distribution "bionic"
  components ["main"]
  key "logentries.key"
  action :add
end

package "python-setproctitle"
package "logentries"
package "logentries-daemon"
