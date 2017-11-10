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


package LimesGUI::I18N::en;
use base 'LimesGUI::I18N';

our %Lexicon = 
(
_AUTO => 1,
# BASIC
browser_title => 'Open AS Communication Gateway&trade;',
no_javascript => 'Looks like you have JavaScript disabled!',
turn_on_javascript => 'Since the Open AS Communication Gateway&trade; provides you with a rich user experience, we recommend you to use an up-to-date version of your favourite browser.</p><p>Additionally we need you to enable JavaScript. To do so, please follow the instructions for your browser.',

# LOGIN
error_bad_login => "Invalid username or password",
error_session_logged_out => "Your session has expired. Due to security reasons you've been logged out",

# NAVIGATION
nav_dashboard => 'Dashboard',
nav_dashboard_dashboard => 'Dashboard',

nav_system => 'System',
nav_system_general_settings => 'General Settings',
nav_system_time_settings => 'Time Settings',
nav_system_remote_assistance => 'Remote Assistance',
nav_system_network => 'Network',
nav_system_security => 'Security',
nav_system_update => 'Update',
nav_system_backup_manager => 'Backup Manager',
nav_system_user => 'User',
nav_system_syslog => 'Syslog',
nav_system_notifications => 'Notifications',

nav_monitoring => 'Monitoring',
nav_monitoring_diagnostics_center => 'Diagnostics Center',
nav_monitoring_process_list => 'Process List',
nav_monitoring_connection_status => 'Connection Status',
nav_monitoring_ping_trace => 'Ping/Trace',
nav_monitoring_mail_queue => 'Mail Queue',
nav_monitoring_testing => 'Testing',

nav_mail_transfer => 'Mail Transfer',
nav_mail_transfer_smtp_servers => 'SMTP Servers',
nav_mail_transfer_domains => 'Domains',
nav_mail_transfer_recipients => 'Recipients',
nav_mail_transfer_smtp_settings => 'SMTP Settings',
nav_mail_transfer_relay_hosts => 'Mail Relay Hosts',

nav_envelope_scanning => 'Envelope Scanning',
nav_envelope_scanning_envelope_processing => 'Envelope Processing',
nav_envelope_scanning_dnsl_manager => 'DNS List Manager',
nav_envelope_scanning_bwlist_manager => 'Black-/Whitelist Manager',

nav_content_scanning => 'Content Scanning',
nav_content_scanning_policies => 'Policies',
nav_content_scanning_attachments => 'Attachments',
nav_content_scanning_anti_virus => 'Anti-Virus Settings',
nav_content_scanning_spam_handling => 'Spam Handling',
nav_content_scanning_languages => 'Language Filtering',

nav_quarantine => 'Quarantine',
nav_quarantine_general_settings => 'General Settings',
nav_quarantine_quarantining_options => 'Quarantining Options',
nav_quarantine_box_status_management => 'Box Status Management',
nav_quarantine_user_box_administration=> 'User\'s Box Administration',

nav_logging => 'Logging',
nav_logging_live_log => 'Live Log',
nav_logging_log_viewer => 'Log Viewer',
nav_logging_maillog_simple => 'Simple Mail-Log',
nav_logging_statistics => 'Statistics',
nav_logging_syslog => 'Syslog',

nav_modules => 'Modules',
nav_modules_licence_management => 'Licence Management',
nav_modules_email_encryption => 'E-Mail Encryption',

nav_logout => 'logout',

# COMPONENT - AMCHART
amchart_export => 'save chart as image',
amchart_last_24h => 'last 24h',
amchart_last_week => 'last week',
amchart_last_month => 'last month',
amchart_last_year => 'last year',

# TEMPLATE TEXT FOR AUTOMIZATION
## STATUS BAR HEADINGS
heading_error_status => 'Error',
heading_info_status => 'Info',
heading_success_status => 'Success',
heading_warning_status => 'Attention!',


# TEXT IN CONTENT 
## GENERAL WORDS - unsorted
as_communication_gateway => 'Open AS Communication Gateway&trade;',
attention => 'Attention',
hostname => 'Hostname',
domainname => 'Domainname',
email_address => 'E-mail address',
email => 'E-Mail',
phone => 'Phone',
update => 'Update',
problem_description => 'Problem Description',
reset => 'reset',
ping => 'Ping',
accept => 'accept',
notify => 'notify',
protocol => 'Protocol',
choose => 'Choose',
proceed => 'Proceed',
english => 'English',
german => 'German',
save_settings => 'save settings',
enable => 'enable',
disable => 'disable',
enabled => 'enabled',
disabled => 'disabled',
description => 'Description',
no_entries => 'No entries found.',
install => 'install',
delete => 'delete',
download => 'download',
cacert => 'CA certificate',
user => 'User',
days => 'days',
day	=> 'day',
more => 'more',
harddisk => 'Harddisk',
memory => 'Memory (RAM)',
swap => 'Swap',
add => 'Add',
or => 'or',
action => 'Action',
current_status => 'Current status',
sorry => 'Sorry',
username => 'Username',
activate => 'Activate',
banned => 'Banned',
blacklisted => 'Blacklisted',
cancel => 'Cancel',
close => 'Close',
greylisted => 'Greylisted',
login => 'Account',
move => 'Move',
no => 'no',
yes => 'yes',
spam => 'Spam',
revoke => 'Revoke',
save => 'Save',
perform_action => 'Perform Action',
totals => 'Totals',
addserver => 'Server address',
backup_file => 'Backup file',

## GENERAL WORDS - time related
daily => 'daily',
hours => 'hours',
day_hours => 'time of day',
week_days => 'week days',
day_mon => 'monday',
day_tue => 'tuesday',
day_wed => 'wedndesday',
day_thu => 'thursday',
day_fri => 'friday',
day_sat => 'saturday',
day_sun => 'sunday',

## GENERAL WORDS - user account related



## GENERAL WORDS - infobar error-message related
single_missing => ' is missing. ',
multiple_missing => ' are missing. ',
single_invalid => ' is invalid. ',
multiple_invalid => ' are invalid. ',
and => 'and',



###################################################################################
### ************************** NEW_GUI I18N SCHEME **************************** ###
###################################################################################


### DASHBOARD :: DASHBOARD 
toggle_widget => 'toggle widget',
dashboard_dashboard_abstract => 'This page displays a summary of interesting information about your Open AS Communication Gateway.',
dashboard_dashboard_appliance_status_heading => 'System Information',
dashboard_dashboard_service_status_heading => 'Service Status',
dashboard_dashboard_mailtraffic_stats_heading => 'E-Mail Statistics',
dashboard_dashboard_notifications_heading => 'Notifications',
dashboard_dashboard_quicklinks_heading => 'Quicklinks',
dashboard_dashboard_support_heading => 'Support',

### DASHBOARD :: NOTIFICATION
dashboard_notification_notify_password_heading => 'Default Password',
dashboard_notification_notify_password => 'Your password is still factory-default. As a matter of security, please change your password!<br/><br/>',
dashboard_notification_notify_ip_heading => 'Confirm new IP address',
dashboard_notification_notify_ip => 'The IP address of your appliance has been changed. Please proceed to apply changes permanently.',

dashboard_dashboard_mail_traffic_type_of_mail => 'Type of e-mail',
dashboard_dashboard_mail_traffic_all_time => 'all time',
dashboard_dashboard_mail_traffic_today => 'today',
dashboard_dashboard_mail_traffic_last_24h => 'last 24 h',
dashboard_dashboard_mail_traffic_last_h => 'last hour',
dashboard_dashboard_mail_traffic_type_passed_clean => 'Passed (clean)',
dashboard_dashboard_mail_traffic_type_passed_spam => 'Passed (tagged as spam)',
dashboard_dashboard_mail_traffic_type_blocked_spam => 'Blocked (spam)',
dashboard_dashboard_mail_traffic_type_blocked_greylisted => 'Blocked (greylisted)',
dashboard_dashboard_mail_traffic_type_blocked_blacklisted => 'Blocked (blacklisted)',
dashboard_dashboard_mail_traffic_type_blocked_virus => 'Blocked (virus mail)',
dashboard_dashboard_mail_traffic_type_blocked_banned => 'Blocked (banned attachment)',

dashboard_dashboard_workflow_heading => '',

dashboard_dashboard_service_status_antispam => 'Anti-Spam Engine',
dashboard_dashboard_service_status_antivirus => 'Anti-Virus Engine',
dashboard_dashboard_service_status_mailagent => 'Mail Transfer Agent',
dashboard_dashboard_service_status_database => 'Database Engine',
dashboard_dashboard_service_status_logging => 'Mail Logging Engine',
dashboard_dashboard_service_status_smtpauth => 'SMTP Authentication Proxy',

dashboard_dashboard_appliance_status_sn => 'Serial Number',
dashboard_dashboard_appliance_status_product => 'Product',
dashboard_dashboard_appliance_status_version => 'Firmware version',
dashboard_dashboard_appliance_status_avgcpu => 'Avg. CPU Usage <em>(last 1h)</em>',
dashboard_dashboard_appliance_status_avgmem => 'Memory Usage',
dashboard_dashboard_appliance_status_avgload => 'Load Average <em>(last 15min)</em>',
dashboard_dashboard_appliance_status_hdd => 'Harddisk Usage',
dashboard_dashboard_appliance_status_uptime => 'System Uptime',

dashboard_dashboard_quicklinks_newsmtp => 'add a new SMTP server',
dashboard_dashboard_quicklinks_newdomain => 'add a new domain',
dashboard_dashboard_quicklinks_bwlist => 'edit e-mail/IP Black-/Whitelists',
dashboard_dashboard_quicklinks_greylisting => 'change greylisting settings',
dashboard_dashboard_quicklinks_diagnostics => 'perform self-diagnostics',
dashboard_dashboard_quicklinks_policies => 'administer scanning policy settings',
dashboard_dashboard_quicklinks_quarantine => 'open quarantine box status manager',
dashboard_dashboard_quicklinks_livelog => 'trace realtime mail-flow',
dashboard_dashboard_quicklinks_licences => 'manage your licences',

dashboard_dashboard_notifications_getupdate_heading => 'New updates',
dashboard_dashboard_notifications_getupdate => 'Get the latest update now!',

dashboard_dashboard_notifications_reboot_required_heading => 'Restart required',
dashboard_dashboard_notifications_reboot_required => 'A Restart of the System to complete the last update is necessary',

dashboard_dashboard_notifications_renew_licence_heading => 'Renew licence',
dashboard_dashboard_notifications_renew_licence => 'One or more of your licences are to expire soon - please renew them as soon as possible.',

dashboard_dashboard_notifications_licence_expired_heading => 'Licence(s) expired!',
dashboard_dashboard_notifications_licence_expired => 'One or more licences have expired! Please renew them immediately.',

dashboard_dashboard_notifications_no_smtp_servers_heading => 'No SMTP servers defined',
dashboard_dashboard_notifications_no_smtp_servers => 'You do not have any SMTP servers defined yet. Please to go <em>Mail Transfer - SMTP Servers</em> to do so.',

dashboard_dashboard_notifications_no_domains_heading => 'No domains defined',
dashboard_dashboard_notifications_no_domains => 'You do not have any domains defined yet. Please go to <em>Mail Transfer - Domains</em> and create at least one new domain and associate it with an SMTP server.',

dashboard_dashboard_notifications_high_mailq_level_heading => 'High Mailqueue Level',
dashboard_dashboard_notifications_high_mailq_level => 'The appliance\'s mail-queue is on a very high level (this is not necessarily bad, but you may have a look).',

dashboard_dashboard_notifications_update_running_heading => 'Update in progress',
dashboard_dashboard_notifications_update_running => 'The appliance is currently upgrading its firmware. <strong>Do not switch off power supply</strong> or prematurely reboot the appliance.',

dashboard_dashboard_notifications_default_text_heading => 'Everything\'s fine',
dashboard_dashboard_notifications_default_text => 'Your appliance is correctly up and running.',

dashboard_dashboard_support_text => 'If you have any questions or need help with something, please visit the project web-page at <a href="https://openas.org">https://openas.org</a>',


### SYSTEM :: GENERAL SETTINGS
system_general_settings_abstract => 'This configuration page offers you a comprehensive overview of the currently installed component and system versions. Furthermore you can restart, shutdown or reset the appliance.',
system_general_settings_version_heading => 'Installed Software versions',
system_general_settings_reboot_shutdown_heading => 'Reboot or shutdown the appliance',
system_general_settings_reboot_shutdown_reboot => 'Reboot the appliance',
system_general_settings_reboot_shutdown_shutdown => 'Shutdown the appliance',
system_general_settings_reboot_shutdown_action => 'Choose action',

is_shutting_down => 'The appliance is shuting down now.',
shutdown_action_message => 'Do you really want to shutdown your Open AS Communication Gateway?',
reboot_action_message => 'Do you really want to restart your Open AS Communication Gateway?',
reboot => 'Restart',
is_rebooting => 'The appliance is rebooting now.',
shutdown => 'Shutdown',

system_general_settings_reset_heading => 'Reset the appliance',
system_general_settings_reset_reset_statistics => 'Statistics only',
system_general_settings_reset_reset_soft => 'Soft Reset',
system_general_settings_reset_reset_hard => 'Hard Reset',
system_general_settings_reset_type => 'Choose reset level',
system_general_settings_reset_statistics_text => 'Delete mail statistics and livelog. Settings, backups, mailqueue items and downloadable logfiles are kept unchanged.',
system_general_settings_reset_soft_text => 'Reset configuration to factory default, delete mail statistics and livelog. The downloadable logfiles, backups and mailqueue contents are kept unchanged. The IP will be reset and the appliance will reboot.',
system_general_settings_reset_hard_text => 'Completely set the appliance back to factory default. All statistics, backups, logfiles, settings and all current mailqueue items are deleted. The IP will be reset and the appliance will reboot. USE WITH CARE!',
system_general_settings_reset_redirect_text => 'Resetting the appliance',
reset_statistics => 'Reset Statistics',
reset_soft => 'Reset (Soft)',
reset_hard => 'Reset (Hard)',
reset_statistics_action_message => 'All mail statistics and livelog information will be reseted. If you proceed you will be logged out from your current session.',
reset_soft_action_message => 'The configuration will be set back to factory defaults. If you proceed you will be logged out from your current session and the appliance initiates a reboot. After restarting the factory default IP address will be <strong>192.168.0.100</strong>.',
reset_hard_action_message => 'The configuration will be set back to factory defaults and all user-generated files, like logs and backups, will be deleted. If you proceed you will be logged out from your current session and the appliance initiates a reboot. After restarting the factory default IP address will be <strong>192.168.0.100</strong>.',

### SYSTEM :: REMOTE ASSISTANCE
system_remote_assistance_abstract => 'Administer all settings relating to remote assistance of your Open AS Communication Gateway.',
system_remote_assistance_ssh_heading => 'Secure Shell Service',
system_remote_assistance_ssh_text => '<strong>SSH</strong> enables you to utilize <em>Emergency Commands</em> and it will always listen on port 22/tcp. In addition, you may also enable SSH to listen on port 22/tcp. The SSH service can be used in conjuction with Emergency Commands, managable under <em>System - User</em>.',
system_remote_assistance_ssh_ssh => 'Listen on port 22/tcp',
system_remote_assistance_ssh_status_set => 'The new setting has been applied.',
system_remote_assistance_snmp_heading => 'SNMP MONITORING',
system_remote_assistance_snmp_status => 'Enable SNMP agent',
system_remote_assistance_snmp_text => '<strong>SNMP</strong> gives you the possibility to proactively monitor certain system stages concerning your Open AS Communication Gateway&trade;, as well as asyncronously receiving messages upon occurence of common events (so called <em>traps</em>).',
system_remote_assistance_snmp_location => 'System location',
system_remote_assistance_snmp_community => 'Community string',
system_remote_assistance_snmp_network => 'Network <em>(CIDR)</em>',
system_remote_assistance_snmp_contact => 'System contact',
system_remote_assistance_snmp_success => 'Your SNMP settings have been successfully applied.',

### SYSTEM :: UPDATE
system_update_abstract => 'Set Up2Date settings and update your appliance here.',
system_update_settings_heading => 'Up2Date Settings: Automatically...',
system_update_upgrade_info_heading => 'Version upgrade information',
system_update_upgrade_table_heading => 'Available system version updates',
system_update_upgrade_info_latest_security_update_info => 'With this button the installation of the latest security update begins. If it was already downloaded, the installation starts right away - otherwise the necessary update packages are downloaded first.',
system_update_upgrade_info_updates_automated => 'Security Updates automated',
system_update_upgrade_info_updates_automated_text => => 'Your Open AS Communication Gateway&trade; is automatically updated with the latest available security updates for your current system version. <em>New features have to be installed manually!</em>',
system_update_upgrade_info_latest_security_update => 'Get the latest available Security Update!',
system_update_upgrade_info_system_updates_automated => 'System Updates automated',
system_update_upgrade_info_system_updates_automated_text	=> 'Your system is automatically updated with the latest security and system updates provided by the Up2Date Service. <em>Major New Releases still have to be installed manually!</em>',
system_update_upgrade_info_up_to_date => 'The current system version is up-to-date',
system_update_upgrade_info_button_upgrade => 'Upgrade',

system_update_versions_heading => 'System and security versions at a glance',
system_update_versions_checkforupdates => 'Check for updates',
system_update_settings_update_automation_settings => 'Up2Date Settings: Automatically...',
system_update_settings_automation_settings_configured => 'Up2Date Settings updated',
system_update_oss_heading => 'Sorry, upgrades are not yet supported',
system_update_oss_unavailable => 'Sorry, system upgrades are not yet supported in the open-source version at the moment. <b>Use aptitude in the shell to update the packages!</b>',

### SYSTEM :: SECURITY
system_security_abstract => 'To restrict access to the management interface of this appliance you can define IP ranges which are allowed to manage this device. Other source IP addresses will be blocked from accessing the management frontend.',
system_security_adm_form_heading => 'Add administration IP range',
system_security_adm_form_text => '<strong>Attention:</strong> In case you don\'t define an administration range, <em>all</em> connections to the Open AS Communication Gateway&trade; <em>will be allowed</em> - despite its origin (this is NOT recommended).',
system_security_adm_form_range_start => 'Range Start',
system_security_adm_form_range_end => 'Range End',
system_security_adm_form_description => 'Description',
system_security_adm_form_success => 'Administration IP range has been successfully added.',

system_security_adm_table_heading => 'Currently defined administration IP ranges',
system_security_adm_table_noentries => 'There are currently no administration ranges configured .',
system_security_adm_table_range => 'IP Range',
system_security_adm_table_description => 'Description',
system_security_adm_table_action => 'Action',
system_security_adm_table_delete => 'Delete',

system_security_ca_assign_heading => 'Assign CA certificate to Mailserver',
system_security_ca_assign_text => '<strong>Note:</strong> SMTP servers providing SMTP-Authentication may be forced only to accept certificates of known CAs. Here, you may assign an additional CA certificate to a certain SMTP server.',
system_security_ca_assign_file_pem => 'Certificate <em>(.CRT/.PEM file)</em>',
system_security_ca_assign_smtpsrv => 'SMTP server',
system_security_ca_assign_applycert => 'Assign certificate',
system_security_ca_assign_success => 'CA Certificate successfully assigned to Mailserver',

system_security_ca_unassign_heading => 'Revoke Mailserver CA certificate',
system_security_ca_unassign_text => '<strong>Note:</strong> If you have already assigned a CA certificate to be used with a certain SMTP server, you may revoke it here.',
system_security_ca_unassign_smtpsrv => 'SMTP server',
system_security_ca_unassign_revokecert => 'Revoke certificate',
system_security_ca_unassign_unassign => 'Successfully removed any certificates from given mailserver configuration.',
system_security_ca_unassign_success_unassign => 'Successfully removed any certificates from given mailserver configuration.',

system_security_revoke_keypair_heading => 'Assign keypair to Open AS Communication Gateway&trade;',
system_security_revoke_keypair_file_cert => 'Certificate <em>(.CRT/.PEM file)</em>',
system_security_revoke_keypair_file_key => 'Private key <em>(.KEY file)</em>',
system_security_revoke_keypair_text => '<strong>Note:</strong> Here you can upload a cryptographic certificate and a corresponding private key in order to keep communication between the Open AS Communication Gateway&trade; and foreign SMTP servers secured by SSL. You may also ',
system_security_revoke_keypair_applykeypair => 'Assign keypair',
system_security_revoke_keypair_delkeypair => 'revoke any existing keypair',
system_security_revoke_keypair_success_keypair_assign => 'Keypair successfully assigned to Open AS Communication Gateway MTA (will now offer TLS)',


### SYSTEM :: TIME-SETTINGS
system_time_settings_abstract => 'You can use this management page to configure your current timezone and your prefered time synchronization servers.',
system_time_settings_timezone_heading => 'Timezone',
system_time_settings_timezone_timezone => 'Select your timezone',
system_time_settings_timezone_status_updated => 'The timezone has been set.',

system_time_settings_ntp_heading => 'Time Synchronization Servers',
system_time_settings_ntp_addserver => 'Add a new NTP Server',
system_time_settings_ntp_server => 'NTP Server #',
system_time_settings_ntp_status_set => 'NTP settings have been applied.',


### SYSTEM :: NETWORK
system_network_abstract => 'Administer the IP, DNS and proxy settings of your appliance. Changing the IP address requires to re-login into the GUI and confirmation. Otherwise the old IP configuration will be restored after 10 minutes.',
system_network_hostname_heading => 'Host- and Domainname Settings',
system_network_hostname_hostname => 'Hostname',
system_network_hostname_domainname => 'Domainname',
system_network_hostname_status_updated => 'The new settings have been applied.',

system_network_ip_heading => 'IP Configuration',
system_network_ip_ip_address => 'IP Address',
system_network_ip_subnet_mask => 'Subnet Mask',
system_network_ip_default_gateway => 'Default Gateway',
system_network_ip_status_set => 'The new IP address has been set.',
system_network_ip_err_subnet => 'The defined gateway is not in the same subnet as the given IP address.',

system_network_ip_notification_heading => 'Confirm IP address change',
system_network_ip_notification_text => 'The IP address of your appliance will be changed and your management session will be closed. If you proceed you have to <strong>login within the next 5 minutes</strong>. Otherwise your previous network settings will be restored. This step is necessary to prevent you from locking yourself out!',
system_network_ip_notification_link_text => 'Proceed',
system_network_ip_redirect_text => 'Redirecting to: ',

system_network_dns_heading => 'DNS Configuration',
system_network_dns_primary_dns => 'Primary DNS Server',
system_network_dns_secondary_dns => 'Secondary DNS Server',
system_network_dns_status_set => 'The DNS servers have been set.',

system_network_proxy_heading => 'Proxy Configuration',
system_network_proxy_proxy_server => 'Proxy Server',
system_network_proxy_proxy_port => 'Proxy Port',
system_network_proxy_proxy_username => 'Proxy Username',
system_network_proxy_proxy_password => 'Proxy Password',
system_network_proxy_proxy_enabled => 'Proxy enabled',
system_network_proxy_status_set => 'Proxy settings have been applied.',
system_network_proxy_text => '<strong>Note:</strong> If applicable, do not forget to add correct prefixes (e.g. http://) in front of your proxy server address. Remeber to check the <em>enabled</em> checkbox in order to utilize the proxy server.',

system_network_adminranges_heading => 'Administration IP Ranges',


### SYSTEM :: BACKUP MANAGER
system_backup_manager_abstract => 'Backup and restore the configuration of the Open AS Communication Gateway&trade;. You can either download the configuration as an ecrypted file to your local drive, or upload a previously stored backup file.',
system_backup_manager_create_heading => 'Create a backup',
system_backup_manager_create_create => 'Create',
system_backup_manager_list_heading => 'Available backups',
system_backup_manager_list_filename => 'Backup file',
system_backup_manager_list_action => 'Action',
system_backup_manager_list_install => 'install',
system_backup_manager_list_save => 'Save',
system_backup_manager_list_success => 'Successfully deleted selected backup',
system_backup_manager_list_delete => 'delete',
system_backup_manager_list_available_text => '<strong>Note:</strong> Here you can find find a complete list of all currently available backups from certain points in time. You may install, delete or download backups through the links within the <em>Action</em> column.</p><p class="info"><strong>Warning:</strong> If you decide to <em>install</em> a previously created backup, the appliance will immediately enforce a system reboot!',
system_backup_manager_create_success => 'New backup has been created successfully.',
system_backup_manager_list_download => 'download',
system_backup_manager_list_noentries => 'There are currently no available pre-created backups. You must either create a new backup using the button above, or upload an existing backup file.',

system_backup_manager_upload_heading => 'Upload backup-file',
system_backup_manager_upload_text => '<strong>Note:</strong> You can upload a previously downloaded encrypted backup-file in order to re-initialize its contents and add the backup into the list of backups shown above. Just uploading a backup <em>will not</em> install the backup.',
system_backup_manager_upload_backup => 'Encrypted backup file',
system_backup_manager_upload_upload => 'Upload backup',


### SYSTEM :: USER
system_user_abstract => 'Change the password for the current user. Your new password must contain at least 8 characters, including at least 1 digit and 1 special character out of the following list: ! @ % - _ . : , ; # + *',
system_user_pw_gui_heading => 'Set the password currently logged-in user',

system_user_pw_gui_username => 'Username',
system_user_pw_gui_pw_current => 'Current password',
system_user_pw_gui_pw_new => 'New password',
system_user_pw_gui_pw_new_verify => 'Re-type new password',
system_user_pw_gui_success => 'Password has been successfully changed',
system_user_pw_gui_error_password_invalid => 'The old password is invalid.',
system_user_pw_gui_error_newpass_nomatch => 'The passwords don\'t match.',
system_user_pw_gui_error_newpass_insecure => 'Your new password must contain at least 8 characters, including at least 1 digit and 1 special character out of the following list: !@%-_.:,;#+*',


#### SYSTEM :: SYSLOG
logging_syslog_abstract => 'Configure an external syslog server, the Open AS Communication Gateway&trade; will forward all log messages to.',
logging_syslog_remote_heading => 'Remote Syslog service',
logging_syslog_remote_host => 'Syslog host',
logging_syslog_remote_port => 'Port',
logging_syslog_remote_proto => 'Protocol',
logging_syslog_remote_enabled => 'Enabled',
logging_syslog_remote_success => 'Successfully saved syslog settings.',
logging_syslog_remote_note=> '<strong>Note:</strong> Do not forget to check the <em>enabled</em> checkbox in order to activate external syslog logging.',


#### SYSTEM :: NOTIFICATIONS
system_notifications_abstract => 'The administrator may define a list of e-mail addresses the Open AS Communication Gateway&trade; will send its notification e-mails to. The most common notification is the Daily Appliance Report, offering daily spam statistics and the appliance health status.',
system_notifications_add_heading => 'Add new or update existing recipient for System Notifications',
system_notifications_add_email => 'E-Mail Address',
system_notifications_add_smtpsrv => 'SMTP Server',
system_notifications_add_name => 'Name',
system_notifications_add_login => 'SMTP Login',
system_notifications_add_password => 'SMTP Password',
system_notifications_add_usetls => 'Use TLS',
system_notifications_add_add => 'Add',
system_notifications_add_success => 'New recipient address has been successfully added to notification list.',
system_notifications_add_error => 'Error adding recipient address to notification list.',
system_notifications_add_text => '<strong>Note:</strong> The easiest way in order to add a new recipient for system notifications is to simply provide an e-mail address and the corresponding name of the recipient. If you want to send the notifications for a specific recipient through an SMTP server not managed by the Open AS Communication Gateway&trade;, you may also enter an alternate server address.',

system_notifications_list_heading => 'Administer current list of notification recipients',
system_notifications_list_email => 'E-Mail Address',
system_notifications_list_smtpsrv => 'SMTP Server',
system_notifications_list_name => 'Name',
system_notifications_list_login => 'SMTP Login',
system_notifications_list_password => 'SMTP Password',
system_notifications_list_usetls => 'Use TLS',
system_notifications_list_delete => 'delete',
system_notifications_list_del_success => 'Successfully removed recipient from notification list.',
system_notifications_list_del_error => 'Error removing recipient from notification list.',
system_notifications_list_save => 'Save',
system_notifications_list_edit => 'edit',
system_notifications_list_action => 'Action',
system_notifications_list_empty => 'There are currently no recipients addresses defined to send system notifications and appliance reports to.',


#### MONITORING :: DIAGNOSTICS_CENTER
monitoring_diagnostics_center_abstract => 'The Diagnostics Center provides information of the current system status and offers the possibility to autonomously self-analyse your current configuration.',
monitoring_diagnostics_center_system_status_heading => 'System status',
monitoring_diagnostics_center_self_diagnostics_heading => 'Configuration diagnostics overview',
monitoring_diagnostics_center_self_diagnostics_text => 'Click the <em>Perform Diagnostics</em> button to start the self-diagnostics process. Depending on your configuration (number of SMTP servers, configured domains, etc.), this procedure may take up to a few minutes.',
monitoring_diagnostics_center_self_diagnostics_start => 'Perform diagnostics',
monitoring_diagnostics_center_self_diagnostics_rerun => 'Rerun diagnostics',
monitoring_diagnostics_center_self_diagnostics_network                     => 'Network configuration',
monitoring_diagnostics_center_self_diagnostics_host_reachable              => '<span class="success">Found</span>',
monitoring_diagnostics_center_self_diagnostics_host_unreachable            => '<span class="error">Unreachable</span>',
monitoring_diagnostics_center_self_diagnostics_dns_query_ok                => '<span class="success">Query successful</span>',
monitoring_diagnostics_center_self_diagnostics_dns_query_error             => '<span class="error">Unable to query DNS server</span>',
monitoring_diagnostics_center_self_diagnostics_self_lookup                 => 'Appliance DNS lookup',
monitoring_diagnostics_center_self_diagnostics_self_lookup_ok_single       => '<span class="success">Successfully resolved</span>',
monitoring_diagnostics_center_self_diagnostics_self_lookup_ok_multiple     => '<span class="warning">One of multiple DNS replies succeeded</span>',
monitoring_diagnostics_center_self_diagnostics_self_lookup_err_not_found   => '<span class="error">Failed (No A-record found)</span>',
monitoring_diagnostics_center_self_diagnostics_self_rlookup                => 'Appliance reverse DNS lookup',
monitoring_diagnostics_center_self_diagnostics_self_rlookup_ok             => '<span class="success">Successfully resolved</span>',
monitoring_diagnostics_center_self_diagnostics_self_rlookup_err_no_match   => '<span class="warning">Doesn\'t point to correct hostname</span>',
monitoring_diagnostics_center_self_diagnostics_self_rlookup_err            => '<span class="error">Reverse lookup failed</span>',
monitoring_diagnostics_center_self_diagnostics_lastupdate_ts               => 'Current version information',
monitoring_diagnostics_center_self_diagnostics_lastupdate_ts_outdated      => '<span class="error">Older than 1 hour</span>',
monitoring_diagnostics_center_self_diagnostics_lastupdate_ts_fresh         => '<span class="success">Up to date</span>',
monitoring_diagnostics_center_self_diagnostics_configured_smtp_servers     => 'Configured SMTP mailservers',
monitoring_diagnostics_center_self_diagnostics_no_smtp_servers_configured  => 'You havn\'t configured any SMTP servers yet',
monitoring_diagnostics_center_self_diagnostics_service_unreachable         => '<span class="error">No mailserver response</span>',
monitoring_diagnostics_center_self_diagnostics_service_reachable           => '<span class="success">Service ready</span>',
monitoring_diagnostics_center_self_diagnostics_configured_domains          => 'Configured mail domains',
monitoring_diagnostics_center_self_diagnostics_no_domains_configured       => 'You havn\'t configured any domains yet',
monitoring_diagnostics_center_self_diagnostics_domain_mx_ok_single         => '<span class="success">MX record valid, reverse-lookup succeeded</span>',
monitoring_diagnostics_center_self_diagnostics_domain_mx_ok_multiple       => '<span class="warning">One of multiple MX records valid</span>',
monitoring_diagnostics_center_self_diagnostics_domain_mx_ok_single_norl    => '<span class="warning">MX record valid, but reverse lookup failed</span>',
monitoring_diagnostics_center_self_diagnostics_domain_mx_ok_multiple_norl  => '<span class="warning">One of multiple MX records valid, but reverse lookup failed</span>',
monitoring_diagnostics_center_self_diagnostics_domain_mx_error             => '<span class="error">MX record doesn\'t point to AS appliance</span>',

monitoring_diagnostics_center_system_status_harddisk                       => 'Harddisk',
monitoring_diagnostics_center_system_status_memory                         => 'Memory (RAM)',
monitoring_diagnostics_center_system_status_swap                           => 'Swap',
monitoring_diagnostics_center_system_status_logging_space                  => 'Logs',
monitoring_diagnostics_center_system_status_quarantine_space               => 'Quarantine',

### MONITORING :: PROCESS_LIST
monitoring_process_list_plist_heading                                     => 'Process list',
monitoring_process_list_abstract                                          => 'Shows all currently running processes on the Open AS Communication Gateway&trade;, including the corresponding process IDs, CPU- and memory usages. The list is consecutively refreshed.',

### MONITORING :: CONNECTION_STATUS
monitoring_connection_status_abstract                                     => 'Shows all currently active network connections.',

### MONITORING :: PING_TRACE
monitoring_ping_trace_abstract                                             => 'The network diagnostics tools Ping and Traceroute may help you discover network and connectivity problems.',
monitoring_ping_trace_ping_heading                                         => 'Ping host',
monitoring_ping_trace_ping_hostname                                        => 'Hostname/IP',
monitoring_ping_trace_ping_success_text                                    => ' (%s) successfully responded to ICMP echo request in %.2fms with %d%% packet loss.',
monitoring_ping_trace_ping_success                                         => 'ICMP Echo Response successfully received.',
monitoring_ping_trace_ping_failure                                         => ' didn\'t respond to ping request.',

monitoring_ping_trace_trace_heading                                        => 'Traceroute host',
monitoring_ping_trace_trace_hostname                                       => 'Hostname/IP',
monitoring_ping_trace_trace_success                                        => 'Traceroute finished successfully.',
monitoring_ping_trace_trace_error                                          => 'Traceroute to given host did not succeed.',
monitoring_ping_trace_trace_noreverselookup                                => 'No reverse lookup',
monitoring_ping_trace_trace_result                                         => 'Tracing result for ',
monitoring_ping_trace_trace_hop                                            => 'Hop',
monitoring_ping_trace_trace_router                                         => 'Router',
monitoring_ping_trace_trace_time                                           => 'Time (s)',


### MONITORING :: MAIL_QUEUE
monitoring_mail_queue_abstract                                            => 'The mail-queue takes care of incoming mails and queues them persistently until they have been completely and successfully processed.',
monitoring_mail_queue_stats_success                                       => 'Mail-queue successfully flushed.',
monitoring_mail_queue_stats_heading                                       => 'Flush Mail-Queue',
monitoring_mail_queue_stats_text => 'By pressing the button below, you may flush the contents of the mail queue. Flushing the queue means, to proactively force the Open AS Communication Gateway to deliver all mails in the queue. This mainly affects mails for which delivery has been deferred for some reason (e.g. the remote SMTP server is not responding). In such cases, delivery is re-attempted after a certain period of time automatically, or may be enforced manually here.<br/><br/><strong>Note: </strong>Flushing the mail-queue does, by design, not guarantee that mails actually <i>can</i> be delivered.',
monitoring_mail_queue_stats_mailcount                                     => 'Current number of mails in the queue',
monitoring_mail_queue_stats_queuesize                                     => 'Current size of the queue',
monitoring_mail_queue_stats_flush                                         => 'Flush queue',
monitoring_mail_queue_list_heading                                        => 'Current mail-queue content',
monitoring_mail_queue_list_queuenr                                        => 'Queue ID',
monitoring_mail_queue_list_queue                                          => 'Queue',
monitoring_mail_queue_list_size                                           => 'Size',
monitoring_mail_queue_list_datetime                                       => 'Time of arrival',
monitoring_mail_queue_list_sender                                         => 'Sender',
monitoring_mail_queue_list_recipients                                     => 'Recipient(s)',
monitoring_mail_queue_list_noentries                                      => 'The mail queue is currently empty.',


### MONITORING :: TESTING
monitoring_testing_abstract                                               => 'These settings allow you to enforce certain testing routines for your Open AS Communication Gateway&trade; in order to ensure correct operating behavior.',
monitoring_testing_spam_heading                                           => 'Spam test settings',
monitoring_testing_spam_gtube_string                                      => 'Spam test string',
monitoring_testing_spam_gtube_score                                       => 'Attributed spam score',
monitoring_testing_spam_success                                           => 'Spam test settings successfully saved.',
monitoring_testing_spam_error                                             => 'Error saving spam test settings.',


### ENVELOPE_SCANNING :: BWLIST_MANAGER
envelope_scanning_bwlist_manager_abstract                                => 'Enable, disable and administer IP-, mail-address-, and domain-based black- and whitelisting.',
envelope_scanning_bwlist_manager_control_heading                         => 'Control center',
envelope_scanning_bwlist_manager_control_status                          => 'Current engine status',
envelope_scanning_bwlist_manager_blacklist_heading                       => 'Blacklist',
envelope_scanning_bwlist_manager_whitelist_heading                       => 'Whitelist',
envelope_scanning_bwlist_manager_control_addnew_text                     => 'The <em>Entry</em> field may contain IP addresses, CIDR addresses, hyphenated IP ranges, e-mail addresses, hostnames and domain names. Moreover, you may use an asterisk (*) as wildcard for mail and domain addresses.',
envelope_scanning_bwlist_manager_control_addnew_desc                     => 'Description',
envelope_scanning_bwlist_manager_control_addnew_entry                    => 'Entry',
envelope_scanning_bwlist_manager_control_addnew_modality                 => 'Modality',
envelope_scanning_bwlist_manager_control_addnew_blacklist                => 'Add to Blacklist',
envelope_scanning_bwlist_manager_control_addnew_whitelist                => 'Add to Whitelist',
envelope_scanning_bwlist_manager_control_addnew_success                  => 'New entry has been successfully added.',
envelope_scanning_bwlist_manager_control_addnew_formaterror              => 'Unrecognized entry format.',
envelope_scanning_bwlist_manager_control_enabled                         => 'The Black-/Whitelist Manager has been successfully activated.',
envelope_scanning_bwlist_manager_control_disabled                        => 'The Black-/Whitelist Manager has been successfully deactivated.',

envelope_scanning_bwlist_manager_blacklist_text                          => 'The blacklist policy ensures that e-mails originating from certain domains, hosts, IPs or networks are not accepted by the Open AS Communication Gateway&trade; (unless a there is a whitelist-entry, since these are processed in advance).',
envelope_scanning_bwlist_manager_blacklist_entry                         => 'Entry',
envelope_scanning_bwlist_manager_blacklist_type                          => 'Type',
envelope_scanning_bwlist_manager_blacklist_description                   => 'Description',
envelope_scanning_bwlist_manager_blacklist_delete                        => 'remove',
envelope_scanning_bwlist_manager_blacklist_action                        => 'Action',
envelope_scanning_bwlist_manager_blacklist_noentries                     => 'There are currently no blacklisted addresses or domains defined.',
envelope_scanning_bwlist_manager_blacklist_del_success                   => 'Selected entry has been successfully removed.',
envelope_scanning_bwlist_manager_blacklist_del_error                     => 'Unable to delete selected entry.',

envelope_scanning_bwlist_manager_whitelist_text                          => 'The whitelist policy ensures that e-mails originating from certain domains, hosts, IPs or networks are always accepted by the Open AS Communication Gateway.',
envelope_scanning_bwlist_manager_whitelist_entry                         => 'Entry',
envelope_scanning_bwlist_manager_whitelist_type                          => 'Type',
envelope_scanning_bwlist_manager_whitelist_description                   => 'Description',
envelope_scanning_bwlist_manager_whitelist_delete                        => 'remove',
envelope_scanning_bwlist_manager_whitelist_action                        => 'Action',
envelope_scanning_bwlist_manager_whitelist_noentries                     => 'There are currently no whitelisted addresses or domains defined.',
envelope_scanning_bwlist_manager_whitelist_del_success                   => 'Selected entry has been successfully removed.',
envelope_scanning_bwlist_manager_whitelist_del_error                     => 'Unable to delete selected entry.',
envelope_scanning_bwlist_manager_disabled                                => 'The black-/whitelisting engine is currently disabled.',


### ENVELOPE_SCANNING :: ENVELOPE_PROCESSING
envelope_scanning_envelope_processing_abstract                          => 'Administer mail-envelope based scanning techniques.',
envelope_scanning_envelope_processing_greylisting_heading               => 'Greylisting',
envelope_scanning_envelope_processing_greylisting_basic_greylisting     => 'Basic Greylisting',
envelope_scanning_envelope_processing_greylisting_botnet_blocker        => 'Selective Greylisting',
envelope_scanning_envelope_processing_greylisting_greylisting_enable_success        => 'Greylisting has been successfully enabled.',
envelope_scanning_envelope_processing_greylisting_greylisting_disable_success       => 'Greylisting has been successfully disabled.',
envelope_scanning_envelope_processing_greylisting_botnetblocker_enable_success      => 'Botnet Blocker has been successfully enabled.',
envelope_scanning_envelope_processing_greylisting_botnetblocker_disable_success     => 'Botnet Blocker has been successfully disabled.',
envelope_scanning_envelope_processing_greylisting_message   => 'Greylisting reject text',
envelope_scanning_envelope_processing_greylisting_authtime   => 'Authentication time <em>(days)</em>',
envelope_scanning_envelope_processing_greylisting_domainlevel   => 'Domain-level whitelist required <em>(mails)</em>',
envelope_scanning_envelope_processing_greylisting_triplettime   => 'Greylisting delay time <em>(min)</em>',
envelope_scanning_envelope_processing_greylisting_connectage   => 'Max reconnect time <em>(hours)</em>',
envelope_scanning_envelope_processing_greylisting_success => 'New greylisting parameters have been successfully applied.',


### CONTENT_SCANNING :: POLICIES
content_scanning_policies_abstract => 'This page gives you the possibility to precisely define the way how incoming e-mails are processed and content scanned, depending on their origin.',
content_scanning_policies_scanning_policy_heading => 'Scanning policy',
content_scanning_policies_scanning_policy_type => 'Mail origin/Threat type',
content_scanning_policies_scanning_policy_origin_extern => 'Default',
content_scanning_policies_scanning_policy_origin_relayhosts => 'Relay hosts',
content_scanning_policies_scanning_policy_origin_whitelist => 'Whitelisted hosts',
content_scanning_policies_scanning_policy_origin_smtpauth => 'SMTP authenticated users',
content_scanning_policies_scanning_policy_type_spam => 'Scan for spam',
content_scanning_policies_scanning_policy_type_virus => 'Scan for viruses',
content_scanning_policies_scanning_policy_type_att => 'Scan for banned attachments',
content_scanning_policies_scanning_policy_success => 'Newly configured scanning policy settings have successfully been applied.',

content_scanning_languages_abstract => 'With language-based spam filtering, it\'s easily possible to eliminate spam consisting of unwanted languages or characters.',
content_scanning_languages_language_filter_heading => 'Language filtering',
content_scanning_languages_language_filter_text => 'If enabled, the language filtering engine lets you configure which languages you want to receive mails composed in. If the language of an e-mail cannot precisely be determined, the mail is going to be processed as normal. A mail consisting of any disallowed language will drastically higher the mail\'s spam score and, therefore, raise chances for the mail to become treated as spam.',
content_scanning_languages_language_filter_success => 'Newly configured language preferences have been successfully saved.',
content_scanning_languages_language_filter_status => 'Language filtering engine status',
content_scanning_languages_language_filter_langs => 'Allowed languages',

### CONTENT_SCANNING :: ATTACHMENTS
content_scanning_attachments_abstract => 'Administer recipient warnings on e-mails containing viruses or banned attachments and define file extensions which should be blocked.',

content_scanning_attachments_warnings_heading => 'Recipient Warnings',
content_scanning_attachments_warnings_virus => 'Warn on virus',
content_scanning_attachments_warnings_virus_enabled => 'Recipients will be warned on viruses.',
content_scanning_attachments_warnings_virus_disabled => 'Recipients will not be warned on viruses.',
content_scanning_attachments_warnings_banned => 'Warn on banned files',
content_scanning_attachments_warnings_banned_enabled => 'Recipients will be warned on banned files.',
content_scanning_attachments_warnings_banned_disabled => 'Recipients will not be warned on banned files.',

content_scanning_attachments_block_file_extensions_heading => 'Block attachments by file extension',
content_scanning_attachments_block_file_extensions_success => 'Successfully added file extension to attachment blocking list.',
content_scanning_attachments_block_mime_types_heading => 'Block attachments by MIME type',

content_scanning_attachments_group_heading => 'Block filetypes by groups',
content_scanning_attachments_group_error_entry_exists => 'Content MIME-type entry already exists in Configured Block Rules list.',
content_scanning_attachments_group_success => 'Filetype-group blocking rules successfully updated.',
content_scanning_attachments_group_text => 'Within this section, you may choose filetypes out from various different filetype groups, such as Executables, Multimedia and Archives.',

content_scanning_attachments_list_heading => 'Configured block rules overview',
content_scanning_attachments_list_text => 'Below, you\'ll find a list of all blocking rules (including file extensions, content-types and group-types) currently active. Manually added file extension block rules may be deleted directly within the table below.',
content_scanning_attachments_list_noentries => 'There are currently no attachment types configured to be blocked.',
content_scanning_attachments_list_entry => 'Blocked extension/Content-type',
content_scanning_attachments_list_description => 'Description',
content_scanning_attachments_list_action => 'Action',
content_scanning_attachments_list_entry => 'Configured block rules',
content_scanning_attachments_list_delete => 'Delete',
content_scanning_attachments_list_success => 'Successfully deleted given attachment type from blocking list.',

content_scanning_attachments_block_file_extensions_extension => 'File extension',
content_scanning_attachments_block_file_extensions_desc => 'Blocking description',
content_scanning_attachments_block_file_extensions_text => 'You may enter an arbitrary file extension which is going to be blocked after adding the newly defined rule. Note that this check can only be done on <em>filenames</em>, not on its content.',

content_scanning_attachments_block_mime_types_text => 'The list below shows all blockable MIME content-types. Check all boxes of types <em>which should be blocked</em>. Upon saving, the chosen entries are shown on the <em>Configured Block Rules</em> list. If you want to unblock certain content-types, simply deselect the corresponding checkbox and reapply the new settings.',
content_scanning_attachments_block_mime_types_error_entry_exists => 'Content MIME-type entry already exists in Configured Block Rules list.',
content_scanning_attachments_block_mime_types_success => 'MIME-type blocking rules successfully updated.',

content_scanning_attachments_custom_section_file_extension => 'Block by file extension',
content_scanning_attachments_custom_section_mime_types => 'Block by MIME type',
content_scanning_attachments_custom_content_types => 'MIME type to block',


### CONTENT_SCANNING :: ANTI_VIRUS
content_scanning_anti_virus_abstract => 'Choose the antivirus engine(s) and calibrate settings regarding archive scanning.',
content_scanning_anti_virus_scanners_heading => 'Anti-virus scanning engines',
content_scanning_anti_virus_options_heading => 'Archive scanning options',

content_scanning_anti_virus_scanners_text => 'All available anti-virus engines are listed below. You may separately en- or disable certain engines, according to your currently active licenses.',
content_scanning_anti_virus_scanners_clamav => 'Clam Anti-Virus Engine',
content_scanning_anti_virus_scanners_kav => 'Kaspersky Anti-Virus Engine',
content_scanning_anti_virus_scanners_success => 'Newly configured anti-virus engine settings have been successfully applied.',
content_scanning_anti_virus_scanners_locked_noup2date => 'No license available in the open-source version',

content_scanning_anti_virus_options_unchecked_tag => 'Unchecked subject tag',
content_scanning_anti_virus_options_recursion_level => 'Recursion level',
content_scanning_anti_virus_options_max_archive_files => 'Max. number of files in archive',
content_scanning_anti_virus_options_max_archive_size => 'Max. archive size <em>(MB)</em>',
content_scanning_anti_virus_options_success => 'Newly configured anti-virus options have been successfully applied.',


### CONTENT_SCANNING :: SPAM HANDLING
content_scanning_spam_handling_abstract => 'Modify the score settings for each policy category. To change a value, simply type the preferred scoring into the corresponding input field. Your changes take action <strong>after you confirmed the changes</strong> by clicking the save button.',
content_scanning_spam_handling_matrix_heading => 'The Score Matrix',
content_scanning_spam_handling_matrix_success => 'Newly configured score-settings have been successfully saved.',
content_scanning_spam_handling_matrix_text => 'Customize the score-values in order to manage spam-, quarantine- and blocking-scores as well as the DSN scoring limit. Valid scores are 0-99, with a maximum of one dotted decimal place (e.g. 3, 12, 4.7). ',
content_scanning_spam_handling_matrix_default => 'Default',
content_scanning_spam_handling_matrix_whitelist => 'Whitelisted hosts',
content_scanning_spam_handling_matrix_relayhosts => 'Relay hosts',
content_scanning_spam_handling_matrix_smtpauth => 'SMTP authenticated',
content_scanning_spam_handling_matrix_defaultqon => 'Quarantine enabled',
content_scanning_spam_handling_matrix_defaultqoff => 'Quarantine disabled',
content_scanning_spam_handling_matrix_policy => 'Policy',
content_scanning_spam_handling_matrix_tag => 'Tag',
content_scanning_spam_handling_matrix_quarantine => 'Quarantine',
content_scanning_spam_handling_matrix_block => 'Block',
content_scanning_spam_handling_matrix_nodsn => 'No DSN',


### MAIL_TRANSFER :: SMTP SERVERS
mail_transfer_smtp_servers_abstract => 'Define the SMTP servers known by your Open AS Communication Gateway&trade; that can be assigned to domains.',
mail_transfer_smtp_servers_form_heading => 'Add or update an SMTP server',
mail_transfer_smtp_servers_add_heading => 'Add new or update an existing SMTP server',
mail_transfer_smtp_servers_add_description => 'Description',
mail_transfer_smtp_servers_add_address => 'Mailserver address',
mail_transfer_smtp_servers_add_port => 'TCP Port',
mail_transfer_smtp_servers_add_update_enable_smtpauth => 'User authentication',
mail_transfer_smtp_servers_add_update_error_ldap_test => 'Sorry, the test e-mail address you provided could not be found in the given LDAP result set - please assure that address, filters, properties and base DN are correct. If you are sure about your settings, you may also check the "Do not verify test e-mail address" checkbox below at your own risk.',
mail_transfer_smtp_servers_add_enable_ldap => 'Enable LDAP user lookups',
mail_transfer_smtp_servers_add_no_ldap_test => 'Do not verify test e-mail address (not recommended)',

mail_transfer_smtp_servers_add_ldap_username => 'LDAP username',
mail_transfer_smtp_servers_add_ldap_password => 'LDAP password',
mail_transfer_smtp_servers_add_ldap_server => 'LDAP server',
mail_transfer_smtp_servers_add_ldap_basedn => 'Base DN',

mail_transfer_smtp_servers_add_ldap_filter => 'Filter',
mail_transfer_smtp_servers_add_ldap_properties => 'Property',
mail_transfer_smtp_servers_add_ldap_testmail => 'Test e-mail address',
mail_transfer_smtp_servers_add_ldap_autolearn_domains => 'Auto-learn domains from LDAP',

mail_transfer_smtp_servers_add_save => 'Save settings',
mail_transfer_smtp_servers_add_savenew => 'Add SMTP server',
mail_transfer_smtp_servers_add_smtpauth => 'SMTP Authentication',
mail_transfer_smtp_servers_add_smtpauth_none => 'No authentication',
mail_transfer_smtp_servers_add_smtpauth_plaintext => 'Plain text',
mail_transfer_smtp_servers_add_smtpauth_tls_all => 'Encrypted (TLS), accept any CA',
mail_transfer_smtp_servers_add_smtpauth_tls_known => 'Encrypted (TLS), known CAs only',
mail_transfer_smtp_servers_add_cutdelim => 'Cut delimiter and domain for SMTP-Authentication',

mail_transfer_smtp_servers_add_error_smtpsrv_not_exists => 'SMTP server does not exist.',
mail_transfer_smtp_servers_add_error_smtpsrv_exists => 'SMTP server already exists.',
mail_transfer_smtp_servers_add_error_test_ldap => 'LDAP test did not success.',
mail_transfer_smtp_servers_add_success_create => 'New SMTP server has been successfully added.',
mail_transfer_smtp_servers_add_success_update  => 'New SMTP server settings have been successfully applied.',

mail_transfer_smtp_servers_list_heading => 'Currently defined SMTP servers',
mail_transfer_smtp_servers_list_noentries => 'There are currently no SMTP servers configured.',
mail_transfer_smtp_servers_list_addnew => 'Add new SMTP server',
mail_transfer_smtp_servers_list_apply => 'Proceed',
mail_transfer_smtp_servers_list_smtpsrv_filter => 'Select SMTP server',
mail_transfer_smtp_servers_list_delete => 'delete',
mail_transfer_smtp_servers_list_edit => 'edit',
mail_transfer_smtp_servers_list_desc => 'Description',
mail_transfer_smtp_servers_list_addr => 'Address',
mail_transfer_smtp_servers_list_action => 'Action',
mail_transfer_smtp_servers_list_del_success => 'Successfully deleted selected SMTP server.',
mail_transfer_smtp_servers_list_notexistent => 'Chosen SMTP server does not exist.',


### MAIL_TRANSFER :: DOMAINS
mail_transfer_domains_abstract => 'The mail exchange (MX) record of your domains should point to your Open AS Communication Gateway&trade; in order to receive and analyze incoming e-mails. For each domain, you have to specify a relay mail server to which the message should be forwarded.',
mail_transfer_domains_add_heading => 'Add a new Domain',
mail_transfer_domains_add_domain => 'Domain',
mail_transfer_domains_add_address => 'Mailserver address',
mail_transfer_domains_add_instant_enable => 'Enable domain now',
mail_transfer_domains_add_addnew => 'Add new domain',
mail_transfer_domains_add_update => 'Save settings',

mail_transfer_domains_list_heading => 'Maintain currently configured domains',
mail_transfer_domains_list_noentries => 'There are currently no configured domains.',
mail_transfer_domains_list_text => 'The Domain Control Center gives you an overview about all currently configured domains and its associated SMTP servers and offers the possibility to maintain and update already existing ones. You may also specifically delete and temporarily en- or disable certain domains.',
mail_transfer_domains_list_domain => 'Domain',
mail_transfer_domains_list_mailserver => 'Mailserver address',
mail_transfer_domains_list_action => 'Action',
mail_transfer_domains_list_status => 'Status',
mail_transfer_domains_list_delete => 'delete',
mail_transfer_domains_list_edit => 'edit',

mail_transfer_domains_list_enabled => 'Enabled',

mail_transfer_domains_add_disable_success => 'Domain has been successfully disabled.',
mail_transfer_domains_add_enable_success => 'Domain has been successfully enabled.',
mail_transfer_domains_add_delete_success => 'Domain has been successfully deleted.',
mail_transfer_domains_add_create_success => 'Domain has been successfully created.',

mail_transfer_domains_add_create_error => 'Domain already exists.',


mail_transfer_domains_add_bulk_heading => 'Add multiple domains via CSV upload',
mail_transfer_domains_add_bulk_heading => 'Add multiple domains via CSV upload',
mail_transfer_domains_multiple_add_nofile => 'Please choose a correct CVS file for upload.',

mail_transfer_domains_reassign_heading => 'Batch reassignment of domains to SMTP servers',
mail_transfer_domains_reassign_smtpsrv_from => 'Currently assigned SMTP server',
mail_transfer_domains_reassign_smtpsrv_to => 'Newly assigned SMTP server',
mail_transfer_domains_reassign_move => 'Move',

mail_transfer_domains_reassign_success => 'Successfully transfered all assigned domains from chosen source SMTP server to destination SMTP server.',
mail_transfer_domains_reassign_error => 'Error reassigning domains from chosen SMTP server.',
mail_transfer_domains_reassign_sameservers_error => 'You have choosen the same SMTP server for source and destination.',

mail_transfer_domains_add_bulk_csvfile => 'Domain file <em>(CSV)</em>',
mail_transfer_domains_add_bulk_predelete => 'Pre-delete domains',
mail_transfer_domains_add_bulk_smtpsrv => 'Assign to mailserver',
mail_transfer_domains_add_bulk_upload_error=> 'Error parsing CSV file.',
mail_transfer_domains_add_bulk_toobig_error=> 'Given file is either too big, or does not seem to be a valid CSV file.',
mail_transfer_domains_add_bulk_success => 'Successfully added all domains from CSV file.',


### MAIL_TRANSFER :: RECIPIENTS
mail_transfer_recipients_abstract => 'Specify valid addresses for your domains. If no address is entered (manually or via LDAP), every address will be accepted.',

mail_transfer_recipients_list_heading => 'List recipients',
mail_transfer_recipients_list_text => 'List all currently known recipients within one recipient table. Depending on your configuration (and LDAP database), this list can be excessively rich.',
mail_transfer_recipients_list_domain => 'Domain',
mail_transfer_recipients_list_showcache => 'Show LDAP cache',
mail_transfer_recipients_list_status => 'Status',
mail_transfer_recipients_list_address => 'E-mail address',
mail_transfer_recipients_list_action => 'Action',
mail_transfer_recipients_list_success => 'List of known recipients successfully updated',
mail_transfer_recipients_list_delete => 'Delete',
mail_transfer_recipients_list_nousers => 'There are currently no known recipients for domain',

mail_transfer_recipients_add_heading => 'Add recipient',
mail_transfer_recipients_add_text => 'Here you can manually add single recipients for a specific domain. If the <em>accept</em>-box is checked, the newly added recipient is accepted. If unchecked, the recipient will be explicitely blocked.',
mail_transfer_recipients_add_user => 'User',
mail_transfer_recipients_add_domain => '@',
mail_transfer_recipients_add_accept => 'Modality',
mail_transfer_recipients_add_success => 'Successfully added new recipient.',

mail_transfer_recipients_bulk_add_heading => 'Upload recipient list',
mail_transfer_recipients_bulk_add_csvfile => 'Recipients list <em>(CSV)</em>',
mail_transfer_recipients_bulk_add_predelete => 'Pre-delete recipients',
mail_transfer_recipients_bulk_add_error_nofile => 'No file has been uploaded.',
mail_transfer_recipients_bulk_add_error_filetoobig => 'Maximum filesize exceeded.',
mail_transfer_recipients_bulk_add_error_nocsv => 'Uploaded file does not seem to be valid CSV.',
mail_transfer_recipients_bulk_add_error_parseline => 'Error parsing uploaded CSV file.',

mail_transfer_recipients_ldap_cache_heading => 'Update LDAP caches',
mail_transfer_recipients_ldap_cache_update_text => 'If LDAP is enabled for the configured SMTP servers, the LDAP caches for <em>all domains</em> are being updated by pressing the <em>Update</em>-button.',
mail_transfer_recipients_ldap_cache_success => 'Successfully updated LDAP caches.',


### MAIL_TRANSFER :: DNSL_MANAGER
envelope_scanning_dnsl_manager_abstract                                => 'Enable, disable and administer remote blacklist services applied on incoming e-mails. You can also Add your own RBL and subsequently incorporate additional RBLs into the blacklisting policy.',
envelope_scanning_dnsl_manager_control_heading                         => 'DNSBL Control Center',
envelope_scanning_dnsl_manager_control_status                          => 'Current DNSBL status',
envelope_scanning_dnsl_manager_control_addnew_text                     => 'You may add additional DNSBL server addresses, which are supplementary queried. Once added, make sure to actually enable the new service in the box below.',
envelope_scanning_dnsl_manager_control_newrbl                          => 'DNSBL address',
envelope_scanning_dnsl_manager_control_addnew_btn                      => 'Add DNSBL',
envelope_scanning_dnsl_manager_control_addnew_success                  => 'New DNSBL address successfully added.',
envelope_scanning_dnsl_manager_control_addnew_error_entryexists        => 'New DNSBL address successfully added.',
envelope_scanning_dnsl_manager_control_del_success                     => 'DNSBL Server successfully deleted.',
envelope_scanning_dnsl_manager_control_rbls_enabled                    => 'Remote blacklisting successfully enabled',
envelope_scanning_dnsl_manager_control_rbls_disabled                   => 'Remote blacklisting successfully disabled',
envelope_scanning_dnsl_manager_control_blockthreshold                  => 'Blocking threshold',
envelope_scanning_dnsl_manager_control_blockthreshold_text             => 'The <em>Blocking threshold</em> parameter defines the number of positive replies from DNSBLs necessary to actually block incoming mails (smaller values lead to earlier blacklisting decisions).',
envelope_scanning_dnsl_manager_control_blockthreshold_btn              => 'Save threshold',
envelope_scanning_dnsl_manager_control_blockthreshold_success          => 'New DNSBL blocking threshold has been successfully saved.',
envelope_scanning_dnsl_manager_list_del_success                        => 'Successfully deleted selected DNSBL entry.',
envelope_scanning_dnsl_manager_list_text                               => 'You may granularily enable or disable the currently configured DNSBL services. While self-added DNS blacklists can easily be removed, the preset DNSBLs remain statically. The order of the DNSBL services does not affect functionality.',
envelope_scanning_dnsl_manager_list_toggle_success                     => 'DNSBL service successfully toggled.',
envelope_scanning_dnsl_manager_list_rbls_inactive                      => 'You have currently disabled DNS blacklisting. Enable it in the box above in order to configure and manage your list of DNSBLs.',
envelope_scanning_dnsl_manager_list_heading                            => 'Configured DNSBLs',
envelope_scanning_dnsl_manager_list_remove                             => '(remove)',


### MAIL_TRANSFER :: SMTP SETTINGS
mail_transfer_smtp_settings_abstract => 'Administer restrictions for connecting clients that do not follow the SMTP standard and configure the SMTP server interface of the Open AS Communication Gateway.',

mail_transfer_smtp_settings_client_heading => 'Client Restrictions',
mail_transfer_smtp_settings_client_helo_required => 'Require EHLO/HELO',
mail_transfer_smtp_settings_client_rfc_strict => 'Require RFC Compatibility',
mail_transfer_smtp_settings_client_sender_domain_verify => 'Sender Domain Verification',
mail_transfer_smtp_settings_client_sender_fqdn_required => 'Sender FQDN Required',
mail_transfer_smtp_settings_client_error => 'Unknown setting was submitted.',
mail_transfer_smtp_settings_client_success => 'Your requested changes have been applied.',

mail_transfer_smtp_settings_server_heading => 'Server Settings',
mail_transfer_smtp_settings_server_smtpd_banner => 'Banner Message',
mail_transfer_smtp_settings_server_max_connections => 'Max. connections within 30 min.',
mail_transfer_smtp_settings_server_smtpd_timeout => 'SMTP Timeout <em>(sec.)</em>',
mail_transfer_smtp_settings_server_smtpd_queuetime => 'SMTP queue lifetime <em>(hours)</em>',
mail_transfer_smtp_settings_server_updated => 'Settings have been applied.',


### MAIL_TRANSFER :: RELAY HOSTS
mail_transfer_relay_hosts_abstract => 'Define the hosts and networks which are allowed to relay e-mails via this Open AS Communication Gateway&trade;. Usually you need to enter the IP address of your mailserver here.',

mail_transfer_relay_hosts_form_heading => 'Add new IP range',
mail_transfer_relay_hosts_form_range_start => 'IP range start',
mail_transfer_relay_hosts_form_range_end => 'IP range end',
mail_transfer_relay_hosts_form_description => 'Description',
mail_transfer_relay_hosts_form_added => 'Your given IP range has been added.',

mail_transfer_relay_hosts_table_heading => 'Allowed relay IP ranges',
mail_transfer_relay_hosts_table_header_range => 'IP range',
mail_transfer_relay_hosts_table_header_description => 'Description',
mail_transfer_relay_hosts_table_empty => 'Currently there are no relay hosts defined.',
mail_transfer_relay_hosts_table_deleted => 'The selected IP range has been deleted.',


### QUARANTINE :: GENERAL_SETTINGS
quarantine_general_settings_abstract => 'Enable or disable the end-user quarantine and modify the basic settings and language preferences.',
quarantine_general_settings_timing_options_heading => 'Quarantine timing options',
quarantine_general_settings_timing_options_max_confirm_retries => 'Number of Activation Requests',
quarantine_general_settings_timing_options_max_confirm_interval => 'Timeout after last Activation Request <em>(in days)</em>',
quarantine_general_settings_timing_options_global_item_lifetime => 'Global items lifetime <em>(in days)</em>',
quarantine_general_settings_timing_options_user_item_lifetime => 'User items lifetime <em>(in days)</em>',
quarantine_general_settings_timing_options_sender_name => 'Sender name',
quarantine_general_settings_timing_options_sizelimit_address => 'Size warning address',
quarantine_general_settings_timing_options_success => 'Quarantine timing options have been successfully saved.',

quarantine_general_settings_day_daily => 'Daily',
quarantine_general_settings_day_mon => 'Monday',
quarantine_general_settings_day_tue => 'Tuesday',
quarantine_general_settings_day_wed => 'Wednesday',
quarantine_general_settings_day_thu => 'Thursday',
quarantine_general_settings_day_fri => 'Friday',
quarantine_general_settings_day_sat => 'Saturday',
quarantine_general_settings_day_sun => 'Sunday',

quarantine_general_settings_activation_request_heading => 'Activation Request notifications',
quarantine_general_settings_activation_request_text => 'Granularily define if and when end-user quarantine activation request notifications are sent by the Open AS Communication Gateway.',
quarantine_general_settings_activation_request_choose_interval => 'Choose notification',
quarantine_general_settings_activation_request_status_report => 'Daily spam report',
quarantine_general_settings_activation_request_activation_request => 'Quarantine activation request',
quarantine_general_settings_activation_request_automation => 'Automatically send request',
quarantine_general_settings_activation_request_automation_disabled => 'Never',
quarantine_general_settings_activation_request_automation_enabled => 'Automatically',
quarantine_general_settings_activation_request_day_hours => 'Time of day',
quarantine_general_settings_activation_request_week_days => 'Week days',
quarantine_general_settings_activation_request_success => 'Activation request settings successfully changed.',

quarantine_general_settings_spam_report_heading => 'Quarantine spam report notifications',
quarantine_general_settings_spam_report_text => 'Granularily define if and when end-user quarantine status notifications are sent by the Open AS Communication Gateway.',
quarantine_general_settings_spam_report_choose_interval => 'Choose notification',
quarantine_general_settings_spam_report_spam_report => 'Daily spam report',
quarantine_general_settings_spam_report_activation_request => 'Quarantine activation request',
quarantine_general_settings_spam_report_automation => 'Automatically send report',
quarantine_general_settings_spam_report_automation_disabled => 'Never',
quarantine_general_settings_spam_report_automation_enabled => 'Automatically',
quarantine_general_settings_spam_report_day_hours => 'Time of day',
quarantine_general_settings_spam_report_week_days => 'Week days',
quarantine_general_settings_spam_report_success => 'Quarantine report settings successfully saved.',

quarantine_general_settings_language_options_heading => 'Language for end-user notifications',
quarantine_general_settings_language_options_language => 'Choose language',
quarantine_general_settings_language_options_english => 'English',
quarantine_general_settings_language_options_german => 'German',
quarantine_general_settings_language_options_success => 'Notifcations language has been successfully changed.',


### QUARANTINE :: QUARANTINING_OPTIONS
quarantine_quarantining_options_mail_handling_destiny_spam => 'Spam mails',
quarantine_quarantining_options_mail_handling_destiny_virus => 'Virus mails',
quarantine_quarantining_options_mail_handling_destiny_banned => 'Banned attachments',

quarantine_quarantining_options_mail_handling_heading => 'Handling of infected mails',
quarantine_quarantining_options_mail_handling_sendto_enduser => 'Send to end-user quarantine',
quarantine_quarantining_options_mail_handling_sendto_global => 'Send to global mailbox',
quarantine_quarantining_options_mail_handling_discard => 'Discard',
quarantine_quarantining_options_mail_handling_success => 'Successfully changed infected mails handling routine.',

quarantine_quarantining_options_global_mailboxes_heading => 'Global mailboxes configuration',
quarantine_quarantining_options_global_mailboxes_spam_box => 'Spam mails',
quarantine_quarantining_options_global_mailboxes_virus_box => 'Virus mails',
quarantine_quarantining_options_global_mailboxes_banned_box => 'Banned attachments',
quarantine_quarantining_options_global_mailboxes_success => 'Global quarantine boxes have been updated',

quarantine_quarantining_options_abstract => 'This page assists you in managing received infected mails. Base on the infection type, you can choose where to send them (Infected mails destiny) and, in some cases, to whom (admin mailboxes).',
quarantine_quarantining_options_domains_heading => 'Enable domains for per-user quarantine',
quarantine_quarantining_options_domains_text => 'You may select all domains for which the end-user quarantine shall proactively take care of unwated and/or dangerous mails.',
quarantine_quarantining_options_domains_alldomains => 'All configured domains',
quarantine_quarantining_options_domains_domains => 'Domains',
quarantine_quarantining_options_domains_enabled => 'Enabled',
quarantine_quarantining_options_domains_success => 'Successfully changed quarantine domains.',

quarantine_quarantining_options_visibility_heading => 'Visibility options for infected mails',
quarantine_quarantining_options_visibility_full => 'Show mails and available actions',
quarantine_quarantining_options_visibility_mail => 'Hide mails and available actions',
quarantine_quarantining_options_visibility_links => 'Show mails but hide available actions',
quarantine_quarantining_options_visibility_spam => 'Spam mails',
quarantine_quarantining_options_visibility_virus => 'Virus mails',
quarantine_quarantining_options_visibility_banned => 'Banned attachments',
quarantine_quarantining_options_visibility_success => 'Quarantine report visibility preferences successfully saved.',


### QUARANTINE :: BOX_STATUS_MANAGEMENT
quarantine_box_status_management_abstract => 'Manage the status for user quarantines: enable, disable, resend activation requests and reset the confirmation counters.',
quarantine_box_status_management_filter_heading => 'Filter preferences',
quarantine_box_status_management_filter_box_irrelevant => 'Irrelevant',
quarantine_box_status_management_filter_box_unconfirmed => 'Unconfirmed',
quarantine_box_status_management_filter_box_qenabled => 'Quarantine enabled',
quarantine_box_status_management_filter_box_qdisabled => 'Quarantine disabled',
quarantine_box_status_management_filter_empty => 'Your search did not return any results.',

quarantine_box_status_management_filter_domain_filter => 'Show users from',
quarantine_box_status_management_filter_box_status => 'Quarantine box status',
quarantine_box_status_management_filter_alldomains => 'All configured domains',
quarantine_box_status_management_filter_apply => 'Apply filter',
quarantine_box_status_management_filter_success => 'Filtering preferences successfully applied.',
quarantine_box_status_management_filter_reset_success => 'Activation process successfully reset.',

quarantine_box_status_management_list_reset_success => 'Mail counter successfully reset.',
quarantine_box_status_management_list_notify_success => 'User notification has been successfully reset.',
quarantine_box_status_management_list_enable_success => 'Quarantine for specified user successfully enabled.',
quarantine_box_status_management_list_disable_success => 'Quarantine for specified user successfully disabled.',
quarantine_box_status_management_list_address => 'E-mail address',
quarantine_box_status_management_list_status => 'Box status',
quarantine_box_status_management_list_action => 'Available actions',
quarantine_box_status_management_list_heading => 'Quarantine boxes according to filter',
quarantine_box_status_management_list_notify => 'Send activation request',
quarantine_box_status_management_list_renotify => 'Resend activation request',
quarantine_box_status_management_list_reset => 'Restart activation process',
quarantine_box_status_management_list_enable => 'Enable quarantine',
quarantine_box_status_management_list_disable => 'Disable quarantine',
quarantine_box_status_management_list_noresults => 'There are currently no entries to be displayed. Please change your filter preferences.',


### QUARANTINE :: USER_BOX_ADMINISTRATION
quarantine_user_box_administration_abstract => 'Manage specific quarantine boxes for users with the common actions (delete or release quarantined messages or empty the whole queue).',
quarantine_user_box_administration_filter_heading => 'Box selection',
quarantine_user_box_administration_filter_username => 'Username',
quarantine_user_box_administration_filter_domain => '@',
quarantine_user_box_administration_filter_apply => 'Show user\' box',
quarantine_user_box_administration_filter_success => 'Quarantine box successfully loaded.',

quarantine_user_box_administration_status_information_heading => 'Box status information',
quarantine_user_box_administration_status_information_user => 'User',
quarantine_user_box_administration_status_information_qunconfirmed => 'Unconfirmed',
quarantine_user_box_administration_status_information_qenabled => 'Quarantine enabled',
quarantine_user_box_administration_status_information_qdisabled => 'Quarantine disabled',
quarantine_user_box_administration_status_information_boxstatus => 'Quarantine box status',
quarantine_user_box_administration_status_information_itemcount => 'E-mails currently quarantined',
quarantine_user_box_administration_status_information_empty => 'Empty this quarantine',
quarantine_user_box_administration_status_information_delete => 'Delete all',
quarantine_user_box_administration_status_information_nodata => 'You didn\'t select a user\' quarantine box.',
quarantine_user_box_administration_status_information_unknown_recipient => 'Unknown recipient',
quarantine_user_box_administration_status_information_unknown_recipient_text => 'There is no user with this name available for the specified domain.',
quarantine_user_box_administration_status_information_unknown => 'Unknown recipient: There is no user with this name available for the specified domain.',
quarantine_user_box_administration_status_informaiton_all_mails_deleted => 'All quarantined mails of given user successfully deleted.',

quarantine_user_box_administration_item_list_heading => 'Quarantined items for selected box',
quarantine_user_box_administration_item_list_release => 'Release item',
quarantine_user_box_administration_item_list_rerelease => 'Re-release item',
quarantine_user_box_administration_item_list_delete => 'Delete item',
quarantine_user_box_administration_item_list_type => 'Type',
quarantine_user_box_administration_item_list_received => 'Received',
quarantine_user_box_administration_item_list_sender => 'Sender',
quarantine_user_box_administration_item_list_subject => 'Subject',
quarantine_user_box_administration_item_list_action => 'Action',
quarantine_user_box_administration_item_list_spam => 'Spam',
quarantine_user_box_administration_item_list_virus => 'Virus',
quarantine_user_box_administration_item_list_banned => 'Banned',
quarantine_user_box_administration_item_list_nodata => 'You didn\'t select a user\' quarantine box.',
quarantine_user_box_administration_item_list_mail_deleted => 'Specified mail successfully deleted from quarantine.',
quarantine_user_box_administration_item_list_mail_released => 'Specified mail successfully released and send to user mailbox.',


### LOGGING :: LIVE LOG
logging_live_log_abstract => 'Analyze the current mail flow in real-time.',
logging_live_log_livelog_heading => 'Live log',
logging_live_log_livelog_date => 'Date',
logging_live_log_livelog_time => 'Time',
logging_live_log_livelog_sender => 'Sender',
logging_live_log_livelog_recipient => 'Recipient',
logging_live_log_livelog_subject => 'Subject',
logging_live_log_livelog_status => 'Result',


### LOGGING :: LOG VIEWER
logging_log_viewer_abstract => 'Inspect, analyze, search and find any happening in the past with the Log Viewer.',
logging_log_viewer_search_heading => 'Search and examine logs',
logging_log_viewer_search_from => 'Search logs from',
logging_log_viewer_search_to => 'Until',
logging_log_viewer_search_pattern => 'Search pattern',
logging_log_viewer_search_use_regex => 'Treat pattern as regular expression',
logging_log_viewer_search_ignore_case => 'Ignore casing (a = A)',
logging_log_viewer_search_reverse => 'Reverse order (oldest entry first)',
logging_log_viewer_search_start => 'Start search',
logging_log_viewer_search_success => 'Search successfully finished.',
logging_log_viewer_search_error_toomanylines => 'Too many lines found, please narrow your search date interval or concretize your search pattern.',
logging_log_viewer_search_error_nolines => 'Sorry, I could not find what you were searching for. You may want to try it again with a generalized search pattern or a wider search date interval.',
logging_log_viewer_search_num => '#',
logging_log_viewer_search_match => 'Line match',
logging_log_viewer_search_warning => '<strong>Warning:</strong> Dependent on traffic, load and log scale, complex searches over long periods of time may take a considerable amount of time to succeed!',


logging_log_viewer_list_heading => 'Download logfile per day',


### LOGGING :: SIMPLE MAILLOG
logging_maillog_simple_abstract => 'In addition to analyzing the raw appliance logs, the Open AS Communication Gateway&trade; provides an easy-to-use and easy-to-read mail log.',
logging_maillog_simple_search_heading => 'Search and examine mail log',
logging_maillog_simple_search_from => 'Search logs from',
logging_maillog_simple_search_to => 'Until',
logging_maillog_simple_search_pattern => 'Search pattern',
logging_maillog_simple_search_yield => 'Processing result',
logging_maillog_simple_search_ignore_case => 'Ignore casing (a = A)',
logging_maillog_simple_search_reverse => 'Reverse order (oldest entry first)',
logging_maillog_simple_search_start => 'Start search',
logging_maillog_simple_search_success => 'Search successfully finished.',
logging_maillog_simple_search_error_toomanylines => 'Too many lines found, please narrow your search date interval or concretize your search pattern.',
logging_maillog_simple_search_error_nolines => 'Sorry, I could not find what you were searching for. You may want to try it again with a generalized search pattern or a wider search date interval.',
logging_maillog_simple_search_num => '#',
logging_maillog_simple_search_match => 'Line match',
logging_maillog_simple_search_ts => 'Timestamp',
logging_maillog_simple_search_yield => 'Result',
logging_maillog_simple_search_from => 'From',
logging_maillog_simple_search_to => 'To',
logging_maillog_simple_search_qnr => 'Queue#',
logging_maillog_simple_search_subject => 'Subject',
logging_maillog_simple_search_authority => '<strong>Warning:</strong> While the <em>Log-Viewer</em> crawls through the original raw logs whose search results are authorative, the <em>Simple Mail-Log</em> results are, although supposed to be consistent and complete, non-authorative. If you do not want to narrow down your search results by utilizing specific search patterns, just use a hyphen as pattern (-).',


### LOGGING :: STATISTICS
logging_statistics_abstract => 'Granularily inspect your past mail traffic within the last 24 hours, the last week, the last month or the last entire year.',
logging_statistics_entire_traffic_stats_heading => 'Entire traffic stats',


### MODULES :: LICENCE MANAGEMENT
modules_licence_management_abstract => 'You can add new or renew existing licences for already existing or additional services provided by the Open AS Communication Gateway.',
modules_licence_management_info_heading => 'Licencing information',
modules_licence_management_info_lastupdate => 'The licensing information has last been updated on ',
modules_licence_management_info_neverupdated => 'The licencing information has up until now never been updated.',
modules_licence_management_info_lastupdated => 'The licensing information has last been updated on ',
modules_licence_management_info_getinfo => 'get more detailed information on the Open AS website',
modules_licence_management_info_service => 'TBD',
modules_licence_management_info_licence_not_activated => 'hasn\'t been activated',
modules_licence_management_info_request_licence => 'request a licence for this module',
modules_licence_management_info_validuntil => 'is valid until',
modules_licence_management_info_more => 'more',
modules_licence_management_info_days => 'days',
modules_licence_management_info_renewlicence => 'renew licence',
modules_licence_management_info_licence_expired_on => 'has expired on',
modules_licence_management_info_updatelicence => 'Update licence file',

modules_licence_management_info_lic_never_updated => 'The licencing information has up until now never been updated.',
modules_licence_management_info_lic_last_updated => 'The licencing information has been updated on ',
modules_licence_management_info_lic_get_info => 'get more detailed information on the Open AS website',
modules_licence_management_info_lic_not_activated => 'hasn\'t yet been activated',
modules_licence_management_info_lic_request => 'request a licence for this module',
modules_licence_management_info_lic_valid_until => 'is valid until',
modules_licence_management_info_lic_renew => 'renew licence',
modules_licence_management_info_lic_expired_on => 'has expired on',
modules_licence_management_info_success => 'Successfully updated lincence(s).',

modules_licence_management_update_heading => 'Update licence key(s)',
modules_licence_management_update_enterkey => 'Enter a new licence key',
modules_licence_management_update_enterkey_text => 'In order to activate your newly purchased licence, just enter the multi-parted licence key into the input fields below (casing is irrelevant).',
modules_licence_management_update_validate => 'Validate licence',
modules_licence_management_update_key => 'Enter licence key',

modules_licence_management_update_k1 => 'part 1',
modules_licence_management_update_k2 => 'part 2',
modules_licence_management_update_k3 => 'part 3',
modules_licence_management_update_k4 => 'part 4',
modules_licence_management_update_k5 => 'part 5',
modules_licence_management_update_k6 => 'part 6',
modules_licence_management_update_k7 => 'part 7',
modules_licence_management_update_k8 => 'part 8',

modules_licence_management_upload_heading => 'Upload a licence file',
modules_licence_management_upload_ulf => 'Upload ULF key',
modules_licence_management_upload_text => 'Upload an Open AS licence key file (.ULF).',
modules_licence_management_upload_upload => 'Upload licence',

modules_email_encryption_abstract => 'Administer your E-mail encryption settings. Using this feature, the Open AS Communication Gateway will automatically encrypt outgoing e-mails if you place a previously defined tag within the subject, and put the contents (text and attachments) into an encrypted ZIP archive. The engine also includes experimental PDF-conversion and encryption support.',
modules_email_encryption_control_heading => 'E-mail encryption',
modules_email_encryption_control_commercial => 'Sorry, this feature is only available in the commercial version. Please contact Open AS Support if you want to purchase a licence (Note: E-mail encryption is the only functional restriction in the OSS version, aside from an additional commercial virus-scanning engine).',
modules_email_encryption_control_id_cryptotag => 'Identification tag',
modules_email_encryption_control_id_packtype => 'Encoding type',
modules_email_encryption_control_id_enctype => 'Password assignment',
modules_email_encryption_control_pwhandling_generate => 'Generate random password for each encrypted mail',
modules_email_encryption_control_pwhandling_preset => 'Always use a pre-set password',
modules_email_encryption_control_id_password => 'Pre-set password',
modules_email_encryption_control_success => 'E-mail encryption settings have been successfully saved.',
modules_email_encryption_control_status => 'E-mail encryption engine status',


######################################################################################################################################
## *****************************                         New Help Pages v2.0                          *************************** ##
######################################################################################################################################

#################################################### DASHBOARD
### DASHBOARD :: DASHBOARD
help_dashboard_dashboard_appliance_status => 'Shows general appliance (health) information and provides a basic overview over the installed system version.',
help_dashboard_dashboard_service_status => 'Shows which activated services are currently online and running.',
help_dashboard_dashboard_mailtraffic_stats => 'Provides a graphical summary of the e-mails processed by the Open AS Communication Gateway&trade;',


#################################################### SYSTEM
### SYSTEM :: GENERAL SETTINGS
help_system_general_settings_version => 'Displays all relevant version information about numerous appliance-specific software packages like anti-virus engine, anti-spam engine, installed and available firmware version, revision number and a timestamp of the last system update.',
help_system_general_settings_reboot_shutdown => 'Hereby, you may reboot or shutdown your appliance. Note that, with certain appliance types, shutting down the machine doesn\'t necessarily mean that the machine will power itself off.',
help_system_general_settings_reset => 'This dialog gives you the possibility to reset your Open AS Open AS Communication Gateway&trade; to default settings. The appliance reset will be done according to the chosen reset-level, which may be <em>Statistics only</em>, <em>Soft reset</em> and <em>Hard reset</em>. While the first option will delete all mail statistics and livelog records, the remaining environment (including settings, backups, mailqueue items and logfiles) is kept untouched. The second option, the <em>Soft reset</em>, will reset the appliance to its factory defaults. Only logfiles, backups and mail-queue are kept. The last option <em>Hard reset</em> will reset the appliance to its factory defaults and delete everything else. <strong>Note:</strong> Soft- and hard-resets will force the appliance to reset the network configuration!',

### SYSTEM :: TIME SETTINGS
help_system_time_settings_timezone => 'Select your timezone here. In terms of e-mailing, correct configuration of time and timezone is essential in order to keep e-mail headers and logs consistent.',
help_system_time_settings_ntp => 'Here you can administer, add and delete network time servers. By default there is a correctly working set of servers enlisted, change these settings only if you want to use a timeserver in your local network. To get a list of NTP-servers in your area please visit <a href="http://www.pool.ntp.org/zone/@">http://www.pool.ntp.org/zone/@</a>.',

### SYSTEM :: REMOTE ASSISTANCE
help_system_remote_assistance_ssh => 'The Open AS Communication Gateway&trade; utilizes a Secure-Shell daemon in order to allow you to deposit <em>Emergency Commands</em> for e.g. restarting the appliance or retrieving system information without using the web-interface. <strong>SSH will always actively listen on port 22 for incoming connections, despite the setting of this configuration option</strong>. However, this setting forces the SSH daemon to additionally listen on port 22.',
help_system_remote_assistance_snmp => 'Once activated, the on-appliance SNMP agent will provide useful information about the appliance common health status, performance and activities. To successfully activate SNMP, an SNMP community string is substantial to identify SNMP packet ownerships, as well as a CIDR network-address which acts as basic network-level querying limitation range. Only SNMP walks from within the given network range are allowed to retrieve information. Moreover, you must include a system contact and system location string.',

### SYSTEM :: NETWORK
help_system_network_ip => 'Use this section to define IP, subnetmask and default gateway of your Open AS Communication Gateway&trade;. After saving, it takes about 5 seconds to change the network settings. You have another 10 minutes to re-login to the appliance on it\'s new address and confirm your new settings. If you don\'t re-login within the given timespan, the settings will automatically fall back to the last working configuration.',
help_system_network_dns => 'Configure IP addresses for DNS servers that will be used by your Open AS Communication Gateway&trade;. We strongly recommend you to also specify a secondary DNS server to avoid the loss of e-mails in case the primary DNS server goes down.',
help_system_network_proxy => 'Configure the proxy server address (don\'t forget prefixes like e.g. http://), port and username + password (if necessary, otherwise leave empty) that will be used by your Open AS Communication Gateway.',

help_system_network_hostname => 'Specify the system\'s hostname and domainname. These ones does not necessarily have to be the same as resolved through DNS, but it\'s used as best practice and recommended if possible.',

### SYSTEM :: SECURITY
help_system_security_adm_form => 'Use this section to define IP address ranges from which the web interface of your Open AS Communication Gateway&trade; can be accessed. As long as no ranges are defined, the appliance will be accessible from everywhere within your network.',
help_system_security_adm_table => 'Here, all your currently configured IP administration ranges are listed. You may remove single entries by clicking the <em>Delete</em> link.',
help_system_security_ssl => 'During the configuration of your SMTP servers, you may administer the Open AS Communication Gateway&trade; to use SSL/TLS.</p><h4>Assign CA certificate to Mailserver</h4><p>Hereby, you may upload a cryptographical certificate file (.CRT, .PEM) which will subsequently be used as valid certificate to establish and accept connections from/to the chosen SMTP server. Once a certificate has been uploaded, you may revoke it again using the <em>Revoke Certificate</em> form below.</p><h4>Assign keypair to Open AS Communication Gateway</h4><p>In order make the enable the possibility for the Open AS Communication Gateway&trade; to receive mails through TLS, you have to upload a cryptographic certificate and its corresponding private key. As this has been accomplished, the SMTP STARTTLS command will instantly be available to all incoming SMTP sessions.',

### SYSTEM :: UPDATE
help_system_update_settings => 'You can edit the update automation settings here.</p><ul><li><em>Automatically get the latest Update Information</em> does not install or download anything. The newest available informations on updates (security and system updates) are being downloaded, nothing is being installed</li><li><em>Automatically download security updates</em> as soon as they are available. If the next options are disabled you can install the updates in the box below manually.</li><li><em>Automatically install security updates</em> is highly recommended. E-Mail delivery is only suspended for about 30 to 60 seconds. The updates are designed to be installable even during office hours.</li><li>If you want your appliance stay on the newest feature version you may want to activate <em>Automatically install the latest system version</em>. If an update requires a restart (major feature updates) or if the service interruption could exceed 60 seconds you will still to have to install it manually.</li></ul>',
help_system_update_versions => 'The currently installed system version and the available security updates (for this particular system version) are displayed here, as well as a timestamp of the last successful check for updates. If this timestamp is older than two hours and you have automatic checking enabled please check your firewall settings since your Open AS Communication Gateway&trade; seems to be unable to connect to the update server.<br />Searching for updates manually is possible at any time.',
help_system_update_upgrade_info => 'If a security version is available you can start the installation here. If you have <em>automatically download security updates</em> enabled the installation will start almost immediately.',
help_system_update_upgrade_table => 'If new system versions are available you can install them here. They will be downloaded and installed. Information on the updates can be found on our homepage <a href="https://openas.org">openas.org - Updates</a>',

### SYSTEM :: BACKUP MANAGER
help_system_backup_manager_list => 'To generate a backup of your current settings (that also can be stored on your local hard drive) simply click the"Create" button. An encrypted backup-archive will be created, and added to your list of backups stored directly on the appliance. Once a backup has been created, you may download, install and delete it through the list of backups in the same dialog.',
help_system_backup_manager_upload => 'Here, you may upload any previously created encrypted backup archive to the Open AS Communication Gateway&trade;. Uploading a backup file <strong>will not install</strong> it yet, but simply add it to the list of available backups from which the backup can eventually be installed.',

### SYSTEM :: USER
help_system_user_pw_gui => 'Here you may change the password for the currently logged in user on the web-interface (which will most likely be called <em>admin</em>.',

### SYSTEM :: SYSLOG
help_system_syslog_remote => 'Here you can define an external syslog server in your network. The Syslog Host field needs a valid IP-address or DNS-hostname of your syslog server (IP is recommended). Syslog uses 514/udp as default, but the port is changeable. The Enabled checkbox has to be activated, otherwise it will not work.',


### SYSTEM :: NOTIFICATIONS
help_system_notifications_add => 'To add a new recipient to the Open AS Communication Gateway&trade; System Notifications list, simply enter the e-mail address, name and SMTP server. Note that you don\'t necessarily need to use an SMTP server currently managed by the Open AS Communication Gateway&trade; itself here. If you want to utilize SMTP authentication, you may additionally enter a login username and password. For SSL/TLS encryption, simply enable the TLS checkbox.',
help_system_notifications_list => 'A full list of all currently configured notification recipients is shown in this section. Via the links inside the Action-column, you may edit the configuration settings of one specific recipient, or remove a recipient from the notification list.',



#################################################### MAIL TRANSFER
### MAIL TRANSFER :: DOMAINS
help_mail_transfer_domains_add_bulk => 'You can add multiple domains at once via file upload. You have to make a CSV-file with the domains and the enabled/disabled state. Only one domain per line is allowed. The state is optional, comma-separated and can be on or off.<br/>See the following list as working example file:</p><ul><li>domain1.com</li><li>domain2.com,off</li><li>domain3.com,on</li></ul>',
help_mail_transfer_domains_reassign => 'Here you can reassign all domains assigned to one SMTP server to another one.',
help_mail_transfer_domains_select => 'This section allows you to add a new e-mail domain for which your Open AS Communication Gateway&trade; will accept messages and the SMTP server to which the filtered messages will be delivered. Your Open AS Communication Gateway&trade; appliance will not accept e-mail messages for a disabled domain.',

### MAIL TRANSFER :: RECIPIENTS
help_mail_transfer_recipients_add => 'If you want to add a recipient you can do this here. Manually added recipients override LDAP recipients (eg. you can block a recipient although he is in the LDAP directory). Enable \'accept\' if you want the added recipient to be accepted, disable it if you want a recipient to be explicitly blocked. The Open AS Communication Gateway&trade; will accept all addresses for a domain as long as there are no recipients explicitly defined. Once one recipient is given (manually or via LDAP) the Open AS Communication Gateway&trade; only accept addresses that are definitly configured to <strong>accept</strong>.',
help_mail_transfer_recipients_bulk_add => 'You can upload a text file containing all addresses you want your appliance to accept or reject. By default all addresses are accepted. Enter one complete e-mail address per line (including domain eg. user@test.tld). You can mix addresses of different domains as long as those domains are configured on the Domains page. If pre-deletion is enabled all domains included in the file will be overwritten. Appending \'on\' or \'off\' to the e-mail address (and seperating with a \',\' - i.e. user@test.tld, off) overrides the default accept.',
help_mail_transfer_recipients_ldap_cache => 'By clicking this button a LDAP cache update will be initiated. All LDAP servers that are currently configured will be queried.',
help_mail_transfer_recipients_list => 'You can show all the recipient addresses for each domain here. If wanted this includes the addresses currently in the LDAP cache. Please note that manually entered addresses always take precedence over automatically added addresses.',

### MAIL TRANSFER :: RELAY HOSTS
help_mail_transfer_relay_hosts_form => 'Here you should add all IP ranges that should be allowed to use the Open AS Communication Gateway&trade; to send outgoing mails. This can either be servers that are not able to do SMTP authentication or local network clients that are not configured to do SMTP authentication. If you want to add only one IP then put it in both "Range Start" and "Range End" fields.',
help_mail_transfer_relay_hosts_table => 'This section lists all internal IP Ranges configured to send e-mails without SMTP Authentication. Press "Delete" to remove a range.',

### MAIL TRANSFER :: SMTP SERVERS
help_mail_transfer_smtp_servers_add_update => 'Use this section to update an existing or to define a new SMTP server. To this SMTP Server you can assign domains in the "Domains" section.</p><ul><li>In "Description" put in a name for your mail server with which it will be displayed at the domain configuration page.</li><li>"Mailserver address" holds the (IP-) address of your mail server.</li><li>"TCP Port" is the port your mail server is listening for incoming mails. The default port is 25.</li><li>"SMTP authentication": If this SMTP server provides SMTP authentication, you may change this drop-down box to <em>Plain Text</em>, <em>Encrypted (TLS), accept any CA</em> or <em>Encrypted (TLS), known CAs only</em>. While the second option will transfer all authentication credentials in clear text over the network, the third option will accept any encrypted TLS connection. The last option will also encrypt connections, but only from parties whose cryptographical certificate is signed by VeriSign, Thawte or any other officially trusted authority. In <em>System - Security</em>, you can also add your own SSL certificate which will be handled as valid and trusted. </li></ul><p>Use LDAP Authentication if you want to block incoming mails to invalid mail addresses. The Open AS Communication Gateway&trade; will update its cache of addresses once an hour. The prefilled settings have been tested on a standard Microsoft Exchange. You need to provide a LDAP Server (or a comma-separated list of servers), a valid user who can access the needed information (no write is access needed) and a Base DN which will most likely look similar to "dc=company,dc=local". You may override single addresses or check the cached addresses on the <em>Mail Transfer - Recipients</em> page.<br/><strong>Note:</strong> If enabling <em>Auto-learn domains from LDAP</em>, all domains from retrieved e-mail addresses which were previously unknown, are automatically added to the list of handled domains for the specified SMTP server and immediately activated. Enabling this option may be dangerous due to security reasons, so only use it if you are confident that the LDAP query really only returns what you were looking for, and the Open AS Communication Gateway&trade; is the sole SMTP proxy for all retrieved mail domains.',
help_mail_transfer_smtp_servers_select => 'In this section, you\'ll see a complete list of all currently configured SMTP servers, if any. By clicking on the links on the right, you may easily delete or edit an SMTP server.',

### MAIL TRANSFER :: SMTP SETTINGS
help_mail_transfer_smtp_settings_client => 'These settings require the sending mail server to obey strictly to parts of the SMTP protocol definitions.</p><ul><li>"Require HELO/EHLO" doesn\'t accept connections if they don\'t start with the HELO/EHLO command that all mail servers are using for their communication (recommended <strong>enabled</strong>).</li><li>"Require RFC Compatibility" as defined in the standard <a href="ftp://ftp.rfc-editor.org/in-notes/std/std10.txt">ftp://ftp.rfc-editor.org/in-notes/std/std10.txt</a> (recommended <strong>disabled</strong> because of Outlook Express problems)</li><li>"Sender Domain Verification" checks if the sender address contains a valid domain name (recommended <strong>enabled</strong>).</li><li>"Sender FQDN (Fully Qualified Domain Name)" checks if the domain name with which the sending mail server introduced itself, is associated correctly with its IP (recommended <strong>enabled</strong>).</li></ul>',
help_mail_transfer_smtp_settings_server => 'This section allows you:</p><ul><li>To set the welcome message sent to SMTP servers trying to communicate with Open AS Communication Gateway</li><li>On "Maximum Connections per IP" you can prevent Denial of Service attacks where attackers try to open as many connections to your appliance as possible in order to prevent other mail servers from reaching the appliance. Use a value of 0 to do not limit the number of connections.</li><li>The "SMTP Timeout" sets the number of seconds a remote mail server is given to send the next command.</li><li>The "SMTP Queue Lifetime" sets the maximum lifetime of emails within the mail queue, before it is dropped an a DSN (Delivery Sender Notification) is being returned.</li></ul>',

#################################################### ENVELOPE SCANNING
### ENVELOPE SCANNING :: ENVELOPE PROCESSING
help_envelope_scanning_envelope_processing_greylisting => 'This section allows you to activate or disable greylisting. <strong>Greylisting</strong> is one of the most efficient weapons when it comes to fighting spam: Someone sends an e-mail. Open AS Communication Gateway&trade; responds with "I\'m busy at the moment, try again later" but stores sender IP, sender e-mail address and recipient e-mail address.<br />Mail servers try to deliver mails again after a short while (normally within a few minutes up to half an hour). When that mail sever attempts to deliver the e-mail for the second time, Open AS Communication Gateway&trade; already has an entry with the combination of that sender IP, sender e-mail address and recipient e-mail address stored and because of that accepts the mail and stores the 3 entries until the next month. If an e-mail arrives some time during the next month with the same combination (server, sender address, recipient address) it\'s accepted without any delay and the validity for this combination is extended for another month.<br />Since spam sender in general don\'t try to re-send their messages (because that would double their costs) only with greylisting enabled about 90% of the spam gets caught.<br/>The <strong>Botnet Blocker</strong> is an advanced feature which allows the AS to decide on which client to apply the greylisting policy, based on wether the connection is coming from a client with a dynamic IP Address.<br/>This means that if the Botnet Blocker is enabled, clients will be told to \'come back later \' only if it\'s IP is detected as dynamic, otherwise the connection will be accepted and mail will be delivered to the scanning engine for spam detection. In this way less connections will be throttled and mail processing time decreases without lost of efficiency on blocking spam.<br/><br/>The <strong>SMTP response text upon greylisting</strong> is the textual answer a client will receive when the connection attempt has been greylisted, and comes together with a temporary error code (4xx).<br/>Once a connecting client has passed the greylisting, the triplet will be valid for the number of days defined in the <strong>Authentication time</strong> field.<br/>At last, you may also change the <strong>Triplet time</strong>, the number of minutes a greylisted client will have to wait until a second connection attempt may be made.',

### ENVELOPE SCANNING :: DNSL MANAGER
help_envelope_scanning_dnsl_manager_control => 'Here you can toggle the usage of an externally provided blacklist that contains IP addresses known to be used by spammers. <strong>Do not activate Remote Blacklist if you are using SMTP Authentication</strong> for outgoing e-mails because this may result in blocking of your own outgoing e-mails.<br/>You may <strong>add a new RBL</strong> by entering its address in the <em>DNSBL address</em> box and clicking the add-button. The <em>Blocking threshold</em> value defines the number of RBLs which must return a positive reply (meaning, the email/IP in question is blacklisted) in order to actually block the connection.',
help_envelope_scanning_dnsl_manager_list => 'This sections lists all currently known RBLs. You may granularily en- or disable certain lists. Be aware that, if RBLs are active and less than <em>Blocking threshold</em> RBLs are used, the blocking mechanism will never be enforced.',

### ENVELOPE SCANNING :: BLACK-/WHITELIST MANAGER
help_envelope_scanning_bwlist_manager_control => 'When the <em>Black-/Whitelisting engine</em> is enabled, the Open AS Communication Gateway&trade; secured through a highly flexible and scalable SMTP firewalling system. In the <em>Control Center</em>, you may en- or disable the black/-whitelisting engine itself, and create new black- or whitelist entries.<br/>Every entry has a distinct <em>Description</em>, <em>Entry</em> and <em>Modality</em>. While the <em>Description</em> may be any textual representation for a rule, the <em>Entry</em> field may contain a number of different entry formats, according to what you intend to block:</p><ul><li>Simple IP addresses,</li><li>CIDR addresses/ranges,</li><li>hyphenated IP address ranges,</li><li>e-mail addresses</li><li>hostnames</li><li>domain names</li></ul><p>Moreover, e-mail addresses and domain names may include an asterisk (*) as wildcard. Finally, the <em>Modality</em> defines on which list the newly created entry will appear.<br/><strong>Note:</strong>Whitelist entries will <strong>always</strong> override blacklist entries!',
help_envelope_scanning_bwlist_manager_blacklist => 'This list shows your currently configured blacklist.',
help_envelope_scanning_bwlist_manager_whitelist => 'This list shows your currently configured whitelist.',

#################################################### CONTENT SCANNING
### CONTENT SCANNING :: ANTI-VIRUS
help_content_scanning_anti_virus_options => 'You can set specific options for the anti-virus engines:</p><ul><li><strong>Unchecked Subject Tag:</strong> If a mail is not checked against viruses, the given tag is prepended to the e-mail subject.</li><li><strong>Recursion Level:</strong> The maximum allowed hierachy levels of recurring archives within an archive. If there are more, the archive will not be checked. <em>Recommended value: 12</em></li><li><strong>Max. Files in Archive:</strong> The maximum amount of files within an archive. If there are more files, the archive will not be checked. <em>Recommended value: 1000</em></li><li><strong>Max. Archive Size (Mb):</strong> The maximum filesize of the compressed archive. If larger, the archive will not be checked. <em>Recommended value: 10</em></li></ul>',
help_content_scanning_anti_virus_scanners => 'The appliance contains multiple anti-virus scanning engines to provide best scanning results. You can enable or disable specific engines but it\'s recommended to keep them all enabled for maximum security against virus and malware threats.',

### CONTENT SCANNING :: ATTACHMENTS
help_content_scanning_attachments_warnings => 'This section lists all e-mail addresses that receive informations from this appliance. <em>Warn on virus</em> will inform the original recipient when he/she would have received a virus-infected e-mail, while <em>Warn on banned files</em> will inform the original recipient on arrival of an e-mail which contains any banned attachment.<br/><strong>Note:</strong> Enabling <em>Warn on virus</em> is not recommended for production use.',
help_content_scanning_attachments_block_file_extensions => 'Use this form, if you simply want to disallow transferring e-mails containing files with certain extensions as attachments. The file-type is being blocked immediately after saving the blocking description and according file extension.<br/><strong>Note:</strong> The file-checking routine will only rely on the file extension, not it\'s actual content!',
help_content_scanning_attachments_block_mime_types => 'Based on a very large number of currently defined MIME-types, you may select all filetypes which should subsequently be blocked from transferring.',
help_content_scanning_attachments_group => 'For simplicity and readability reasons, the third and last possibility to block unwanted attachments is using the filetype-groups checklist. Just check the boxes of filetypes you want to block and hit the <em>Save</em>-button. This list holds the most important and often used filetypes and is based on previous filetype grouping (archives, multimedia, etc.).',
help_content_scanning_attachments_list => 'This section shows a list of all currently defined attachment blocking rules. While MIME-type and file-group block rules are only shown to be active, file extension-based blocking rules can also be deleted (other types are revoked through the checkbox-lists above).',

### CONTENT SCANNING :: LANGUAGES
help_content_scanning_languages_language_filter => 'When enabled, the language filter helps you to sort out e-mails composed of unwanted and/or unusual languages. After enabling the filtering engine, check all language you want <strong>to allow</strong>. If the language of an e-mail cannot precisely be determined, the mail is going to be processed as normal. A mail consisting of any disallowed language, will drastically higher the mail\'s spam score and, therefore, raise chances for the mail to become treated as spam. Therefore, disallowing a language does not necessarily mean that all such mails are strictly blocked.',

### CONTENT SCANNING :: POLICIES
help_content_scanning_policies_scanning_policy => 'This page gives you the possibility to define exactly what the Open AS Communication Gateway&trade; should do with mails entering by a certain way.<ul><li>External means every Mail that doesn\'t fall under one of the ways listed below.</li><li>Whitelisted hosts are mails that are coming in from a whitelisted IP range, e-mail address or domain.</li><li>Relay hosts are mails that the Open AS Communication Gateway&trade; received from an IP on the Relay Hosts list.</li><li>SMTP Authentication are Mails that are received by users who authenticated first, so normally outgoing e-mails sent by people that have an e-mail account at your company.</li></ul>By deselecting checks (like spam-check, virus-check, attachment-check) you disable that check for that certain type of mails.',

### CONTENT SCANNING :: SPAM HANDLING/SCORE MATRIX
help_content_scanning_spam_handling_matrix => '<ul><li><strong>Tag Score:</strong> If the mail gets an equal or greater score, it will be tagged.</li><li><strong>Quarantine Score:</strong> Triggers quarantine (Enduser or global mailbox, depending on the settings), if enabled.</li><li><strong>Block Score:</strong> Mail gets discarded (lost) above this score.</li><li><strong>No DSN score:</strong> Spam level beyond no DSN (Delivery Status Notification) is sent anymore. This score only takes effect for blocked e-mails since tagged/quarantined mails don\'t generate a DSN. Thus we recommend setting the Block score so high so that no legitimate mail gets discarded.</li></ul><p>With this matrix you can configure these four scores depending on the policies the sender and recipient belong to. For instance you can configure mails to recipients with enabled quarantine to never being just tagged but directly quarantined by setting the Tag score and quarantine score to be the same value.<br/>If you want to disable quarantining for a policy just set the corresponding quarantine score to 0.<br/> <strong>Keep in mind</strong> that this last manipulation will not change any of the behaviors of the other policies.</p><h4>Rules you should follow concerning scores</h4><ol><li>Scores are always positive numbers - either integers or with one decimal i.e. 5 or 6.3</li><li>Quarantine scores are always above or equal to Tag scores, moreover they are not being used in case of recipient with disabled quarantine.</li><li>Block scores are always above or equal to quarantine scores.</li><li>DSN scores are always above or equal to block scores.</li><li>To disable a score, simply set it to 0. For Example if the Tag score for Relay Hosts policy is set to 0 then no mail in this category will get a tagged header.</li></ol><p>If these rules are broken either the score is not accepted or it can cause inconsistency in the anti-spam engine.<br/>Spam usually has a score between 4 and 15, below 4 mails may be legitimate, above 15 mails are very likely to be spam.',

#################################################### QUARANTINE
### QUARANTINE :: BOX STATUS MANAGEMENT
help_quarantine_box_status_management_filter => "On this site you can manage the end-user quarantines for all recipients that are currently handled by the Open AS Communication Gateway.<br />For every single user - independent of the status of his quarantine - you have several possible actions:</p><ul><li>View all users at once or sort them according to their domain and quarantine status</li><li>Users who haven't yet confirmed their quarantine can be notified again on demand or have their entire notification process reset. According to the number of retries configured under the <em>General Settings</em> the notification will be resent to the specified user.</li><li>Already enabled quarantine boxes can be deliberately disabled</li><li>For users who have their quarantine disabled it can either be directly enabled or the whole notification process can be started one more time.</li></ul>",
help_quarantine_box_status_management_list => 'This section basically represents a number of recipients according to your filtering preferences above.',

### QUARANTINE :: GENERAL SETTINGS
help_quarantine_general_settings_timing_options => "Here you can change basic settings for your quarantine engine:</p><ul><li><strong>Number of Activation Requests:</strong> Number of activation requests sent to the user. After the last one user is timed out and his box' status is automatically set to <em>quarantine disabled</em>.</li><li><strong>Timeout after last Activation Request:</strong> After the last activation request has been sent to the user, the quarantine engine waits for the duration specified here before the personal quarantine for the specified user is really turned off. When that is happening the quarantine deactivation e-mail is sent to the user.</li><li><strong>Global items lifetime:</strong> Timespan after what quarantined items that belong to unconfirmed users will be deleted. </li><li><strong>User Items lifetime:</strong> Timespan after what quarantined items that belong to users with their quarantine enabled will be deleted</li><li><strong>Size warning address:</strong> This address is used for notification mails concerning quarantine size limit exceedings</li></ul>",
help_quarantine_general_settings_activation_request => 'Here you can specify the intervals and repetition settings for the quarantine activation request sent to the users. You may en- or disable the transmission of activation requests in general, as well as define the daytime and week-days on which activation requests are sent.<br/>It is recommended to choose a time of the day during which there usually is less e-mail traffic (by night or early morning) so that there is no unnecessary high activation during business hours.',
help_quarantine_general_settings_spam_report => 'Here you can specify the intervals and repetition settings for the quarantine spam report sent to the users which actively use their quarantine. You may en- or disable the transmission of spam reports in general, as well as define the daytime and week-days on which spam reports are sent.<br/>It is recommended to choose a time of the day during which there usually is less e-mail traffic (by night or early morning) so that there is no unnecessary high load during business hours.',
help_quarantine_general_settings_language_options => 'Define the language that is used for end-user notifications as the status report, activation request, etc.',


### QUARANTINE :: QUARANTINING OPTIONS
help_quarantine_quarantining_options_mail_handling => 'Mails Destiny represents the End of the Infected Mail\'s journey through the internet. The Open AS Communication Gateway&trade; gives 3 possible Destinies for each of the Infection types(Spam, viruses,banned attachements):</p> <ul><li><strong>Per User quarantine</strong> : Choosing this options means that the mails will be stored in the User quarantine, making it possible to release or delete this mail. </li><li><strong> Send to Admin Email</strong> : With this option the system will send Every Email Infected of the same kind to the given Email address in the below box. <strong>Note :</strong> It goes without saying that this option forces you to give an Email address first </li><li><strong>Throw Away</strong> : Mail is discarded safely, means that If this option is chosen for every Infected mail in this Category A DSN will be generated and Sent.</li></ul>',
help_quarantine_quarantining_options_global_mailboxes => 'This is the list of Mailboxes where infected mails are sent by the System if And only if, the Destiny of the Infection Category <strong> In the above box, namely \'Infected Mails Destiny\'</strong>  is  \'Admin Mailbox\'.<br/> For Instance if Spam mails destiny is \'Admin Mailbox\' And  Send spam to is : user@domain.test then every Spam mail with a score beyond quarantine Score(see The Score Matrix) and below block score, will be sent to user@domain.test.',
help_quarantine_quarantining_options_domains => 'Here, all your currently configured domains are shown in a list with checkboxes. Check all domains you would like to be handled through the Open AS Communication Gateway&trade; enduser quarantine. Only users from this domains will receive spam reports and activation requests.',
help_quarantine_quarantining_options_visibility => 'Here you can change options for your quarantine reports. Enabling \'Hide action links\' for an e-mail type removes the control links in the spam reports of all users. They will not be able to delete or release those e-mail types, although they will still be displayed. Enabling \'Hide Mails\' even does not display the mails of the type. Mails can still be released by you - the admin - in the WebGUI. If a user deletes e-mails for a day or empties his whole box, e-mail types that are not under full control will still be deleted.',

### QUARANTINE :: USER BOX ADMINISTRATION
help_quarantine_user_box_administration_filter => "On this page you can manage quarantined mails for a specified user. Using the e-mail address you can display a list of the mails currently in quarantine and make use of the following actions:</p><ul><li><strong>Release:</strong> The e-mail is instantly released from quarantine and sent to the recipient. After being releases the mail get's scheduled for deletion from the quarantine (by a cleanup process). Since it is not deleted right away it can be re-released in case it didn't reach the recipient.</li><li><strong>Delete:</strong> E-Mails that are definitely unwanted (spam, viruses or just unwanted) they can be removed from the quarantine with this.</li><li><strong>Delete All:</strong> Empties the complete quarantine box for the specified user. <strong>Use with caution! This process can't be undone</strong></li></ul> ",
help_quarantine_user_box_administration_item_list => 'Once you have selected a user\'s quarantine box in the box selection section, this list holds all currently quarantined e-mails for the specified user which may be released or deleted.',
help_quarantine_user_box_administration_status_information => 'Once you have selected s users\'s quarantine box in the box selection section, this box gives a short overview about the selected quarantine box and gives information about the box status and the number of quarantined e-mails.',

#################################################### MONITORING
### MONITORING :: DIAGNOSTICS CENTER
help_monitoring_diagnostics_center_system_status => 'The <em>System status</em> box contains the current absolute (and maybe percentual) usage or harddisk, main memory (RAM), swap, logs and the mail quarantine.',
help_monitoring_diagnostics_center_self_diagnostics => 'Here, your Open AS Communication Gateway&trade; network configuration attributes as well as configured SMTP servers and domains are checked for host- and service-availability.<br/>The section <em>Network configuration</em> is testing your DNS servers to correctly resolve domain-names and checks whether your default gateway is reachable. Moreover, DNS lookups and reverse-lookups are performed on the appliance\'s fully qualified domainname (FQDN, consisting of provided host and domainname).<br/>Section <em>Configured SMTP mailservers</em> checks if the given mailservers are reachable and SMTP daemons are running. <br/>Section <em>Configured domains</em> determines whether the DNS configuration of those domains correctly point to the AS appliance by retrieving and verifying the corresponding MX records as well as performing reverse-lookups.',

### MONITORING :: MAIL Q
help_monitoring_mail_queue_stats => 'This box shows the current number of mail in the mail queue, as well as the current size of the queue. The concept of the <strong>Mail Queue</strong> is a dynamic list of email which have been fully accepted for further delivery. The Mail Queue is stored persistently on the appliance\'s harddisk (this means that, in case of emergencies, interrupts of power supply, etc.), already accepted e-mails are not lost, but will be transfered to its designated destination SMTP server, when the appliance is up and running again.<br/><strong>Note:</strong> The Mail Queue will only store and try to process e-mails which are not older than the <em>Maximum Queue Lifetime</em>, which defaults to 6 hours and is freely configurable in <em>Mail Transfer - SMTP Settings</em>.',
help_monitoring_mail_queue_list => 'Here, the entire list of all currently available mail queues are shown, distinguishable by color and <i>Queue</i> column. There are basically three queues:<br/><ul><li><strong>Active: </strong>Mails in this queue are currently being actively processed by the mail sub-system, and are expected to get delivered shortly.</li><li><strong>Incoming: </strong>Mails in this queue have already been accepted and queued for further processing, but are not yet ready for final delivery.</li><li><strong>Deferred: </strong>Mails in this queue already passed one or more delivery attempts, whereby mail delivery did not succeed for some reason (e.g. the remote SMTP server did not respond). More details concerning the reasons of delivery failures may be obtained from the tooltip of the corresponding line within the table.</li></ul><br/>In case sender and/or recipient mail addresses are too large for proper rendering, the tooltips of the corresponding fields reveal full detail.',

### MONITORING :: PING/TRACE
help_monitoring_ping_trace_ping => 'Enter a hostname or IP address in order to send an ICMP Echo Request. This can be used for network and problem analysis within your mailing infrastructure.',
help_monitoring_ping_trace_trace => 'Enter a hostname or IP address in order to trace the route to that point, beginning from the Open AS Communication Gateway&trade;. This can be used for network and problem analysis within your mailing infrastructure. If <em>No reverse lookup</em> is checked, no reverse DNS lookups will be enforced and the result will be a list of plain IP addresses.',

### MONITORING :: PROCESS LIST
help_monitoring_process_list_plist => 'Here, the current list of processes running at the Open AS Communication Gateway&trade; is shown and consecutively refreshed. This makes it easier to keep an eye on what\'s going on inside the appliance, and which processes take up which amount on memory and processing time.',

### MONITORING :: SPAM
help_monitoring_testing_spam => 'This letter combination can be used to test the spam detection engine. If encountered in an e-mail, a spam score equal to the one you specify in \'Assigned Score\' will automatically be assigned, without subjecting it to automatic deletion. To prevent this happening to everyday e-mails, it is a requirement to make this string as complex as possible. Restrictions enforced are:</p><ul><li>At least 32 characters length</li><li>At least 5, but no more than 25 special characters (~,/,#,+,...)</li><li>No whitespaces</li></ul><p>Assigned Score should be a large positive number containing at most 1 digit in the decimal side for example 5.3 or 100 or 14.1',

#################################################### LOGGING
### LOGGING :: LIVELOG
help_logging_live_log_livelog => 'The Live-Log, based on the Open AS Real-Time-Mailflow Engine, is a consecutively refreshing list of emails, which is updated immediately upon arrival of a new e-mail.',

### LOGGING :: LOVE VIEWER
help_logging_log_viewer_search => 'The brand new <em>Log Viewer</em> is made to search and examine logs easily and effectively. Simply chose the desired time interval the search should take place in, and any search pattern to look for. The search is performed upon the appliance\' raw log files. In addition, the search pattern may also be a standard <em>Regular Expression</em>. Check the corresponding check-boxes in order to ignore case sensitivity or reverse the result order (by time).<br/><strong>Note:</strong> Depending on traffic, load and log scale, complex searches over long periods of time may take a considerable amount of time to succeed!',
help_logging_log_viewer_list => 'This box contains a complete list of daily logfiles. Each line contains all daily logfiles for exactly on month. If some certain days do not occur, no logfiles have been saved for this period (which should only be the case if the appliance is shut down).',

### LOGGING :: MAILLOG SIMPLE
help_logging_maillog_simple_search => 'In addition to the raw appliance logfiles, the new Open AS Communication Gateway&trade; includes a <em>Simple Mail-Log</em>, which consists of exactly one line per e-mail, and all important information collected about that e-mail. This means, that searching for what has actually happened to a certain e-mail is much easier through this interface. The search form is similar to the <em>Log Viewer</em>, except regular expressions cannot be used, and a processing result (the decision what has been done with the e-mail) can be chosen.<br/><strong>Note:</strong> While the <em>Log Viewer</em> crawls through the original raw logs whose search results are authoritative, the Simple Mail-Log results are, although supposed to be consistent and complete, non-authoritative.',
help_logging_maillog_simple_list => 'This box provides a list of all currently recorded simple mail-logs.',

### LOGGING :: STATISTICS
help_logging_statistics_entire_traffic_stats => 'This page gives detailed statistical representations of the past traffic activity of the Open AS Communication Gateway&trade;. The traffic statistics can be narrowed down to certain time-slices, as the last 24 hours, the last week, the last month or the last year. Moreover, you may show or hide certain types of emails (passed, tagged, blocked, etc.) through the checkboxes on the right side of the diagram. You may also download a image copy or the currently shown diagram.',

#################################################### MODULES
### MODULES :: LICENCE MANAGEMENT
help_modules_licence_management_info => 'Here you can see what licenses you have already activated and how long they will be active. If (for some reason) that information does not seem correct to you, click on "Update License File" to get the newest information. Only licenses available for the firmware version you have currently installed are listed here.',
help_modules_licence_management_update => 'Here you may enter a voucher. The license file will be downloaded from Open AS and the desired feature is immediately unlocked.',
help_modules_licence_management_upload => 'If the appliance can not connect to the Open AS license server you can get a license file from the Open AS support team via <a href="mailto:team@openas.org?subject=I%20need%20a%20valid%20license%20file%20to%20upload%20to%20my%20AS%20Communication%20Gateway">e-mail</a>. Upload the file you will receive here and it will override any current licensing information.<br/> <strong>We recommend, that you enable direct internet access for your appliance so it can connect to our license server online</strong>',







###################################################################################################
################################################## Obsolete #######################################
###################################################################################################

# CONTENT
## ANTISPAM
### DOMAINS
#### TEXT
antispam_domains_abstract => 'The mail exchange (MX) record of your domains should point to your Open AS Communication Gateway&trade; in order to receive and analyze incoming e-mails. For each domain you have to specify a relay mail server to which the messages should be forwarded.',

heading_antispam_domains_na	=> 'No SMTP server defined!',
antispam_domains_text	=> 'In order to define domains and map them to a SMTP server, please first add at least one SMTP server under the menu item <a href="/admin/antispam/smtp_servers" title="add a SMTP server first">Anti-Spam Configuration &raquo; SMTP Servers</a>.',

heading_antispam_domains_adddomain => 'Add new domain',
antispam_domains_domain_name => 'Domain',
antispam_domains_dest_mailserver => 'Mailserver address',
antispam_domains_enabled => 'enabled',

heading_antispam_domains_multiadddomain => 'Add multiple domains via file upload',
antispam_domains_list_file => 'Domain file (.csv)', 
antispam_domains_multi_dest_mailserver => 'Mailserver address', 
antispam_domains_predelete => 'Pre-delete domains',

heading_antispam_domains_bulk_assignment => 'Batch reassignment to SMTP servers', 
antispam_domains_src_mailserver => 'Currently assigned SMTP server', 
antispam_domains_smtp_dest => 'New assigned SMTP server',

heading_antispam_domains_configured_domains => 'Configured domains',

## APPLIANCE
### BACKUP
#### TEXT
title_appliance_backup => 'Backup Manager',
abstract_appliance_backup => 'Backup and restore the configuration of your Open AS Communication Gateway&trade;. You can either download the configuration as an encrypted file to your local drive or upload a stored backup file.',

heading_appliance_backup_create => 'Create a backup',
appliance_backup_create_text => 'By clicking the button below you can create a backup of all your current settings.',

heading_appliance_backup_upload => 'Upload a backup file',

heading_appliance_backup_list => 'Available backups',
appliance_backup_backup_file => 'Chose backup file',
#### OVERLAY
appliance_backup_install_confirm_message => '<strong>Installing this backup will cause the appliance to restart!</strong> New network settings will be:',

## APPLIANCE
### SYSTEM
#### TEXT
appliance_system_timezone => 'Timezone',
appliance_system_ntp_server => 'NTP Server',
appliance_system_addserver => 'Add a NTP server',
#### ERRORS
error_ntp_exists => 'This NTP server has already been added',

## APPLIANCE
### USER
#### TEXT
appliance_user_user => 'Username',
appliance_user_password => 'Current password',
appliance_user_newpassword1 => 'New password',
appliance_user_newpassword2 => 'Re-type new password',
appliance_user_adminpassword => 'Current admin password',
appliance_user_newsshpassword1 => 'New password',
appliance_user_newsshpassword2 => 'Re-type new password',


# Errors
error_missing_fields    => 'One or more required fields are empty.',
error_invalid_fields    => 'One or more fields contain invalid values.',
error_is_missing        => 'is missing.',
error_is_invalid        => 'is invalid.',
error_invalid_ip_address    => 'has an invalid IP address.',
error_gateway_outof_subnet  => 'is not in the specified subnet.',
error_invalid_character	=> 'Please remove the invalid characters in all of the follwing values:',

error_backup_couldnt_read_file  => 'Could\'t read file',
error_backup_file_in_use        => 'Please try again a little bit later, somebody else is copying this file',
error_backup_could_not_store_upload => 'Could\'t store your uploaded file as', 
error_backup_could_not_open_file => 'Could\'t open file',
error_backup_read_from_file     => 'Could\'t read from file',
error_backup_no_upload_file_found => 'No upload file received',
error_backup_file_not_found     => 'File not found',

error_notification_settings_invalid_smtp_server => 'Invalid SMTP server',
error_notification_settings_invalid_account => 'Invalid or existing recipient',
error_invalid_score => 'The provided score is not valid , please check the rules in help page',

error_entry_exists => 'Entry already exists',
error_entry_exists_in => 'New entry overlaps with %s from %s',
error_entry_gap_blacklist => 'Mails from some addresses %s will still be accepted because of existing %s entries!',
error_entry_gap_whitelist => 'Whitelisted addresses %s will be accepted; all others are blocked because of an existing %s entry!',
error_entry_illegal => 'You cannot whitelist %s as long as there are %s entries for this domain!',
error_entry_doestn_exist => 'Entry doesn\'t exist',




# Status messages

status_interface_updated        => 'Interface settings applied.',
status_dns_updated              => 'DNS settings applied.',
status_smtpd_banner_updated     => 'Banner Message updated.',
status_setting_updated          => 'Setting updated.',
status_domain_created           => 'New Domain created.',
status_domains_domain_list_added    => 'The list of domains has been added.',
status_domains_parse_error      => 'There was a parsing error on line: ',
status_host_domain_name_updated => 'Host/Domainname updated.',
status_spam_settings_updated    => 'Spam Settings updated.',
status_backup_created           => 'Backup generated successfully',
status_backup_deleted           => 'Backup deleted successfully',
status_backup_installed         => 'Backup installed successfully',
status_backup_upload            => 'Backup upload successfully',
status_user_password_changed    => 'The password has been changed.',
status_timesync_success         => 'The timeservers have been updated.',
status_notification_settings_changed => 'The recipient details have been changed.',
status_notification_settings_recipient_deleted => 'The following recipient has been deleted: ',
status_notification_settings_new_recipient => 'The following recipient has been added: ',
status_advanced_smtp_settings_updated => 'Advanced SMTP Settings have been updated.',
status_whitelist_ip_created     => 'IP was added to the whitelist.',
status_blacklist_ip_created     => 'IP range was added to the blacklist.',
status_policy_saved		      => 'The policy has been saved',
status_timezone_updated		  => 'The timezone was updated',
status_backup_uploaded		  => 'Backup successfully uploaded',
disabled_no_license_up2date  => 'unavailable in open-source version (commercial license required)',


logging_space			=> 'Logs',
quarantine_space		=> 'Quarantine',

#time related
daily => 'daily',
hours => 'Hours',
day_hours => 'Time of day',
week_days => 'Week Days',
day_mon => 'Monday',
day_tue => 'Tuesday',
day_wed => 'Wedndesday',
day_thu => 'Thursday',
day_fri => 'Friday',
day_sat => 'Saturday',
day_sun => 'Sunday',

# Frontpage 
hello_morning			=> 'Good morning',
hello_day				=> 'Howdy',
hello_evening			=> 'What a nice evening',
hello_night				=> 'Looks like you\'re a nightowl,',	
graphical_summary		=> 'Graphical interpretation of Spam Statistics (last 24h)',
used       				=> 'used',
overview       			=> 'at a glance',
heading_frontpage       => 'Open AS Communication Gateway',
welcome_text            => 'Welcome to the Open AS Communication Gateway&trade; Administration Interface.',
passed_clean            => 'Passed',
passed_spam             => 'Tagged (SPAM)',
tagged_short            => 'Tagged',
blocked_spam            => 'Blocked (SPAM)',
blocked_greylisted      => 'Blocked (Greylisting)',
blocked_blacklisted     => 'Blocked (Blacklist)',
blocked_virus           => 'Blocked (Virus)',
blocked_banned          => 'Blocked (Banned Attachment)',

all_time                => 'all time',
today                   => 'today',
last24h                 => 'last 24h',
lasthour                => 'last hour',

systeminfo              => 'Appliance System Information',
service_info            => 'Appliance Service Status',
antispam_service        => 'Anti-Spam Engine',
antivirus_service       => 'Anti-Virus Engine',
mail_agent              => 'Mail Agent',
database_service        => 'Database Engine',
mail_logging            => 'Mail Logging Engine',
smtpauth_service        => 'SMTP Authentication Proxy',

running                 => 'running',
not_running             => 'not running',

serialnumber            => 'Serial Number',
cpu_usage               => 'CPU Usage',
cpu_avg_1h               => 'Avg. CPU Usage (last hour)',
memory_usage            => 'Memory Usage',
memory_usage            => 'Memory Usage',
load_average            => 'Load Average (last 15min)',
uptime                  => 'System Uptime',

# Appliance #
title_appliance                         => 'Appliance Administration',
abstract_appliance                      => '',
product				                    => 'Product Type',
title_appliance_update_currentversions  => 'Current Versions',
reboot_required							=> 'A Restart of the System to complete the last update is necessary',
virus_engine_versions                   => 'Virus Engine Version',
antispam_engine_rules_versions          => 'Anti-Spam Engine Rules Versions',
system_version                          => 'System Version',
system_version_available                => 'Available Security Version',
last_update                             => 'Last version update',
build_version                           => 'Build',
revision_version                        => 'Revision',


# Appliance - System #
title_appliance_system                  => 'Appliance System Administration',
abstract_appliance_system               => 'Administer the host and domain name as well as the time settings of your Open AS Communication Gateway.',
heading_appliance_system_hostdomname    => 'Hostname/Domainname Settings',
heading_appliance_system_timezone       => 'Timezone',
heading_appliance_system_timesync       => 'Timeserver Synchronization',
heading_notification_settings_addaccount => 'Add new recipient',
heading_appliance_system_syslog         => 'External Syslog Server',
heading_appliance_system_sshd			=> 'Secure Shell Service',
syslog_host                             => 'Syslog Host',
syslog_port                             => 'Port',
status_syslog_set                       => 'Syslog Settings updated.',
appliance_system_sshd_status			=> 'Listen on port 22',
status_sshd_set							=> 'SSH Settings updated.',

# Appliance - Licence Management #
title_appliance_license                 => 'Licence Management',
abstract_appliance_license              => 'You can add new or renew existing licences for existing additional services provided by the Open AS Communication Gateway.',
appliance_license_info_header           => 'Licencing Information',
appliance_license_never_updated         => 'The licencing information has up until now never been updated.',
appliance_license_last_updated          => 'The licensing information has last been updated on ',
appliance_license_valid_until           => 'is valid until',
appliance_license_expired_on          	=> 'has expired on',
appliance_license_not_activated         => 'hasn\'t yet been activated',
license_file_downloaded					=> 'Licence information has been updated',
care_pack								=> 'CarePack',
renew_licence							=> 'renew licence',
request_licence							=> 'request a licence for this module',
up2date									=> 'Up2Date',
virtual_use                             => 'Operating Licence (virtual)',
update_license_file                     => 'Update Licence File',
heading_appliance_license_enter_voucher => 'Enter a new licence key',
licence_get_info                        => 'get more detailed information on the Open AS website',
error_code_short_xmlrpc_400				=> 'Transfered licence key was not accepted.',
error_code_short_xmlrpc_403				=> 'Authentication with License Server failed.',
error_code_short_xmlrpc_404				=> 'The entered licence key is not valid.',
error_code_short_xmlrpc_405				=> 'The entered licence key is not for your product.',
error_code_short_xmlrpc_409				=> 'Licence key already used.',
error_code_short_xmlrpc_410				=> 'Licence unknown to the Licence Server.',
error_code_short_xmlrpc_417				=> 'Licence Information could not be updated, please contact support.',
error_code_short_xmlrpc_500				=> 'An unknown error has occurred.',
error_code_short_xmlrpc_999				=> 'The Open AS Licence Management is currently not reachable.',



voucher 								=> 'Licence Key',
heading_appliance_upload_license_file   => 'Upload new licence file',
appliance_license_license_file          => 'Licence file (ULF)',
license_file          					=> 'Licence file (ULF)',


# Appliance - Reset #
title_appliance_reset                   => 'Reset Appliance Settings',
abstract_appliance_reset                => 'Set back the appliance settings to factory default or delete statistical data.',
heading_appliance_reset_grade           => 'Reset Level',
heading_appliance_reset_confirm_grade   => 'Confirm Reset Level',
appliance_reset_choose                  => 'Select Reset Extent',


# Appliance - Processlist #
title_appliance_processlist				=> 'Process List',
abstract_appliance_processlist			=> 'Shows all currently running processes on the Open AS Communication Gateway&trade;, including the corresponding process IDs, CPU- and memory usages. The list is consecutively refreshed.',




# Appliance - Update #
update_available						=> 'A new update is available',
get_update								=> 'Get the newesest update',
title_appliance_update                  => 'Up2Date Settings',
abstract_appliance_update               => 'Set Up2Date Automation Settings and update your appliance here.',
update_automation_settings              => 'Up2Date Settings: Automatically...',
auto_settings_update                    => 'Get the latest Update Information',
auto_settings_download                  => 'Download security updates',
auto_settings_upgrade                   => 'Install security updates',
auto_settings_auto_newest               => 'Install the latest system version',
automation_settings_configured			=> 'Up2Date Settings updated',
title_current_update_versions			=> 'System and Security Versions at a Glance',
current_system_version					=> 'Currently installed System Version',
latest_security_version					=> 'Latest available Security Update',
latest_feature_version					=> 'Latest available System Version',
last_version_information_update			=> 'Last Update of Version Information',
update_info_underground_website			=> 'For information on this update, check the Open AS support website',
update_now                              => 'Get latest Update Information',



newest_sec_version_installed            => 'You have the newest security version installed.',
newest_feature_version_installed        => 'You have the newest feature version installed.',
available_security_update	        	=> 'Available Security Updates',
available_system_version_update	        => 'Available System Version Updates',
heading_get_up2date_license        		=> 'Get an Up2Date or Operating licence to make system updates',
install_main_version                    => 'Install feature version now',
title_appliance_update_running          => 'Up2Date Running',
title_appliance_update_sec_version      => 'Security Update',
title_appliance_update_main_version     => 'System Update',


# Appliance - User #
title_appliance_user                    => 'Change Passwords',
heading_appliance_user_change_password  => 'Change the current password for user "admin".',
abstract_appliance_user                 => 'Change the password for the current user. Your new password must contain at least 8 characters, including at least 1 digit and 1 special character out of the following list: @%-_.:,;#+*',

# Appliance - About #
title_appliance_about                   => 'About Open AS Communication Gateway',
abstract_appliance_about                => 'Information about used software components and a list of the development team.',
development_team                		=> 'Open AS Communication Gateway&trade; Development Team',
open_source_as	                		=> 'Software used in the Open AS Communication Gateway',
open_source_as_text                		=> '<p>The Open AS Communication Gateway&trade; utilizes various customized open source software components like <a href="http://spamassassin.apache.org/">SpamAssassin</a> and <a href="http://www.amavis.org/">AMaViS</a>.</p><p>For a complete list and the source code, please write an e-mail to <a href="mailto:team@openas.org?subject=AS%20Communication%20Gateway%20open%20source%20software%20component%20list">team@openas.org</a> and Open AS will send you a CD with the required data.</p>',
heading_appliance_user_change_password_ssh => 'Set password for Emergency Commands',


# Appliance - Backup #


create				                    => 'Create',
create_backup                           => 'Create Backup',
file                                    => 'File',
backup_install_confirm_message          => 'New network settings will be:',

# Appliance - System - Admin Range #
add_admin_range	=> 'Add Administration IP-Ranges',
admin_range => 'Administration IP-Ranges',
admin_range_set => 'Administration IP-Range configured',
error_too_big_admin_range => 'Administration Range is too big. Please use a range of maximum 65000 IP',

# Notification - Settings #
title_appliance_notification_settings   => 'Notification Settings',
abstract_appliance_notification_settings   => 'Administer recipients of notifications that are sent by the Open AS Communication Gateway.',
heading_notification_settings_recipients   => 'Configured Recipients',
notification_settings_username  => 'Name',
notification_settings_smtp_server => 'SMTP Server',
notification_settings_smtp_login => 'SMTP Login',
notification_settings_smtp_password => 'SMTP Password',
notification_settings_smtp_use_ssl => 'Use TLS',

# Anti-Spam #
title_antispam                  => 'Anti-Spam Configuration',
abstract_antispam               => 'This graphic visualizes the work flow of the Open AS Communication Gateway; From the first whitelists to pass over several blacklist and content filters until the successful delivery.',

# Anti-Spam - General #
title_antispam_general          => 'General Settings',
abstract_antispam_general       => 'Enable or disable the greylisting engine, specify the spam-tag, the spam test string and its correspondant score.',
heading_antispam_general_spam   => 'Spam Settings',
spam_subject_tag                => 'Spam Subject Tag',
spam_admin                      => 'Spam Administrator',
heading_antispam_general_gtube  => 'Spam Test String',
gtube_tag                       => 'Spam Test String',
gtube_score                     => 'Attributed score',
gtube_modified					=> 'Test String settings have been modified',
gtube_len_invalid				=> 'UBE String too short',
gtube_special_invalid			=> 'Too few or too many special characters in UBE string',
gtube_white_invalid				=> 'Whitespace characters not allowed in UBE string',
smtpd_banner 					=> 'Banner Message',
antispam_helo_required          => 'Require HELO/EHLO',
antispam_sender_domain_verify   => 'Sender Domain Verification',
antispam_sender_fqdn_required   => 'Sender FQDN Required',
antispam_rfc_strict             => 'Require RFC Compatibility',
incoming_smtp_connection        => 'Allowed Incoming SMTP Connections per 30 Minutes',
smtpd_timeout                   => 'SMTP Timeout (sec)',
smtpd_queuetime                 => 'SMTP Queue Lifetime (hours))',
antispam_use_greylisting        => 'Greylisting',
antispam_use_selective_greylisting        => 'Botnet Blocker',
basic_greylisting_status 		=>'Basic Greylisting',
selective_greylisting_status 	=>'Botnet Blocker',
abstract_antispam_score  		=> 'Modify the score settings for each policy category. To change a value, simply click on the number and use the appearing input. Your changes only take action <strong>after you confirmed the changes</strong> by clicking the save button.',
    
# Anti-Spam - Domains #
title_antispam_domains  => 'Domain Management',



antispam_domains_domain => 'Domain',
antispam_domains_submit => 'Add Domain',
dest_mailserver_addr => 'Destination Mailserver Adress',
dest_mailserver => 'SMTP Mailserver',
error_domain_exists => 'There is already one domain with this name',
error_domain_not_exists => 'The domain does not exist.',
error_domain_list_too_big => 'The uploaded list exceeds the maximum size of bytes: ',
error_domain_parse_line => 'Parsing error at line: ',

# Antispam - Recipients #
title_antispam_recipient_maps            => 'Recipients',
abstract_antispam_recipient_maps         => 'Specify valid addresses for your Domains. If no address is entered (manually or via LDAP) every address will be accepted.',
heading_antispam_recipients_addrecipient => 'Add Recipient',
heading_antispam_recipients_multiadd_recipients => 'Upload Recipient List',
list_file								 => 'Recipient list file',
recipient_user							 => 'User',
status_recipient_added                   => 'Recipient added',
status_recipient_list_added              => 'Recipient list added',
antispam_recipients_recipient_list_file  => 'Recipients List (CSV)',
antispam_recipients_list_predelete       => 'Pre-Delete Recipients',
show_ldap                                => 'Show LDAP Cache',
select_domain                            => 'Please select a domain',
heading_show_selected_recipients		 => 'Show selected Recipients',
choose_domain							 => 'Choose a domain',
heading_display_recipients_list			 => 'Select Recipients to display',
heading_recipients_list                  => 'Defined Recipients for',
delete_all_recipients                  	 => 'Delete all manually added recipients for this domain',


# Antispam - SMTP Settings #
title_antispam_smtp             => 'SMTP Settings',
abstract_antispam_smtp          => 'Administer restrictions for connecting clients that do not follow the SMTP standard.',
smtp_restrictions               => 'Client Restrictions',
heading_antispam_smtp_advanced  => 'Advanced Settings',
max_connections                 => 'Maximum connections per IP in 30 minutes',
ldap_server                     => 'LDAP Server(s)',
ldap_user                       => 'Username',
ldap_pass                       => 'Password',
ldap_base                       => 'Base DN',
ldap_filter                     => 'Filter',
ldap_property                   => 'Property',
ldap_search_addr                => 'Test E-Mail Address',
ldap_test_failure               => 'At least one LDAP Server failed a test.',
connection_to_ldap_server       => 'Connection to server',
addr_found_on_ldap              => 'Testing for given mail address on',
ignore_ldap_check               => 'Do not test LDAP Settings',


# Anti-Spam - SSL Certificate #
heading_antispam_smtp_ssl       => 'SSL Certificate',
antispam_smtp_ssl_certificate	=> 'Certificate',
antispam_smtp_ssl_key		=> 'Private key',
antispam_smtp_ssl_na		=> 'none available',
pem_file			=> 'CRT or KEY file',

# Anti-Spam - Anti-Virus #
title_antispam_antivirus => 'Anti-Virus Settings',
abstract_antispam_antivirus => 'Chose the antivirus engine(s) and calibrate settings regarding archive scanning.',
antispam_antivirus_select => 'Anti-Virus Scanners',
clamav => 'Clam AV',
kasperskyav => 'Kaspersky Anti-Virus',
heading_antispam_antivirus_options => 'Anti-Virus Options',
unchecked_subject_tag => 'Unchecked Subject Tag',
archive_recursion => 'Recursion Level',
archive_maxfiles => 'Max. Files in Archive',
archive_maxfilesize => 'Max. Archive Size (Mb)',
status_antivirus_options_updated => 'Anti-Virus options updated.',
score_matrix_use => "With the score matrix you can define spam scores",
# Anti-Spam - IP Range Whitelist

title_policy_iprangewhitelist => 'Internal IP / Range Whitelist',
abstract_policy_iprangewhitelist => 'In this section you can define IP ranges which are allowed to send outgoing mails through the Open AS Communication Gateway&trade; without SMTP authentication required e.g. servers or local network ranges if you want any user to be allowed to send e-mails.',
range_start => 'Range Start',
range_end => 'Range End',
ip_ranges => 'IP Ranges',
ip_or_range => 'IP / Range',
ip_range_whitelist_added => 'IP-Range added',
ip_range_whitelist_deleted => 'IP-Range deleted',


# Anti-Spam Score
scores_changes_unsaved => 'There are unsaved changes on this page! Please click save for them to take effect.',
scores_defaults_unsaved => 'The scores have been set to default, changes will only take effect after saving.',
title_antispam_score => 'The Score Matrix',
score_settings => 'Score Settings',
manage_score_settings => 'Manage spam scores and the DSN limit',
set_to_default => 'set to default',
info_score => 'Info Score',
clean_score => 'Clean',
spam_score => 'Tagged as Spam',
do_not_tag => 'never tag',
block_score => 'Blocked',
do_not_block => 'never block',
score_updated => 'Score Settings Updated',
status_incorect_scores => 'The new score has to be higher than the old one',
tag2_score  => 'Tag',
kill_score  => 'Quarantine',
cutoff_score  => 'Block',
dsn_limit_score  => 'No DSN',
quarantine_activated => 'enabled quarantine',
quarantine_disactivated => 'disabled quarantine',
# policy #
title_policy                  => 'Scanning Policy',
abstract_policy               => 'This page gives you the possibility to define exactly what your Open AS Communication Gateway&trade; should do with mails entering by a certain way.',

# policy - Internal e-mails
policy_default	=> 'Default',
policy_relay_hosts	=> 'Relay Hosts',
policy_internal_ip_whitelist	=> 'Whitelisted Hosts',
policy_smtp_authentication	=> 'SMTP authentication',
policy_banned_attachment	=> 'Illegal attachments',



# policy - Attachments #
title_policy_attachments => 'Attachment Settings',
abstract_policy_attachments => 'Administer recipient warnings on e-mails containing viruses or banned attachments. Define file extensions which should be blocked.',
recipient_warnings => 'Recipient Warnings',
warn_recipient_virus => 'Warn on virus',
warn_recipient_virus_enabled => 'Recipients will be warned on viruses',
warn_recipient_virus_disabled => 'Recipients will not be warned on viruses',
banned_attachment => 'File Extension',
banned_attachment_added => 'Banned attachment added',
banned_attachment_deleted => 'Banned attachment deleted',
warn_recipient_banned_file => 'Warn on banned files',
blocked_attachment_file_extension => 'File extension to be blocked',
warn_recipient_banned_file_enabled => 'Recipients will be warned on banned files',
warn_recipient_banned_file_disabled => 'Recipients will not be warned on banned files',
title_policy_add_attachment => 'Add Custom Block Rule', 
title_policy_add_groups => 'Add a Group of Blocked Attachments', 
title_policy_add_contenttypes => 'Add Content-Type Blocked Attachment', 
blocked_extension => 'File extension', 
blocked_group => 'Blocked group', 
blocked_contenttype => 'Blocked content-type', 
blocked_attachments => 'Blocked Attachments', 
banned_attachment => 'Extension/Content Type',
policy_attachments_choose_group => 'Block this group',       
policy_attachments_customize_group => 'Custom Exceptions',       
policy_attachments_select_group => 'Select a group',       
policy_attachments_select_group_first => 'Select a group first',     
policy_attachments_archives => 'Archives',       
policy_attachments_multimedia => 'Multimedia Files',       
policy_attachments_images => 'Images and Graphics',       
policy_attachments_office_data => 'MS Office',       
policy_attachments_executables => 'Executables',       
policy_attachments_nothing => 'Nothing',       
policy_attachments_only_custom_rules => 'Custom rules',       
content_type_description => 'Blocked Content-Type', 
invert_selection => 'Invert', 
all_selection => 'Select all', 
filter_by => 'Filter elements by ',    
attachments_choice => 'Bann using', 
list_of_blocked_attachments => 'Blocked Attachments Rules', 
content_types =>'Content Types', 
extensions => 'File Extension', 
tobedeleted => 'Blocked Attachment to be deleted', 

# postfwd - black-/whitelist manager +  RBLs
title_policy_bwlistman => 'Black-/Whitelist Manager',
abstract_policy_bwlistman => 'Enable, disable and administer IP-, mail-address-, and domain-based black- and whitelisting.',
bwlistman_status => 'Black-Whitelisting Engine',
bwlistman_entry_desc => 'The <em>Entry</em> field may contain IP addresses, CIDR addresses, hyphenated IP ranges, e-mail addresses, hostnames and domain names. You may also use an asterisk (*) as wildcard for mail and domain addresses.',
bwlistman_add_entry => 'Add a new entry',

bwlistman_help_general => 'The Black-/Whitelist Manager allows you to granularly define black- and whitelisting rules in order to protect your e-mailing infrastructure.',

bwlistman_help_add => 'The <em>Entry</em> field may contain several kinds of generic sender-specific rules. Accepted syntactical options are IP addresses, IP-CIDR addresses/networks, hyphenated IP ranges, e-mail addresses, domain addresses and hostnames. Moreover, e-mail addresses, domain addresses and hostnames may be entered in conjuction with an asterisk (*) which will be interpreted as generic wildcard.<br/><br/><strong>Examples:<br/></strong>10.0.0.1 (single IP)<br/>192.168.1.0/24 (CIDR Range)<br/>192.168.1.1 - 192.168.2.254 (IP Range)<br/>user@domain.tld (mail address)<br/>*@domain.tld (multiple mail addresses)<br/>*.mail.domain.tld (reverse lookup)<br/><br/><strong>Note:</strong> Whitelisted entries will override blacklisted entries, while both lists override greylisting and bot-net blocking, if enabled.',

bwlistman_entry => 'Entry',
bwlistman_type => 'Type',
bwlistman_desc => 'Description',
bwlistman_modality => 'Modality',
bwlistman_add_bl => 'Add to Blacklist',
bwlistman_add_wl => 'Add to Whitelist',

bwlistman_gui_ip_addr_cidr => 'IP/Net',
bwlistman_gui_ip_addr_plain => 'IP',
bwlistman_gui_ip_range => 'IP Range',
bwlistman_gui_domainname_wildcard => 'Reverse',
bwlistman_gui_domainname => 'Reverse',
bwlistman_gui_mail_addr_wildcard => 'E-Mail',
bwlistman_gui_mail_addr => 'E-Mail',
bwlistman_gui_hostname_wildcard => 'Host',
bwlistman_gui_hostname => 'Host',


# policy - IP Blacklist #
title_policy_ipblacklist => 'IP Blacklist',
ip_blacklisting => 'IP Blacklisting',
abstract_policy_ipblacklist => 'Enable or disable checks of remote blacklists and specify own IP addresses that should be blocked.',

#policy - Remote Blacklist #
abstract_policy_remoteblacklist => 'Enable, disable or change the order of remote blacklist queries on incoming e-mails. You can also add your own RBL and subsequently incorporate additional RBLs into the blacklisting policy.',
heading_policy_ipblacklist_form => 'Add IP Range To Blacklist',
heading_policy_ipblacklist_list => 'Current Blacklist Entries',
heading_policy_rbl_form => 'Add a custom RBL',
heading_policy_rbl_list => 'Configured RBLs',
policy_rbl_list_text => '<strong>Attention:</strong> The order of the RBLs reflects the order they are being processed and needs to be specifically safed. The sequence can be changed by simply <strong>drag&amp;drop</strong> the single entries.',
user_rbl_input => 'specified RBL',
rbl_order_saved => "The new order has been saved",


# policy - IP Whitelist #
title_policy_ipwhitelist => 'IP Whitelist',
ip_whitelisting => 'IP Whitelisting',
abstract_policy_ipwhitelist => 'Specify IP addresses which should be excluded from greylisting and, depending on policy settings, eventually be excluded from spam or virus checks.',
heading_policy_ipwhitelist_form => 'Add IP Address To Whitelist',
heading_policy_ipwhitelist_list => 'Current Whitelist Entries',

# policy - E-Mail Address Blacklist #
title_policy_emailaddressblacklist => 'E-Mail Address Blacklist',
emailaddress_blacklisting => 'E-Mail Address Blacklisting',
abstract_policy_emailaddressblacklist => 'Configure the blacklist for sender e-mail addresses or whole domains from which e-mail messages should always be blocked.',
heading_policy_emailaddressblacklist_form => 'Add E-Mail Address To Blacklist',
heading_policy_emailaddressblacklist_list => 'Current Blacklist Entries',

# policy - E-Mail Address Whitelist #
title_policy_emailaddresswhitelist => 'E-Mail Address Whitelist',
emailaddress_whitelisting => 'E-Mail Address Whitelisting',
abstract_policy_emailaddresswhitelist => 'Configure the Whitelist for E-Mail addresses or whole Domains from which EMail messages should always be accepted.',
heading_policy_emailaddresswhitelist_form => 'Add E-Mail Address To Whitelist',
heading_policy_emailaddresswhitelist_list => 'Current Whitelist Entries',

# antispam - External Blacklists #
title_policy_remoteblacklist => 'RBL Mananger',
system_provided_rbls => 'System provided RBLs',
user_defined_rbls => 'User Defined RBLs',
add_user_rbl => 'RBL Address',
rbl_checks => 'Remote Blacklisting',
rbl_checks_for_zen_are => 'RBL (zen.spamhaus.org)',
rbl_disabled => 'Remote Blacklisting Disabled',
rbl_enabled => 'Remote Blacklisting Enabled',
custom_rbl_added => 'Custom RBL has been successfuly added',    
# Logs & Reports #
attachments => 'Attachment',
you_can_view => 'You can either view the',
last_ninty_days => 'the logfiles of the last 90 days',

## Statistics ##
caption      		=> 'Caption',
statistics_for      => 'Statistics for',
switch_to      		=> 'Switch to',
last_24h            => 'Last 24h',
last_week           => 'Last Week',
last_month          => 'Last Month',
last_year           => 'Last Year',
livelog             => 'Live Log',

from_domain         => 'Sender Domain',
to_domain           => 'Recipient Domain',
top_100             => 'Top 100 Domains',
back                => 'back',
show                => 'Show',

mail_from           => 'sender',
rcpt_to             => 'recipient',
subject             => 'subject',
date                => 'date',
size                => 'size',
time                => 'time',
details             => 'details',
details_from_selected_mail             => 'Details for selected e-mail',
received             => 'received',
no_livelog_data             => 'Either you haven\'t <strong>properly configured</strong> your Open AS Communication Gateway&trade; yet or there has simply been <strong>no e-mail traffic up until now</strong>. We recommend running an <a href="/admin/appliance/diagnostics">appliance diagnose</a> to determine whether everything is working properly.',

## SMTPCrypt ##
title_smtpcrypt		=> 'Mail Encryption',
abstract_smtpcrypt	=> 'Administer your E-Mail encryption settings',
heading_smtpcrypt_globals => 'Global configuration attributes',
smtpcrypt_global_crypttag => 'Identification tag',
smtpcrypt_global_packtype => 'Encoding type',
smtpcrypt_global_pwhandling => 'Password assignment',
smtpcrypt_global_pwhandling_generate => 'Generate random password',
smtpcrypt_global_pwhandling_preset => 'Always use preset password',
smtpcrypt_global_default_pw => 'Preset password',
smtpcrypt_status_setglobals => 'Global mail encryption settings have been successfully saved',
smtpcrypt_global_status => 'Engine status',


### MailQueue statistics ####
mailq_stat => 'Mail Queue',
mailq_curr_num => 'Current number of mails in the queue',
mailq_curr_size => 'Current size of the queue',
mailq_purge => 'Flush',
mailq_size_header => 'Current Count/Size',
mailq_count_last24 => 'Queue count for the last 24h',
mailq_size_last24 => 'Queue size for the last 24h',
mailq_purged => 'Queue flush has been initiated',


#Quarantine

#frontpage
title_quarantine =>'Quarantine',
abstract_quarantine =>'Manage the end-user quarantine for your Open AS Communication Gateway&trade; in every little detail.',
quarantine_heading => 'An enabled end-user quarantine holds many advantages',
quarantine_heading_release => 'Release wanted e-mail',
quarantine_release_text => 'No more wondering where wanted e-mails magically disappeared to. Users can release their wanted e-mail by themselves with just one click. No need for additional credentials - this quarantine is solely based on e-mail.',
quarantine_heading_manage => 'Manage the box status',
quarantine_manage_text => 'Every single quarantine box can be managed. Release, re-release or delete e-mails at once or just have a comprehensive overview of the quarantine box stats for every user.',
quarantine_heading_config => 'Administrate a user\'s box',
quarantine_config_text => 'For users who missed their activation process or upon request, the quarantine status can explicitly turned on or off. The activation request process can also be started at any time or - if already running - restarted as well.',
quarantine_heading_delete => 'Get rid of nasty spam',
quarantine_delete_text => 'With the status report e-mails with malicious content, viruses or banned attachments can be deleted. These unwanted e-mails can either be purged one by one, by days or the whole quarantine box.',

title_quarantine_settings => 'Quarantine General Settings',
abstract_quarantine_settings => 'Enable or disable the end-user quarantine and modify the basic settings and language preferences.',
quarantine_enabled => 'The end-user quarantine System is now enabled',
quarantine_disabled => 'The end-user quarantine System is now disabled',
quarantine_settings => 'Quarantine timing options',
quarantine_intervals => 'Dispatch options for end-user notifications',
quarantine_status => 'Per User quarantine status',
quarantine_settings_changed => 'Quarantine settings have been changed successfully',
quarantine_intervals_changed => 'Quarantine intervals have been changed successfully',
quarantine_language_changed => 'The language for end-user notifications and reports has been changed',
quarantine_template_languages => 'Current Language',
quarantine_languages => 'Choose language for end-user notifications',
quarantine_user_toggle => 'Enable/Disable quarantine by Recipient',
title_quarantine_recipient => 'User\'s Box Administration',
abstract_quarantine_recipient => 'Manage specific quarantine boxes for users with the common actions (delete or release quarantined messages or empty the whole queue).',
title_quarantine_management => 'Box status Management',
abstract_quarantine_management =>'Manage the status for user quarantines: enable, disable, resend activation requests, reset confirmation counter.',
#Quarantine Settings
spamreport =>'Spam Report interval',
notify_unconfirmees => 'Confirmation request interval', 
max_retries => 'Number of Activation Requests',
max_interval => 'Timeout after last Activation Request (in days)',
global_lifetime => 'Global items lifetime(in days)',
user_lifetime => 'User items lifetime(in days)',
sender_name => 'Sender Name',
error_unknown_recipient => 'Unknown recipient',
error_unknown_recipient_text => 'There is no user with this name available for the specified domain.',
max_confirm_retries  =>'Maximum Confirmation Retries',
max_confirm_interval => 'Maximum Confirmation Interval',
global_item_lifetime => 'Global Items lifetime',
user_item_lifetime  => 'Per User Items lifetime',
sender_name  => 'Sender Name',
quarantine_choose_interval => 'Choose Notification',
quarantine_status_report => 'Daily spam report',
quarantine_activation_request => 'Quarantine Activation request',
send_notifications_enabled => 'Send automatic activation confirmations',
send_reports_enabled   => 'Send automatic quarantine reports',
sizelimit_address => 'Size warning address',
show_virus => 'Full control over virus e-mails',
show_banned => 'Full control over banned attachment e-mails',
show_spam => 'Full control over spam e-mails',
hide_report => 'Display deactivated mails in report but hide action links',
spam_report_footnote => 'If you disable full control over a e-mail type, the user will still see the e-mail in his report, but he will not be able to release or delete the e-mail. (Although they will be deleted if he empties his box or a day)',
quarantine_report_options => 'Visibility options for infected e-mails by category',
quarantine_report_options_changed => 'The actions have successfully changed',
quarantine_report_options_full_control => 'show mails and available actions',
quarantine_report_options_hide_mails => 'hide mails and available actions',
quarantine_report_options_hide_links => 'show mails but hide available actions',

#Quarantine intervals
automate_sending => 'Send this Notification',
automation_enabled => 'Automatically',
automation_disabled => 'Never',

#quarantine management
user_quarantine_status => 'Quarantine Status',
user_quarantine_items => 'Quarantined Items',
status_unconfirmed => 'unconfimed',
status_enabled => 'enabled',
status_disabled => 'disabled',
status_unknown => 'unknown',
user_quarantine_enabled => 'Quarantine for this user successfully enabled',
user_quarantine_disabled => 'Quarantine for this user successfully disabled',
user_reset => 'Recipient\'s notification timeout has been reset ',
user_reset => 'Recipient\'s notification timeout has been reset ',
user_notified => 'A activation request has been sent to this address ',
quarantine_users_from => 'User from',
quarantine_all_domains => 'All configured domains',
quarantine_box_status => 'Quarantine Box Status',
quarantine_box_status_info => 'Quarantine Box Status Information',
quarantine_statuts_irrelevant => 'irrelevant',
redirect_to_quarantine_box => 'Take a look into the quarantine box for this user',

#quarantine recipient mails
mail_deleted => 'The mail have been successfully deleted',
mails_deleted => 'All mails have been successfully deleted',
mail_released => 'The mail have been successfully released',
delete_all => 'Delete All',
recipient_input => 'Username',
mails_in_quarantine => 'E-mails currently quarantined',
empty_quarantine => 'Empty this quarantine',
##these are used in If else statements so don't remove them
user_unconfirmed => 'unconfirmed',
user_enabled => 'quarantine enabled',
user_disabled => 'quarantine disabled',
send_activation_request => 'send activation request',
restart_activation_request => 'restart activation request process',

#quarantine user box administration
quarantine_re_release => 're-release from quarantine',
quarantine_release => 'release from quarantine',
quarantine_delete => 'delete from quarantine',
at_domain => 'Domain',

heading_recipient_list => 'Quarantine boxes matching your search criteria',

heading_error_disabled_quarantine => 'Quarantine not (yet) enabled',
error_disabled_quarantine => 'Quarantine engine should enabled first! You can do this at the <a href="/admin/quarantine/settings" title="Quarantine General Settings">General Settings</a>.',
error_no_match => 'Found no entries matching your criterias',

##quarantine Options###
title_quarantine_options => 'Quarantining Options',
abstract_quarantine_options => 'This Page is here to help you Manage your Infected Mails. Based on the Infection type you can choose where to send them (Infected Mails destiny) And in some cases to whom (Admin Mailboxes) ',
options_mails_destiny_usage => 'Handling of infected e-mails by category',
spam_destiny => 'Spam mails',
virus_destiny => 'Virus mails',
banned_destiny => 'Banned attachments',

destiny_user => 'send to end-user quarantine-box',
destiny_admin => 'send to global mail boxes',
destiny_discard => 'discard',
options_admin_mailboxes_usage => 'Define the global mail boxes for each category',
error_give_admin_email_adress => 'Please define the addresses for the global mail boxes first',

options_destiny_changed => 'Global mail boxes saved successfully',

options_quarantine_domains_usage => 'Enable domains for per user quarantine',
options_domains_changed => 'Domain state successfully changed',
quarantine_domains => 'Domains',

spam_box_input => 'Global mail box for spam mails',
virus_box_input => 'Global mail box for virus mails',
banned_box_input => 'Global mail box for banned attachments',
#
per_user_enabled => 'Currently used',
per_user_disabled => 'Not used',



status_domain_updated => 'Domain updated',
configured_domains => 'Configured Domains',
configured_domains_text => 'Your Open AS Communication Gateway&trade; knows the following domains. Domains with a blue border are enabled.',

configured_recipients_text => 'The following recipients are registered to receive the daily report.',

admin_range_confirm_message => 'Do you really want to exclude your current IP from administration ranges?',

password => 'Password',

send_error_report => 'Send Error Report',
send_error_report_text => 'Please fill in your data so we can file your report correctly.',
admin_name => 'Your name',
phone_nr => 'Phone number',
want_contact => 'Please contact me',
comment => 'Comment',
submit => 'Submit',

error => 'Error',
error_occured_text => 'An unexpected error has occured. <strong>Please send us an error report so we can fix this issue for you.</strong>',
error_occured_send_mail => 'You can send us an e-mail, call us or use the form below.',
error_occured_drop_line => 'Drop us a line - we will return to you shortly',
error_occured_report_directly => 'Report the error directly',
error_occured_return_frontpage => 'no, thanks, I\'d rather just return to the <a href="/admin" title="take me back to the Frontpage">Front Page</a>',

error_report_thankyou_text => 'Thank you for sending us your error report. It will help us to make your Open AS Communication Gateway&trade; even better.',
error_report_sent => 'Error Report Sent',

status_blacklist_addr_created => 'Blacklist entry created',
status_whitelist_addr_created => 'Whitelist entry created',

firewall_changed    => 'Firewall Settings Changed',
firewall_changed_text => 'For the new firewall settings to take action, please re-logon to proceed with the activation.',
firewall_settings_have_changed => 'The firewall settings have successfully been changed. Please confirm them.',

error_too_big_range => 'Specified range is too big',
error_illegal_range => 'Illegal range specified',

quarantine_admin => 'Quarantine E-Mail',
notification_admin => 'Notification E-Mail',

heading_log_download => 'Log Download',
available_logfiles => 'Available Logfiles',

ip_blacklisting_disabled => 'IP blacklisting disabled',
ip_blacklisting_enabled => 'IP blacklisting enabled',

ip_whitelisting_disabled => 'IP whitelisting disabled',
ip_whitelisting_enabled => 'IP whitelisting enabled',

addr_blacklisting_disabled => 'E-Mail address blacklisting disabled',
addr_blacklisting_enabled => 'E-Mail address blacklisting enabled',

addr_whitelisting_disabled => 'E-Mail address whitelisting disabled',
addr_whitelisting_enabled => 'E-Mail address whitelisting enabled',

message_id => 'Message ID',
status => 'status',
banned_attachments => 'Banned attachment(s)',
virus => 'Virus',

error_range_entry_overlap => 'This range overlap an already defined one',
firewall_settings_rollback => 'Administrative IP Ranges was restored',

# Anti-Spam - SMTP servers #
title_antispam_smtpsrvs  => 'SMTP Servers Management',
heading_antispam_recipients_maps_na  => 'No Domains configured!',
antispam_recipients_maps_text  => 'In order to define recipients, please first add a domain under the menu item <a href="/admin/antispam/domains" title="add a domain first">Anti-Spam Configuration &raquo; Domains</a>.',
heading_antispam_recipients_maps_ldap_update => 'Update LDAP Cache',
antispam_recipients_maps_ldap_update_info => 'If LDAP is enabled for the configured SMTP servers by pushing this button the LDAP cache for <strong>all domains</strong> is updated.',
heading_antispam_smtpsrvs_addsmtpsrv => 'Add New SMTP Server',
antispam_smtpsrvs_port => 'TCP Port',
antispam_smtpsrvs_auth_enabled => 'User authentication',
antispam_smtpsrvs_ldap_enabled => 'Enable LDAP Lookups',
antispam_smtpsrvs_usermaps_enabled => 'Enable manual Recipient Maps',
antispam_smtpsrvs_submit => 'Add smtpsrv',
abstract_antispam_smtpsrvs => 'The mail exchange (MX) records of your domains should point to your Open AS Communication Gateway&trade; in order for the appliance to receive and analyze incoming e-mails. Here you have to specify at least one mail server to which Open AS Communication Gateway&trade; can deliver incoming e-mails to.',
configured_smtpsrvs => 'Configured SMTP servers',
configured_smtpsrvs_text => 'Your Open AS Communication Gateway&trade; knows the following SMTP servers.',

antispam_smtpsrvs_auth_methods => 'Authentication methods used',
antispam_smtpsrvs_ssl_auth => 'SMTP Authentication',
antispam_smtpsrvs_ssl_auth_no => 'Plain text',
antispam_smtpsrvs_ssl_auth_certificate => 'Encrypted (TLS)',
antispam_smtpsrvs_check_sertificate => 'Check SSL Certificate',
antispam_smtpsrvs_ssl_auth_valid_certificate => 'Accept only certificates from known authorities',
antispam_smtpsrvs_ssl_auth_other_certificate => 'Accept any valid certificate',
antispam_smtpsrvs_fqdn => 'Cut the delimiter and domain part for authentication',
error_smtpsrv_exists => 'There is a SMTP server with the same IP and port',
status_smtpsrv_created => 'The SMTP server information was stored',
status_smtpsrv_updated => 'The SMTP server information was updated',

title_antispam_smtp_servers => 'SMTP Servers',
abstract_antispam_smtp_servers => 'Define the SMTP Severs known by your Open AS Communication Gateway&trade; that can be assigned to Domains',
domain_name => 'Domain name',
status_cacert_invalid => 'CA certificate is invalid',
status_cert_invalid => 'Certificate and/or private key invalid',
status_cacert_uploaded => 'CA certificate was uploaded',
status_cert_uploaded => 'Certificate was uploaded',
error_cacert_could_not_store_upload => 'Could\'t store CA certificate',
error_cacert_could_not_open_file => 'Could\'t open the CA certificate',
status_cacert_exceeded_size => 'The CA certificate file exceeded the maximum allowed size, or the filetype is wrong',
status_cert_exceeded_size => 'The certificate file exceeded the maximum allowed size',
status_cert_exceded_size => 'The certificate file exceeded the maximum allowed size',
smtpsrv_addr => 'Mailserver Address',
antispam_cacert_yescert => 'upload&use',
antispam_cacert_nocert => 'maybe later',
status_cacert_assigned => 'CA certificate was assigned',
status_cert_assigned => 'Certificate was saved',
antispam_cacert_exists => 'There is assigned a certificate',
status_cacert_unassigned => 'CA certificate was removed',
status_cert_unassigned => 'Certificate was removed',
antispam_cacert_assign => 'Assign a CA certificate',
antispam_domain_smtp_links => 'The following Domains are still using this STMP server. If you delete this server anyway then all these Domains will be deleted too!',
antispam_smtpsrvs_domains => 'Linked domains',
antispam_smtpsrvs_delete_domains_too => 'Delete SMTP server and all linked domains',



antispam_domains_smtpsrv_na => 'no SMTP server configured',
antispam_domains_mailsrv_na => 'no mail server configured',
status_domains_reassigned => 'Domains are now linked with the new SMTP server',
status_domains_src_eq_dst => 'The newly assigned SMTP server is the same as the current one',
status_no_domains_assigned => 'No domain was linked to the new SMTP server',
status_no_match_cert_pkey => 'The certificate and the private key don\'t match each other',

antispam_domains_na => 'No domains configured',
);

our %quar_tmpl =
(
_AUTO => 1,
# daily report strings
dr_title => 'Gateway Status Report',
dr_h1 => 'Gateway Status Report for',
dr_introduction => 'If you would like to have some more detailed information on your spam statistics, just log in to your favourite anti-spam appliance [[% hostname %].[% domainname %]] and pay the statistics a visit.',

dr_h2_backup => 'Backup reminder',
dr_backup_reminder_text => 'It seems that you haven\'t made a backup of your appliance configuration <strong style="color: red;">in over 3 months</strong>. We strongly recommend that you log into your Open AS Communication Gateway&trade; and use the Backup Manager to make a backup of the recent system configuration!',

dr_h2_licencing => 'Licencing Information <span style="font-weight: normal; color: #999;> | Click on a module for more information</span>"',
dr_h2_licencing_nocss => 'Licencing Information',
dr_up2date => 'Up2Date',
dr_care_pack => 'CarePack',
virtual_use => 'Operating licence (virtual)',
dr_valid_until => 'is valid until',
dr_more_d => 'more days',
dr_not_y_act => 'hasn\'t yet been activated',
dr_expiredt => 'has expired on',
dr_get_lic => 'get a licence',

dr_mailq => 'MailQueue Status',
dr_h2_email_statistics => 'Email statistics',
dr_type_mail => 'Type of email',
dr_today => 'today',
dr_last24h => 'last 24h',
dr_lasthour => 'last hour',
dr_gateway_status => 'Gateway System Information',
dr_product => 'Product',
dr_firmware => 'Firmware Version',
dr_update_available => '*Update available!',
dr_serial => 'Serial Number',
dr_update_clam => 'ClamAV <span style="color: #999; font-weight: normal;">(last updated)</span>',
dr_update_clam_nocss => 'ClamAV',
dr_harddisk => 'Harddisk Usage',
dr_sys_uptime => 'System Uptime',
dr_item => 'Items in MQ',

dr_passed => 'passed (clean)',
dr_tagged => 'passed (tagged as spam)',
dr_spam => 'blocked (spam)',
dr_greylisted => 'blocked (greylisted)',
dr_blacklisted => 'blocked (blacklisted)',
dr_virus => 'blocked (virus)',
dr_banned => 'blocked (banned attachment)',

dr_load_avg => 'Load Average <span style="color: #999; font-weight: normal;">(last 15min)</span>',
dr_load_avg_nocss => 'Load Average',
dr_used => 'used',
dr_help => 'need help?',

# quarantine template strings
# global
quar_product => 'Open AS Communication Gateway&trade;',
quar_footer_signature => 'This end-user quarantine is brought to you  by',
quar_footer_company => 'Open AS',
quar_footer_brand => 'via the Open AS Communication Gateway',
quar_today => 'Today,',
quar_confirmation_subject => '[QUARANTINE] Personal End-User quarantine',
quar_report_subject => '[QUARANTINE] Status Report',
quar_activate_subject => '[QUARANTINE] Activation Confirmation',
quar_disabled_subject => '[QUARANTINE] quarantine disabled',
quar_deactivate_subject => '[QUARANTINE] quarantine deactivated',
# report
report_title => 'Quarantine Status Report',
report_status => 'Your quarantine-box status for',
report_usage => 'Use this status report to release valid e-mails and have them sent directly to [% recipient_address %]. Please note that your quarantine list is automatically cleared on a regular basis. For more details please contact your local administrator.',
report_manager => 'QUARANTINE MANAGER',
report_mails_in_quarantine => 'E-Mails currently in your quarantine',
unwanted_below => 'e-mails for this day that are beyond this line are most likely unwanted',
hidden_by_admin => 'This e-mail has been hidden by the administrator',
report_delete_all => 'delete all',
report_delete_day => 'delete day',
report_img_delete_all => 'en_delete_all.gif',
report_img_delete_day => 'en_delete_day.gif',
report_delete_all_plain => 'Empty the complete quarantine',
report_request_plain => 'request a new report',
report_activate_plain => 'activate my personal quarantine',
report_disable_plain => 'disable my personal quarantine',
report_empty_box => 'At the moment your quarantine-box is empty.',
report_received => 'received',
report_type => 'type',
report_score => 'score',
report_automatic => 'automatic',
report_legend => 'Legend',
report_type_s => 'spam',
report_type_v => 'virus',
report_type_b => 'blocked attachment',
report_sender => 'sender',
report_subject => 'subject',
report_subject_delete_all_plain => 'Delete all Messages',
report_subject_report_plain => 'Get Report',
report_subject_enable_plain => 'Enable quarantine',
report_subject_disable_plain => 'Disable quarantine',
report_from_plain => 'From',
report_subject_plain => 'Subject',
report_release_plain => 'release',
report_delete_plain => 'delete',
report_action => 'action',
report_release_message => 'Dear Open AS Communication Gateway,%0Aplease release my quarantined message:',
report_release => 'release',
report_delete_message => 'Dear Open AS Communication Gateway,%0Aplease delete my quarantined message:',
report_delete => 'delete',
report_get_report_message => 'Dear Open AS Communication Gateway,%0Aplease send a quarantine report.',
report_get_report_message_subject => 'Open AS Communication Gateway&trade; - Get Report',
report_activate_message => 'Dear Open AS Communication Gateway,%0Aplease enable my personalized quarantine.',
report_activate_message_subject => 'Open AS Communication Gateway&trade; - Enable quarantine',
report_deactivate_message => 'Dear Open AS Communication Gateway,%0Aplease disable my personalized quarantine.',
report_deactivate_message_subject => 'Open AS Communication Gateway&trade; - Disable quarantine',
report_delete_all_message => 'Dear Open AS Communication Gateway,%0Aplease delete all quarantined messages.',
report_delete_all_message_subject => 'Open AS Communication Gateway&trade; - Delete all Messages',
report_delete_day => 'delete day',
report_subject_delete_day => 'Open AS Communication Gateway&trade; - Delete Messages for day',
report_subject_delete_day_plain => 'Delete Messages for day',
report_subject_delete_day_message => 'Dear Open AS Communication Gateway,%0Aplease delete the quarantined messages for this day.',
report_img_new_report => 'en_qm_new_report.gif',
report_img_enable => 'en_qm_enable.gif',
report_img_disable => 'en_qm_disable.gif',
report_img_alt_new_report => 'new report',
report_img_alt_enable => 'enable personal quarantine',
report_img_alt_disable => 'disable personal quarantine',
# disabled
disable_title => 'Quarantine disabled',
disable_attention => 'Attention: Personal quarantine disabled',
disable_usage => 'The personal quarantine for your e-mail address has been disabled. From now on you have to contact your local network administrator in the event that an expected e-mail has not arrived.',
disable_activate => 'Please note, that it is possible to activate the quarantine again at any time.',
# deactivated
deactivate_title => 'Quarantine disabled',
deactivate_attention => 'Note: Personal quarantine has been deactivated',
deactivate_text => 'The personal quarantine for your e-mail address has been automatically deactivated. From now on e-mail with reasonable suspicion for being spam will be treated according to the policy selected by your network admin.<br>In case you would rather like to use your quarantine, please contact your network admin.',
# confirmation
confirmation_title => 'Quarantine Activation',
confirmation_welcome => 'Welcome to your brand new e-mail quarantine',
confirmation_information => 'Starting today, a personal quarantine feature is available for your address [% recipient_address %]. All you have to do is decide whether you want to use it or not.',
confirmation_usage_info => 'With a personalized e-mail quarantine you can <strong>release undelivered e-mails</strong> from the quarantine yourself without having to wait for your network administrator to do it for you.',
confirmation_usage_delete => 'On a regular basis you will <strong>receive a report</strong> and can release queued e-mails and delete unwanted e-mails (one by one or all at once).',
confirmation_usage_info_plain => 'With a personalized e-mail quarantine you can *release undelivered e-mails* from the quarantine yourself without having to wait for your network administrator to do it for you.',
confirmation_usage_delete_plain => 'On a regular basis you will *receive a report* and can release queued e-mails and delete unwanted e-mails (one by one or all at once).',
confirmation_flooded => 'So your inbox is never flooded by unwanted e-mails again.',
confirmation_activate_info => 'Once activated, your personal quarantine can be deactivated just as easily by either clicking the deactivate button in this e-mail, the status report or dropping your administrator a line.',
confirmation_activate => 'Activate your personal quarantine',
confirmation_activate_plain => 'activate',
confirmation_activate_message => 'Dear Open AS Communication Gateway,%0Aplease enable my personalized quarantine.',
confirmation_activate_message_subject => 'Open AS Communication Gateway&trade; - Enable quarantine',
confirmation_img_activate => 'en_quarantine_activate.jpg',
confirmation_img_alt_activate => 'activate personal quarantine',
# activate
activate_titel => 'Activation Confirmation and Help',
activate_enabled => 'Personal quarantine successfully enabled',
activate_setup => 'Your quarantine box (for [% recipient_address %]) is set up and ready for you to use. From now on, all spam is sent directly to this box which you can easily administer yourself.',
activate_setup_release => 'Release e-mails delete mails that are definitely spam or (de)activate the quarantine itself.',
activate_how => 'How do I use this quarantine?',
activate_good => '<strong>This is the good part:</strong> using this quarantine is as easy as writing e-mail - because that is exactly how it works. Regardless of whether you are connected from inside your company\'s network, checking e-mails from home or from any mobile device, you can manage your quarantine from anywhere at any time. ',
activate_good_plain => 'This is the good part: using this quarantine is as easy as writing e-mail - because that is exactly how it works. Regardless of whether you are connected from inside your company\'s network, checking e-mails from home or from any mobile device, you can manage your quarantine from anywhere at any time.',
activate_action => 'For every action you want to take, simply click on the corresponding button. Next, an e-mail with automatically filled content is generated that you just need to send - without having to change the content or the recipient.',
activate_what => 'And what can I do with it?',
activate_status => 'The quarantine status report is automatically sent to you on a regular basis. The report contains a list of all e-mails that are currently in your quarantine box. E-mails can be individually released or deleted. Released e-mails are <strong>sent to you immediately</strong>.',
activate_status_plain => 'The quarantine status report is automatically sent to you on a regular basis. The report contains a list of all e-mails that are currently in your quarantine box. E-mails can be individually released or deleted. Released e-mails are sent to you immediately.',
activate_cleared => 'Though your quarantine box gets cleared on a regular basis (for more details, please ask your network administrator) you can manually dispose of all e-mail currently in there by <strong>emptying the complete quarantine</strong>.',
activate_cleared_plain => 'Though your quarantine box gets cleared on a regular basis (for more details, please ask your network administrator) you can manually dispose of all e-mail currently in there by emptying the complete quarantine. This process cannot be undone, so please check twice, before doing so.',
activate_undone => 'This process cannot be undone, so please check twice, before cleaning out your quarantine box.',
activate_which => 'Which actions can I take with the quarantine manager?',
activate_assume => 'Let\'s assume you are waiting for an e-mail that hasn\'t arrived, so you want to check the status of your quarantine box now. All you have to do is request a <strong>new report</strong> and you receive the current status of your quarantine box.',
activate_assume_plain => 'Let\'s assume you are waiting for an e-mail that hasn\'t arrived, so you want to check the status of your quarantine box now. All you have to do is request a *new report* and you receive the current status of your quarantine box.',
activate_disabled => 'If you had your quarantine disabled for some reason, it can easily be reenabled with the <strong>enable</strong> button that comes with every quarantine report. It doesn\'t matter how old the report is. The successful enableing will be confirmed with another copy of this e-mail.',
activate_disabled_plain => 'If you had your quarantine disabled for some reason, it can easily be reactivated with the *activate* button that comes with every quarantine report. It doesn\'t matter how old the report is. The successful activation will be confirmed with another copy of this e-mail.',
activate_maintaining => 'If you find maintaining your quarantine by yourself is a workload you\'d rather have done automatically, it is possible to opt-out of the quarantine with one click on the <strong>disable</strong> button. You will receive a confirmation e-mail immediately. Reactivating the quarantine is still possible at any time.',
activate_maintaining_plain => 'If you find maintaining your quarantine by yourself is a workload you\'d rather have done automatically, it is possible to opt-out of the quarantine with one click on the *disable* button. You will receive a confirmation e-mail immediately. Reactivating the quarantine is still possible at any time.',
activate_img_help_list => 'en_help_list.gif',
activate_img_alt_help_list => 'list of e-mails how they are displayed in the quarantine',
activate_img_new_report => 'en_help_new_report.gif',
activate_img_alt_new_report => 'new report',
activate_img_help_enable => 'en_help_enable.gif',
activate_img_alt_help_enable => 'enable quarantine',
activate_img_help_disable => 'en_help_disable.gif',
activate_img_alt_disable => 'disable quarantine',
);

our %mailcrypt_tmpl =
(
_AUTO => 1,
mail_crypt_product => 'E-Mail Encryption',
product => 'Open AS Communication Gateway&trade;',

sendernotification_success_title => 'Encrypted e-mail deliverance notification',  
sendernotification_success_heading => 'You have sent an encrypted e-mail',  
sendernotification_success_recipient_is => 'You have recently sent an encrypted e-mail to',  
sendernotification_success_notify_recipient => 'You may want to contact the recipient and tell him/her the password in order be able to open the file and read the contents.',  
sendernotification_success_password_is => 'The password for the encrypted e-mail is',  

sendernotification_failure_title => 'Encrypted e-mail deliverance notification',  
sendernotification_failure_heading => 'Sorry, something has gone wrong during the encryption!',  
sendernotification_failure_send_to => 'You have tried to send an encrypted e-mail to',  
sendernotification_failure_something_wrong => 'However, <strong>something went wrong</strong> during the encryption process - this could have happened due to one of the following reasons:<ul><li><strong class="error">E-mail is too big:</strong>are there huge uncompressed attachments in your e-mail?<br><em>Solution</em>Please try to convert them to a smaller (file)size.</li><li><strong class="error">Illegal Encoding:</strong> Have you copied some text from a foreign website or document with a weired encoding?<br><em>Solution</em> Please delete the copied text and rewrite it propery.</li></ul>',  
sendernotification_failure_fix_admin => 'If one of these reasons apply, please fix it and try to send the e-mail again. If it still doesn’t work, please contact your administrator.',  

sendernotification_unauthorized_title => 'Encrypted e-mail deliverance notification',  
sendernotification_unauthorized_heading => 'You\'re not authorized to use E-Mail-Encryption',  
sendernotification_unauthorized_send_to => 'You have ordered to send an encrypted e-mail via the E-Mail Encryption Service to',  
sendernotification_unauthorized_not_authorized => 'However, administration policy enforcement asserts that you are <strong>not authorized to use e-mail encryption</strong> on this server.',  
sendernotification_unauthorized_not_forwarded => 'As a matter of fact, your e-mail has not been forwarded and has been deleted from the mail-queue.',  
sendernotification_unauthorized_contact_admin => 'If you should be able to use E-Mail Encryption, you might want to contact the administrator for this server.',  

mail_rcptnotification_title => 'Encrypted e-mail arrival notification',
mail_rcptnotification_heading => 'You have received an encrypted e-mail',
mail_rcptnotification_sender_is => 'has sent you an encrypted e-mail:',
mail_rcptnotification_contact_sender => 'To view the attached file, please enter the correct password. If you don’t already know the password, please contact',
mail_rcptnotification_get_7zip => 'To view archives you can download the (free) 7zip archive software from <a href="http://sourceforge.net/projects/sevenzip/">sourceforge.net</a>.',
mail_rcptnotification_get_adobe => 'To view PDFs you can download the (free) Adobe Reader from <a href="http://get.adobe.com/reader">get.adobe.com/reader</a>.',  

footer_signature => 'E-mail Encryption is brought to you by',  
via => 'via the',
);
