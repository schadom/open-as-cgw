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


package Underground8::Notification::Email;
use base Underground8::Notification;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Notification::Email::SLAVE;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Notification::Email::SLAVE();
    $self->{'_has_changes'} = 0;
    return $self;
}

sub accounts ($)
{
    my $self = instance(shift);
    if (defined $self->{'_accounts'} && ref($self->{'_accounts'}) eq 'ARRAY')
    {
        return $self->{'_accounts'};
    }
    else
    {
        return [];
    }
}
sub accounts_name ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_name'})
    {
        return $self->{'_accounts'}->[$i]->{'_name'};
    }
    else { return ''};
}
sub accounts_address ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_address'})
    {
        return $self->{'_accounts'}->[$i]->{'_address'};
    }
    else { return ''};
}
sub accounts_type ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_type'})
    {
        return $self->{'_accounts'}->[$i]->{'_type'};
    }
    else { return ''};
}
sub accounts_smtp_login ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_smtp_login'})
    {
        return $self->{'_accounts'}->[$i]->{'_smtp_login'};
    }
    else { return ''};
}
sub accounts_smtp_password ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_smtp_password'})
    {
        return $self->{'_accounts'}->[$i]->{'_smtp_password'};
    }
    else {
         return '';};
}
sub accounts_smtp_server ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_smtp_server'})
    {
        return $self->{'_accounts'}->[$i]->{'_smtp_server'};
    }
    else { return ''};
}
sub accounts_smtp_use_ssl ($$)
{
    my $self = instance(shift);
    my $i = shift;
    if (defined $self->{'_accounts'} 
    && defined $self->{'_accounts'}->[$i] 
    && defined $self->{'_accounts'}->[$i]->{'_smtp_use_ssl'})
    {
        return $self->{'_accounts'}->[$i]->{'_smtp_use_ssl'};
    }
    else { return ''};
}

sub account_index($$)
{
    my $self = instance(shift),
    my $address = shift;
    my $index;
    if (defined $self->{'_accounts'} && ref($self->{'_accounts'}) eq 'ARRAY')
    {
        $index = (grep { defined $self->accounts->[$_]->{'_address'} && $self->accounts->[$_]->{'_address'} eq $address} 0..((scalar @{$self->accounts}) -1))[0];
    }
    if (defined $index && length $index && $index >= 0)
    {
        return $index;
    }
    else
    {
        return undef;
    }
}

sub account_delete($$)
{
    my $self = instance(shift),
    my $index = shift;
    if (defined $self->{'_accounts'} && ref($self->{'_accounts'}) eq 'ARRAY' && defined $index && $index =~ /^\d+$/)
    {
        if (defined $self->accounts->[$index])
        {
            splice @{$self->accounts}, $index, 1;
            return 1;
        }
    }
}


sub set_account ($$$$$$$)
{
    my $self = instance(shift);
    my $address = shift;
    my $name = shift;
    my $type = shift;
    my $smtp_server = shift;
    my $smtp_login = shift;
    my $smtp_password = shift;
    my $smtp_use_ssl = shift;
    my $index;
    
    # If we got an invalid email address, configuring an account doesn't make any sense at all
    return undef unless ( defined $address 
        && length $address 
        && $address =~ /^[-!#$%&'*+\/0-9=?A-Z^_a-z{|}~](\.?[-!#$%&'*+\/0-9=?A-Z^_a-z{|}~])*@[a-zA-Z](-?[a-zA-Z0-9])*(\.[a-zA-Z](-?[a-zA-Z0-9])*)+$/);

    $name = (defined $name && length $name)?$name:'';
    $smtp_server = (defined $smtp_server && length $smtp_server && ($type eq 'smtpauth' || $type eq 'smtp'))?$smtp_server:'';
    $smtp_login = (defined $smtp_login && length $smtp_login && ($type eq 'smtpauth' || $type eq 'smtp'))?$smtp_login:'';
    $smtp_password = (defined $smtp_password && length $smtp_password && ($type eq 'smtpauth' || $type eq 'smtp'))?$smtp_password:'';
    $smtp_use_ssl = (defined $smtp_use_ssl && ($type eq 'smtpauth' || $type eq 'smtp') && ($smtp_use_ssl eq '0' || $smtp_use_ssl eq '1'))?$smtp_use_ssl:0;
    if (defined $self->{'_accounts'} && ref($self->{'_accounts'}) eq 'ARRAY')
    {
        $index = (grep { defined $self->accounts->[$_]->{'_address'} && $self->accounts->[$_]->{'_address'} eq $address} 0..((scalar @{$self->accounts}) -1))[0];
    }
    else
    {
        @{$self->{'_accounts'}} = ();
    }
    if (defined $index && $index >= 0)
    {
        $self->accounts->[$index]->{'_name'} = $name;
        $self->accounts->[$index]->{'_address'} = $address;
        $self->accounts->[$index]->{'_type'} = $type;
        $self->accounts->[$index]->{'_smtp_server'} = $smtp_server;
        $self->accounts->[$index]->{'_smtp_login'} = $smtp_login;
        $self->accounts->[$index]->{'_smtp_password'} = $smtp_password;
        $self->accounts->[$index]->{'_smtp_use_ssl'} = $smtp_use_ssl;
        $self->change;
    }
    else
    {
        push @{$self->accounts}, {
            _name => $name,
            _address => $address,
            _type => $type,
            _smtp_server => $smtp_server,
            _smtp_login => $smtp_login,
            _smtp_password => $smtp_password,
            _smtp_use_ssl => $smtp_use_ssl
        };
        $index = (scalar @{$self->accounts}) -1;
        $self->change;
    }
    return $index;
}

sub import_params ($$)
{
    my $self = instance(shift);
    my $import = shift;
    if (ref($import) eq 'HASH')
    {
        foreach my $key (keys %$import)
        {
            $self->{$key} = $import->{$key};
        }
    }
    else
    {
        warn 'No hash supplied!';
    }
}

sub export_params ($)
{
    my $self = instance(shift);
    my $export = undef;
    foreach my $key (keys %$self)
    {
        if (length $key)
        {
            $export->{$key} = $self->{$key};
        }
    }
    delete $export->{'_slave'};
    delete $export->{'_has_changes'};
    return $export;
}
sub commit ($)
{
    my $self = instance(shift);
    $self->unchange;
}


1;