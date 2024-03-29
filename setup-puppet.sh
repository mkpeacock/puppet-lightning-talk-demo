#!/usr/bin/env bash

# See: https://github.com/hashicorp/puppet-bootstrap

#
# This bootstraps Puppet on Ubuntu 12.04 LTS.
#
set -e

# Load up the release information
. /etc/lsb-release

REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT
#--------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

echo "Setting the locale..."
sudo /usr/sbin/locale-gen en_GB.UTF-8
sudo /usr/sbin/update-locale LANG=en_GB.UTF-8


# Do the initial apt-get update
echo "Initial apt-get update..."
apt-get update >/dev/null

# Install wget if we have to (some older Ubuntu versions)
echo "Installing wget..."
apt-get install -y wget >/dev/null

# Install the PuppetLabs repo
echo "Configuring PuppetLabs repo..."
repo_deb_path=$(mktemp)
wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
dpkg -i "${repo_deb_path}" >/dev/null
apt-get update >/dev/null

# Install Puppet
echo "Installing Puppet..."
apt-get install -y puppet >/dev/null

echo "Puppet installed!"

# Install RubyGems for the provider
echo "Installing RubyGems..."
apt-get install -y rubygems >/dev/null
gem install --no-ri --no-rdoc rubygems-update
update_rubygems >/dev/null
