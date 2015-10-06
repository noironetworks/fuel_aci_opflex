#
# The spec is generated automatically by Fuel Plugin Builder tool
# https://github.com/stackforge/fuel-plugins
#
# RPM spec file for package aci_opflex-0.2
#
# Copyright (c) 2015, Apache License Version 2.0, Ratnakar
#

Name:           aci_opflex-0.2
Version:        0.2.1
Url:            None
Summary:        ACI Opflex Plugin
License:        Apache License Version 2.0
Source0:        aci_opflex-0.2.fp
Vendor:         Ratnakar
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Group:          Development/Libraries
Release:        1
BuildArch:      noarch

%description
Enable to setup Openstack with ACI and Opflex

%prep
rm -rf %{name}-%{version}
mkdir %{name}-%{version}

tar -vxf %{SOURCE0} -C %{name}-%{version}

%install
cd %{name}-%{version}
mkdir -p %{buildroot}/var/www/nailgun/plugins/
cp -r aci_opflex-0.2 %{buildroot}/var/www/nailgun/plugins/

%clean
rm -rf %{buildroot}

%files
/var/www/nailgun/plugins/aci_opflex-0.2
