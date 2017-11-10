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


package Underground8::Service::Postfwd;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Postfwd::SLAVE;
use Data::Dumper;
use Net::CIDR::Lite;

#Constructor
sub new ($$) {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{'_slave'} = new Underground8::Service::Postfwd::SLAVE();
	$self->{'_config'} = undef;

    return $self;
}

sub sort_config_by_category($$){
	my $self = instance(shift);
	my $config = shift;

	my (@sorted_blacklist, @sorted_whitelist);

	# Sort blacklist
	if(defined($config->{'blacklist'})) {
		@sorted_blacklist = sort { $a->{'category'} cmp $b->{'category'} } @{ $config->{'blacklist'} };
		$config->{'blacklist'} = \@sorted_blacklist;
	}

	# Sort whitelist
	if(defined($config->{'whitelist'})) {
		@sorted_whitelist = sort { $a->{'category'} cmp $b->{'category'} } @{ $config->{'whitelist'} };
		$config->{'whitelist'} = \@sorted_whitelist;
	}

	return $config;
}

sub load_config($){
	my $self = instance(shift);
	my $config = {};

	# Load XML	
	$config = $self->slave->load_config_xml;

	# Sort 
	$config = sort_config_by_category($self, $config);

	$self->{'_config'} = $config;

	return $config;
}

sub slave($){
	my $self = instance(shift);
	return $self->{'_slave'};
}

sub commit($){
	my $self = instance(shift);

    my $files;
    push @{$files}, $g->{'file_postfwd_cf'};

    my $md5_first = $self->create_md5_sums($files);
	$self->slave->commit($self->{'_config'});
    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {   
        $self->slave->service_restart();
    }

    $self->unchange;

	$self->{'_config'} = $self->load_config;
}


sub add_entry($$$$) {
	my $self = instance(shift);
	my $desc = shift;
	my $entry = shift;
	my $type = shift;

	# Needed for regexed postfwd rules
	my $postfwd_rule = $entry;

	return -1 if $type !~ /^(blacklist|whitelist)$/;

	# Remove ALL suspicious characters (otherwise xml config will be broken)
	$desc =~ s/[^A-Za-z0-9 -]//g;

	# What are we dealing with?
	my $entry_type = $self->determine_entrytype($entry);

	# Return with error code if entry-type is unknown
	return -2 if $entry_type eq "invalid/unknown";

	# If IP range is used, calculate CIDRs; on wildcard usage, s/// asterisks and periods
	if($entry_type eq "ip_range") {
		# Get simplest list of CIDR addresses according to given IP range
		# $postfwd_rule will hold these as list in this case
		my $cidr = Net::CIDR::Lite->new;
		$cidr->add_range( $entry );
		$postfwd_rule = $cidr->list;
	} elsif($entry_type eq "domainname_wildcard") {
		$postfwd_rule =~ s/\./\\./g;
		$postfwd_rule =~ s/\*/.+?/g;
	} elsif($entry_type eq "mail_addr_wildcard") {
		$postfwd_rule =~ s/\./\\./g;
		$postfwd_rule =~ s/\*/.+?/g;
	} elsif($entry_type eq "hostname_wildcard") {
		$postfwd_rule =~ s/\*/.+?/g;
	}

	push @{ $self->{'_config'}->{$type} }, 
		# {  'category' => $category,
		{  'category' => $entry_type,
		   'desc' => $desc, 
		   'entry' => $entry, 
		   'postfwd_rule' => $postfwd_rule,
		   'id' => time() + int(rand(100)) 
	  	};

	return 1;
}


sub del_entry($$){
	my $self = instance(shift);
	my $id = shift;
	my $list_size;

	# Look for ID in blacklist
	if($self->{'_config'}->{'blacklist'}){
		$list_size = scalar @{ $self->{'_config'}->{'blacklist'} };
		for(my $i=0; $i < $list_size; $i++ ) {
			if( $self->{'_config'}->{'blacklist'}->[$i]->{'id'} eq "$id" ) {
				splice @{ $self->{'_config'}->{'blacklist'} }, $i, 1;
				return 1;
			} 
		}
	}

	# Look for ID in whitelist
	if($self->{'_config'}->{'whitelist'}){
		$list_size = scalar @{ $self->{'_config'}->{'whitelist'} };
		for(my $i=0; $i < $list_size; $i++ ) {
			if( $self->{'_config'}->{'whitelist'}->[$i]->{'id'} eq "$id" ) {
				splice @{ $self->{'_config'}->{'whitelist'} }, $i, 1;
				return 1;
			} 
		}
	}

	# Not found
	return 0;
}



### Getter/Setter
# PostFWD service
#sub get_status($){
#    my $self = instance(shift, __PACKAGE__);
#	return $self->{'_config'}->{'status'};
#}
#
#sub enable($) {
#    my $self = instance(shift, __PACKAGE__);
#	$self->{'_config'}->{'status'} = 'enabled';
#}
#
#sub disable($) {
#    my $self = instance(shift, __PACKAGE__);
#	$self->{'_config'}->{'status'} = 'disabled';
#}

# Remote Blacklists
sub get_status_rbl($) {
	my $self = instance(shift);
	return $self->{'_config'}->{'status_rbl'};
}

sub enable_rbl($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_rbl'} = 'enabled';
}

sub disable_rbl($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_rbl'} = 'disabled';
}

sub add_rbl($$;$$){
	my $self = instance(shift);
	my $rbl = shift; 
	my $system_type = shift || 0;
	my $enabled = shift || 0;

	my $type = ($system_type) ? "system" : "user";
	my $rbls = $self->{'_config'}->{'rbls'};

	my $rank = scalar (keys %$rbls) + 1;
	$self->{'_config'}->{'rbls'}->{$rbl} = { rank=>$rank, enabled=>$enabled, type=>$type, }
		unless defined($self->{'_config'}->{'rbls'}->{$rbl});

}

sub del_rbl($$){
	my $self = instance(shift);
	my $rbl = shift;

	my $rbls = $self->{'_config'}->{'rbls'};

	# Decrement ranks
	foreach my $entry (keys %$rbls) {
        if($rbls->{$entry}->{'rank'} > $rbls->{$rbl}->{'rank'}) {
            $rbls->{$entry}->{'rank'} = $rbls->{$rbl}->{'rank'} - 1;
		}
	}

    delete($rbls->{$rbl}) ;
}

sub reorder_rbl($$){
	my $self = instance(shift);
	my $order = shift;
	my $count = 1;

    foreach (@$order) {
        if(defined $self->{'_config'}->{'rbls'}->{$_}) {
            $self->{'_config'}->{'rbls'}->{$_}->{'rank'}= $count;
            $count ++;   
        }
    }
}

sub rbls($){
	my $self = instance(shift);
	return $self->{'_config'}->{'rbls'};
}

sub toggle_entry_rbl($$) {
    my $self = instance(shift);
    my $rbl_name = shift ;

	my $rbls = $self->{'_config'}->{'rbls'};

    $rbls->{$rbl_name}->{'enabled'} = ($rbls->{$rbl_name}->{'enabled'} == 1) ? 0 : 1 ;
    $self->commit($self);
}

sub rbl_threshold($;$){
	my $self = instance(shift);
	my $threshold = shift || undef;

	if(!defined($threshold)) {
		return $self->{'_config'}->{'rbl_threshold'};
	} else {
		$self->{'_config'}->{'rbl_threshold'} = $threshold;
	}
}



# Black/Whitelist manager
sub get_status_bwman {
	my $self = instance(shift);
	return ($self->{'_config'}->{'status_bwman'} or 'disabled');
}

sub enable_bwman($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_bwman'} = 'enabled';
}

sub disable_bwman($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_bwman'} = 'disabled';
}

# Greylisting
sub get_status_greylisting {
	my $self = instance(shift);
	return $self->{'_config'}->{'status_greylisting'};
}

sub enable_greylisting($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_greylisting'} = 'enabled';
}

sub disable_greylisting($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_greylisting'} = 'disabled';
}

# Selective Greylisting
sub get_status_selective_greylisting {
	my $self = instance(shift);
	return $self->{'_config'}->{'status_selective_greylisting'};
}

sub enable_selective_greylisting($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_selective_greylisting'} = 'enabled';
}

sub disable_selective_greylisting($){
	my $self = instance(shift);
	$self->{'_config'}->{'status_selective_greylisting'} = 'disabled';
}



# Check IP address correctness (with optional CIDR suffix)
sub validate_ip($$$$;$){
	my ($n1,$n2,$n3,$n4,$cidr) = @_; 

	return 0 if ($n1 < 1 || $n1 > 254);
	return 0 if ($n2 < 0 || $n2 > 255);
	return 0 if ($n3 < 0 || $n3 > 255);
	return 0 if (($n4 < 1 && !defined($cidr)) || ($n4 < 0 && defined($cidr)) || $n4 > 254);

	return 0 if (defined($cidr) && (($cidr > 32 || $cidr < 1)));

	return 1;
}

sub determine_entrytype($$){
    my $self = instance(shift, __PACKAGE__);
	my $entry = shift;
	my $result = "invalid/unknown";

	# Regexes for detecting entry types (IPs, addrs, etc.)
	my $regex_ip_cidr  = '([1-2]?[0-9]?[0-9])\.([1-2]?[0-9]?[0-9])\.([1-2]?[0-9]?[0-9])\.([1-2]?[0-9]?[0-9])\/([1-3]?[0-9])';
	my $regex_ip_plain = '([1-2]?[0-9]?[0-9])\.([1-2]?[0-9]?[0-9])\.([1-2]?[0-9]?[0-9])\.([1-2]?[0-9]?[0-9])';
	my $regex_ip_range = "$regex_ip_plain ?- ?$regex_ip_plain";
	my $regex_domain   = '[-a-zA-Z0-9.*]*\.[a-zA-Z]{2,7}';
	my $regex_mailaddr = '[-a-zA-Z0-9._*]*@' . $regex_domain;
	my $regex_hostname = '[-a-zA-Z0-9_*]{2,255}';

	# IP/CIDR
	if($entry =~ /^$regex_ip_cidr$/){
		$result = "ip_addr_cidr" if validate_ip($1,$2,$3,$4,$5);
	# IP/plain
	} elsif($entry =~ /^$regex_ip_plain$/){
		$result = "ip_addr_plain" if validate_ip($1,$2,$3,$4);
	# IP Range
	} elsif($entry =~ /^$regex_ip_range$/){
		$result = "ip_range" if (validate_ip($1,$2,$3,$4) && validate_ip($5,$6,$7,$8));
	# Domainname
	} elsif($entry =~ /^$regex_domain$/){
		$result = ($entry =~ /\*/) ? "domainname_wildcard" : "domainname" ;
	# Mail address
	} elsif($entry =~ /^$regex_mailaddr$/){
		$result = ($entry =~ /\*/) ? "mail_addr_wildcard" : "mail_addr" ;
	# Hostname
	} elsif($entry =~ /^$regex_hostname$/) {
		$result = ($entry =~ /\*/) ? "hostname_wildcard" : "hostname" ;
	}

	return $result;
}

1;
