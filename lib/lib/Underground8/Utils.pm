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


package Underground8::Utils;
use Carp;
use Error;
use Underground8::Exception::Execution;
use File::Temp qw/ tempdir /;
BEGIN {
    use Exporter ();

    @Underground8::Utils::ISA         = qw(Exporter);
    @Underground8::Utils::EXPORT      = qw(instance safe_system $g mk_tmp_dir);
    @Underground8::Utils::EXPORT_OK   = qw();
}

my $etc = "";
my $bin = "";
my $var = "";
my $www_static = "";
my $user = (getpwuid($<))[0];

if ($ENV{'LIMESLIB'})
{
    my $libpath = $ENV{'LIMESLIB'};
    $etc = "$libpath/etc";
    $bin = "$libpath/bin";    
    $var = "$libpath/etc/";
}
else
{
    $etc = "/etc/open-as-cgw";
    $bin = "/usr/bin";
    $var = "/var/open-as-cgw";
}

if ($ENV{'LIMESGUI'})
{
    my $guipath = $ENV{'LIMESGUI'};
    $www_static = "$guipath/root/static";
}
else
{
    $www_static = "/var/www/LimesGUI/root/static";
}

our $g = {

    # XML
    xml_temp_dir => '/tmp',
    xml_temp_dir_name => 'xml_backupXXXXX',
    extensions_groups => "$etc/conf/groups.xml",  
    rbls_list   =>  "$etc/conf/rbls.xml",
    # Configuration
    cfg_dir =>  "$etc/xml",
    cfg_xml_backup_dir =>  "$etc/xml_backup",

    cfg_antispam =>  "$etc/xml/antispam.xml",
    cfg_system =>  "$etc/xml/system.xml",
    cfg_notification => "$etc/xml/notification.xml",
    cfg_usermaps => "$etc/xml/usermaps.xml",

    cfg_quarantine=> "$etc/xml/quarantine.xml",

	cfg_postfwd => "$etc/xml/postfwd.xml",

    cfg_template_dir => "$etc/cfg-templates",
    cfg_cacert_dir =>  "$etc/cacert",
    cfg_backup_dir => "$var/backup",
    cfg_crypt_key => '17ayo65f1o8ye69r',
   
    cfg_backup_include => "$etc/xml/backup.include",
    cfg_backup_exclude => "$etc/xml/backup.exclude",
                    
    cfg_sn_file => "$etc/sn",
    cfg_vconfig_file => "$etc/conf/vconfig",
    cfg_system_version_file => "$etc/versions",
    cfg_system_version_available_file => "$etc/avail_secversion",
    cfg_update_last_timestamp => "$etc/update_timestamp",
    cfg_system_version_all_file => "$etc/avail_versions",
    cfg_system_version => "1.0",
    cfg_hw_versions => "$etc/conf/hw_versions",

    # Authentication
    file_guipasswd => "$etc/guipasswd",
	cmd_usermod => "/usr/bin/sudo /usr/sbin/usermod",
	cmd_mailq => "/usr/bin/mailq",

    # Files
    file_postfix_transport => '/etc/postfix/transport',
    file_postfix_main => '/etc/postfix/main.cf',
    file_postfix_main_cf => '/etc/postfix/main.cf',
    file_postfix_master_cf => '/etc/postfix/master.cf',
    file_postfix_master => '/etc/postfix/master.cf',
    file_postfix_amavis_bypass_filter => '/etc/postfix/amavis_bypass_filter',
    file_postfix_amavis_bypass_accept => '/etc/postfix/amavis_bypass_accept',
    file_postfix_amavis_senderbypass_accept => '/etc/postfix/amavis_senderbypass_accept',
    file_postfix_amavis_senderbypass_filter => '/etc/postfix/amavis_senderbypass_filter',
    file_postfix_amavis_bypass_internal_filter => '/etc/postfix/amavis_bypass_internal_filter',
    file_postfix_amavis_bypass_internal_warn => '/etc/postfix/amavis_bypass_internal_warn',
    file_postfix_amavis_bypass_internal_accept => '/etc/postfix/amavis_bypass_internal_accept',
    file_postfix_mynetworks => '/etc/postfix/mynetworks',
    file_postfix_local_rcpt_map => '/etc/postfix/local_rcpt_map',
    file_postfix_mbox_transport => '/etc/postfix/mbox_transport',
    file_postfix_virtual_mbox => '/etc/postfix/virtual_mbox',
    file_postfix_virtual_alias => '/etc/postfix/virtual_alias',
    file_postfix_sasl_smtpd_conf => '/etc/postfix/sasl/smtpd.conf',    
    file_postfix_filter_dynip => '/etc/postfix/filter-dynip.pcre',
	file_postfix_header_checks => '/etc/postfix/header_checks',

    file_networking_interfaces => '/etc/network/interfaces',
   
    file_etc_environment => '/etc/environment',
 
    file_resolv => '/etc/resolv.conf',
    file_hosts => '/etc/hosts',
    file_hostname => '/etc/hostname',
    file_mailname => '/etc/mailname',

    file_amavis_15_vs => '/etc/amavis/conf.d/15-av_scanners',
    file_amavis_15_cfm => '/etc/amavis/conf.d/15-content_filter_mode',
    file_amavis_20_dd => '/etc/amavis/conf.d/20-debian_defaults',
    file_amavis_99_openas => '/etc/amavis/conf.d/99-openas',

    file_spamassassin_20_dnsbl_tests => '/var/lib/spamassassin/updates_spamassassin_org/20_dnsbl_tests.cf',
    file_spamassassin_local_cf => '/etc/spamassassin/local.cf',

    file_clamav_clamdconf => "/etc/clamav/clamd.conf",
    file_clamav_freshclamconf => "/etc/clamav/freshclam.conf",  
 
    #file_kaspersky_kavserverconf => '/etc/kav/kav_server.conf',
    #file_kaspersky_kavupdaterconf => '/etc/kav/kav_updater.conf',
    
    file_sqlgrey_conf => '/etc/sqlgrey/sqlgrey.conf',
    file_sqlgrey_default => '/etc/default/sqlgrey',

    file_postfwd_cf => '/etc/postfix/postfwd.cf',
    file_postfwd_default => '/etc/default/postfwd',
    
    file_ntpd_conf => '/etc/ntp.conf',

    file_sasl_conf => '/etc/sasl.cf',

    file_firewall => "$bin/firewall.sh",

    file_mysql => '/etc/mysql/my.cnf',
    file_monit => '/etc/monit/monitrc',
    file_monit_default => '/etc/default/monit',
    
    file_usus_conf => "$etc/conf/usus.conf",

    file_syslogng =>'/etc/syslog-ng/conf.d/open-as-cgw.conf',
    file_syslogng_logrotate => '/etc/logrotate.d/syslog-ng',

    file_quarantine_ng_conf => "$etc/conf/quarantine-ng.conf",
	file_smtpcrypt_conf => "$etc/xml/smtpcrypt.xml",

    file_cpuinfo => '/proc/cpuinfo',

    file_grub_menu_list => '/boot/grub/menu.lst',
    file_lsb_release => '/etc/lsb-release',

    file_virtual_restrictions => "$etc/conf/virtual_restrictions",

    ldap_maps_dir => '/var/cache/ldap/',
    ldap_maps_cache_file => 'ldap_maps.xml',

    usermaps_raw_file => '/etc/postfix/usermaps',

    file_batv_default => '/etc/default/batv-filter',
    file_batv_relay => '/etc/mail/batv-filter.relay',
    file_batv_domains => '/etc/mail/batv-filter.domains',
    file_batv_key => '/etc/mail/batv-filter.key',

    # templates
    template_postfix_amavis_bypass_filter => 'postfix/amavis_bypass_filter.tt2',
    template_postfix_amavis_bypass_accept => 'postfix/amavis_bypass_accept.tt2',
    template_postfix_amavis_senderbypass_accept => 'postfix/amavis_senderbypass_accept.tt2',
    template_postfix_amavis_senderbypass_filter => 'postfix/amavis_senderbypass_filter.tt2',
    template_postfix_amavis_bypass_internal_filter => 'postfix/amavis_bypass_internal_filter.tt2',
    template_postfix_amavis_bypass_internal_warn => 'postfix/amavis_bypass_internal_warn.tt2',
    template_postfix_amavis_bypass_internal_accept => 'postfix/amavis_bypass_internal_accept.tt2',
    template_postfix_mynetworks => 'postfix/mynetworks.tt2',
    template_postfix_main_cf => 'postfix/main_cf.tt2',
    template_postfix_master_cf => 'postfix/master_cf.tt2',
    template_postfix_local_rcpt_map => 'postfix/local_rcpt_map.tt2',
    template_postfix_mbox_transport => 'postfix/mbox_transport.tt2',
    template_postfix_virtual_mbox => 'postfix/virtual_mbox.tt2',
    template_postfix_virtual_alias => 'postfix/virtual_alias.tt2',
    template_postfix_sasl_smtpd_conf => 'postfix/sasl/smtpd.conf.tt2',
    template_postfix_filter_dynip => 'postfix/filter-dynip.pcre.tt2',
	template_postfix_header_checks => 'postfix/header_checks.tt2',

    template_amavis_15_vs => 'amavis/15-av_scanners.tt2',
    template_amavis_15_cfm => 'amavis/15-content_filter_mode.tt2',
    template_amavis_20_dd => 'amavis/20-debian_defaults.tt2',
    template_amavis_99_openas => 'amavis/99-openas.tt2',

    template_sqlgrey_conf => 'sqlgrey/sqlgrey.conf.tt2',
    template_sqlgrey_default => 'sqlgrey/default_sqlgrey.tt2',

    template_postfwd_cf => 'postfwd/postfwd.cf.tt2',
    template_postfwd_default => 'postfwd/default_postfwd.tt2',
    
    template_ntpd_conf => 'ntp-simple/ntp.tt2',

    template_sasl_conf => 'saslauthd/sasl.tt2',

    template_spamassassin_20_dnsbl_tests => 'spamassassin/20_dnsbl_tests.tt2',
    template_spamassassin_local_cf => 'spamassassin/local.cf.tt2',

    template_firewall => 'iptables/firewall.tt2',

    template_mysql => 'mysql/my.cnf.tt2',

    template_monit => 'monit/monitrc.tt2',
    template_monit_default => 'monit/monit-default.tt2',

    template_clamav_clamdconf => 'clamav/clamd.conf.tt2',
    template_clamav_freshclamconf => 'clamav/freshclam.conf.tt2',

    #template_kaspersky_kavserverconf => 'kaspersky/kav_server.conf.tt2',
    #template_kaspersky_kavupdaterconf => 'kaspersky/kav_updater.conf.tt2',

    template_syslogng => 'syslog-ng/open-as-cgw.conf.tt2',
    template_syslogng_logrotate => 'syslog-ng/syslog-ng.logrotate.tt2',

    template_usus_conf => 'usus/usus.conf.tt2',

    template_quarantine_ng_conf => 'quarantine_ng/quarantine_ng_conf.tt2',
    template_email_quarantine_report_html => 'email/quarantine_report_html.tt2',
    template_email_quarantine_report_plain => 'email/quarantine_report_plain.tt2',
    template_email_quarantine_confirmation_html => 'email/quarantine_confirmation_html.tt2',
    template_email_quarantine_confirmation_plain => 'email/quarantine_confirmation_plain.tt2',
    template_email_quarantine_commands_html => 'email/quarantine_commands_html.tt2',
    template_email_quarantine_commands_plain => 'email/quarantine_commands_plain.tt2',
    template_email_quarantine_activate_html => 'email/quarantine_activate_html.tt2',
    template_email_quarantine_activate_plain => 'email/quarantine_activate_plain.tt2',
    template_email_quarantine_disabled_html => 'email/quarantine_disabled_html.tt2',
    template_email_quarantine_disabled_plain => 'email/quarantine_disabled_plain.tt2',
    template_email_quarantine_deactivate_html => 'email/quarantine_deactivate_html.tt2',
    template_email_quarantine_deactivate_plain => 'email/quarantine_deactivate_plain.tt2',

    template_etc_environment => 'proxy/environment.tt2',

    template_grub_menu_list => 'grub/menu.lst.tt2',

    template_batv_default => 'batv-filter/default_batv-filter.tt2',
    template_batv_relay => 'batv-filter/relayhosts.tt2',
    template_batv_domains => 'batv-filter/domains.tt2',
    template_batv_key => 'batv-filter/batv-filter.key.tt2',

	template_snmpd_conf => 'net-snmp/snmpd.conf.tt2',
	template_snmpd_default => 'net-snmp/snmpd_default.tt2',


    # Command
    cmd_iptables_stop => '/usr/bin/sudo /etc/init.d/openas-firewall stop',
    cmd_iptables_start => '/usr/bin/sudo /etc/init.d/openas-firewall start',

    cmd_reboot => "/usr/bin/sudo $bin/haltreboot.pl reboot",
    cmd_shutdown => "/usr/bin/sudo $bin/haltreboot.pl halt",
                    
    cmd_postfix_start => '/usr/bin/sudo /etc/init.d/postfix start',
    cmd_postfix_stop => '/usr/bin/sudo /etc/init.d/postfix stop',
    cmd_postfix_restart => '/usr/bin/sudo /etc/init.d/postfix restart',
    cmd_postfix_reload => '/usr/bin/sudo /etc/init.d/postfix reload',
    cmd_postfix_postmap => '/usr/bin/sudo /usr/sbin/postmap',
    cmd_postfix_postconf => '/usr/bin/sudo /usr/sbin/postconf',
    cmd_postfix_check => '/usr/bin/sudo /etc/init.d/postfix check',

    cmd_batv_restart => '/usr/bin/sudo /etc/init.d/batv-filter restart >/dev/null 2>&1',
    
    cmd_ntpd_start => '/usr/bin/sudo /etc/init.d/ntp start',
    cmd_ntpd_stop => '/usr/bin/sudo /etc/init.d/ntp stop',
    cmd_ntpd_restart => '/usr/bin/sudo /etc/init.d/ntp restart',
   
 
    cmd_network_ifup => '/usr/bin/sudo /sbin/ifup',
    cmd_network_ifdown => '/usr/bin/sudo /sbin/ifdown',
    cmd_network_route => '/usr/bin/sudo /sbin/route',
    cmd_network_restart => "$bin/restart_network.pl",
    
    cmd_hostname_change => '/usr/bin/sudo /usr/bin/hostnamectl set-hostname', 
    cmd_dnsmasq_restart => '/usr/bin/sudo /etc/init.d/dnsmasq restart',

    cmd_amavis_restart => '/usr/bin/sudo /etc/init.d/amavis restart',        
    cmd_amavis_release => '/usr/bin/sudo /usr/sbin/amavisd-release ',
    cmd_quarantine_cron_restart => '/usr/bin/sudo /etc/init.d/openas-qcron restart',        
    cmd_quarantine_ng_restart => '/usr/bin/sudo /etc/init.d/openas-qng restart',        
    
    cmd_sqlgrey_start => '/usr/bin/sudo /usr/sbin/service sqlgrey start',
    cmd_sqlgrey_stop => '/usr/bin/sudo /usr/sbin/service sqlgrey stop',
    cmd_sqlgrey_restart => '/usr/bin/sudo /usr/sbin/service sqlgrey restart',
    cmd_sqlgrey_reload => '/usr/bin/sudo /usr/sbin/service sqlgrey reload',    

    cmd_postfwd_start => '/usr/bin/sudo /etc/init.d/postfwd start',
    cmd_postfwd_stop => '/usr/bin/sudo /etc/init.d/postfwd stop',
    cmd_postfwd_restart => '/usr/bin/sudo /etc/init.d/postfwd restart',
    cmd_postfwd_kill => '/usr/bin/sudo /usr/bin/killall postfwd',
    cmd_postfwd_reload => '/usr/bin/sudo /etc/init.d/postfwd reload',
    
    cmd_rtlogd_restart => '/usr/bin/sudo /etc/init.d/openas-rtlogd restart',

    cmd_saslauthd_stop => '/usr/bin/sudo /etc/init.d/saslauthd stop',
    cmd_saslauthd_start=> '/usr/bin/sudo /etc/init.d/saslauthd start',

    cmd_saslauthd_sym_delete => '/usr/bin/sudo /usr/sbin/update-rc.d -f saslauthd remove',
    cmd_saslauthd_sym_create => '/usr/bin/sudo /usr/sbin/update-rc.d saslauthd start 20 2 3 4 5 . start 20 6 . stop 20 1 .',

    cmd_revoke_network_settings => "$bin/revoke_networksettings.pl",
    cmd_revoke_firewall_settings => "$bin/revoke_firewallsettings.pl",

    cmd_webserver_restart => '/usr/bin/sudo /etc/init.d/nginx restart',

    cmd_usus => "/usr/bin/sudo /usr/bin/nohup $bin/usus.pl",
    cmd_dpkg => '/usr/bin/dpkg',

    cmd_ls_timezones => '/bin/ls -1 /usr/share/zoneinfo/',
    cmd_crontab =>  '/usr/bin/crontab',

    cmd_rm_tmp => '/bin/rm -rf /tmp/*',
    
    cmd_chown => "/usr/bin/sudo /bin/chown $user:$user",

    cmd_uniq => '/usr/bin/uniq',
    cmd_wc => '/usr/bin/wc',
	cmd_ps => '/bin/ps axu',
	cmd_ps_hierachical => '/bin/ps axuf',

    # LEGACY: pre-lucid, pre-upstart
    #cmd_mysql_stop => '/usr/bin/sudo /etc/init.d/mysql stop',
    #cmd_mysql_start => '/usr/bin/sudo /etc/init.d/mysql start',
    #cmd_mysql_restart => '/usr/bin/sudo /etc/init.d/mysql restart',
    cmd_mysql_stop => '/usr/bin/sudo /usr/sbin/service mysql stop',
    cmd_mysql_start => '/usr/bin/sudo /usr/sbin/service mysql start',
    cmd_mysql_restart => '/usr/bin/sudo /usr/sbin/service mysql restart',

    cmd_monit_stop => '/usr/bin/sudo /etc/init.d/monit stop',
    cmd_monit_start => '/usr/bin/sudo /etc/init.d/monit start',
    cmd_monit_restart => '/usr/bin/sudo /etc/init.d/monit restart',
    cmd_monit_perm_addgrp => '/usr/bin/sudo /bin/chmod g+rw /etc/monit/monitrc',
    cmd_monit_perm_delgrp => '/usr/bin/sudo /bin/chmod g-rw /etc/monit/monitrc',


    cmd_syslogng_stop => '/usr/bin/sudo /usr/sbin/service syslog-ng stop',
    cmd_syslogng_start => '/usr/bin/sudo /usr/sbin/service syslog-ng start',
    cmd_syslogng_restart => '/usr/bin/sudo /usr/sbin/service syslog-ng restart',

	cmd_snmp_stop => '/usr/bin/sudo /etc/init.d/snmpd stop',
	cmd_snmp_start => '/usr/bin/sudo /etc/init.d/snmpd start',
	cmd_snmp_restart => '/usr/bin/sudo /etc/init.d/snmpd restart',


    cmd_resetter_statistics => "/usr/bin/sudo /$bin/resetter.pl --quiet --statistics",
    cmd_resetter_soft => "/usr/bin/sudo $bin/resetter.pl --quiet --soft",
    cmd_resetter_hard => "/usr/bin/sudo $bin/resetter.pl --quiet --hard",

	cmd_sshd_start => '/usr/bin/sudo /etc/init.d/sshd start',
	cmd_sshd_stop => '/usr/bin/sudo /etc/init.d/sshd stop',
	cmd_sshd_restart => '/usr/bin/sudo /etc/init.d/sshd restart',

    cmd_grub_update => '/usr/bin/sudo $bin/update-grub.sh >/dev/null 2>&1',
    cmd_blkid => '/usr/bin/sudo /sbin/blkid',

    cmd_vmware_toolbox_cmd => '/usr/bin/sudo /usr/bin/vmware-toolbox-cmd',

    # Reports
    cmd_clamav_version => '/usr/sbin/clamd --v',
    cmd_clamav_restart => '/usr/bin/sudo /etc/init.d/clamav-daemon restart',
    cmd_clamav_freshclam_restart => '/usr/bin/sudo /etc/init.d/clamav-freshclam restart',

    #cmd_kaspersky_kavserver_restart => '/usr/bin/sudo /etc/init.d/kav-server restart',
    cmd_sambucus_server_restart => '/usr/bin/sudo /etc/init.d/sambucus restart',

    file_spamassassin_version => '/var/lib/spamassassin/updates_spamassassin_org.cf',

    file_snmpd_conf => '/etc/snmp/snmpd.conf',
    file_snmpd_default => '/etc/default/snmpd',

    file_amcharts_data_path => "$www_static/amcharts/data/",
    template_amcharts_data_path => "amcharts/",
    
    file_amcharts_mail_traffic_data => "$www_static/amcharts/data/mail_traffic_data.xml",
    template_amcharts_mail_traffic_data => "amcharts/mail_traffic_data.tt2",
    
    cmd_tar => '/bin/tar',
    cmd_gzip => '/bin/gzip',
    cmd_gunzip => '/bin/gunzip',
    cmd_cp => '/bin/cp',
    cmd_rm => '/bin/rm',
    cmd_mv => '/bin/mv',
    cmd_openssl => '/usr/bin/openssl',
    cmd_grep => '/bin/grep',
    cmd_cat => '/bin/cat',
    cmd_sed => '/bin/sed',
    cmd_ping => '/bin/ping',

    cmd_uname_r => '/bin/uname -r',

    mail_chart_livelog_interval => 60,
    mail_chart_hourlog_interval => 3600,
    mail_chart_daylog_interval => 86400,

    # Network
    net_if0 =>  'eth3',

    # MailQ
    mailq_purge_command => '/usr/sbin/postqueue -f',

    # Databases
    rt_log_mysql_username => 'rt_log',
    rt_log_mysql_password => 'rt_log',
    rt_log_mysql_database => 'rt_log',
    rt_log_mysql_hostname => 'localhost',

    # email templates
    template_email_daily_spam_report_plain => 'email/daily_spam_report_plain.tt2',
    template_email_daily_spam_report_html => 'email/daily_spam_report_html.tt2',

    # ssl
    ca_certificates => '/etc/ssl/certs/ca-certificates.crt',

    # log download
    mail_log => '/var/log/open-as-cgw/mangled-mail.log',
    log_dir => '/root/static/log/',
	mailsimple_log => '/var/log/mail-simple.log',
	ascgw_log => '/var/log/ascgw.log',

    # mime types
    mime_types => '/etc/mime.types',
    mime_types_amavis => "$etc/conf/mime.types.amavis",


	# This is for senseless obscurity in WebGUI process list... get rid of it
	# substitution and delete masks for process list
	process_substitutions => {
		'master' => 'mail-daemon',
		'sqlgrey.*' => 'greylisting-daemon',
		'amavisd' => 'mail-processing-engine',
		'limesgui.*' => 'AS interface-daemon',
		'clamd.*' => 'antivirus-engine',
		'freshclam.*' => 'antivirus-update-daemon',
		'munin.*' => 'backend-logging-daemon',
		'monit.*' => 'process-watcher',
		'saslauthd.*' => 'authentication-daemon',
		'syslog.*' => 'logging-daemon',
		'rtlog.*' => 'realtime-logging-daemon',
		'LCDd.*' => 'hwevent-daemon',
		'snmp_agent.*' => 'u8-antispam-engine',
		'mysql.*' => 'database-engine',
		'aveserver.*' => 'kaspersky-antivirus',
		'keepup2date.*' => 'kaspersky-upate-engine',
		'qmgr.*' => 'maild-qmgr',
		'dnsmasq.*' => 'dns-forwarder',
		'pickup.*' => 'maild-mail-pickup',
		'smtpd.*' => 'maild-smtpd',
		'anvil.*' => 'maild-statistics-daemon',
		'showq.*' => 'maild-status-daemon',
		'logger.*' => 'logging-client',
		'quarantine.*' => 'quarantine-control-daemon',
		'(^cron|^CRON)' => 'recurrence-daemon',
		'postfwd .*' => 'smtp-firewall',
	},

	# Processes not to be shown in WebGUI process list
	process_deletemask => '(getty|\[.*\]|sshd:|.*login.*|.*bash.*|launch\.pl|postfwd:.*)',

	cmd_logging_space => '/usr/bin/du -sh /var/log | awk \'{print $1}\'',
	cmd_quarantine_space => '/usr/bin/du -sh /var/quarantine | awk \'{print $1}\'',

    available_mail_types => [qw(passed_clean passed_spam blocked_spam blocked_greylisted blocked_blacklisted blocked_virus blocked_banned)],
};



sub instance ($@)
{
    my $self = shift;
    if (ref $self)
    {
        if (@_)
        {
            my $package = shift;
            return $self if $self->isa($package);
			carp "\$self is of type " . ( ref $self ) . " instead of $package!";
        }
        else
        {
            return $self;
        }
    }
    carp "Method must be called on an instance!";
}

sub safe_system ($@)
{
    my $cmd = shift;
    my @valid_codes = (@_)?@_:(0);

    local $SIG{'CHLD'} = '';
    my $output = qx/$cmd/;
    my $exitcode = $? >> 8;

    foreach my $code (@valid_codes)
    {
        if ($exitcode == $code)
        {
	    if( wantarray ) {
		return ( $exitcode, $output);
	    } else {
        	return $output;
	    }
        }
    }
    throw Underground8::Exception::Execution($cmd,$exitcode,$output);
}


# First argument acts as switch for return value (seconds vs dd/hh/mm/ss)
sub time_diff ($%) {
    my $human_readable = shift;
	  my %args = @_; 
	  my @offset_days = qw(0 31 59 90 120 151 181 212 243 273 304 334);

	  my $year1  = substr($args{'date1'}, 0, 4); 
	  my $month1 = substr($args{'date1'}, 5, 2); 
	  my $day1   = substr($args{'date1'}, 8, 2); 
	  my $hh1    = substr($args{'date1'},11, 2) || 0;
		my $mm1    = substr($args{'date1'},14, 2) || 0;
		my $ss1    = substr($args{'date1'},17, 2) if (length($args{'date1'}) > 16);
		$ss1  ||= 0;

		my $year2  = substr($args{'date2'}, 0, 4); 
		my $month2 = substr($args{'date2'}, 5, 2); 
		my $day2   = substr($args{'date2'}, 8, 2); 
		my $hh2    = substr($args{'date2'},11, 2) || 0;
		my $mm2    = substr($args{'date2'},14, 2) || 0;
		my $ss2    = substr($args{'date2'},17, 2) if (length($args{'date2'}) > 16);
		$ss2  ||= 0;

		my $total_days1 = $offset_days[$month1 - 1] + $day1 + 365 * $year1;
		my $total_days2 = $offset_days[$month2 - 1] + $day2 + 365 * $year2;
		my $days_diff   = $total_days2 - $total_days1;

		my $seconds1 = $total_days1 * 86400 + $hh1 * 3600 + $mm1 * 60 + $ss1;
		my $seconds2 = $total_days2 * 86400 + $hh2 * 3600 + $mm2 * 60 + $ss2;

		my $ssDiff = $seconds2 - $seconds1;
		return $ssDiff if !$human_readable;

		my $dd     = int($ssDiff / 86400);
		my $hh     = int($ssDiff /  3600) - $dd *    24; 
		my $mm     = int($ssDiff /    60) - $dd *  1440 - $hh *   60; 
		my $ss     = int($ssDiff /     1) - $dd * 86400 - $hh * 3600 - $mm * 60; 

		return ($dd,$hh,$mm,$ss);
}

sub get_process_substitutions {
	return $g->{'process_substitutions'};
}

sub get_process_deletemask {
	return $g->{'process_deletemask'};
}

sub get_localtime
{
    my @date = localtime();
    return (sprintf "%04d.%02d.%02d_%02d-%02d-%02d", ($date[5] + 1900), ($date[4]+1), $date[3], $date[2], $date[1], $date[0]);
}

sub mk_tmp_dir ($$)
{
    my $tmp_dir_name = shift;
    my $tmp_dir_path = shift;
    
    my $dir = tempdir($tmp_dir_name,DIR=>$tmp_dir_path) or throw Underground8::Exception("FATAL ERROR: Please reboot Appliance");
    
    return $dir;
}

1;
