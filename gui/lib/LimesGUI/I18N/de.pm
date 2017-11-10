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


package LimesGUI::I18N::de;
use base 'LimesGUI::I18N';
use LimesGUI::I18N::en;

our %Lexicon = %LimesGUI::I18N::en::Lexicon;


our %quar_tmpl =
(
_AUTO => 1,
# daily report strings
dr_title => 'Gateway Status Report',
dr_h1 => 'Gateway Status Report für',
dr_introduction => 'Wenn Sie detailiertere Informationen zu Ihren Spam Statistiken haben möchten, loggen Sie sich einfach auf Ihrere Appliance ein ([% hostname %].[% domainname %]).',

dr_h2_backup => 'Backup Erinnerung',
dr_backup_reminder_text => 'Es hat den Anschein, als hätten Sie <strong style="color: red;">seit über 3 Monaten</strong> kein Backup mehr gemacht. Wir würden Ihnen dringend ans Herz legen, sich an Ihrem AS Communication Gateway anzumelden und mittels des Backup Managers die aktuelle Systemkonfiguration zu sichern!',

dr_h2_licencing => 'Lizenz Informationen <span style="font-weight: normal; color: #999;> | Klicken Sie auf ein Modul für mehr Info</span>"',
dr_up2date => 'Up2Date',
dr_care_pack => 'CarePack',
virtual_use => 'Betriebslizenz (virtual)',
dr_valid_until => 'ist gültig bis',
dr_more_d => 'mehr Tage',
dr_not_y_act => 'wurde bisher nicht aktiviert',
dr_expiredt => 'ist bereits abgelaufen am',
dr_get_lic => 'Lizenz bestellen',

dr_mailq => 'MailQueue Status',
dr_h2_email_statistics => 'E-Mail Statistiken',
dr_type_mail => 'markiert als',
dr_today => 'heute',
dr_last24h => 'letzten 24h',
dr_lasthour => 'letzte Stunde',
dr_gateway_status => 'Gateway System Information',
dr_product => 'Produkt',
dr_firmware => 'Firmware Version',
dr_update_available => '*Update verfügbar!',
dr_serial => 'Serien Nummer',
dr_update_clam => 'ClamAV <span style="color: #999; font-weight: normal;">(letztes Update)</span>',
dr_harddisk => 'Festplattenverbrauch',
dr_sys_uptime => 'System Uptime',
dr_item => 'Elemente in MQ',

dr_passed => 'passed (clean)',
dr_tagged => 'passed (tagged as spam)',
dr_spam => 'blocked (spam)',
dr_greylisted => 'blocked (greylisted)',
dr_blacklisted => 'blocked (blacklisted)',
dr_virus => 'blocked (virus)',
dr_banned => 'blocked (banned attachment)',

dr_load_avg => 'Load Average <span style="color: #999; font-weight: normal;">(last 15min)</span>',
dr_used => 'verbraucht',
dr_help => 'Brauchen Sie Hilfe?',

# quarantine template strings
# global
quar_product => 'AS Communication Gateway',
quar_footer_signature => 'Diese Endbenutzer-Quarant&auml;ne wird bereitgestellt von',
quar_footer_company => 'underground_8',
quar_footer_brand => '&uuml;ber das AS Communication Gateway',
quar_today => 'Heute,',
quar_confirmation_subject => '[QUARANTAENE] Persoenliche End-Benutzer Quarantaene',
quar_report_subject => '[QUARANTAENE] Status Report',
quar_activate_subject => '[QUARANTAENE] Aktivierungsbestaetigung',
quar_disabled_subject => '[QUARANTAENE] Quarantaene ausgeschaltet',
quar_deactivate_subject => '[QUARANTAENE] Quarantaene deaktiviert',
# report
report_title => 'Quarant&auml;ne Status Report',
report_status => 'Ihr Quarant&auml;ne-Box Status f&uuml;r',
report_usage => 'Verwenden Sie diesen Status Report um valide E-Mails freizugeben und diese direkt an [% recipient_address %] zu senden. Bitte beachten Sie, dass Ihre Quarant&auml;ne-Liste automatisch in definierten Abst&auml;nden gel&ouml;scht wird. F&uuml;r weitere Details kontaktieren Sie Ihren Administrator.',
report_manager => 'QUARANT&Auml;NE MANAGER',
report_mails_in_quarantine => 'E-Mails in Ihrer Quarant&auml;ne',
unwanted_below => 'für diesen Tag sind alle E-Mails unterhalb hoechstwahrscheinlich ungewollt',
hidden_by_admin => 'Dieses E-Mail wurde vom Administrator ausgeblendet',
report_delete_all => 'alle l&ouml;schen',
report_delete_day => 'Tag l&ouml;schen',
report_img_delete_all => 'de_delete_all.gif',
report_img_delete_day => 'de_delete_day.gif',
report_delete_all_plain => 'Gesamte Quarantaene-Box leeren',
report_request_plain => 'Neuen Report anfordern',
report_activate_plain => 'Persoenliche Quarantaene einschalten',
report_disable_plain => 'Persoenliche Quarantaene ausschalten',
report_empty_box => 'Aktuell ist Ihre Quarant&auml;ne-Box leer.',
report_received => 'empfangen',
report_type => 'Typ',
report_score => 'Score',
report_automatic => 'automatisch',
report_legend => 'Legende',
report_type_s => 'Spam',
report_type_v => 'Virus',
report_type_b => 'verd&auml;chtiger Anhang',
report_sender => 'Absender',
report_subject_delete_all_plain => 'Alle Nachrichten loeschen',
report_subject_report_plain => 'Report anfordern',
report_subject_enable_plain => 'Quarantaene einschalten',
report_subject_disable_plain => 'Quarantaene auschalten',
report_from_plain => 'Von',
report_subject_plain => 'Betreff',
report_release_plain => 'freigeben',
report_delete_plain => 'loeschen',
report_subject => 'Betreff',
report_action => 'Aktion',
report_release_message => 'Hallo AS Communication Gateway,%0Abitte gib diese E-Mail in der Quarantaene frei:',
report_release => 'freigeben',
report_delete_message => 'Hallo AS Communication Gateway,%0Abitte loesche diese E-Mail in der Quarantaene:',
report_delete => 'l&ouml;schen',
report_get_report_message => 'Hallo AS Communication Gateway,%0Abitte sende einen Quarantaene Report.',
report_get_report_message_subject => 'AS Communication Gateway - Report anfordern',
report_activate_message => 'Hallo AS Communication Gateway,%0Abitte schalt meine persoenliche Quarantaene ein.',
report_activate_message_subject => 'AS Communication Gateway - Einschalten Quarantaene',
report_deactivate_message => 'Hallo AS Communication Gateway,%0Abitte schalt meine persoenliche Quarantaene aus.',
report_deactivate_message_subject => 'AS Communication Gateway - Ausschalten Quarantaene',
report_delete_all_message => 'Hallo AS Communication Gateway,%0Abitte loesche alle E-Mails in der Quarantaene-Box.',
report_delete_all_message_subject => 'AS Communication Gateway - Loesche alle E-Mails',
report_img_new_report => 'de_qm_new_report.gif',
report_img_enable => 'de_qm_enable.gif',
report_img_disable => 'de_qm_disable.gif',
report_delete_day => 'Tag l&ouml;schen',
report_subject_delete_day => 'AS Communication Gateway - L&ouml;sche E-Mails f&uuml;r Tag',
report_subject_delete_day_plain => 'L&ouml;sche E-Mails fuer Tag',
report_subject_delete_day_message => 'Hallo AS Communication Gateway,%0Abitte loesche die quarantaenisierten E-Mails fuer diesen Tag.',
report_img_alt_new_report => 'Neuer Report',
report_img_alt_enable => 'Persoenliche Quarantaene einschalten',
report_img_alt_disable => 'Persoenliche Quarantaene ausschalten',
# disabled
disable_title => 'Quarant&auml;ne ausgeschaltet',
disable_attention => 'Achtung: Pers&ouml;nliche Quarant&auml;ne ausgeschaltet',
disable_usage => 'Die pers&ouml;nliche Quarant&auml;ne fuer Ihre E-Mail Adresse wurde ausgeschalten. Ab jetzt muessen Sie Ihren Administrator kontaktieren, falls eine erw&uuml;nschte E-Mail nicht bei Ihnen eintrifft.',
disable_activate => 'Bitte beachten Sie, dass es weiterhin jederzeit m&ouml;glich, ist die Quarant&auml;ne wieder ein zu schalten.',
# deactivated
deactivate_title => 'Quarant&auml;ne deaktiviert',
deactivate_attention => 'Hinweis: Pers&ouml;nliche Quarant&auml;ne deaktiviert',
deactivate_text => 'Die pers&ouml;nliche Quarant&auml;ne f&uuml;r Ihre E-Mail Adresse wurde automatisch deaktiviert. E-Mails mit Verdacht auf Spam oder virus-verseuchtem Inhalt, die an Ihre Adresse gesendet werden, werden in Zukunft laut den vom Netzwerkadministrator getroffenen Richtlinien behandelt.<br>Falls Sie sich doch entscheiden, Ihre Quarant&auml;ne benutzen zu wollen, setzen Sie sich mit ihrem Netzwerkadministrator in Verbindung.',
# confirmation
confirmation_title => 'Quarant&auml;ne Aktivierung',
confirmation_welcome => 'Willkommen zu Ihrer brandneuen E-Mail Quarant&auml;ne',
confirmation_information => 'Ab sofort ist die pers&ouml;nliche Quarant&auml;ne-Funktionalit&auml;t f&uuml;r Ihre Adresse [% recipient_address %] verf&uuml;gbar. Alles was Sie tun m&uuml;ssen, ist zu entscheiden, ob Sie diese Funktion verwenden wollen oder nicht.',
confirmation_usage_info => 'Mit Ihrer pers&ouml;nlichen E-Mail Quarant&auml;ne k&ouml;nnen Sie nicht zugestellte E-Mails selbst aus Ihrer Quarant&auml;ne <strong>freigeben</strong> ohne daf&uuml;r auf Ihren Administrator warten zu m&uuml;ssen.',
confirmation_usage_delete => 'In definierten Abst&auml;nden werden Ihnen <strong>Reports zugestellt</strong> und Sie k&ouml;nnen zwischengespeicherte E-Mails freigeben oder unerw&uuml;nschte E-Mails l&ouml;schen (einzeln oder gesammelt).',
confirmation_usage_info_plain => 'Mit Ihrer persoenlichen E-Mail Quarantaene koennen Sie nicht zugestellte E-Mails selbst aus Ihrer Quarantaene *freigeben* ohne dafuer auf Ihren Administrator warten zu muessen.',
confirmation_usage_delete_plain => 'In definierten Abstaenden werden Ihnen *Reports zugestellt* und Sie koennen zwischengespeicherte E-Mails freigeben oder unerwuenschte E-Mails loeschen (einzeln oder gesammelt).',
confirmation_flooded => 'Ihre Mailbox wird ab jetzt nicht mehr mit unerw&uuml;nschten E-Mails geflutet.',
confirmation_activate_info => 'Einmal aktiviert, kann Ihre pers&ouml;nliche Quarant&auml;ne jedoch auch ganz einfach, durch Klick auf den Ausschalten-Button in dieser E-Mail, dem Status-Report oder durch eine E-Mail an Ihren Administrator, ausgeschaltet werden.',
confirmation_activate => 'Aktivieren Sie Ihre pers&ouml;nliche Quarant&auml;ne',
confirmation_activate_plain => 'aktivieren',
confirmation_activate_message => 'Hallo AS Communication Gateway,%0Abitte aktiviere meine persoenliche Quarantaene.',
confirmation_activate_message_subject => 'AS Communication Gateway - Quarantaene aktivieren',
confirmation_img_activate => 'de_quarantine_activate.jpg',
confirmation_img_alt_activate => 'Persoenlichen Quarantaene aktivieren',
# activate
activate_titel => 'Aktivierungsbest&auml;tigung und Hilfe',
activate_enabled => 'Pers&ouml;nliche Quarant&auml;ne erfolgreich aktiviert',
activate_setup => 'Ihre Quarant&auml;ne-Box (f&uuml;r [% recipient_address %]) ist eingerichtet und einsatzbereit. Ab sofort wird jeglicher Spam an diese Box gesendet die von Ihnen selbst einfach zu administrieren ist.',
activate_setup_release => 'E-Mails freigeben, E-Mails l&ouml;schen die definitiv Spam sind, oder (de)aktivieren der Quarant&auml;ne selbst.',
activate_how => 'Wie verwende ich die Quarant&auml;ne?',
activate_good => '<strong>Das ist der gute Teil:</strong> die Verwendung dieser Quarant&auml;ne ist so einfach wie das Schreiben einer E-Mail - denn genauso funktioniert sie. Egal ob Sie innerhalb Ihrer Firma verbunden sind, ob Sie Ihre E-Mails von zu Hause abrufen oder von Ihrem mobilen Ger&auml;t, Sie k&ouml;nnen Ihre Quarant&auml;ne von &uuml;berall zu jeder Zeit verwalten ',
activate_good_plain => 'Das ist der gute Teil: die Verwendung dieser Quarantaene ist so einfach wie das Schreiben einer E-Mail - denn genauso funktioniert sie. Egal ob Sie innerhalb Ihrer Firma verbunden sind, ob Sie Ihre E-Mails von zu Hause abrufen oder von Ihrem mobilen Geraet, Sie koennen Ihre Quarantaene von ueberall zu jeder Zeit verwalten.',
activate_action => 'F&uuml;r jede Aktion die Sie durchf&uuml;hren wollen, klicken Sie einfach auf den passenden Button. Danach wird eine E-Mail mit automatisch generiertem Inhalt erstellt die Sie nur noch versenden m&uuml;ssen - ohne den Inhalt oder den Empf&auml;nger ver&auml;ndern zu m&uuml;ssen.',
activate_what => 'Und was kann ich damit machen?',
activate_status => 'Der Quarant&auml;ne Status Report wird in definierten Zeitabst&auml;nden automatisch an Sie versandt. Dieser Report enth&auml;lt eine Liste aller E-Mails die sich zur Zeit in Ihrer Quarant&auml;ne-Box befinden. E-mails k&ouml;nnen einzeln freigegeben oder gel&ouml;scht werden. Freigegebenen E-Mails werden <strong>umgehend an Sie gesendet</strong>.',
activate_status_plain => 'Der Quarantaene Status Report wird in definierten Zeitabstaenden automatisch an Sie versandt. Dieser Report enthaelt eine Liste aller E-Mails die sich zur Zeit in Ihrer Quarantaene-Box befinden. E-mails koennen einzeln freigegeben oder geloescht werden. Freigegebene E-Mails werden umgehend an Sie gesendet.',
activate_cleared => 'Trotz der automatischen Bereinigung Ihrer Quarant&auml;ne-Box (fragen Sie Ihren Administrator f&uuml;r mehr Details) k&ouml;nnen Sie auch selbst die <strong>komplette Quarant&auml;ne leeren</strong>.',
activate_cleared_plain => 'Trotz der automatischen Bereinigung Ihrer Quarantaene-Box (fragen Sie Ihren Administrator fuer mehr Details) koennen Sie auch selbst die komplette Quarantaene leeren. Dieser Vorgang kann jedoch nicht rueckgaengig gemacht werden, ueberlegen Sie daher genau ob Sie diese Aktion durchfuehren wollen.',
activate_undone => ' Diese Aktion kann nicht r&uuml;ckg&auml;ngig gemacht werden, &uuml;berlegen Sie daher vorher genau ob Sie die Quarant&auml;ne-Box wirklich komplett leeren wollen.',
activate_which => 'Welche Aktionen kann ich mit dem Quarant&auml;ne Manager durchf&uuml;hren?',
activate_assume => 'Nehmen wir an Sie warten auf eine E-Mail die noch nicht angekommen ist, Sie wollen also den Status der Quarant&auml;ne-Box abfragen. Alles was Sie daf&uuml;r machen m&uuml;ssen ist einen <strong>neuen Report</strong> anzufordern und Sie erhalten den aktuellen Status Ihrer Quarant&auml;ne-Box.',
activate_assume_plain => 'Nehmen wir an Sie warten auf eine E-Mail die noch nicht angekommen ist, Sie wollen also den Status der Quarantaene-Box abfragen. Alles was Sie dafuer machen muessen ist einen *neuen Report* anzufordern und Sie erhalten den aktuellen Status Ihrer Quarantaene-Box.',
activate_disabled => 'Wenn Sie Ihre Quarant&auml;ne ausgeschaltet haben koennen Sie diese ganz einfach wieder einschalten indem Sie den <strong>Einschalten</strong> Button der in jedem Quarant&auml;ne Report verf&uuml;gbar ist dr&uuml;cken. Es ist unerheblich wie alt dieser Report ist. Einschalten wird mit einer neuen Kopie dieser E-Mail best&auml;tigt.',
activate_disabled_plain => 'Wenn Sie Ihre Quarantaene ausgeschaltet haben koennen Sie diese ganz einfach wieder einschalten indem Sie den *Einschalten* Button der in jedem Quarantaene Report verfuegbar ist druecken. Es ist unerheblich wie alt dieser Report ist. Einschalten wird mit einer neuen Kopie dieser E-Mail bestaetigt.',
activate_maintaining => 'Falls Sie der Meinung sind, dass die Administration der Quarant&auml;ne zu viel Arbeit f&uuml;r Sie bedeutet und dies lieber automatisch erledigt haben wollen, dann schalten Sie die Quarant&auml;ne mit einem Klick auf den <strong>Aussschalten</strong> Button aus. Sie erhalten sofort eine Best&auml;tigungs-E-Mail. Die neuerliche Aktivierung der Quarant&auml;ne ist weiterhin jederzeit m&ouml;glich.',
activate_maintaining_plain => 'Falls Sie der Meinung sind, dass die Administration der Quarantaene zu viel Arbeit fuer Sie bedeutet und dies lieber automatisch erledigt haben wollen,dann schalten Sie die Quarant&auml;ne mit einem Klick auf den *Aussschalten* Button aus. Sie erhalten sofort eine Bestaetigungs-E-Mail. Die neuerliche Aktivierung der Quarantaene ist weiterhin jederzeit moeglich.',
activate_img_help_list => 'de_help_list.gif',
activate_img_alt_help_list => 'Liste alle E-Mails der Quarantaene',
activate_img_new_report => 'de_help_new_report.gif',
activate_img_alt_new_report => 'Neuer Report',
activate_img_help_enable => 'de_help_enable.gif',
activate_img_alt_help_enable => 'Quarantaene einschalten',
activate_img_help_disable => 'de_help_disable.gif',
activate_img_alt_disable => 'Quarantaene ausschalten',
);

our %mailcrypt_tmpl =
(
_AUTO => 1,
mail_crypt_product => 'E-Mail Encryption',
product => 'AS Communication Gateway&trade;',

sendernotification_success_title => 'Benachrichtigung &uuml;ber verschl&uuml;sselten Versand',  
sendernotification_success_heading => 'Sie haben ein verschl&uuml;sseltes E-Mail versandt',  
sendernotification_success_recipient_is => 'Sie haben gerade an folgenden Empf&auml;nger ein verschl&uuml;sseltes E-Mail versandt:',  
sendernotification_success_notify_recipient => 'Um das verschl&uuml;sselte E-Mail auch lesen zu k&ouml;nnen, sollten Sie dem Empf&auml;nger kontaktieren und ihm/ihr das Password mitteilen.',  
sendernotification_success_password_is => 'Das verschl&uuml;sselte E-Mail kann mit dem folgenden Passwort ge&ouml;ffnet werde:',  

sendernotification_failure_title => 'Benachrichtigung &uuml;ber Zustellung eines verschl&uuml;sselten E-Mails',  
sendernotification_failure_heading => 'Irgendwas ist da w&auml;hrend der Verschl&uuml;sselung falscht gelaufen!',  
sendernotification_failure_send_to => 'Sie haben gerade an folgenden Empf&auml;nger ein verschl&uuml;sseltes E-Mail versandt:',  
sendernotification_failure_something_wrong => 'Es scheint, als w&auml;re <strong>etwas schief gelaufen</strong> w&auml;rend des Verschl&uuml;sselungsprozesses. Hierf&uuml;r gibt es mehrere m&ouml;gliche Gr&uuml;nde:<ul><li><strong class="error">E-Mail ist zu gro&szlig;:</strong> hat das E-Mail gro&szlig;e, unkomprimierte Dateianh&auml;nge?<br><em>L&ouml;sung</em> (Datei-) Gr&ouml;&szlig;e vermindern.</li><li><strong class="error">Nicht unterst&uuml;tze Codierung:</strong> Haben Sie Text-Teile aus einer fremd-codierten Datei oder Website kopiert?<br><em>L&ouml;sung</em> Bitte l&ouml;schen Sie den kopierten Text und schreiben ihn sauber neu.</li></ul>',  
sendernotification_failure_fix_admin => 'Sollte eines dieser Probleme auf Sie zu treffen, versuchen Sie es mit der angegebenen L&ouml;sung und senden Sie das E-Mail erneut. Sollte der Versand noch immer nicht funktionieren, wenden Sie sich bitte an Ihrem Administrator.',  

sendernotification_unauthorized_title => 'Benachrichtigung &uuml;ber nicht-authorisierten Benutzungsversuch der E-Mail Encryption',  
sendernotification_unauthorized_heading => 'Sie sind nicht berechtigt, verschl&uuml;sselte E-Mails zu verschicken',  
sendernotification_unauthorized_send_to => 'YSie haben offensichtlich versucht, via E-Mail Encryption ein verschl&uuml;sseltes E-Mail an folgenden Empf&auml;nger zu schicken:',  
sendernotification_unauthorized_not_authorized => 'Es sieht jedoch so aus, als w&auml;ren Sie <strong>nicht berechtigt</strong> die auf diesem System installierte automatische E-Mail Verschl&uuml;sselung zu benutzen.',  
sendernotification_unauthorized_not_forwarded => 'Beachten Sie, dass dieses E-Mail weder versandt wurde, noch irgendwo auf dem System in der Mail Queue zwischen gespeichert wurde.',  
sendernotification_unauthorized_contact_admin => 'Sollten Sie jedoch zum Versand verschl&uuml;sselter E-Mails berechtigt sein, dann wenden Sie sich bitte an Ihrem Administrator, damit dieser Sie freischalten kann.',  

mail_rcptnotification_title => 'Benachrichtigung &uuml;ber den Empfang eines verschl&uuml;sselten E-Mails',
mail_rcptnotification_heading => 'Sie haben ein verschl&uuml;sseltes E-Mail erhalten!',
mail_rcptnotification_sender_is => 'hat Ihnen ein verschl&uuml;sseltes E-Mail geschickt:',
mail_rcptnotification_contact_sender => 'Um die angeh&auml;ngte Datei, die sowohl das E-Mail, als auch alle Anh&auml;nge enth&auml;lt &ouml;ffnen zu k&ouml;nnen, geben Sie bitte das entsprechende Passwort an. Wenn Sie das Passwort (noch) nicht kennen, dann kontaktieren Sie bitte',
mail_rcptnotification_get_7zip => 'Um diese Archiv-Datei &ouml;ffnen zu k&ouml;nnen, verwenden Sie am einfachsten (gratis) Software wie z.B. 7zip, die Sie hier downloaden k&ouml;nnen: <a href="http://sourceforge.net/projects/sevenzip/">sourceforge.net</a>.',
mail_rcptnotification_get_adobe => 'Um diese PDF-Datei &ouml;ffnen zu k&ouml;nnen, verwenden Sie am einfachsten (gratis) Software wie z.B. Adobe Reader, die Sie hier downloaden k&ouml;nnen: <a href="http://get.adobe.com/reader">get.adobe.com/reader</a>.',  

footer_signature => 'E-mail Encryption wird zur Verf&uuml;gung gestellt von',  
via => 'via das',
);
