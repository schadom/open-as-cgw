#!/usr/bin/perl -w
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


use strict;

#
# This file implement a SASL proxy for Postfix
# Copyright@ 2007 Underground-8
#

use IO::Socket::INET;
use IO::Socket::SSL qw(debug0);		# debug0 for no debug messages, debug3 for debug messages
use Net::SSLeay;
use Digest::HMAC_MD5 qw(hmac_md5_hex);
use MIME::Base64 qw(encode_base64 decode_base64);
use DBI;

#
# Example of config file:
#
# debug 1
# server mail.underground8.com
# port 25
# timeout 5
# send_fq_username 1
# 
# use_ehlo 1
# use_tls 1
# helo_as "LimesAS"
# 
# auth_with_cram_md5 0
# auth_with_digest_md5 0
# auth_with_login 1
# auth_with_plain 1
#
# check_certificate 1
# certificat_owner /CN=mail.gmx.net
# certificat_issuer /OU=Certification Services Division/
# certificates_folder /usr/share/ca-certificates
#

my $config_file_def = '/etc/sasl.cf';
my $debug = 0;
my %smtp_server = ( server => "localhost", port => 25, timeout => 10, send_fqun => 1 );
my %config = ( use_ehlo => 1, use_tls => 1, helo_as => "localhost" );
my %auth_methods = ( cram_md5 => 1, digest_md5 => 0, login => 1, plain => 1 );
my %certificate = ( check => 0, owner => "", issuer => "", folder => "/etc/ssl/certs" );

my $username = $ENV{ 'SASL_U' };
open(MYFILE, ">>/tmp/smtpauth.log"); print MYFILE "(pre) user: $username\n"; close(MYFILE);
die( "Is missing the account name" ) if ! $username ;
my $password = $ENV{ 'SASL_P' }; 
open(MYFILE, ">>/tmp/smtpauth.log"); print MYFILE "(pre) pass: $password\n"; close(MYFILE);
die( "Is missing the account password" ) if ! $password;
my $config_file = shift;
if( (! defined $config_file) || ($config_file eq "") )
{
    $config_file = $config_file_def;
}

# debug
open(MYFILE, ">>/tmp/smtpauth.log"); print MYFILE "user: $username, pass: $password\n"; close(MYFILE);

my %smtp_server_features;
my ($code, $text, $more, $full);
my $exit_code = 0;			# not authenticated yet

# Keep here the full e-mail address
my $user = $username;
my $user_non_fqdn = $username;
$user_non_fqdn =~ s/[^a-z0-9.\-][a-z0-9.\-]+$//i;
my $user_domain;
if( $user eq $user_non_fqdn ) {
    $user_domain = "";
} else {
    $user_domain = $username;
    $user_domain =~ s/^.*[^a-z0-9.\-]([a-z0-9.\-]+)$/$1/i;
}

die( "Missing config file: $config_file" ) if( ! -f $config_file );
read_config_file( $config_file );
print "* Config file '$config_file' was read successfully\n" if $debug;

sub read_config_file
{
    my $cf = $_[ 0 ];
    open( CONFIG, $cf) || die( "Could not open/read config file: $cf" );
    while( my $line = <CONFIG> )
    {
        if( $line =~ /^#/ )
	{
	    next;
	}

        if( $line =~ /^debug (\d)$/i )
	{
            $debug = $1;
        }

        if( $line =~ /^server ([a-z0-9._\-]+)$/i )
	{
            $smtp_server{ 'server' } = $1;
        }
        if( $line =~ /^port (\d+)$/i )
	{
            $smtp_server{ 'port' } = $1;
        }
        if( $line =~ /^timeout (\d+)$/i )
	{
            $smtp_server{ 'timeout' } = $1;
        }
        if( $line =~ /^send_fq_username (\d)$/i )
	{
            $smtp_server{ 'send_fqun' } = $1;
        }

        if( $line =~ /^use_ehlo (\d+)$/i )
	{
            $config{ 'use_ehlo' } = $1;
        }
        if( $line =~ /^use_tls (\d+)$/i )
	{
            $config{ 'use_tls' } = $1;
        }
        if( $line =~ /^helo_as ([a-z0-9._\-]+)$/i )
	{
            $config{ 'helo_as' } = $1;
        }

        if( $line =~ /^auth_with_cram_md5 (\d+)$/i )
	{
            $auth_methods{ 'cram_md5' } = $1;
        }
        if( $line =~ /^auth_with_digest_md5 (\d+)$/i )
	{
            $auth_methods{ 'digest_md5' } = $1;
        }
        if( $line =~ /^auth_with_login (\d+)$/i )
	{
            $auth_methods{ 'login' } = $1;
        }
        if( $line =~ /^auth_with_plain (\d+)$/i )
	{
            $auth_methods{ 'plain' } = $1;
        }

        if( $line =~ /^check_certificate (\d)$/i )
	{
            $certificate{ 'check' } = $1;
        }
        if( $line =~ /^certificat_owner (.+)$/i )
	{
            $certificate{ 'owner' } = $1;
        }
        if( $line =~ /^certificat_issuer (.+)$/i )
	{
            $certificate{ 'issuer' } = $1;
        }
        if( $line =~ /^certificats_folder (.+)$/i )
	{
            $certificate{ 'folder' } = $1;
        }
    }
    close( CONFIG );
}

# Init mysql link
my $db_usr = "smtp_auth-user";
my $db_pwd = "loltruck2000";
my $dbh = DBI->connect('DBI:mysql:smtp_auth', $db_usr, $db_pwd ) || die "Could not connect to database: $DBI::errstr";

# Check if the username/password are in the cache
my ($srv_ref, $domain, $auth, $auth_method, $ssl_validation, $use_fqdn);
my $usrpwd = hmac_md5_hex( "$user\n$password", "" );
print "*** SQL: SELECT smtp_srv_ref, domain FROM cache_auth WHERE hashup='$usrpwd'\n" if ($debug > 2);
my $sth = $dbh->prepare( "SELECT cache_auth.smtp_srv_ref, smtp_servers.addr, smtp_servers.port, smtp_servers.auth_enabled, smtp_servers.auth_methods, "
    . "smtp_servers.ssl_validation, smtp_servers.use_fqdn, cache_auth.domain FROM cache_auth INNER JOIN smtp_servers "
    . "ON smtp_servers.smtp_srv_ref = cache_auth.smtp_srv_ref AND cache_auth.hashup = '$usrpwd' LIMIT 1" );
$sth->execute() or die( "!@" );
$sth->bind_columns( undef, \$srv_ref, \$smtp_server{'server'}, \$smtp_server{'port'}, \$auth, \$auth_method, \$ssl_validation, \$use_fqdn, \$domain ) or die( "!@" );
if( $sth->fetch() )
{
    $sth->finish();

    # username/password found in cache
    print "* Cache-Hit: $user last authenticated by " . $smtp_server{ 'server' } . ":" . $smtp_server{ 'port' } . " for domain '$domain'\n" if $debug;

    # if there is any user_domain then check if the domain stil point to that server
    my $cached_domain_ok = 1;
    if( $user_domain )
    {
	my $sth = $dbh->prepare( "SELECT name FROM domains WHERE name = '$domain' AND smtp_srv_ref = '$srv_ref'" );
	$sth->execute() or die( "!@" );
	if( ! $sth->fetch() )
	{
	    $sth->finish();

	    $cached_domain_ok = 0;
	}
    }

    if( $cached_domain_ok )
    {
	if( $use_fqdn ) {
	    $username = $user;
	} else {
	    $username = $user_non_fqdn;
	}

	if( $auth )
	{
    	    $auth_methods{ 'plain' } = ($auth_method & 1);
    	    $auth_methods{ 'login' } = ($auth_method & 2);
    	    $auth_methods{ 'digest_md5' } = ($auth_method & 4);
    	    $auth_methods{ 'cram_md5' } = ($auth_method & 8);

	    if( $ssl_validation == 1 ) {
    		$config{ 'use_tls' } = 0;
    		$certificate{ 'check' } = 0;
	    } elsif( $ssl_validation == 2 ) {
    		$config{ 'use_tls' } = 1;
    		$certificate{ 'check' } = 0;
	    } else {
    		$config{ 'use_tls' } = 1;
    		$certificate{ 'check' } = 1;
    		$certificate{ 'owner' } = "";
    		$certificate{ 'issuer' } = "*";
	    }
    
	    # connect to smtp server and check auth ($exit_code is 1 if there was success)
	    check_smtp_server();

	    if( $exit_code )
	    {
		my $sql = "UPDATE cache_auth SET last_hit = NOW() WHERE hashup='$usrpwd'";
		$dbh->do( "$sql" ) or die( "!@" );
	    }
	}
    }
}

# check all smtp servers assigned to a domain
if( ! $exit_code && $user_domain )
{
    # delete the user from the cache
    my $sql = "DELETE FROM cache_auth WHERE hashup='$usrpwd'";
    $dbh->do( "$sql" ) or die( "!@" );

    print "* Cache-Miss: try to authenticate $user against its declared domain $user_domain\n" if $debug;

    #get all the servers assigned to a domain
    $sth = $dbh->prepare( "SELECT smtp_servers.smtp_srv_ref, smtp_servers.addr, smtp_servers.port, smtp_servers.auth_enabled, smtp_servers.auth_methods, "
	. "smtp_servers.ssl_validation, smtp_servers.use_fqdn FROM domains INNER JOIN smtp_servers "
	. "ON smtp_servers.smtp_srv_ref = domains.smtp_srv_ref AND domains.name = '$user_domain'" );
    $sth->execute() or die( "!@" );
    $sth->bind_columns( undef, \$srv_ref, \$smtp_server{'server'}, \$smtp_server{'port'}, \$auth, \$auth_method, \$ssl_validation, \$use_fqdn ) or die( "!@" );
    while( $sth->fetch() )
    {
	if( $use_fqdn ) {
	    $username = $user;
	} else {
	    $username = $user_non_fqdn;
	}

	if( $auth )
	{
    	    $auth_methods{ 'plain' } = ($auth_method & 1);
    	    $auth_methods{ 'login' } = ($auth_method & 2);
    	    $auth_methods{ 'digest_md5' } = ($auth_method & 4);
    	    $auth_methods{ 'cram_md5' } = ($auth_method & 8);

	    if( $ssl_validation == 1 ) {
        	$config{ 'use_tls' } = 0;
        	$certificate{ 'check' } = 0;
	    } elsif( $ssl_validation == 2 ) {
        	$config{ 'use_tls' } = 1;
        	$certificate{ 'check' } = 0;
	    } else {
        	$config{ 'use_tls' } = 1;
        	$certificate{ 'check' } = 1;
        	$certificate{ 'owner' } = "";
        	$certificate{ 'issuer' } = "*";
	    }

	    # connect to smtp server and check auth ($exit_code is 1 if there was success)
	    check_smtp_server();
	    
	    # I found a server that accepted me
	    if( $exit_code )
	    {
		# add the user in the cache
		my $sql = "INSERT INTO cache_auth (hashup, smtp_srv_ref, domain, last_hit) VALUES ('$usrpwd', '$srv_ref', '$user_domain', NOW() )";
		$dbh->do( "$sql" ) or die( "!@" );
		
		last;
	    }
	}
    }
    $sth->finish();
}

# check all servers if no success with the cached one
if( ! $exit_code  )
{
    # delete the user from the cache
    my $sql = "DELETE FROM cache_auth WHERE hashup='$usrpwd'";
    $dbh->do( "$sql" ) or die( "!@" );

    print "* Fall-back: try to authenticate $user against all SMTP servers\n" if $debug;

    # username/password not found in cache -> check all servers
    $sth = $dbh->prepare( "SELECT smtp_srv_ref, addr, port, auth_enabled, auth_methods, ssl_validation, use_fqdn FROM smtp_servers WHERE auth_enabled != 0" );
    $sth->execute() or die( "!@" );
    $sth->bind_columns( undef,\$srv_ref, \$smtp_server{'server'}, \$smtp_server{'port'}, \$auth, \$auth_method, \$ssl_validation, \$use_fqdn ) or die( "!@" );
    while( $sth->fetch() )
    {
	if( $use_fqdn ) {
	    $username = $user;
	} else {
	    $username = $user_non_fqdn;
	}

	if( $auth )
	{
    	    $auth_methods{ 'plain' } = ($auth_method & 1);
    	    $auth_methods{ 'login' } = ($auth_method & 2);
    	    $auth_methods{ 'digest_md5' } = ($auth_method & 4);
    	    $auth_methods{ 'cram_md5' } = ($auth_method & 8);

	    if( $ssl_validation == 1 ) {
        	$config{ 'use_tls' } = 0;
        	$certificate{ 'check' } = 0;
	    } elsif( $ssl_validation == 2 ) {
        	$config{ 'use_tls' } = 1;
        	$certificate{ 'check' } = 0;
	    } else {
        	$config{ 'use_tls' } = 1;
        	$certificate{ 'check' } = 1;
        	$certificate{ 'owner' } = "";
        	$certificate{ 'issuer' } = "*";
	    }

	    # connect to smtp server and check auth ($exit_code is 1 if there was success)
	    check_smtp_server();
	    
	    # I found a server that accepted me
	    if( $exit_code )
	    {
		# add the user in the cache
		my $sql = "INSERT INTO cache_auth (hashup, smtp_srv_ref, domain, last_hit) VALUES ('$usrpwd', '$srv_ref', '$user_domain', NOW() )";
		$dbh->do( "$sql" ) or die( "!@" );
		
		last;
	    }
	}
    }
    $sth->finish();
}

$dbh->disconnect();

if( $debug )
{
    if( $exit_code ) {
	print "***[ Final decision : $user WAS authenticated ]***\n";
    } else {
	print "***[ Final decision : $user WAS NOT authenticated ]***\n";
    }
}
exit( $exit_code );

################################################################

my $sock;

sub check_smtp_server
{
    # Connecting to the SMTP server
    $sock = IO::Socket::INET->new (
	    PeerAddr => $smtp_server{ 'server' },
	    PeerPort => $smtp_server{ 'port' },
	    Proto => 'tcp',
	    Timeout => $smtp_server{ 'timeout' }
	);

    if( ! $sock )
    {
	print "Connect failed to SMTP server $smtp_server{server}:$smtp_server{port}. Reason: $@\n";
	return;
    }
    
    $sock->autoflush( 1 );
    print "* Server $smtp_server{server}:$smtp_server{port} was contacted\n" if $debug;

    # Wait for the welcome message of the server.
    get_line_from_smtp_server();
    die( "Unknown SMTP initial string: '$full'\n") if( $code != 220 );

    # Send HELO or EHLO to the SMTP server
    send_halo() or exit( 0 );
    print "* I succed to speak the same language with the SMTP server :)\n" if $debug;

    # Assume everything is OK
    $exit_code = 1;

    # Check if we want encription and if the SMTP server support it
    if( $config{ 'use_tls' } && (defined( $smtp_server_features{ 'STARTTLS' } ) || defined( $smtp_server_features{ 'TLS' } )) )
    {
	print "* Start using TLS\n" if( $debug );

	# Do Net::SSLeay initialization
	Net::SSLeay::load_error_strings();
	Net::SSLeay::SSLeay_add_ssl_algorithms();
	Net::SSLeay::randomize();
	
	send_line_to_smtp_server( "STARTTLS" );
	get_line_from_smtp_server();
	die( "Unknown STARTTLS response '$code'.\n") if( $code != 220 );
		
	# Convert the socket from normal to SSL/TLS
	my %opt = ( SSL_version => 'TLSv1.2 TLSv1.1 TLSv1' );
	if( $certificate{ 'check' } && $certificate{ 'issuer' } eq "*" )
	{
	    print "* Force checking of server's certificate\n" if $debug;
	    $opt{ 'SSL_verify_mode' } = '3';	# verify peer
	    $opt{ 'SSL_ca_path' } = $certificate{ 'folder' };
	    $opt{ 'SSL_ca_file' } = $certificate{ 'folder' } . "/ca-certificates.crt";
	}
	if( ! IO::Socket::SSL::socket_to_SSL( $sock, %opt ) )
	{
	    print "* Server's certificate is NOT OK\n" if ($debug && $certificate{ 'check' });
	    die( "STARTTLS: " . IO::Socket::SSL::errstr() . "\n" ); 
	}

	print "* Server's certificate is OK\n" if ($debug && $certificate{ 'check' });
		
	my $smpt_server_certificate = $sock->dump_peer_certificate();
	print "* Cipher: " . $sock->get_cipher () . "\n$smpt_server_certificate" if $debug;
    
	# Check certificate if it is required so
	if( $certificate{ 'check' } )
	{
	    my ($owner, $issuer, $dummy) = split( "\n", $smpt_server_certificate );
	    if( $certificate{ 'owner' } )
	    {
		$exit_code = 0 if $owner !~ /$certificate{ 'owner' }/;
	    }
	    if( $certificate{ 'issuer' } && $certificate{ 'issuer' } ne "*" )
	    {
		$exit_code = 0 if $issuer !~ /$certificate{ 'issuer' }/;
	    }
	}

	# Send HELO or EHLO again as required by the SMTP standard
	send_halo() or $exit_code = 0;
    }

    if( $exit_code )
    {
	# Try to authenticate using the allowed and supported methods
	if( ! defined( $smtp_server_features{ 'AUTH' } ) ) {
	    print "* The SMTP server accept all connections\n" if $debug;

	    # if the server does not provide authentication then our client is not authenticated
	    $exit_code = 0;
	} else {
	    print "* SMTP server AUTH methods: $smtp_server_features{AUTH}\n" if $debug;
    
	    # Try CRAM_MD5
	    if( $auth_methods{ 'cram_md5' } && ($smtp_server_features{ 'AUTH' } =~ /CRAM-MD5/i) )
	    {
		print "* Auth using CRAM-MD5\n" if $debug;

		send_line_to_smtp_server( "AUTH CRAM-MD5" );
		get_line_from_smtp_server();
		$exit_code = 0 if( expect_code( $code, 334, "AUTH failed: $full" ) );
	
		my $response = encode_cram_md5( $text, $username, $password );
		send_line_to_smtp_server( $response );
		get_line_from_smtp_server();
		$exit_code = 0 if( expect_code( $code, 235, "AUTH failed: $full" ) );
	    }
    
	    # Try DIGEST_MD5
	    elsif( $auth_methods{ 'digest_md5' } && ($smtp_server_features{ 'AUTH' } =~ /DIGEST-MD5/i) )
	    {
	    }
        
	    # Try LOGIN
	    elsif( $auth_methods{ 'login' } && ($smtp_server_features{ 'AUTH' } =~ /LOGIN/i) )
	    {
		print "* Auth using LOGIN\n" if $debug;

		send_line_to_smtp_server( "AUTH LOGIN" );
		get_line_from_smtp_server();
		$exit_code = 0 if( expect_code( $code, 334, "AUTH failed: $full" ) );

		send_line_to_smtp_server( encode_base64( $username, "" ) );
		get_line_from_smtp_server();
		$exit_code = 0 if( expect_code( $code, 334, "AUTH failed: $full" ) );

		send_line_to_smtp_server( encode_base64( $password, "" ) );
		get_line_from_smtp_server();
		$exit_code = 0 if( expect_code( $code, 235, "AUTH failed: $full" ) );
	    }
        
	    # Try PLAIN
	    elsif( $auth_methods{ 'plain' } && ($smtp_server_features{ 'AUTH' } =~ /PLAIN/i) )
	    {
		print "* Auth using PLAIN\n" if $debug;

		send_line_to_smtp_server( "AUTH PLAIN " . encode_base64( "$username\0$username\0$password", "" ) );
		get_line_from_smtp_server();
		$exit_code = 0 if( expect_code( $code, 235, "AUTH failed: $full" ) );
	    }

	    # Catch if no auth succeed    
	    else
	    {
		warn ("No supported authentication method advertised by the server.\n");
		$exit_code = 0;
	    }

	    # Announce succees
	    print "* Authentication of $username on $smtp_server{server} succeeded\n" if( $debug && $exit_code );
	}
    } # if( $exit_code )

    # Stop the communication with the SMTP server
    send_line_to_smtp_server( "QUIT" );

    # release the socket
    close( $sock );
    $sock = undef;

    if( $debug )
    {
	if( $exit_code ) {
	    print "@@@ Success @@@\n";
	} else {
	    print "@@@ Failer @@@\n";
	}
    }

    return $exit_code;
}

##################################################################

# Get from the SMTP server
#
#($code, $text, $more, $full) are populated with the code, the text after the code,
#	if there are more lines to be read, the full answer
sub get_line_from_smtp_server
{
    my $sep;
    
    $full = $sock->getline();
    chomp( $full );

    ($code, $sep, $text) = ( $full =~ /(\d+)(.)([^\r]*)/);
    $more = ( $sep eq "-" ) ? 1 : 0;

    print "S: $full\n" if $debug > 1;
}

# Send to the SMTP server
sub send_line_to_smtp_server
{
    my $msg = shift;

    $sock->print( "$msg\r\n" );

    print "C: $msg\n" if $debug > 1;
}

sub expect_code
{
    my $code_in = shift;
    my $code_ex = shift;
    my $msg = shift;
    
    if( $code_in != $code_ex )
    {
	warn( "$msg\n" ) if $debug;
	return 1;
    }
    
    return 0;
}

# Store all server's (E)SMTP features into a hash
sub send_halo
{
    my ($feature, $param);

    my $helo = $config{ 'use_ehlo' } ? "EHLO" : "HELO";

    send_line_to_smtp_server( "$helo $config{helo_as}" );
    get_line_from_smtp_server;

    return 0 if( expect_code( $code, 250, "$helo failed: $full" ) );

    # Empty the hash
    %smtp_server_features = ();

    # if it is following the list of features then $more is 1
    if( $more )
    {
	do {
    	    get_line_from_smtp_server;
    	    ($feature, $param) = ($text =~ /^(\w+)[= ]*(.*)$/);
    	    $smtp_server_features{ $feature } = $param;
	} while( $more );
    }

    return 1;
}

sub encode_cram_md5
{
    my ($ticket64, $username, $password) = @_;
    my $ticket = decode_base64( $ticket64 ) or die( "Unable to decode Base64 encoded string '$ticket64'\n" );
	
    my $password_md5 = hmac_md5_hex( $ticket, $password );
    return encode_base64( "$username $password_md5", "" );
}
