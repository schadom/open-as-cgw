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


package Underground8::Log::Listener::Email;

use Underground8::Log::Writer::Email;
use Underground8::Log::Email;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use Date::Format;
use Sys::Syslog;
use strict;
use warnings;

my $DEBUG = 0;
my $count = 0;

sub new {
	my ($class, $mq_offset, $debug) = (shift, shift, shift || 0);
	$DEBUG = $debug;

	my $self = {
		_writer => new Underground8::Log::Writer::Email($mq_offset),
                _listen_services => [   'amavis', 
					'sqlgrey',
					'postfix/smtpd',
					'postfix/smtp',
					'postfix/qmgr',
					'postfix/cleanup',
					'postfwd/master',
					'postfwd/policy',
					'postfwd'
                                     ],
		_mails => {
				msg_id		=> { },
				queue_nr	=> { },
				ip_from		=> { },
				client_ip	=> { },
			},

		_queuenr_to_ip => { },
		_queuenr_to_msgid => { },
		_queuenr_to_subject => { },
		_initialized => 0,
	};

	$self = bless $self, $class;
	return $self;
}

sub init {
	my $self = shift;
}

sub writer {
	my $self = shift;
	return $self->{'_writer'};
}

sub mails {
	my $self = shift;
	return $self->{'_mails'};
}

sub queuenr_to_msgid {
	my $self = shift;
	return $self->{'_queuenr_to_msgid'};
}
 
sub queuenr_to_ip {
	my $self = shift;
	return $self->{'_queuenr_to_ip'};
}
 
sub queuenr_to_subject {
	my $self = shift;
	return $self->{'_queuenr_to_subject'};
}

sub listen_services {
	my $self = shift;
	return $self->{'_listen_services'};
}

sub add_greylisted_mail {
	my ($self, $date_log, $from, $to, $host, $sqlgrey_status) = (shift, shift, lc(shift), lc(shift), shift, shift);

	my $mail = new Underground8::Log::Email;
	my $date = [ gettimeofday ];  #### veeRRRy dirty :(
	$mail->received($date);
	$mail->received_log($date_log);
	$mail->from($from);
	$mail->to($to);
	$mail->client_ip($host);
	$mail->sqlgrey_status($sqlgrey_status);
	
	$self->commit_greylisted($mail);
	$count++;
	debug ("$count greylisted: $from -> $to ($host)",1);
} 

sub add_blocked_mail {
	my ($self, $date_log, $from, $to, $host, $sqlgrey_status) = (shift, shift, lc(shift), lc(shift), shift, shift);

	my $mail = new Underground8::Log::Email;
	my $date = [ gettimeofday ];  #### veeRRRy dirty :(

	$mail->received($date);
	$mail->received_log($date_log);
	$mail->from($from);
	$mail->to($to);
	$mail->client_ip($host);
	$mail->sqlgrey_status($sqlgrey_status);

	$self->commit_blocked_blacklist($mail);
	$count++;
	debug ("$count blacklisted: $from -> $to ($host)",1);
} 

sub add_outgoing_mail {
	my ($self, $date_log, $queue_nr, $client_ip) = @_;

	my $mail = new Underground8::Log::Email;
	my $date = [ gettimeofday ];  #### veeRRRy dirty :(

	$mail->received($date);
	$mail->received_log($date_log);
	$mail->sqlgrey_status("outgoing");
	$mail->client_ip($client_ip);

	debug("Adding outgoing Mail queue_nr: $queue_nr, ip: $client_ip",3);

	unless (defined $self->mails->{'client_ip'}->{$client_ip} && scalar (@{$self->mails->{'client_ip'}->{$client_ip}}) > 0) {
		push @{$self->mails->{'client_ip'}->{$client_ip}}, $mail;
	}
	$self->set_mail_queuenr_ip($queue_nr,$client_ip);
}

sub add_accepted_mail {
	my ($self, $date_log, $from, $to, $host, $sqlgrey_status) = (shift, shift, lc(shift), lc(shift), shift, shift);

	my $mail = new Underground8::Log::Email;
	my $date = [ gettimeofday ];
	$mail->received($date);
	$mail->received_log($date_log);
	$mail->from($from);
	$mail->to($to);
	$mail->client_ip($host);
	$mail->sqlgrey_status($sqlgrey_status);
	
	debug("Adding accepted Mail from:$from, to:$to, ip:$host",3);

	# there are cases when queue_nrs are already known for a new email
	# (smtpd/cleanup message comes before sqlgrey)
	# So, let's first have a look on the queue_nr mapping and see if there are
	# any empty entries. If so, our new mail belongs to this queue_nr.
	unless ($sqlgrey_status =~ qr/new|abuse/) # performance
	{
		foreach my $queue_nr (keys %{$self->mails->{'queue_nr'}})
		{
			if (@{$self->mails->{'queue_nr'}->{$queue_nr}} == 0)
			{					  
				if ($self->queuenr_to_ip->{$queue_nr})
				{
					if ( $self->queuenr_to_ip->{$queue_nr} eq $host) {
						debug("Found empty queue_nr entry: $queue_nr",2);
						$mail->queue_nr($queue_nr);

						push @{$self->mails->{'queue_nr'}->{$queue_nr}}, $mail;
						debug ("Mapping Mail to $queue_nr",2);

						if ($self->queuenr_to_msgid->{$queue_nr} ) {
							my $msg_id = $self->queuenr_to_msgid->{$queue_nr};
							$mail->msg_id($msg_id);

							push @{$self->mails->{'msg_id'}->{$msg_id}}, $mail;
							debug("Mapping Mail to $msg_id",2);
																				  
							# clean up
							delete $self->queuenr_to_msgid->{$queue_nr};					
							my $tmp_mails = $self->mails->{'ip_from'}->{$host}->{$from};
							$self->clean_mapping($tmp_mails,$msg_id);
						}

						# clean up
						delete $self->mails->{'client_ip'}->{$host};
						delete $self->queuenr_to_ip->{$queue_nr};
					}
				}
			}
		}
	}

	# create lookup tree
	unless ($mail->queue_nr)
	{
		if ($self->mails->{'ip_from'}->{$host}->{$from})
		{
			# since we cannot be 100% sure if mail is the same as already queued mails
			# we take the last added queue_nr available of the last 10 seconds.
			my $last_queuenr;
			my $last_queuenr_date = [ gettimeofday ];
			my $max_interval = 3;
			foreach my $mail (@{$self->mails->{'ip_from'}->{$host}->{$from}}) {
				if ($mail) {
					if ($mail->from ne $from) {
						my $interval = tv_interval($mail->received,$last_queuenr_date);
						if ($mail->queue_nr && $interval < $max_interval && $interval > 0) {
							$last_queuenr = $mail->queue_nr;
							$max_interval = $interval;
						}
					}
				}
			} if ($last_queuenr) {
				$mail->queue_nr($last_queuenr);
				push @{$self->mails->{'queue_nr'}->{$last_queuenr}}, $mail;
				debug ("Mapping new Recipient to Queue-Nr $last_queuenr",2);
			}
		}
		push @{$self->mails->{'client_ip'}->{$host}}, $mail unless $mail->queue_nr;
	}

	push @{$self->mails->{'ip_from'}->{$host}->{$from}}, $mail unless $mail->msg_id;
}



sub set_mail_queuenr_ip {
	my ($self, $queue_nr, $client_ip) = @_;
	my $from;

	unless ($queue_nr && $client_ip) {
		die "Error setting Queue_Nr: No valid values provided";
	}

	if ($self->mails->{'client_ip'}->{$client_ip}) {
		foreach my $mail (@{$self->mails->{'client_ip'}->{$client_ip}}) {
			$from = $mail->from;
			$mail->queue_nr($queue_nr);
			push @{$self->mails->{'queue_nr'}->{$queue_nr}}, $mail;
		}

		debug ("Setting queue_nr $queue_nr for ip $client_ip",3);
		
		# delete the references under client_ip to avoid inconsistencies
		delete $self->mails->{'client_ip'}->{$client_ip};
	} elsif ($client_ip ne '127.0.0.1') {
		$self->queuenr_to_msgid->{$queue_nr} = '';
		$self->queuenr_to_ip->{$queue_nr} = $client_ip;
		$self->mails->{'queue_nr'}->{$queue_nr} = [];
		debug("IP to Queue-nr: $client_ip -> $queue_nr without any mails yet.",2);
		return;
	}

	# let's see if there is already collected data
	my $subject = $self->queuenr_to_subject->{$queue_nr};
	if ($subject) {
		foreach my $mail (@{$self->mails->{'queue_nr'}->{$queue_nr}}) {
			$mail->subject($subject);
		}
		# clean up
		delete $self->queuenr_to_subject->{$queue_nr};
		debug("Applying Header Subject to Mail with queue_nr $queue_nr",2); 
	}

	my $msg_id = $self->queuenr_to_msgid->{$queue_nr};
	if ($msg_id) {
		foreach my $mail (@{$self->mails->{'queue_nr'}->{$queue_nr}}) {
			$mail->msg_id($msg_id);
			push @{$self->mails->{'msg_id'}->{$msg_id}}, $mail;
		}

		# clean up
		if ($from) {
			my $tmp_mails = $self->mails->{'ip_from'}->{$client_ip}->{$from};
			$self->clean_mapping($tmp_mails,$msg_id);
			delete $self->mails->{'ip_from'}->{$client_ip}->{$from} if @{$self->mails->{'ip_from'}->{$client_ip}->{$from}} == 0;
			delete $self->mails->{'ip_from'}->{$client_ip}->{$from} if keys %{$self->mails->{'ip_from'}->{$client_ip}} == 0;
		}

		delete $self->queuenr_to_msgid->{$queue_nr};
		debug("Applying Msg-Id to Mail with queue_nr $queue_nr",2);
	}
}

# map queue_nr to msg_id
# this happens to mails after all recipients are known
sub set_mail_queuenr_msgid {
	my ($self, $queue_nr, $msg_id) = @_;

	unless ($queue_nr && $msg_id) {
		die "Queue_nr and Message id have to be specified!";
	}

	# there are mails with the specified queue_nr, so we have
	# to tell them their msg_id
	if ($self->mails->{'queue_nr'}->{$queue_nr}) {
		if (@{$self->mails->{'queue_nr'}->{$queue_nr}} > 0) {
			my ($t_from, $t_client_ip);
			
			# set msg id for all mails and create mapping
			foreach my $mail (@{$self->mails->{'queue_nr'}->{$queue_nr}}) {
				$t_from = $mail->from;
				$t_client_ip = $mail->client_ip;
				$mail->msg_id($msg_id);
				push @{$self->mails->{'msg_id'}->{$msg_id}}, $mail;
			}
			
			debug ("Setting Msg-Id $msg_id for queue-nr $queue_nr",3);

			if ($t_from && $t_client_ip) {
				my $tmp_mails = $self->mails->{'ip_from'}->{$t_client_ip}->{$t_from};
				if ($tmp_mails) {
					$self->clean_mapping($tmp_mails,$msg_id);
					delete $self->mails->{'ip_from'}->{$t_client_ip}->{$t_from} if @{$self->mails->{'ip_from'}->{$t_client_ip}->{$t_from}} == 0;
					delete $self->mails->{'ip_from'}->{$t_client_ip}->{$t_from} if keys %{$self->mails->{'ip_from'}->{$t_client_ip}} == 0; 
				}
			}
		} else {
			debug("Queue-Nr to Msg-ID: $queue_nr -> $msg_id, but no mails matching.",2);
			$self->queuenr_to_msgid->{$queue_nr} = $msg_id;
		}

		return;
	}
	# there are no mails with the queue_nr, so it's a new queue_nr -> let's thell them
	elsif ($self->mails->{'msg_id'}->{$msg_id}) {
		my $old_queue_nr = '';
		foreach my $mail (@{$self->mails->{'msg_id'}->{$msg_id}}) {
			$old_queue_nr = $mail->queue_nr;
			$mail->queue_nr($queue_nr);
		}

		# remove old queue_nr mapping
		if ($old_queue_nr) {
			delete $self->mails->{'queue_nr'}->{$old_queue_nr};
		} else {
			debug("Got Message-id $msg_id for mail(s) which do not have an old queue_nr",2);
		}
	}
}

sub clean_mapping {
	my ($self, $mails, $msg_id) = @_;

	if (defined $mails) {
		my $cnt = @$mails;
		foreach my $index (0 .. $cnt-1) {
			my $mail = $mails->[$index];
			if ($mail && $mail->msg_id eq $msg_id) {
				delete $mails->[$index];
			}
		}
	}
	return;
}

sub set_mail_subject {
	my ($self, $queue_nr, $subject) = @_;
	
	debug ("Setting Header Subject for queue-nr: $queue_nr",3);

	unless ($queue_nr) {
		die "Setting Mail Subject: No valid queue_nr \"$queue_nr\" or subject \"$subject\" provided\n";
	}

	if (! $subject)
	{
		debug ("Setting Header Subject to none",1);
		$subject = "none";
	}
	
	if ($self->mails->{'queue_nr'}->{$queue_nr}) {
		foreach my $mail (@{$self->mails->{'queue_nr'}->{$queue_nr}}) {
			$mail->subject($subject) unless $mail->subject;
		}
	} else {
		debug("Got Header subject for queue-nr $queue_nr, but no Mails yet.",2);
		$self->queuenr_to_subject->{$queue_nr} = $subject;
		$self->mails->{'queue_nr'}->{$queue_nr} = [];
	}
}

sub set_mail_amavis_status {
	my ($self, $status, $status_detail, $msg_id, $hits) = @_;

	debug ("Setting Amavis status for msg-id: $msg_id",3);

	if ($self->mails->{'msg_id'}->{$msg_id}) {
		foreach my $mail (@{$self->mails->{'msg_id'}->{$msg_id}}) {
			$mail->amavis_status($status);
			$mail->amavis_hits($hits);
			$mail->amavis_detail($status_detail) if $status_detail;
		}
	}
}

sub set_mail_from_to {
	my ($self, $msg_id, $from, $to) = (shift, shift, lc(shift), lc(shift));

	foreach my $mail (@{$self->mails->{'msg_id'}->{$msg_id}}) {
		$mail->from($from) unless $mail->from;
		$mail->to($to) unless $mail->to;
	}
}

sub mail_accepted {
	my ($self, $msg_id) = @_;

	debug ("Pre-Commit: $msg_id ",3);

	if ($msg_id ne '') {
		if ($self->mails->{'msg_id'}->{$msg_id}) {
			my $mailcount = @{$self->mails->{'msg_id'}->{$msg_id}};
			if ($mailcount > 0) {
				debug ("Accepted [2]: $msg_id has $mailcount mails",4);
				# send the mails to the writer
				my $queue_nr;

				foreach my $mail(@{$self->mails->{'msg_id'}->{$msg_id}}) {   
					$count++;
					$queue_nr = $mail->queue_nr;

					# calculate delay
					my $delay =  tv_interval($mail->received);
					$mail->delay($delay);

					# Mail has to be complete
					if ($mail->complete) {
						debug ("Accepted [3]: mail for $msg_id ist complete",4);
						# send to the writer
						if ($mail->amavis_status =~ qr/Passed/) {
							$self->commit_accepted($mail);
							debug ("$count $msg_id passed",1);
						} elsif ($mail->amavis_status =~ qr/Blocked/) {
							if ($mail->amavis_status =~ qr/INFECTED/) {						
								$self->commit_blocked_virus($mail);
								debug ("$count $msg_id blocked infected",1);

							} elsif ($mail->amavis_status =~ qr/BANNED/) {
								$self->commit_blocked_bannedfile($mail);
								debug ("$count $msg_id blocked banned",1);

							} elsif ($mail->amavis_status =~ qr/SPAM/) {
								$self->commit_blocked_spam($mail);
								debug ("$count $msg_id blocked spam",1);
							}
						}
					} else {
						debug ("Mail is not complete. msgid: $msg_id",2);
					}
				}

				delete $self->mails->{'queue_nr'}->{$queue_nr};
			} else {
				debug ("No Mails for msgid $msg_id found, although there is a hash entry", 2);
				debug ((Dumper $self->mails), 4);
			}

			delete $self->mails->{'msg_id'}->{$msg_id};
		} else {
			debug ("No Mails for msgid $msg_id found", 2);
		}
	}					
}

sub relayed_mail {
	my ($self, $date, $queue_nr, $to, $relay, $status) = @_;

	# sent (250 2.0.0 Ok: queued as DB4738247B)
	if ($status =~ qr/^(\w+)\s\((.+)\)/) {
		my ($relay_status, $relay_msg) = ($1, $2);
		my $mail = new Underground8::Log::Email;

		$mail->received_log($date);
		$mail->queue_nr($queue_nr);
		$mail->to($to);
		$mail->relay($relay);
		$mail->relay_status($relay_status);
		$mail->relay_msg($relay_msg);

		$self->commit_relayed($mail);
	} else {
		debug ("Something with the relay status was wrong!",4);
	}
}


sub sysrtlog($$){
	my ($status, $mail) = @_;
	my $msg;

	if($status eq "RELAYED") {
		return if $mail->from eq "";

		$msg = "RELAYED     " . " by " . $mail->relay
				. " to <" . $mail->to . ">" 
				. ", queuenr=" . $mail->queue_nr
				. ", timestamp=" . $mail->received_log;
	} elsif($status eq "ACCEPTED"){
		$msg = "ACCEPTED    <" . $mail->from . "> -> <" . $mail->to . ">"
			. ", queuenr=" . $mail->queue_nr
			. ", timestamp=" . $mail->received_log
			. ", subject=<" . $mail->subject . ">";
	} elsif($status eq "GREYLISTED"){
		$msg = "GREYLISTED  <" . $mail->from . "> -> <" . $mail->to . ">"
			. ", timestamp=" . $mail->received_log;
	} elsif($status eq "BLACKLISTED"){
		$msg = "BLACKLISTED <" . $mail->from . "> -> <" . $mail->to . ">"
			. ", timestamp=" . $mail->received_log;
	} elsif($status eq "VIRUS_INFECTED"){
		$msg = "VIRUS       <" . $mail->from . "> -> <" . $mail->to . ">"
			. ", queuenr=" . $mail->queue_nr
			. ", timestamp=" . $mail->received_log
			. ", subject=<" . $mail->subject . ">";
	} elsif($status eq "BANNED_ATTACHMENT"){
		$msg = "BANNED_ATT  <" . $mail->from . "> -> <" . $mail->to . ">"
			. ", queuenr=" . $mail->queue_nr
			. ", timestamp=" . $mail->received_log
			. ", subject=<" . $mail->subject . ">";
	} elsif($status eq "SPAM"){
		$msg = "SPAM        <" . $mail->from . "> -> <" . $mail->to . ">"
			. ", queuenr=" . $mail->queue_nr
			. ", timestamp=" . $mail->received_log
			. ", subject=<" . $mail->subject . ">";
	} else {
		return;
	}

	# Slower but more secure
	openlog "simplemail", "ndelay", "local0";
	syslog "info|local0", "mail-status=$msg";
	closelog;
}



sub commit_relayed {
	my ($self, $mail) = @_;
	$self->writer->commit_relayed($mail);
	debug ("**commit_relayed ".$mail->msg_id, 4);
	sysrtlog ("RELAYED", $mail);
}

sub commit_accepted {
	my ($self, $mail) = @_;
	$self->writer->commit_accepted($mail);
	debug ("**commit_accepted ".$mail->msg_id, 4);
	sysrtlog ("ACCEPTED", $mail);
}

sub commit_greylisted {
	my ($self, $mail) = @_;
	$self->writer->commit_greylisted($mail);
	debug ("**commit_greylisted ".$mail->msg_id, 4);
	sysrtlog ("GREYLISTED", $mail);
}

sub commit_blocked_blacklist {
	my ($self, $mail) = @_;
	$self->writer->commit_blocked_blacklist($mail);
	debug ("**commit_blocked_blacklist ".$mail->msg_id, 4);
	sysrtlog ("BLACKLISTED", $mail);
}
 
sub commit_blocked_virus {
	my ($self, $mail) = @_;
	$self->writer->commit_blocked_virus($mail);
	debug ("**commit_blocked_virus ".$mail->msg_id, 4);
	sysrtlog ("VIRUS_INFECTED", $mail);
}

sub commit_blocked_bannedfile {
	my ($self, $mail) = @_;
	$self->writer->commit_blocked_bannedfile($mail);
	debug ("**commit_blocked_bannedfile ".$mail->msg_id, 4);
	sysrtlog ("BANNED_ATTACHMENT", $mail);
}

sub commit_blocked_spam {
	my ($self, $mail) = @_;
	$self->writer->commit_blocked_spam($mail);
	debug ("**commit_blocked_spam ".$mail->msg_id, 4);
	sysrtlog ("SPAM", $mail);
}


# this is teh main logic.
# Since this method makes me have nightmares, be gentle to it.
sub process {
	my ($self, $date, $host, $service, $pid, $message) = @_;
	debug("$service : $message",6);

	### POSTFWD: Recognize Blacklisted, Whitelisted and non-Greylisted accapted mails
	if($service =~ qr/postfwd/){
   		# [RULES] rule=17, id=DUMMY, client=stewie.dev.underground8.com[10.1.60.137], sender=<bla@hellfire.com>, recipient=<user1@starwars.test>, helo=<me>, proto=SMTP, state=RCPT, delay=0s, hits=RBL_LOOKUP;DUMMY, action=DUNNO
		if($message =~ qr/\[.+?\]\srule=\d+?,\sid=.+?,\sclient=.+?\[(\d+\.\d+\.\d+\.\d+)\],\ssender=<(.+?)>,\srecipient=<(.+?)>,\shelo=<.+?>,\sproto=.+?,\sstate=.*/) {
			my ($client_ip, $from, $to) = ($1, $2, $3);
			debug ("postfwd says we have new mail from $from -> $to", 3);

			# Blacklisted
			if($message =~ /id=BL.*/) {
				$self->add_blocked_mail($date, $from, $to, $client_ip, 'blacklist');
			} 
			# Whitelisted
			elsif($message =~ /id=WL.*/){
				$self->add_accepted_mail($date, $from, $to, $client_ip, 'whitelist');
				$self->{'_initialized'} = 1;
			}

			# RBL'ed mails
			elsif($message =~ /id=RBL_ENFORCE.*/){
				$self->add_blocked_mail($date, $from, $to, $client_ip, 'blacklist');
			}

			# Everything except greylisted 
			elsif($message !~ /rc_greylisting/){
				$self->add_accepted_mail($date, $from, $to, $client_ip, 'update');
				$self->{'_initialized'} = 1;
			}
		} 
	}

	### SQLGREY: Recognize newly arrived Greylisted mails, Greylisting-Updates and Greylisting-Abuse
	elsif ($service =~ qr/sqlgrey/) {
		my ($sqlgrey_msg, $type, $client_ip, $from, $to, $module);
		
		# OLD POLICYD:
		# rcpt=13, greylist=update, host=10.2.200.10 (unknown), from=abc@orf.at, to=lol@domain.tld, size==
		#	
		# NEW SQLGREY:
		# sqlgrey: grey: new: 193.99.144(193.99.144.71), emailcheck-robot@ct.de -> hello@spam-me.org
		# sqlgrey: grey: early reconnect: 193.99.144.71(193.99.144.71), emailcheck-robot@ct.de -> hello@spam-me.org
		# sqlgrey: grey: reconnect ok: 193.99.144.71(193.99.144.71), emailcheck-robot@ct.de -> hello@spam-me.org (00:08:17)
		# sqlgrey: grey: from awl: 193.99.144.71, emailcheck-robot@ct.de added
		# sqlgrey: grey: from awl match: updating 193.99.144.71(193.99.144.71), emailcheck-robot@ct.de(emailcheck-robot@ct.de)
		if ($message =~ qr/rcpt=\d+,\s(.+)/) {
			$sqlgrey_msg = $1;
			debug ("sqlgrey msg: $sqlgrey_msg",4);

			# extract data from message
			if ($sqlgrey_msg =~ qr/(module|greylist|type)=(\w+)\,\shost=([\d\.]+)\s\(.+\)\,\sfrom=([\w\d\.\=\-\_\@\<\>]+)\,\sto=([\w\d\.\=\-\_\@]+)\,.+/) {
				($module, $type, $client_ip, $from, $to) = ($1, $2, $3, $4, $5);
				debug ("sqlgrey message arrived ($module=$type)",3);

				$type = 'update' if $type =~ qr/bypass|passthrough/;
				$from = 'MAILER-DAEMON' if $from eq '<>';

				# accepted (whitelisted or greylist update)
				if ($type =~ qr/update/) {
					$self->add_accepted_mail($date, $from, $to, $client_ip, $type);
					$self->{'_initialized'} = 1;
				}
				# temporarily blocked (new greylist, abuse)
				elsif ($type =~ qr/new|abuse/) {
					$self->add_greylisted_mail($date, $from, $to, $client_ip, $type);
				}
			} else {
				debug ("Didn't match sqlgrey regex",3);
			}
		}
	}

	### POSTFIX/SMTPD
	elsif ($service =~ qr/postfix\/smtpd/) {
		# find out queue nr by ip
		#print "$message\n";
		if ($message =~ qr/^([A-F0-9]{8,12}):\sclient=[\d\_\+\w\-.]+\[([0-9\.]+)\]\,?(.*)/) {
			my ($queue_nr, $client_ip, $sasl_text) = ($1, $2, $3);

			if ($sasl_text =~ qr/sasl_method/) {
				$self->add_outgoing_mail($date, $queue_nr, $client_ip);
				$self->{'_initialized'} = 1;
		# } elsif ($self->{'_initialized'}) {  # ORIGINAL
		} else { # THIS IS HIGHLY EXPERIMENTAL
				$self->set_mail_queuenr_ip($queue_nr, $client_ip);
			}	
		}
		#2007-08-03T10:38:37+02:00 kermit postfix/smtpd[17484]: NOQUEUE: warn: RCPT from unknown[10.2.200.134]: ; from=<bobross@gmx.at> to=<matthias@abizzle.net> proto=ESMTP helo=<lol>
		elsif ($message =~ qr/NOQUEUE:\swarn:\sRCPT\sfrom\s[\d\_\+\w\-.]+\[([0-9.]+)\].+from=\<([\w\d\.\-\_\@\=]*)\>\sto=\<([\w\d\.\-\=\_\@]+)\>/) {
			debug("New Mail from Internal Range",2);
			my ($client_ip, $from, $to, $type) = ($1, $2 || 'MAILER-DAEMON', $3, 'outgoing');

			$self->add_accepted_mail($date, $from, $to, $client_ip, $type);
			$self->{'_initialized'} = 1;
		}
		#2008-03-12T10:58:58+01:00 mail postfix/smtpd[24659]: NOQUEUE: reject: RCPT from 148.29.broadband9.iol.cz[90.176.29.148]: 554 5.7.1 Service unavailable; Client host [90.176.29.148] blocked using zen.spamhaus.org; http://www.spamhaus.org/query/bl?ip=90.176.29.148; from=<creaksqe0@tailoredman.com> to=<a.derya@a1container.com> proto=ESMTP helo=<148.29.broadband9.iol.cz>
		elsif ($message =~ qr/NOQUEUE:\sreject:\sRCPT\sfrom\s[\d\_\+\w\-.]+\[([0-9.]+)\].+blocked\susing\s.+from=\<([\w\d\.\-\_\@\=]*)\>\sto=\<([\w\d\.\-\=\_\@]+)\>/) {
			debug("Blocked Mail using dnsrbl",2);
			my ($client_ip, $from, $to, $type) = ($1, $2 || 'MAILER-DAEMON', $3, 'blacklist');

			$self->add_blocked_mail($date, $from, $to, $client_ip, $type); 
		}

	### POSTFIX/SMTP
	} elsif ($service =~ qr/postfix\/smtp/) {
		#postfix/smtp[28482]: EA22782AA5: to=<root@kermit.abizzle.net>, orig_to=<root>, relay=127.0.0.1[127.0.0.1]:10028, delay=0.31, delays=0.07/0/0.02/0.22, dsn=2.6.0, status=sent (250 2.6.0 Ok, id=27947-07, from MTA([127.0.0.1]:10025): 250 2.0.0 Ok: queued as 24F6D82964)
		#postfix/smtp[22427]: B58EA82AA5: to=<matthias@abizzle.net>, relay=10.2.200.16[10.2.200.16]:25, delay=0.3, delays=0.07/0.05/0.08/0.1, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued as 360568247C)

		if ($message =~ qr/^([A-F0-9]{8,12}):\sto=\<([\w\d\.\-\=\_\@]+)\>\,\srelay=([\d\w\.\[\]\:\-\_]+)\,.+status=(.+)$/) {
			my ($queue_nr, $to, $relay, $relay_status) = ($1, $2, $3, $4);

			unless ($relay =~ qr/127\.0\.0\.1/) {
				debug ("Got smtp outgoing message: $queue_nr -> $to, $relay says $relay_status",3);
				$self->relayed_mail($date, $queue_nr, $to, $relay, $relay_status);
			}
		}
	}

	### First Mail already arrived
	elsif($self->{'_initialized'}) {
		### Postfix/Cleanup
		if ($service =~ qr/postfix\/cleanup/) {
			if ($message =~ qr/^([A-F0-9]{8,12}):\smessage-id=<(.+)>/) {
				my ($queue_nr, $message_id) = ($1, $2);
				$self->set_mail_queuenr_msgid($queue_nr, $message_id);
			} elsif ($message =~ qr/^([A-F0-9]{8,12}):\swarning:\sheader\s[Ss]ubject:\s(.+)/) {								  
				debug ("Fetching mail subject",3);
				(my $queue_nr, $message) = ($1, $2);
	
				my $subject;
				if ($message =~ qr/=\?.+?\?.+?\?(.+)(\sfrom\s[\d\w\-\.\_\+]+\[([\d\.])+\]\;.+)$/) {
					$subject = $1;
					$subject =~ s/_//g;
				} elsif ($message =~ qr/(.+)(\sfrom\s[\d\w\-\.\_\+]+\[([\d\.])+\]\;.+)$/) {
					$subject = $1;
				}
				$self->set_mail_subject($queue_nr,$subject);
			}

		### Amavis
		} elsif ($service =~ qr/amavis/) {
			# Message-ID: <20070802162925.22316.qmail@securityfocus.com>, Resent-Message-ID: <20070802210520.999BD2386D
			# amavis[8635]: (08635-04) Passed CLEAN, INTERNAL LOCAL [10.2.200.137] [10.2.200.137] <mp@underground8.com> -> <matthias@pfoetscher.com>, Message-ID: <20080507110111.A30BF82A99@kermit.abizzle.net>, mail_id: reIS9lzRe2WQ, Hits: -, queued_as: 7F3AB82AD0, 367 ms
			$message =~ s/ \(\)//;
			if ($message =~ qr/\(.+\)\s([\w\s]+)(\s\((.+)\))?\,.+\<(.*)\>\s\-\>\s\<(.+)\>.*\,\sMessage-ID:\s\<([\,\|\"\!\§\&\/\?\$\%\w\d\.\@\+\-\_]+)\>.+Hits:\s([\w\d\.\-]+)\,.+/) {
				my ($status, $status_detail, $from, $to, $msg_id, $hits) = ($1, $3, $4, $5, $6, $7);
				debug("amavis: from $from to $to",2);
				
				$self->set_mail_from_to($msg_id,$from,$to);
				$self->set_mail_amavis_status($status,$status_detail,$msg_id,$hits);

				# we have our amavis status, so let's commit our mails
				$self->mail_accepted($msg_id);
			}
		}
	} else {
		debug("not initalized: message from $service",4);
	}
}

sub debug {
	my ($text, $level) = (shift, shift || 1);

	print time2str("%c",time) . " rtlog-listener: $text\n" if $level <= $DEBUG;   
}

sub match {
	my ($self, $service) = @_;
	foreach my $listen_service (@{$self->listen_services}) {
		return 1 if $service eq $listen_service;
	}
	return 0;
}

1;
