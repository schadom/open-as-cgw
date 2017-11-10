-- This file is part of the Open AS Communication Gateway.
--
-- The Open AS Communication Gateway is free software: you can redistribute it
-- and/or modify it under theterms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the License,
-- or (at your option) any later version.
--
-- The Open AS Communication Gateway is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
-- General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License along
-- with the Open AS Communication Gateway. If not, see http://www.gnu.org/licenses/.

CREATE DATABASE mailq;
USE mailq;
CREATE TABLE `mcount` (`count_time` bigint(20) unsigned NOT NULL, `mail_count` bigint(20) unsigned NOT NULL, `size` bigint(20) unsigned NOT NULL, PRIMARY KEY  (`count_time`), UNIQUE KEY `count_time` (`count_time`)) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
GRANT SELECT, INSERT, UPDATE, DELETE ON `mailq` . * TO 'mailq'@'localhost';
SET PASSWORD for 'mailq'@'localhost' = PASSWORD('mailq');
