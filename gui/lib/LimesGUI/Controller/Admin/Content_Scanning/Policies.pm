# This file is part of the Open AS Communication Gateway.
#
# The Open AS Communication Gateway is free software: you can redistribute it
# and/or modify it under theterms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# The Open AS Communication Gateway is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
# General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with the Open AS Communication Gateway. If not, see http://www.gnu.org/licenses/.


package LimesGUI::Controller::Admin::Content_Scanning::Policies;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	update_stash($self, $c);
	$c->stash->{template} = 'admin/content_scanning/policies.tt2';
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my %policy;

	my @types = ("bypass_spam", "bypass_virus", "bypass_att");
	$policy{'extern'}{$_}     = $appliance->antispam->policy_external($_)  foreach (@types);
	$policy{'relayhosts'}{$_} = $appliance->antispam->policy_internal($_)  foreach (@types);
	$policy{'whitelist'}{$_}  = $appliance->antispam->policy_whitelist($_) foreach (@types);
	$policy{'smtpauth'}{$_}   = $appliance->antispam->policy_smtpauth($_)  foreach (@types);

	$c->stash->{'policy'} = \%policy;
}


sub toggle : Local {
	my ( $self, $c, $origin, $type ) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		if($origin eq "extern"){
			$appliance->antispam->set_policy_external($type, 1 - $appliance->antispam->policy_external($type) );
		} elsif($origin eq "relayhosts"){
			$appliance->antispam->set_policy_internal($type, 1 - $appliance->antispam->policy_internal($type));
		} elsif($origin eq "whitelist"){
			$appliance->antispam->set_policy_whitelist($type, 1 - $appliance->antispam->policy_whitelist($type));
		} elsif($origin eq "smtpauth"){
			$appliance->antispam->set_policy_smtpauth($type, 1 - $appliance->antispam->policy_smtpauth($type));
		}
		
		$appliance->antispam->commit;
		aslog "info", "Toggled policy state for $origin (type = $type)";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling policy state for $origin (type = $type)";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{template} = 'redirect.inc.tt2';
	};

	update_stash($self, $c);
	$c->stash->{template} = 'admin/content_scanning/policies/scanning_policy.inc.tt2';
}

1;
