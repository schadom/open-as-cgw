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


package Underground8::Appliance::LimesAS;
use base Underground8::Appliance;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Configuration::LimesAS::System;
use Underground8::Configuration::LimesAS::Quarantine;
use Underground8::Configuration::LimesAS::Antispam;
use Underground8::Configuration::LimesAS::Notification;
use Underground8::Configuration::LimesAS::Backup;
use Underground8::Configuration::LimesAS::MailQ;
use Underground8::ReportFactory::LimesAS;
#use Underground8::Configuration::LimesAS::Notification;
#use Underground8::Configuration::LimesAS::Logging;

# Constructor
sub new ($@)
{
    my $class = shift;
    my $self = $class->SUPER::new('LimesAS');
    
    $self->{'_system'} = new Underground8::Configuration::LimesAS::System($self);
    $self->{'_antispam'} = new Underground8::Configuration::LimesAS::Antispam($self);
    $self->{'_quarantine'} = new Underground8::Configuration::LimesAS::Quarantine($self);
    $self->{'_notification'} = new Underground8::Configuration::LimesAS::Notification($self);
    $self->{'_backup'} = new Underground8::Configuration::LimesAS::Backup($self);
    $self->{'_mailq'} = new Underground8::Configuration::LimesAS::MailQ($self);
    $self->{'_reportfactory'} = new Underground8::ReportFactory::LimesAS;
    #$self->{'_notification'} = new Underground8::Configuration::LimesAS::Notification();
    #$self->{'_logging'} = new Underground8::Configuration::LimesAS::Logging();

    return $self;
}

#### Accessors ####

sub system ($)
{
    my $self = instance(shift);
    return $self->{'_system'};
}

sub antispam ($)
{
    my $self = instance(shift);
    return $self->{'_antispam'};
}

sub quarantine ($)
{
    my $self = instance(shift);
    return $self->{'_quarantine'};
}

sub notification ($)
{
    my $self = instance(shift);
    return $self->{'_notification'};
}

sub backup ($)
{
    my $self = instance(shift);
    return $self->{'_backup'};
}

sub mailq ($)
{
    my $self = instance(shift);
    return $self->{'_mailq'};
}

sub report ($)
{
    my $self = instance(shift);
    return $self->{'_reportfactory'};
}

sub commit ($)
{
    my $self = instance(shift);
    $self->system->commit();
    print STDERR "SYSTEM commit done.\n";
    
    # some components like mysql need time to start up
    sleep(3);

    $self->antispam->commit();
    print STDERR "ANTISPAM commit done.\n";
    $self->notification->commit();
    print STDERR "NOTIFICATION commit done.\n";
    $self->quarantine->commit();
    print STDERR "QUARANTINE commit done.\n";
    $self->backup->commit();
    print STDERR "BACKUP commit done.\n";
}

sub load_config ($)
{
    my $self = instance(shift);
    if(-e $g->{'cfg_antispam'} && -s $g->{'cfg_antispam'} && 
       -e $g->{'cfg_system'} && -s $g->{'cfg_system'} && 
       # may not exist - but this is ok... create empty file then in quarantine load_config
       # -e $g->{'cfg_quarantine'} && -s $g->{'cfg_quarantine'} && 
       -e $g->{'cfg_notification'} && -s $g->{'cfg_notification'} &&
       -e $self->backup->config_filename() && -s $self->backup->config_filename() &&
       -e $g->{'cfg_backup_include'} && -s $g->{'cfg_backup_include'} &&
       -e $g->{'cfg_backup_exclude'} && -s $g->{'cfg_backup_exclude'}
    )
    {
    	$self->antispam->load_config();
        $self->system->load_config();
        $self->notification->load_config();
	    $self->backup->load_config();
        $self->quarantine->load_config();
    }
    else
    {
        safe_system("$g->{'cmd_cp'} $g->{'cfg_xml_backup_dir'}/* $g->{'cfg_dir'}");
        safe_system("$g->{'cmd_chown'} $g->{'cfg_dir'}/*");
	    $self->antispam->load_config();
        $self->system->load_config();
        $self->notification->load_config();
	    $self->backup->restore_defaults();
        $self->quarantine->load_config();
        
    }
}

1;
