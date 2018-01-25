[![Open AS Communication Gateway](https://raw.githubusercontent.com/open-as-team/open-as-cgw/master/gui/lib/root/static/img/logo.png)](https://github.com/open-as-team/open-as-cgw) 
## Open AS Communication Gateway

[![Travis CI](https://travis-ci.org/open-as-team/open-as-cgw.svg?branch=master)](https://travis-ci.org/open-as-team/open-as-cgw)
[![Docs](https://img.shields.io/badge/docs-in%20progress-red.svg)](https://open-as-cgw.readthedocs.io/en/latest/)
[![Launchpad PPA](https://img.shields.io/badge/launchpad-ppa-red.svg)](https://code.launchpad.net/~open-as-team/+recipe/open-as-cgw-daily)

[![Open AS Communication Gateway](https://raw.githubusercontent.com/open-as-team/open-as-cgw/master/gui/lib/root/static/img/openas_dashboard2.png)](https://github.com/open-as-team/open-as-cgw) 

An open, integrated, easy-to-use, GUI-managed SMTP gateway scanning your emails for spam and viruses.

The Open AS Communication Gateway (or short 'AS') aims to be a all-in-one solution of an SMTP gateway: It accepts incoming email, performs various antispam-related processes like blacklisting, virus- and spam-scanning, and relays the mails to pre-defined SMTP servers. It's built upon an Ubuntu Server system, and can be entirely managed via a user-friendly web-frontend.

While we focus on Ubuntu LTS as the base distribution for our appliance releases, technically it should also work on Debian or any of it's derivatives, as long as all dependencies are met. Please apologize that we cannot provide any support for such setups.

:warning: This branch is **UNSTABLE** ! :warning:



Main features
----------------------------------------

 * Appliance based on Ubuntu 16.04.3 LTS (Xenial Xerus)
 * Recipient maps (specified manualy or fetched via LDAP, e.g. from MS AD)
 * White- and black-listing based on e-mail addresses, hostnames, domain-names, network ranges, CIDR ranges, reverse lookups and so on
 * Remote blacklisting (DNSBLs, URI DNSBLs, etc.)
 * Greylisting
 * Spam-scanning and scoring
 * Virus-scanning
 * Attachment scanning
 * Dynamic "Score Matrix", which lets you define what to do with mails from a certain origin, to what extent, at what score, etc.
 * End-User-maintainable email quarantining
 * A very pretty, user-friendly web GUI



Installation
----------------------------------------

You can build and install the package yourself or rely on pre-built packages for Ubuntu which are available via PPA on Launchpad. Be aware of the fact, that this methods may require advanced efforts and only limited support can be provided by us.



Developers
----------------------------------------

**Testing environment**

A local test environment can be set-up easily by using Vagrant.

Make sure you have the latest version of Vagrant and Virtualbox installed, clone the repository and type `vagrant up` within the projects main directory. This will automatically deploy a virtual machine running Ubuntu LTS, build our packages and installs them afterwards.

After the provisioning has been completed, the WebGUI should be reachable at https://localhost:8443 on your local machine. 

You can ssh into your test box with the `vagrant ssh` command.


**GUI development**

The Open AS WebGUI is based on the Perl Catalyst framework, which requires a few perl modules to be installed. The easiest way for developers interested in contributing to the GUI is to use the test environment explained above, which has all dependencies already installed. Within this virtual machine you can manually start the GUI in development mode, which will make all changes to the code visible immediately and provides you with proper debug outputs.

Connect to the previously set-up vagrant box via `vagrant ssh` and perform the following steps: 

	# stop the gui within the vm 
	sudo service openas-backend stop && sudo service nginx stop

	# set-up the development environment
	sudo /bin/bash /vagrant/lib/bin/set_dev_environment.sh

	# start the gui in development mode
	sudo /usr/bin/perl /vagrant/gui/script/limesgui_server.pl

By default the repository on your local machine is synced with the Vagrant VM and is available under /vagrant within the virtual machine.


**Contributing**

Feel free to pick any open issue and provide a proper fix.
We greatly appreciate pull requests via Github. 
