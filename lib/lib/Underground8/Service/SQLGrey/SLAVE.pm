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


package Underground8::Service::SQLGrey::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Exception;                                                                                                 
use Underground8::Exception::FileOpen;                                                                                       
use Error;
use Carp;
use Template;
use DBI;
use Data::Dumper;

sub new ($$)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_system_username'} = 'sqlgrey';
    $self->{'_mysql_username'} = '';
    $self->{'_mysql_password'} = '';
    $self->{'_mysql_database'} = '';
    $self->{'_mysql_host'} = '';
    $self->{'_stmt'} = {};
    $self->{'_initialized'} = 0;
    return $self;
}

sub initialized
{
    my $self = instance(shift);
    return $self->{'_initialized'};
}


sub service_restart ($)
{
    my $self = instance(shift, __PACKAGE__);
    my $output = safe_system($g->{'cmd_sqlgrey_restart'});
}
    

sub initialize($$$$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $db_host = shift;
    my $db_name = shift;
    my $db_username = shift;
    my $db_password = shift;

    $self->{'_mysql_username'} = $db_username;
    $self->{'_mysql_password'} = $db_password;
    $self->{'_mysql_database'} = $db_name;
    $self->{'_mysql_host'} = $db_host;

    # ip_blacklist #
    $self->stmt->{'ip_blacklist'}->{'read'} = 'SELECT _blacklist FROM blacklist';
    $self->stmt->{'ip_blacklist'}->{'create'} = 'INSERT INTO blacklist (_blacklist,_description) VALUES (?,?)';
    $self->stmt->{'ip_blacklist'}->{'update'} = 'UPDATE blacklist SET _description=? WHERE _blacklist=?';
    $self->stmt->{'ip_blacklist'}->{'delete'} = 'DELETE FROM blacklist WHERE _blacklist=?';
    


    # ip_whitelist #
    $self->stmt->{'ip_whitelist'}->{'read'} = 'SELECT _whitelist FROM whitelist';
    $self->stmt->{'ip_whitelist'}->{'create'} = 'INSERT INTO whitelist (_whitelist,_description) VALUES (?,?)';
    $self->stmt->{'ip_whitelist'}->{'update'} = 'UPDATE whitelist SET _description=? WHERE _whitelist=?';
    $self->stmt->{'ip_whitelist'}->{'delete'} = 'DELETE FROM whitelist WHERE _whitelist=?';


    # addr_blacklist #
    $self->stmt->{'addr_blacklist'}->{'read'} = 'SELECT _blacklist FROM blacklist_sender';
    $self->stmt->{'addr_blacklist'}->{'create'} = 'INSERT INTO blacklist_sender (_blacklist,_description) VALUES (?,?)';
    $self->stmt->{'addr_blacklist'}->{'update'} = 'UPDATE blacklist_sender SET _description=? WHERE _blacklist=?';
    $self->stmt->{'addr_blacklist'}->{'delete'} = 'DELETE FROM blacklist_sender WHERE _blacklist=?';



    # addr_whitelist #
    $self->stmt->{'addr_whitelist'}->{'read'} = 'SELECT _whitelist FROM whitelist_sender';
    $self->stmt->{'addr_whitelist'}->{'create'} = 'INSERT INTO whitelist_sender (_whitelist,_description) VALUES (?,?)';
    $self->stmt->{'addr_whitelist'}->{'update'} = 'UPDATE whitelist_sender SET _description=? WHERE _whitelist=?';
    $self->stmt->{'addr_whitelist'}->{'delete'} = 'DELETE FROM whitelist_sender WHERE _whitelist=?';
    

    $self->connect();
    $self->{'_initialized'} = 1;
}


#### Accessors ####

sub dbh ($)
{
    my $self = instance(shift, __PACKAGE__);
    unless ($self->{'_dbh'} and $self->{'_dbh'}->ping())
    {
        $self->connect();
    }
    return $self->{'_dbh'};
}

sub stmt ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_stmt'};
}    


####                  ####
#### Database methods ####
####                  ####

sub connect ($)
{
    my $self = instance(shift, __PACKAGE__);
    # connect to database
    my $dsn = "DBI:mysql:database=$self->{'_mysql_database'};host=$self->{'_mysql_host'};mysql_server_prepare=1";
    $self->{'_dbh'} = DBI->connect($dsn, $self->{'_mysql_username'}, $self->{'_mysql_password'}, {
                                    RaiseError => 1,
                                    AutoCommit => 1,
                                    });

    $self->dbh->{'mysql_auto_reconnect'} = 1;

}


sub truncate_db ($)
{
    my $self = instance(shift, __PACKAGE__);

    my $stmt;
    my @tables = qw(blacklist whitelist blacklist_sender whitelist_sender);

    foreach my $table (@tables)
    {   
        $stmt = $self->dbh->prepare("TRUNCATE $table");
        $stmt->execute();
    }
}


sub commit_ip_blacklist ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $data = shift;

	open(TMP, ">/tmp/postfwd.log");
	print TMP $data;
	close(TMP);

    my $stmt = $self->stmt->{'ip_blacklist'};
    $self->commit_db($data, $stmt);
}

sub commit_ip_whitelist ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $data = shift;
    my $config = shift;

    my $stmt = $self->stmt->{'ip_whitelist'};
    $self->commit_db($data, $stmt);
    $self->write_postfix_whitelist_ip($data,$config);
}

sub commit_addr_blacklist ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $data = shift;

    my $stmt = $self->stmt->{'addr_blacklist'};
    $self->commit_db($data, $stmt);

}

sub commit_addr_whitelist ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $data = shift;
    my $config = shift;

    my $stmt = $self->stmt->{'addr_whitelist'};
    $self->commit_db($data, $stmt);
    $self->write_postfix_whitelist_addr($data,$config);

}

sub commit_db ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $data = shift;
    my $stmt = shift;
    my $existing;
    my $tmp;

    my $st_read = $self->dbh->prepare($stmt->{'read'});
    my $st_update = $self->dbh->prepare($stmt->{'update'}); 
    my $st_create = $self->dbh->prepare($stmt->{'create'});
    my $st_delete = $self->dbh->prepare($stmt->{'delete'});
    $st_read->execute();
    
    while (($tmp) = $st_read->fetchrow_array() )
    {
        $existing->{$tmp} = "";
    }

    while ( my ($key, $value) = each(%$data) )
    {
        if (exists($existing->{$key}))
        {
            $st_update->execute($key, $value);
            delete($existing->{$key});
        }
        else
        {
            $st_create->execute($key, $value);
        }
    }
    
    my @remains = keys(%$existing);

    foreach $tmp (@remains)
    {
        $st_delete->execute($tmp);
    }

    
}



###                      ###
### Config write methods ###
###                      ###


sub write_config ($$$$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $mysql_hostname = shift;
    my $mysql_database = shift;
    my $mysql_username = shift;
    my $mysql_password = shift;
    my $config = shift;

    $self->write_sqlgrey_config($mysql_hostname,
                                $mysql_database, 
                                $mysql_username,
                                $mysql_password, 
                                $config);

}

sub write_postfix_whitelist_addr
{
    my $self = instance(shift,__PACKAGE__);
    my $data = shift;
    my $config = shift;

    my $options = {
        addr_whitelisting => $config->{'addr_whitelisting'},
        addresses => [ keys %{$data} ],
    };

    my $template = Template->new({
                                INCLUDE_PATH => $g->{'cfg_template_dir'},
                   });   

    my $amavis_senderbypass_content;
    $template->process($g->{'template_postfix_amavis_senderbypass_filter'},$options,\$amavis_senderbypass_content)
        or throw Underground8::Exception($template->error);
    open (POSTFIX_AMAVIS_SENDERBYPASS,'>',$g->{'file_postfix_amavis_senderbypass_filter'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_senderbypass_filter'});
        print POSTFIX_AMAVIS_SENDERBYPASS $amavis_senderbypass_content;
    close (POSTFIX_AMAVIS_SENDERBYPASS); 

    $amavis_senderbypass_content = "";
    $template->process($g->{'template_postfix_amavis_senderbypass_accept'},$options,\$amavis_senderbypass_content)
        or throw Underground8::Exception($template->error);
    open (POSTFIX_AMAVIS_SENDERBYPASS,'>',$g->{'file_postfix_amavis_senderbypass_accept'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_senderbypass_accept'});
        print POSTFIX_AMAVIS_SENDERBYPASS $amavis_senderbypass_content;
    close (POSTFIX_AMAVIS_SENDERBYPASS);  

    my $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_senderbypass_accept'});
    safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_senderbypass_filter'});
    safe_system($command);

}

sub write_postfix_whitelist_ip
{
    my $self = instance(shift,__PACKAGE__);
    my $data = shift;
    my $config = shift;

    my @ip_addresses = keys %{$data};

    my $options = {
        ip_whitelisting => $config->{'ip_whitelisting'},
        ip_addresses => \@ip_addresses,
    };

    my $template = Template->new({
                                INCLUDE_PATH => $g->{'cfg_template_dir'},
                   });   

    my $amavis_bypass_content;
    $template->process($g->{'template_postfix_amavis_bypass_filter'},$options,\$amavis_bypass_content)
        or throw Underground8::Exception($template->error);

    open (POSTFIX_AMAVIS_BYPASS,'>',$g->{'file_postfix_amavis_bypass_filter'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_bypass_filter'});
        print POSTFIX_AMAVIS_BYPASS $amavis_bypass_content;
    close (POSTFIX_AMAVIS_BYPASS);

    $amavis_bypass_content = "";
    $template->process($g->{'template_postfix_amavis_bypass_accept'},$options,\$amavis_bypass_content)
        or throw Underground8::Exception($template->error);

    open (POSTFIX_AMAVIS_BYPASS,'>',$g->{'file_postfix_amavis_bypass_accept'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_bypass_accept'});
        print POSTFIX_AMAVIS_BYPASS $amavis_bypass_content;
    close (POSTFIX_AMAVIS_BYPASS);
 
    
    my $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_bypass_filter'});
    safe_system($command);

    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_bypass_accept'});
    safe_system($command);
}


sub write_sqlgrey_config ($$$$$)
{
    my $self = instance(shift, __PACKAGE__);                                                                                 
    my $mysql_host = shift;
    my $mysql_database = shift;
    my $mysql_username = shift;
    my $mysql_password = shift;
    my $config = shift;
    print STDERR "\n\nprinting config...\n\n";
    my ($name, $pass, $uid, 
        $gid, $quota, $comment, 
        $gcos, $dir, $shell, 
        $expire) = getpwnam($self->{'_system_username'});    

    my $template = Template->new({
                    INCLUDE_PATH => $g->{'cfg_template_dir'},
                   });   
    my $options = {
                  uid => $uid,
                  gid => $gid,
                  mysql_host => $mysql_host,
                  mysql_database => $mysql_database,
                  mysql_username => $mysql_username,
                  mysql_password => $mysql_password,
                  ip_whitelisting => $config->{'ip_whitelisting'},
                  ip_blacklisting => $config->{'ip_blacklisting'},
                  addr_whitelisting => $config->{'addr_whitelisting'},
                  addr_blacklisting => $config->{'addr_blacklisting'},
                  greylisting => $config->{'greylisting'},
                  selective_greylisting => $config->{'selective_greylisting'},
                  greylisting_authtime => $config->{'greylisting_authtime'},
                  greylisting_triplettime => $config->{'greylisting_triplettime'},
		  greylisting_connectage => $config->{'greylisting_connectage'},
		  greylisting_domainlevel => $config->{'greylisting_domainlevel'},
		  greylisting_message => $config->{'greylisting_message'},
    };                                                                                                                       

    my $config_content;                                                                                                         
    my $default_content;

    $template->process($g->{'template_sqlgrey_conf'},$options,\$config_content)
        or throw Underground8::Exception($template->error);
    open (SQLGREY,'>',$g->{'file_sqlgrey_conf'})
        or croak Underground8::Exception::FileOpen($g->{'file_sqlgrey_conf'});
    print SQLGREY $config_content;
    close (SQLGREY);

    $template->process($g->{'template_sqlgrey_default'},$options,\$default_content)
        or throw Underground8::Exception($template->error);
    open (DEFAULT,'>',$g->{'file_sqlgrey_default'})
        or throw Underground8::Exception::FileOpen($g->{'file_sqlgrey_default'});

    print DEFAULT $default_content;

    close (DEFAULT);
}




1;

