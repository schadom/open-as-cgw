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


package Underground8::Log::Writer::Email::MySQL;
use base Underground8::Log::Writer::Email;

use strict;
use warnings;

use Underground8::Log::Email;
use Underground8::Log::Writer::Email;
use DBI;    
use Time::HiRes qw(gettimeofday tv_interval);
use Date::Format;

use MIME::Words qw(:all);

my $DEBUG = 0;
my $glob_dbh = undef;


sub debug
{
    my $text = shift;
    my $level = shift || 1;

    print time2str("%c",time) . " rtlog-mysql: $text\n" if ($level <= $DEBUG);   
}

# message types
sub unmime 
{
    my ($enc) = @_;


    my @words = decode_mimewords($enc);


    my $dec = "";
    for ( @words) 
    {
        eval 
        {
            $dec .= $_->[1] ? decode_mimewords($_->[1], $_->[0]) : $_->[0];
        };
        if ($@) 
        {
            # if decoding fails for any reason (usually unknown charset)
            # we just append he encoded word.
            print "Decoding failed: $enc\n";
            #$dec .= $_->[0];
        }
    }
    return $dec;
}


sub new
{
    my $class = shift;
    my $id = shift;
    my $debug = shift || 0;
    
    if ($debug)
    {
        $DEBUG = $debug;
    }
    
    debug("starting up", 1);
    my $self = $class->SUPER::new($id);

    $self->{'_mysql_username'} = 'rt_log';
    $self->{'_mysql_password'} = 'rt_log';
    $self->{'_mysql_database'} = 'rt_log';
    $self->{'_mysql_host'} = 'localhost'; 

    # get the status-codes from the database;
    $self->connect();
    debug("Connected to MySQL database", 5);

    my $dbh = $self->dbh;

    my $sqlgrey_stmt_text = "SELECT id, description FROM sqlgrey_status;";
    my $sqlgrey_stmt = $dbh->prepare($sqlgrey_stmt_text);

    if ($sqlgrey_stmt->execute)
    {
        while (my ($id,$description) = $sqlgrey_stmt->fetchrow_array)
        {
            $self->{'_status'}->{'sqlgrey'}->{$description} = $id;
        }
    }

    my $amavis_stmt_text = "SELECT id, description FROM amavis_status;";
    my $amavis_stmt = $dbh->prepare($amavis_stmt_text);

    if ($amavis_stmt->execute)
    {
        while (my ($id,$description) = $amavis_stmt->fetchrow_array)
        {
            $self->{'_status'}->{'amavis'}->{$description} = $id;
        }
    }   

    return $self;
}

sub run
{
    my $self = shift;
    
    # connect to database
    my $dbh = $self->dbh;

    debug("Preparing Statements", 1);

    # prepare the statement
    my $livelog_text = "INSERT INTO mail_livelog (received, received_us, received_log, msg_id, mail_from, rcpt_to, client_ip, queue_nr, subject, sqlgrey, amavis, amavis_hits, amavis_detail, delay) VALUES (FROM_UNIXTIME(?),?,FROM_UNIXTIME(?),?,?,?,?,?,?,?,?,?,?,?);";
    my $livelog = $dbh->prepare($livelog_text);

    my $domain_livelog_text = "INSERT INTO domain_livelog (received,received_us,received_log,from_domain,to_domain,sqlgrey,amavis,amavis_hits) VALUES (FROM_UNIXTIME(?),?,FROM_UNIXTIME(?),?,?,?,?,?);";
    # my $domain_livelog = $dbh->prepare($domain_livelog_text);

    my $greylist_lookup_text = "SELECT received, received_us FROM mail_livelog WHERE (sqlgrey=20 OR sqlgrey=21) AND mail_from=? AND rcpt_to=? AND client_ip=?;";
    my $greylist_lookup = $dbh->prepare($greylist_lookup_text);
    
    my $greylist_delete_text = "DELETE FROM mail_livelog WHERE received=? AND received_us=?;";
    my $greylist_delete = $dbh->prepare($greylist_delete_text);
    
    my $domain_greylist_delete_text = "DELETE FROM domain_livelog WHERE received=? AND received_us=?;";
    my $domain_greylist_delete = $dbh->prepare($domain_greylist_delete_text);
 

    while (1)
    {
        my $mail_hash = $self->mq->rcv;

        debug("Received object from message queue",5);

        if (defined $mail_hash)
        {
            my $type = $mail_hash->{'type'};
            my $mail = $mail_hash->{'mail'};

            debug ("Received mail object $type", 3);

            my $from_domain;
            my $to_domain;
            if ($mail->from =~ qr/^.+\@(.+)$/)
            {
                $from_domain = $1;
            }
            # mailer daemons
            elsif($mail->from =~ qr/MAILER-DAEMON/)
            {
                $from_domain = $mail->from;
            }
            else
            {
                $from_domain = 'incomplete';
            }
            if ($mail->to =~ qr/^.+\@(.+)$/)
            {
                $to_domain = $1;
            }
            
            # commit domain statistics to livelog

			# The following block has been commented due to 2.0.1 release, for 2.0.0 does not
			# offer domain-stats anymore (they're worthless). And since that crappy domain-stuff
			# used up to about 54% of db-activity, it's time to get rid of that.
			# [es, 20100819]
            #unless ($type == Underground8::Log::Writer::Email::RELAYED)
            #{
            #    $domain_livelog->bind_param(1, $mail->received->[0]);
            #    $domain_livelog->bind_param(2, $mail->received->[1]);
            #    $domain_livelog->bind_param(3, $mail->received_log);
            #    $domain_livelog->bind_param(4, $from_domain);
            #    $domain_livelog->bind_param(5, $to_domain);
            #    $domain_livelog->bind_param(6, $self->id_sqlgrey_status($mail->sqlgrey_status));
            #    $domain_livelog->bind_param(7, $self->id_amavis_status($mail->amavis_status));
            #    $domain_livelog->bind_param(8, $mail->amavis_hits);
            #    my $t0 = [ gettimeofday ];
            #    $domain_livelog->execute(); 
            #    $domain_livelog->finish();
            #    debug("Commited mail to domain livelog. Took: ".tv_interval($t0),1);
            #}
            
            if ($type == Underground8::Log::Writer::Email::ACCEPTED ||
                $type == Underground8::Log::Writer::Email::BLOCKEDVIRUS ||
                $type == Underground8::Log::Writer::Email::BLOCKEDSPAM ||
                $type == Underground8::Log::Writer::Email::BLOCKEDBF)
            {
                # lookup if there is a greylisted mail
                if ($mail->sqlgrey_status =~ qr/update/)
                {
                    my $t0 = [ gettimeofday ];
                    $greylist_lookup->bind_param(1, $mail->from);
                    $greylist_lookup->bind_param(2, $mail->to);
                    $greylist_lookup->bind_param(3, $mail->client_ip);
                    my $rows = $greylist_lookup->execute;
                    if ($rows > 0)
                    {
                        # delete greylisted mails
                        while (my ($received,$received_us) = $greylist_lookup->fetchrow_array)
                        {
                            $greylist_delete->bind_param(1, $received);
                            $greylist_delete->bind_param(2, $received_us);
                            $greylist_delete->execute;
                            
                            $domain_greylist_delete->bind_param(1, $received);
                            $domain_greylist_delete->bind_param(2, $received_us);
                            $domain_greylist_delete->execute;
                            $domain_greylist_delete->finish;
                        }
                    }
                    $greylist_lookup->finish;
                    debug("Did greylist lookup. Took: ".tv_interval($t0),1);
                }

                # commit to database
                my $t0 = [ gettimeofday ];
                $livelog->bind_param(1, $mail->received->[0]);
                $livelog->bind_param(2, $mail->received->[1]);
                $livelog->bind_param(3, $mail->received_log);
                $livelog->bind_param(4, $mail->msg_id);
                $livelog->bind_param(5, $mail->from);
                $livelog->bind_param(6, $mail->to);
                $livelog->bind_param(7, $mail->client_ip);
                $livelog->bind_param(8, $mail->queue_nr);
                $livelog->bind_param(9, unmime($mail->subject));
                $livelog->bind_param(10, $self->id_sqlgrey_status($mail->sqlgrey_status));
                $livelog->bind_param(11, $self->id_amavis_status($mail->amavis_status));
                $livelog->bind_param(12, $mail->amavis_hits);
                if ($mail->amavis_detail)
                {
                    $livelog->bind_param(13, $mail->amavis_detail);
                }
                else
                {
                    $livelog->bind_param(13, undef);
                }
                $livelog->bind_param(14, $mail->delay);
                $livelog->execute();
                $livelog->finish();
                debug("Commited accepted mail. Took: ".tv_interval($t0),1);
            }
            elsif ( $type == Underground8::Log::Writer::Email::GREYLISTED ||
                    $type == Underground8::Log::Writer::Email::BLOCKEDBL)
            {
                my $t0 = [ gettimeofday ];
                $livelog->bind_param(1, $mail->received->[0]);
                $livelog->bind_param(2, $mail->received->[1]);
                $livelog->bind_param(3, $mail->received_log);
                $livelog->bind_param(4, undef);
                $livelog->bind_param(5, $mail->from);
                $livelog->bind_param(6, $mail->to);
                $livelog->bind_param(7, $mail->client_ip);
                $livelog->bind_param(8, undef);
                $livelog->bind_param(9, undef);
                $livelog->bind_param(10, $self->id_sqlgrey_status($mail->sqlgrey_status));
                if ($mail->amavis_status)
                {
                    $livelog->bind_param(11, $self->id_amavis_status($mail->amavis_status));
                }
                else
                {
                    $livelog->bind_param(11, undef);
                }
                $livelog->bind_param(12, undef);
                $livelog->execute();
                $livelog->finish();
                debug("Commited blocked mail. Took: ".tv_interval($t0),1);
            }
        }
        else
        {
            debug("Ooops, going to sleep ...\n", 3);
            sleep(1);
        }
    }
}

sub id_sqlgrey_status
{
    my $self = shift;
    my $description = shift;
    return $self->{'_status'}->{'sqlgrey'}->{$description};
}

sub id_amavis_status
{
    my $self = shift;
    my $description = shift;
    return $self->{'_status'}->{'amavis'}->{$description};
}

sub dbh ($)
{
    my $self = shift;
#    unless ($self->{'_dbh'} and $self->{'_dbh'}->ping())
#    {
#        $self->connect();
#    }

    if ($self->{'_dbh'})
    {
        if (!$self->{'_dbh'}->ping())
        {
            debug("Lost MySQL connection!",1);
            die;
        }

    }
    return $self->{'_dbh'};
}

sub connect ($)
{
    my $self = shift;
    # connect to database, bug server_prepare=0 is required, because of bug in driver
    my $dsn = "DBI:mysql:database=$self->{'_mysql_database'};host=$self->{'_mysql_host'};mysql_server_prepare=0";
    $self->{'_dbh'} = DBI->connect($dsn, $self->{'_mysql_username'}, $self->{'_mysql_password'}, {
                                    RaiseError => 0,
                                    AutoCommit => 1,
                                    });

    $self->{'_dbh'}->{'mysql_auto_reconnect'} = 1;
    $glob_dbh = $self->{'_dbh'};
}

sub DESTROY
{
    $glob_dbh->disconnect() if defined $glob_dbh;
}




1;
