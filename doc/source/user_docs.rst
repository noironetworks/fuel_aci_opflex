*******************************************************************
Guide to the Cisco ACI Opflex Plugin version 7.0.-7.0.7.-1 for Fuel
*******************************************************************

This document provides instructions for installing, configuring and using
Cisco ACI opflex plugin for Fuel.

Key terms, acronyms and abbreviations
=====================================

Cisco ACI/GBP
    The Cisco® Application Policy Infrastructure Controller (APIC) was designed based on open APIs, allowing it to be tightly integrated with cloud orchestration platforms such as OpenStack.
BGP
    Border gateway protocol
GBP
    Group Based Policy
RESTful API
    Representational state transfer
SDN
    Software defined network
MOS
    Mirantis OpenStack

Cisco ACI Opflex
===================

Cisco ACI/GBP plugin for Fuel provides the functionality to add Cisco ACI/GBP for Mirantis OpenStack as networking backend option using Fuel Web UI in a user-friendly manner.


License
-------

===================================   ==================
Component                              License type
===================================   ==================
Cisco ACI/GBP                          Commercial
Cisco ACI opflex plugin                Apache 2.0
===================================   ==================


Requirements
------------

===================================   ==================
Requirement                           Version/Comment
===================================   ==================
Fuel                                  7.0
Cisco ACI                             1.1(4e) or later
===================================   ==================

Limitations
-----------

Know limitation of plugin:
   #. To validate deployed OpenStack environment we are able to run health checks. During execution check called 'Check pacemaker status' we will see error: 'Resource clone_p_neutron-l3-agent allowed to start on the nodes [], but it is not started on any node' its expected because during deploy plugin remove those resource from pacemaker.
   #. To run most test cases in health checks tab we need to manually create networks called ne04, net04_ext (external), and router router04 with gateway in net04_ext and interface in net04. Plugin will remove those networks and router during deploy because after deploy (before plugin start working) those networks are created with provider:network_type 'vlan' and its need to be 'opflex'.
   #. We are able to add or remove controllers after deploy, to make this operation functional we cannot have during redeploy networks called net04 or net04_ext because during those operation default fuel try to change type for network from 'opflex' to 'vlan' and those operation cannot be done.
   #. Updating core repos will trigger all puppet manifest run by plugin so during those operation we can't have networks called ne04/net04_ext and we need to remember that this operation could restart all services starter by plugin like agent_ovs.

Installation Guide
==================


Cisco ACI Opflex installation
----------------------------------------


#. Download Cisco ACI/GBP plugin from the Fuel Plugins Catalog.
#. Copy the rpm downloaded at previous step to the Fuel Master node and install the plugin:

scp aci_opflex-7.0-7.0.7-1.noarch.rpm  <Fuel Master node ip>:/tmp/

#. Log into the Fuel Master node and install the plugin:

ssh <the Fuel Master node ip>
fuel plugins --install /tmp/aci_opflex-7.0-7.0.7-1.noarch.rpm

You should get the following output:
Plugin <plugin-name-version>.rpm was successfully installed


#. Copy  installed package (obtained from Cisco by subscription, see Prerequisites above) to the Fuel Master node and run the installation script to unpack the vendor package and populate plugin repository:

scp \*.deb <Fuel Master node ip>:/var/www/nailgun/plugins/aci_opflex-7.0/repositories/ubuntu/

#. Remember to update Packages.gz after update packages:

dpkg-scanpackages -m . /dev/null | gzip -9c > Packages.gz

Cisco ACI Opflex Configuration
----------------------------------------
#. Create a new OpenStack environment with Fuel UI wizard:

   .. image:: pics/1.png

#. Please select KVM or QEMU hypervisor type for your environment

   .. image:: pics/2.png

#. Please select Neutron network topology

   .. image:: pics/3.png

#. Add nodes and assign them the following roles:

   #. At least 1 Controller
   #. At least 1 Compute

   .. image:: pics/4.png

#. Open Settings tab of the Fuel Web UI and scroll the page down. Select the plugin checkbox:

   .. image:: pics/5.png
   .. image:: pics/6.png

#. Fill the plugin configuration fields with correct values:

   #. Select the APIC Driver mode ML2 or GBP

      .. Warning::
         GBP mode is beta (not tested)

   #. SET APIC Host, Username and password (if these are incorrect, the deploy will fail)
   #. Set encapsulation mode, Infra vlan, Gateway and context name.
   #. This field is used to pass additional configuration parameters to the plugin, via key/value pairs.
   #. Static config - This only recommended for use of advanced features of the system, such as statically configured server connectivity with the fabric.
   #. Use pre-existing VPC links - If selected, OpenStack expects the user to have preconfigured VPC links in the APIC. If not selected, then OpenStack will create the VPC links for the user.
   #. APIC external network - This is the name of the external network used in the ACI fabric. This name must match the name of the external network created by the user in OpenStack.
   #. Use pre-existing external network - If selected, the APIC has been preconfigured with the external network used for the OpenStack external network. This option should not be selected if the “Configure external network” option has been set.
   #. Configure external network - If enabled, the APIC ML2 Mechanism Driver configures an the external network in APIC whenever the user creates an external network in OpenStack. This requires the user to provide the parameters for the external network, and should not be selected if the “Use pre-existing external network” option has been selected. These parameters can be provided via key/value pairs in the   “Additional config” field. The format of this configuration is:

      | switch = <switch_id_from_the_apic>
      | port = <switchport_the_external_router_is_connected_to>
      | encap = <encapsulation>
      | cidr_exposed = <cidr_exposed_to_the_external_router>
      | gateway_ip = <ip_of_the_external_gateway>
      |
      | An example follows:
      | switch=203
      | port=1/34
      | encap=vlan-100
      | cidr_exposed=10.10.40.2/16
      | gateway_ip=10.10.40.1


   #. Additional config - This field is used to pass additional configuration file parameters used by the plugin, via key/value pairs. This only recommended for use of advanced features of the system.
   #. OpenStack system ID - This is the name used as the ACI Tenant for OpenStack. The Endpoint Groups, Bridge Domains, Networks, and related objects all appear under this tenant in the ACI GUI.
   #. External EPG name - This field is used as the name of the Network created under the External Routed Network in the APIC to provide the L3 Out policy, allowing traffic to enter and exit the fabric.
   #. Enable Optimized DHCP - This field is used to define where dhcp server should be running.
   #. Enable Optimized Metadata - This field is used to define where neutron metadata server should be running.

#.  Configure the rest of network settings. See details at Mirantis OpenStack User Guide.
      The rest network configuration is up to you. See Mirantis OpenStack User Guide for instructions to configure other networking options.

#. And finally, click Deploy changes to deploy the environment.

Verification
============
Verification that plugin was installed successful:
  #. Create new network and make sure that provider:network_type is "opflex"
  #. Spawn new instance and check if on compute where vm was spawned .ep file was created in /var/lib/opflex-agent-ovs/endpoints directory with with name of mac address of instance
  #. Make sure that on all nodes agent_ovs service are running
  #. Check neutron logs to make sure there is no logs with error severity

Appendix
========

Links to external resources or documentation:
   #. `ACI with OpenStack OpFlex Deployment Guide for Ubuntu docs <http://www.cisco.com/c/en/us/td/docs/switches/datacenter/aci/apic/sw/1-x/openstack/b_ACI_with_OpenStack_OpFlex_Deployment_Guide_for_Ubuntu.pdf>`_.
   #. `Cisco api ml2 driver docs <https://wiki.openstack.org/wiki/Neutron/Cisco-APIC-ML2-driver/>`_.
   #. `Cisco OpFlex Architectural Overview <http://www.cisco.com/c/en/us/td/docs/switches/datacenter/aci/apic/sw/1-x/openstack/b_ACI_with_OpenStack_OpFlex_Architectural_Overview.pdf>`_.

