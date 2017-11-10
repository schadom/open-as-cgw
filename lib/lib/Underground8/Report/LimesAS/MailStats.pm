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


package Underground8::Report::LimesAS::MailStats;
use base Underground8::Report;

use strict;
use warnings;

use Underground8::Utils;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_chart_data'} = undef;
    $self->{'_start_timestamp'} = 0;
    $self->{'_end_timestamp'} = 0;
    $self->{'_passed_clean'} = 0;
    $self->{'_passed_spam'} = 0;
    $self->{'_blocked_greylisted'} = 0;
    $self->{'_blocked_blacklisted'} = 0;
    $self->{'_blocked_virus'} = 0;
    $self->{'_blocked_banned'} = 0;
    $self->{'_blocked_spam'} = 0;
    $self->{'_current_stats'} = { };
    $self->{'_domains'} = [ ];

    bless $self, $class;
    return $self;
}

sub chart_data
{
    my $self = shift;
    $self->{'_chart_data'} = shift if @_;
    return $self->{'_chart_data'};
}

sub start_timestamp
{
    my $self = shift;
    $self->{'_start_timestamp'} = shift if @_;
    return $self->{'_start_timestamp'};
}

sub end_timestamp
{
    my $self = shift;
    $self->{'_end_timestamp'} = shift if @_;
    return $self->{'_end_timestamp'};
}

sub passed_clean
{
    my $self = shift;
    $self->{'_passed_clean'} = shift if @_;
    return $self->{'_passed_clean'};
}

sub passed_spam
{
    my $self = shift;
    $self->{'_passed_spam'} = shift if @_;
    return $self->{'_passed_spam'};
}

sub blocked_greylisted
{
    my $self = shift;
    $self->{'_blocked_greylisted'} = shift if @_;
    return $self->{'_blocked_greylisted'};
}

sub blocked_blacklisted
{
    my $self = shift;
    $self->{'_blocked_blacklisted'} = shift if @_;
    return $self->{'_blocked_blacklisted'};
}

sub blocked_virus
{
    my $self = shift;
    $self->{'_blocked_virus'} = shift if @_;
    return $self->{'_blocked_virus'};
}

sub blocked_banned
{
    my $self = shift;
    $self->{'_blocked_banned'} = shift if @_;
    return $self->{'_blocked_banned'};
}

sub blocked_spam
{
    my $self = shift;
    $self->{'_blocked_spam'} = shift if @_;
    return $self->{'_blocked_spam'};
}

sub current_stats
{
    my $self = shift;
    $self->{'_current_stats'} = shift if @_;
    return $self->{'_current_stats'};
}

sub domains
{
    my $self = shift;
    $self->{'_domains'} = shift if @_;
    return $self->{'_domains'};
}


1;
