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


package Underground8::ReportFactory::LimesAS::LDAP;
use base Underground8::ReportFactory;

use strict;
use warnings;

use Underground8::Utils;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Exception::LDAPTestFailed;
use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;

use Net::LDAP;
use Net::LDAP::Control::Paged;
use Net::LDAP::Constant ( "LDAP_CONTROL_PAGED" );

use Regexp::Common qw[Email::Address];
use Email::Address;




our $DEBUG = 0;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();

    bless $self, $class;
    return $self;
}


sub test_query ($$$$$$$)
{
    my $self = shift;

    my $return;

    my $ldap_server = shift;
    my $ldap_user = shift;
    my $ldap_pass = shift;
    my $ldap_base = shift;
    my $ldap_filter =  shift;
    my $ldap_properties = shift;
    my $search_addr = shift;
    
    $ldap_filter =~ s/\*/$search_addr/g if (defined $search_addr);

    my @ldap_property = split(/,/ , $ldap_properties);
    
    if ( !(ref($ldap_server) eq 'ARRAY'))
    {
        my $tmp = $ldap_server;
        $ldap_server = [];
        $ldap_server->[0] = $tmp;
    }

    # we set this 1 if any of the servers worked, or we throw an exception
    my $success = 0;
    foreach my $server ( @{$ldap_server} )
    {
        $return->{$server}{'test_result'} = 0;
        $return->{$server}{'connection'} = 0;
        $return->{$server}{'addr_found'} = 0;
        $return->{$server}{'mesg'}{'query'} = 0;
        $return->{$server}{'mesg'}{'bind_code'} = 0;
        my $ldap = Net::LDAP->new($server);
        if (defined $ldap)
        {
            $return->{$server}{'connection'} = 1;
        } else {
            $return->{$server}{'connection'} = 0;
        }
        
        # we only bind if we can connect ...
        if ( $return->{$server}{'connection'} )
        {
            my $mesg =  $ldap->bind ( dn => $ldap_user,
                                   password => $ldap_pass);
            $return->{$server}{'mesg'}{'bind_code'} = $mesg->code();
            
            # we now have a return code ... if it is not 0, something was wrong
            if ( $return->{$server}{'mesg'}{'code'} )
            {
                $return->{$server}{'mesg'}{'error_name'} = $mesg->error_name();
                $return->{$server}{'mesg'}{'error_text'} = $mesg->error_text();
            } else {
                # we are defining page here ... for compat with MS-AD :-p
                my $page = Net::LDAP::Control::Paged->new( size => 990 );
                my @args = ( base     => $ldap_base,
                          filter   => $ldap_filter,
                          control  => [ $page ],
                );

                # Now we're getting to it ... searching started
                #
                my $cookie;
                
                # i always liked while true! (needed because of paging)
                $return->{$server}{'addr_found'} = 0;
                while(1) {
                    $mesg = $ldap->search( @args );

                    foreach my $entry ( $mesg->entries )
                    {
                        # sorry ... another foreach, LDAP entries are multivalued
                        foreach my $ldap_property (@ldap_property)
                        {
                            foreach my $mail ( $entry->get_value( "$ldap_property" ) )
                            {
                                #print Dumper $mail;
                                my (@found) = ($mail =~ /($RE{Email}{Address})/g);
    
                                my (@addrs) = map $_->address,
                                                Email::Address->parse("@found");
                                #print Dumper @addrs;
                                foreach my $tmp_addr (@addrs)
                                {
                                    $return->{$server}{'addr_found'} = 1 if ( $tmp_addr eq $search_addr );
                                }
                            }
                        }
                    }
                    # Only continue on LDAP_SUCCESS
                    $mesg->code and last;
                    
                    # Get cookie from paged control 
                    my($resp)  = $mesg->control( LDAP_CONTROL_PAGED ) or last;
                    $cookie    = $resp->cookie or last;
                    
                    # Set cookie in paged control
                    $page->cookie($cookie);
                }
                
                if ($cookie)
                {
                    # We had an abnormal exit, so let the server know we do not want any more
                    $page->cookie($cookie);
                    $page->size(0);
                    $ldap->search( @args );
                    $return->{$server}{'mesg'}{'query'} = 0;
                } else {
                    $return->{$server}{'mesg'}{'query'} = 1;
                    
                    # querying worked ... but testing is only successful if we found the testaddress
                    if ($return->{$server}{'addr_found'})
                    {
                        $return->{$server}{'test_result'} = 1;
                    }
                    
                }
            }
        }
    }
    
    # We throw an Exception if any of the servers did not respond
    foreach my $server (keys %{$return} )
    {
        if (! $return->{$server}{'test_result'} )
        {
            throw Underground8::Exception::LDAPTestFailed($return);
        }
    }    
}

            
sub get_addresses ($$$$$$$)
{
    my $self = shift;

    my $return;

    my $ldap_server = shift;
    my $ldap_user = shift;
    my $ldap_pass = shift;
    my $ldap_base = shift;
    my $ldap_filter =  shift;
    my $ldap_properties = shift;
    
    if ( !(ref($ldap_server) eq 'ARRAY'))
    {
        my $tmp = $ldap_server;
        $ldap_server = [];
        $ldap_server->[0] = $tmp;
    }
    
    #print "\n\nWe are in LDAP.pm from ReportFactory\n";
    #print "ldap_server: $ldap_server\n";
    #print "ldap_user: $ldap_user\n";
    #print "ldap_pass: **********\n";
    #print "ldap_base: $ldap_base\n";
    #print "ldap_filter: $ldap_filter\n";
    #print "ldap_property: $ldap_property\n";

    my @ldap_property = split(/,/ , $ldap_properties);
    
    foreach my $server ( @{$ldap_server} )
    {


        my $ldap = Net::LDAP->new($server);
        if (defined $ldap)
        {
            $return->{$server}{'connection'} = 1;
        } else {
            $return->{$server}{'connection'} = 0;
        }
        
        # we only bind if we can connect ...
        if ( $return->{$server}{'connection'} )
        {
            my $mesg =  $ldap->bind ( dn => $ldap_user,
                                   password => $ldap_pass);
            $return->{$server}{'mesg'}{'bind_code'} = $mesg->code();
            
            # we now have a return code ... if it is not 0, something was wrong
            if ( $return->{$server}{'mesg'}{'code'} )
            {
                $return->{$server}{'mesg'}{'error_name'} = $mesg->error_name();
                $return->{$server}{'mesg'}{'error_text'} = $mesg->error_text();
            } else {
                # we are defining page here ... for compat with MS-AD :-p
                my $page = Net::LDAP::Control::Paged->new( size => 990 );
                my @args = ( base     => $ldap_base,
                          filter   => $ldap_filter,
                          control  => [ $page ],
                );

                # Now we're getting to it ... searching started
                #
                my $cookie;
                
                # i always liked while true! (needed because of paging)
                while(1) {
                    $mesg = $ldap->search( @args );

                    foreach my $entry ( $mesg->entries )
                    {
                        # sorry ... another foreach, LDAP entries are multivalued
                        foreach my $ldap_property (@ldap_property)
                        {
                            #print STDERR "Checking ldap_property $ldap_property\n";
                            foreach my $mail ( $entry->get_value( "$ldap_property" ) )
                            {
                                #print Dumper $mail;
                                my (@found) = ($mail =~ /($RE{Email}{Address})/g);
    
                                my (@addrs) = map $_->address,
                                                Email::Address->parse("@found");
                                #print Dumper @addrs;
                                @addrs = map { lc } @addrs;

								# Fix for Exchange 5.5
								@addrs = map { s/^smtp\$//g; $_; } @addrs;

                                #print STDERR "Found @addrs addresses\n";
                                push @{$return->{'addr_list'}}, @addrs;
                            }
                        }
                    }
                    # Only continue on LDAP_SUCCESS
                    $mesg->code and last;
                    
                    # Get cookie from paged control 
                    my($resp)  = $mesg->control( LDAP_CONTROL_PAGED ) or last;
                    $cookie    = $resp->cookie or last;
                    
                    # Set cookie in paged control
                    $page->cookie($cookie);
                }
                
                if ($cookie)
                {
                    # We had an abnormal exit, so let the server know we do not want any more
                    $page->cookie($cookie);
                    $page->size(0);
                    $ldap->search( @args );
                    $return->{$server}{'mesg'}{'query'} = 0;
                } else {
                    $return->{$server}{'mesg'}{'query'} = 1;
                }
            }
        }
    }
    return $return;
}

            

1;
