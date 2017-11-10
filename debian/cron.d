#
#  limesas-lib maintenance
#
# m	h	dom	mon	dow	user	command
2	*	*	*	*	limes	/usr/bin/mail_logacc.pl >/dev/null 2>&1
0	0	*	*	*	limes	/usr/bin/daily_spam_report.pl >/dev/null 2>&1
10	0	*	*	*	root	/usr/bin/mysql_cron.sh >>/var/log/open-as-cgw/syslog 2>&1
5   */3 *   *   *   root    /usr/bin/sa-update --channelfile /etc/open-as-cgw/conf/sa-update/channelfile --gpgkeyfile /etc/open-as-cgw/conf/sa-update/keyfile --gpghomedir /etc/open-as-cgw/conf/sa-update --updatedir /var/lib/spamassassin && /etc/init.d/amavis restart  >/dev/null 2>&1
10  *   *   *   *   root    /usr/bin/clamav-u8-sig-rsync.sh >/dev/null 2>&1
*/5	*	*	*	*	limes	/usr/bin/mqsize.pl 2>&1
20	*	*	*	*	root    /etc/init.d/openas-ldapsync start > /dev/null 2>&1 
37	3	*	*	*	root    /etc/init.d/openas-qcron restart > /dev/null 2>&1 
*/10	*	*	*	*	root	/usr/bin/check_amavis_phail.sh
*/10	*	*	*	*  	root    /usr/bin/virtual_swap_controller.sh >> /var/log/open-as-cgw/swap_control.log
*	*	*	*	*	root	/usr/bin/update_motd_issue.sh
