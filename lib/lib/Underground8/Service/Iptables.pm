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


package Underground8::Service::Iptables;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Iptables::SLAVE;
use Underground8::Exception::FalseRange;
use Underground8::Exception::TooBigRange;

use Data::Dumper;

# Constructor
sub new($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Iptables::SLAVE();
    $self->{'_user_change'} = 0;

    $self->{'_notify'} = 0;
    $self->{'_has_changes'} = 0;

    $self->{'_ip_range_whitelist'} = [];
    $self->{'_old_ip_range_whitelist'} = [];

	$self->{'_additional_ssh_port'} = 0;
	$self->{'_snmp_port'} = 0;

    return $self;
}

sub remove_slave ($)
{
    my $self = instance(shift);
    delete $self->{'_slave'};
}

sub add_ip_range_whitelist($@)
{
    my $self = instance(shift);
    my $start = shift;
    my $end = shift;
    my $description = shift;

    my $range = {
        start => $start,
        end => $end,
        description => $description,
	state => 1
    };

    # current entries
    my $ranges = $self->ip_range_whitelist;
    my $new_range = $self->make_range($range);
    my $current_ranges = $self->make_range($ranges);

    # check to see if this entry it is not found in old_ip_range_whitelist
    foreach my $entry ( @{ $self->old_ip_range_whitelist } )
    {
	if( ($range->{'start'} eq $entry->{'start'}) && ($range->{'end'} eq $entry->{'end'}) )
	{
	    $range->{ 'state' } = 0;
# I could not put the new description as the activate button could not be displayed so I cannot save this new description
	    $range->{'description'} = $entry->{'description'};
	    last;
	}
    }

    if( $range->{ 'state' } != 0 )
    {
	foreach my $entry (keys %$new_range)
	{
    	    if ($current_ranges->{$entry})
    	    {
        	throw Underground8::Exception::EntryExists();
    	    }
	}
    }

    push @$ranges, $range;
    $self->ip_range_whitelist($ranges);
    $self->change();
}

sub get_additional_ssh_port ($) {
	my $self = instance(shift);
	return $self->{'_additional_ssh_port'};
}

sub additional_ssh_port ($$) {
	my $self = instance(shift);
	my $port = shift;

	$self->{'_additional_ssh_port'}	= $port;
	$self->change();
}

sub get_snmp_status($){
	my $self = instance(shift);
	return $self->{'_snmp'};
}

sub snmp_status($$){
	my $self = instance(shift);
	my $port = shift;

	$self->{'_snmp'} = $port;
	$self->change();
}

sub ip_range_whitelist ($)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_ip_range_whitelist'} = shift;
    }

    return $self->{'_ip_range_whitelist'};
}

sub old_ip_range_whitelist ($)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_old_ip_range_whitelist'} = shift;
    }
    return $self->{'_old_ip_range_whitelist'};
}

# return the list for network/admin_range_listentries.inc.tt2
sub get_ip_range_whitelist ($)
{
    my $self = instance(shift);
    my @ip_ranges = ();
    my %keys = ();
    foreach my $ip_range ( @{ $self->{'_ip_range_whitelist'} }, @{ $self->{'_old_ip_range_whitelist'} } )
    {
	my $start = $ip_range->{ 'start' };
	my $end = $ip_range->{ 'end' };
	if( defined $keys{ "$start-$end" } ) { next; }
	$keys{ "$start-$end" } = 1;
	push @ip_ranges, $ip_range;
    }
    return \@ip_ranges;
}

sub del_ip_range_whitelist($$)
{
    my $self = instance(shift);
    my $start = shift;

    my $loop = 0;
    my $current_ranges = $self->ip_range_whitelist;
    foreach my $range (@{$current_ranges})
    {
        if($range->{'start'} eq "$start")
        {
	    splice( @{$current_ranges}, $loop, 1 );
            $self->ip_range_whitelist($current_ranges);
            $self->change;
            return 1;
        }
        $loop++;	
    }
    throw Underground8::Exception::EntryNotExists();
}

sub newconf_to_oldconf
{
    my $self = instance(shift);
    my ($i, $limit);
    $self->old_ip_range_whitelist( [] );
    for( $i = 0, $limit = scalar @{ $self->ip_range_whitelist }; $i < $limit; $i++)
    {
	foreach my $key (keys %{ $self->ip_range_whitelist->[ $i ] })
	{
	    if( $key eq "state" ) {
		$self->old_ip_range_whitelist->[ $i ]->{ $key } = 2;
	    } else {
		$self->old_ip_range_whitelist->[ $i ]->{ $key } = $self->ip_range_whitelist->[ $i ]->{ $key };
	    }
	}
    }
}

sub oldconf_to_newconf
{
    my $self = instance(shift);
    my ($i, $limit);
    $self->ip_range_whitelist( [] );
    for ($i = 0, $limit = scalar @{ $self->old_ip_range_whitelist }; $i < $limit; $i++)
    {
	foreach my $key (keys %{ $self->old_ip_range_whitelist->[ $i ] })
	{
	    if( $key eq "state" ) {
		$self->ip_range_whitelist->[ $i ]->{ $key } = 0;
	    } else {
		$self->ip_range_whitelist->[ $i ]->{ $key } = $self->old_ip_range_whitelist->[ $i ]->{ $key };
	    }
	}
    }
}

sub user_change ($$)
{
    my $self = instance(shift);
    if(@_)
    {
        $self->{'_user_change'} = shift;
    }
    return $self->{'_user_change'};
}

sub revoke_settings ($)
{
    my $self = instance(shift);
    $self->oldconf_to_newconf();
    $self->slave->revoke_crontab();
    $self->notify('0');
    $self->user_change('0');
    $self->change;
}

sub confirm_settings ($)
{
    my $self = instance(shift);
    $self->newconf_to_oldconf;	# copy _ip_range_whitelist in _old_ip_range_whitelist
    $self->notify('0');
    $self->user_change('0');
    $self->slave->revoke_crontab();
    $self->change;
}

sub create_crontab ($)
{
    my $self = instance(shift);
    $self->slave->create_crontab();
}

sub notify
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_notify'} = shift;
        $self->change;
    }
    return $self->{'_notify'};
}


sub commit($)
{
    my $self = instance(shift);
    my $if_name = shift;
	print STDERR "LIB -- Committing iptables\n";
    map{ $_->{ 'state' } = 0 }( @{ $self->{'_ip_range_whitelist'} } );
    $self->slave->write_config( $if_name, $self->{'_ip_range_whitelist'}, $self->{'_additional_ssh_port'}, $self->{'_snmp'} );
    if($self->user_change == 1)
    {
        $self->slave->create_crontab();
    }
    $self->slave->service_restart();
    $self->unchange;
}

sub check_range_overlap($$$$$)
{
    my $self = shift;
    my $start1 = ip_dec( shift );
    my $end1 = ip_dec( shift );
    my $start2 = ip_dec( shift );
    my $end2 = ip_dec( shift );

    if( ($end2 < $start1) || ($start2 > $end1) )
    {
	return 0;
    }
    
    return 1;
}

sub check_included($$$)
{
    my $self = shift;
    my $ip = shift;
    my $arr_ref = shift;	# [ {start, end, address, description } ]
    my $ret = 1;		# assume all IP was removed

    for my $item ( @$arr_ref )
    {
	if( defined $item->{'state'})
	{
	    next if $item->{'state'} == 2;	# avoid deleted entries
	}
	$ret = 0;		# so, there are not deleted one

	if( defined $item->{'address'} ) {
	    # single IP
	    if( $self->check_range_overlap( $item->{'address'}, $item->{'address'}, $ip, $ip ) )
	    {
		return 1;
	    }
	} elsif( defined $item->{'start'} && defined $item->{'end'} ) {
	    # IP range
	    if( $self->check_range_overlap( $item->{'start'}, $item->{'end'}, $ip, $ip ) )
	    {
		return 1;
	    }
	}
    }
    
    return $ret;
}


sub make_range($$)
{
    my $self = instance(shift);
    my $range = shift;
    my $new_range = {};
    
    if (ref($range) eq 'HASH' && defined($range->{'start'}) && $range->{'start'} ne '' && defined($range->{'end'}) && $range->{'end'} ne '')
    {   
        if ((ip_dec($range->{'end'}) - ip_dec($range->{'start'})) > 65535)
        {
            throw Underground8::Exception::TooBigRange();
        }
        elsif(ip_dec($range->{'start'}) <= ip_dec($range->{'end'}))
        {
            for(my $i=ip_dec($range->{'start'});$i<ip_dec($range->{'end'})+1;$i++)
            {
                $new_range->{dec_ip($i)} = '1';
            }
        }
        else
        {   
            throw Underground8::Exception::FalseRange();
        }   
    }
    elsif(ref($range) eq 'ARRAY')
    {
        foreach my $entry (@$range)
        {
            if(defined($entry->{'start'}) && $entry->{'start'} ne '' && defined($entry->{'end'}) && $entry->{'end'} ne '')
            {
                if ((ip_dec($entry->{'end'}) - ip_dec($entry->{'start'})) > 65535)
                {
                    throw Underground8::Exception::TooBigRange();
                }
                elsif(ip_dec($entry->{'start'}) <= ip_dec($entry->{'end'}))
                {
                    for(my $i=ip_dec($entry->{'start'});$i<ip_dec($entry->{'end'})+1;$i++)
                    {
                        $new_range->{dec_ip($i)} = '1';
                    }
                }
                else
                {
                    throw Underground8::Exception::FalseRange();
                }
               
            }
            elsif(defined($entry->{'start'}) && $entry->{'start'} ne '' && defined($entry->{'end'}) && $entry->{'end'} eq '')
            {
                $new_range->{$entry->{'start'}} = '1';
            }
        }                    
    }
    return $new_range;        
}                

sub dec_ip
{
    if ($_[0] =~ /^\d+$/)
    {
        return (($_[0] >> 24 & 255) . "." . ($_[0] >> 16 & 255) . "." . ($_[0] >> 8 & 255) . "." . ($_[0] & 255));
    }
    else
    {
        return 0;
    }
}

sub ip_dec
{
    my $ip = $_[0];
    if ($ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/)
    {
        return (($1 << 24) + ($2 << 16) + ($3 << 8) + $4);
    }
    else
    {
        return 0;
    }
}

# return 1 if there must be disabled the revoke and activate buttons
sub check_revoke_apply
{
    my $self = instance(shift);
    foreach my $ip_range( @{ $self->get_ip_range_whitelist() } )
    {
	if( $ip_range->{'state'} )
	{
	    return 0;
	}
    }
    return 1;
}

1;
