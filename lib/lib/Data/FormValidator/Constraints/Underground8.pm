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


package Data::FormValidator::Constraints::Underground8;

use strict;
use warnings;
use Error;
use Regexp::Common qw/net/;
use Switch;

BEGIN
{
    use Exporter;
    @Data::FormValidator::Constraints::Underground8::ISA        = qw(Exporter);
    @Data::FormValidator::Constraints::Underground8::EXPORT     = qw(ip_address_or_hostname special_char_count validate_domain validate_smtp_srv valid_blocked_group valid_contenttype validate_score valid_username valid_gtube valid_gtube_score);
    @Data::FormValidator::Constraints::Underground8::EXPORT_OK  = qw();
}


# constraint for checking a form parameter
# returns 1 if the parameter is a valid hostname/domainname or IPv4 ip_address
# 
sub ip_address_or_hostname {
    my ($attrs) = @_;
    return sub {
        my $dfv = shift;

        # Name it to refer to in the 'msgs' system.
        $dfv->name_this('ip_address_or_hostname');

        my $val = $dfv->get_current_constraint_value();

        return ( ($val =~ /^$RE{net}{IPv4}$/) or ($val =~ /^(?! )$RE{net}{domain}\s*$/) );
    }
}

sub valid_username {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return  $val =~ /^([a-zA-Z0-9_\-\.]+)$/;
    }

}

# constraint checking count of special characters in a string
sub special_char_count {
    my ($min_chars,$max_chars,$attrs) = @_;
    return sub {
	my $dfv = shift;

	$dfv->name_this('special_char_count');

	my $val = $dfv->get_current_constraint_value();

	my @val=split //,$val;
	my $count=0;
	for(my $i=0;$i<$#val;$i++){
		$count++ if $val[$i]=~/\W/;
	}
	return (($count >= $min_chars) && ($count <= $max_chars));
    }
}


sub validate_domain
{
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return  $val =~ /^[a-z0-9][a-z0-9\-]*(\.[a-z0-9\-]+)*\.[a-z0-9\-]*[a-z0-9]$/i;
    }

}

sub valid_gtube {
    my ($min_chars,$max_chars,$attrs) = @_;
    return sub {
    my $dfv = shift;
    my $val = $dfv->get_current_constraint_value();
    my $check = $dfv->get_current_constraint_value();
    my @val=split //,$val;
    my $count=0;
    for(my $i=0;$i<$#val;$i++){
        $count++ if $val[$i]=~/\W/;
    }
    return (($count >= $min_chars) && ($count <= $max_chars) && ($check=~ /^\S+$/) && ($check =~ /^.{32,}$/) );
    }
}

sub valid_gtube_score 
{
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return  $val =~ /^\d+(\.\d+)?$/;
    }
}


sub validate_smtp_srv
{
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();

        return  $val =~ /^smtp[0-9]{14}$/;
    }

}
sub validate_score
{
     my ($policy_scores,$policy,$score,$quarantine_enabled) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        my $cond = $val =~/^(?:\.\d|\d+(?:\.\d|))$/o;
        if($val== 0 || $val==0.0) {return 1;} # 0 is seen as a special value that means a disabled score !!!
        elsif (not $cond){ warn "not a number !!!!";return 0;} #not a number !!!!
        
        else   # Test wheter scores are consistent 
        {   
           switch ($score) {
                case "tag"      {
                                    $cond= 1;     
                                }
    
                case "block"    { 
                                    $cond= ($val >= $policy_scores->{$policy}->{'tag'})? 1 : 0;
                                }
                case "cutoff"   {
                                    $cond= ($val >= $policy_scores->{$policy}->{'block'})? 1 : 0;
                                }
                case "dsn"      {
                                    $cond=  ($val >= $policy_scores->{$policy}->{'block'}) ? 1 : 0;
                                }
                case /.*/       {warn "nothing much!!";}
            }
           return $cond;
        }     
    }
}


sub valid_blocked_group {
    return sub {
        my $dfv = shift;

        # Name it to refer to in the 'msgs' system.
        $dfv->name_this('valid_blocked_group');

	my $hash_vals = $dfv->get_input_data();
        my $vals = $hash_vals->{'blocked_group'};

	if( ref($vals) eq "ARRAY" ) {
	    foreach my $val (@$vals)
	    {
	        $val =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	        $val =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
		return 0 if $val !~ /^[a-z0-9._: \-]+ \([a-z0-9,.]+\)$/i;
	    }

    	    return 1;
	} else {
	    return $vals =~ /^[a-z0-9._: \-]+ \([a-z0-9,.]+\)$/i;
	}
    }
}

sub valid_contenttype {
    return sub {
        my $dfv = shift;

        # Name it to refer to in the 'msgs' system.
        $dfv->name_this('valid_contenttype');

	my $hash_vals = $dfv->get_input_data();
        my $vals = $hash_vals->{'blocked_contenttype'};

	if( ref($vals) eq "ARRAY" ) {
	    foreach my $val (@$vals)
	    {
	        $val =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	        $val =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
		return 0 if $val !~ /^\[[a-z0-9.+\-]+\/[a-z0-9.+\-]+\]$/i;
	    }

    	    return 1;
	} else {
	    return $vals =~ /^\[[a-z0-9.+\-]+\/[a-z0-9.+\-]+\]$/i;
	}
    }
}


1;
