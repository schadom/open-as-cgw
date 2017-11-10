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


package Underground8::Configuration::LimesAS::Notification;
use base Underground8::Configuration;

use strict;
use warnings;

#use Clone::Any qw(clone);
use Clone qw(clone);

use Underground8::Utils;
use Underground8::Notification::Email;
use XML::Smart;
use Data::Dumper;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $appliance = shift;

    my $self = $class->SUPER::new("notification",$appliance);
    
    $self->{'_email'} = new Underground8::Notification::Email();
    return $self;
}

#### Accessors ####
# local only

# Email

sub email ($@)
{
    my $self = instance(shift);
    $self->{'_email'} = shift if @_;
    return $self->{'_email'};
}

sub email_accounts ($)
{
    my $self = instance(shift);
    return $self->email->accounts();
}
sub email_accounts_name ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_name(shift);
}
sub email_accounts_address ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_address(shift);
}
sub email_accounts_type ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_type(shift);
}
sub email_accounts_smtp_login ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_smtp_login(shift);
}
sub email_accounts_smtp_password ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_smtp_password(shift);
}
sub email_accounts_smtp_server ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_smtp_server(shift);
}
sub email_accounts_smtp_use_ssl ($$)
{
    my $self = instance(shift);
    return $self->email->accounts_smtp_use_ssl(shift);
}



sub email_account_index($$)
{
    my $self = instance(shift);
    return $self->email->account_index(shift);
}
sub email_account_delete($$)
{
    my $self = instance(shift);
    return $self->email->account_delete(shift);
}
sub email_set_account ($$$$$$$)
{
    my $self = instance(shift);
    return $self->email->set_account(@_);        
}
#### CRUD Methods ####

sub commit($)
{
    my $self = instance(shift);
    $self->email->commit() if $self->email->is_changed;
    $self->save_config();
}


### Administration Ranges ###


#### Load / Save Configuration ####

sub load_config ($)
{
    my $self = instance(shift);
    $self->load_config_xml_smart();
}

sub load_config_xml_smart ($)
{
    my $self = instance(shift);
    my $infile = $self->config_filename();
    my ($i, $limit);
    my $XML = new XML::Smart($infile,'XML::Smart::Parser');
    $XML = $XML->cut_root;
    
    ## Import of User Data for Mail Notifications
    my $email = $XML->{'_notification'}->{'_email'}->tree_pointer_ok;
    $limit = (defined $XML->{'_email'} && defined $XML->{'_email'}->{'_accounts'} && defined $XML->{'_email'}->{'_accounts'}->[0] && defined $XML->{'_email'}->{'_accounts'}->[0]->{'_address'} && $XML->{'_email'}->{'_accounts'}->[0]->{'_address'} ne '')?scalar @{$XML->{'_email'}->{'_accounts'}}:0;
    for ($i = 0; $i < $limit; $i++)
    {
        push @{$email->{'_accounts'}}, {
            _name => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_name'}),
            _address => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_address'}),
            _type => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_type'}),
            _smtp_server => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_smtp_server'}),
            _smtp_login => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_smtp_login'}),
            _smtp_password => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_smtp_password'}),
            _smtp_use_ssl => sprintf('%s', $XML->{'_email'}->{'_accounts'}->[$i]->{'_smtp_use_ssl'})
        };
    }
    $self->email->import_params($email);
}

sub load_config_xml ($)
{
    my $self = instance(shift);
    my $infile = $self->config_filename();
    my $unblessed_self = $self->xml->XMLin($infile);

    # create the email accounts and remove them from the original hash
    my $unblessed_email = $unblessed_self->{'_email'};
    delete $unblessed_self->{'_email'};
    $self->email->import_params($unblessed_email);

}

sub save_config ($)
{
    my $self = instance(shift);
    $self->save_config_xml_smart();
}

sub save_config_xml_smart ($)
{
    my $self = instance(shift);

    my $outfile = $self->config_filename();

    my $XML = new XML::Smart('','XML::Smart::Parser');
    $XML->cut_root;

    # unbless the email accounts
    $XML->{'root'}->{'_email'} = $self->email->export_params;

    $XML->save($outfile);
}

sub save_config_xml ($)
{
    my $self = instance(shift);
    
    my $outfile = $self->config_filename();
 
    use Data::Dumper;

    my $unblessed_self;
    foreach my $key (keys %$self)
    {
        $unblessed_self->{$key} = $self->{$key};
    }
    
    # remove the xml parser
    delete $unblessed_self->{'_xml'};
    # remove the appliance backlink
    delete $unblessed_self->{'_appliance'};
    
    # unbless the network interface
    $unblessed_self->{'_email'} = $self->email->export_params;
    
    print Dumper $unblessed_self;
   
    # export to xml    
    $self->xml->XMLout($unblessed_self, OutputFile => $outfile);
}

1;
