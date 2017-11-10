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

-- Realtime Log Database Structure Creation for Limes AS
-- 
-- user: rt_log password: rt_log
-- SELECT, INSERT, UPDATE, DELETE

-- --------------------------------------------------------

CREATE DATABASE `rt_log` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

USE `rt_log`;
 

GRANT SELECT, INSERT, UPDATE, DELETE ON `rt_log` . * TO 'rt_log'@'localhost' WITH MAX_USER_CONNECTIONS 10;
SET PASSWORD for 'rt_log'@'localhost' = PASSWORD('rt_log');
-- 
-- Table structure for table `amavis_status`
-- 

CREATE TABLE `amavis_status` (
  `id` int(11) NOT NULL,
  `description` varchar(30) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


INSERT INTO `amavis_status` (`id`, `description`) VALUES (10, 'Passed CLEAN'),
(11, 'Passed SPAMMY'),
(20, 'Blocked INFECTED'),
(21, 'Blocked BANNED'),
(22, 'Blocked SPAM');

-- --------------------------------------------------------

-- 
-- Table structure for table `domain_from_daily`
-- 

CREATE TABLE `domain_from_daily` (
  `received_start` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_end` timestamp NOT NULL default '0000-00-00 00:00:00',
  `domain` varchar(255) collate utf8_unicode_ci NOT NULL,
  `passed_clean` bigint(20) NOT NULL,
  `passed_spam` bigint(20) NOT NULL,
  `blocked_greylisted` bigint(20) NOT NULL,
  `blocked_blacklisted` bigint(20) NOT NULL,
  `blocked_virus` bigint(20) NOT NULL,
  `blocked_banned` bigint(20) NOT NULL,
  `blocked_spam` bigint(20) NOT NULL,
  PRIMARY KEY  (`received_start`,`received_end`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `domain_from_hourly`
-- 

CREATE TABLE `domain_from_hourly` (
  `received_start` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_end` timestamp NOT NULL default '0000-00-00 00:00:00',
  `domain` varchar(255) collate utf8_unicode_ci NOT NULL,
  `passed_clean` bigint(20) NOT NULL,
  `passed_spam` bigint(20) NOT NULL,
  `blocked_greylisted` bigint(20) NOT NULL,
  `blocked_blacklisted` bigint(20) NOT NULL,
  `blocked_virus` bigint(20) NOT NULL,
  `blocked_banned` bigint(20) NOT NULL,
  `blocked_spam` bigint(20) NOT NULL,
  PRIMARY KEY  (`received_start`,`received_end`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `domain_livelog`
-- 

CREATE TABLE `domain_livelog` (
  `received` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_us` int(11) NOT NULL,
  `received_log` timestamp NOT NULL default '0000-00-00 00:00:00',
  `from_domain` varchar(255) collate utf8_unicode_ci NOT NULL,
  `to_domain` varchar(255) collate utf8_unicode_ci NOT NULL,
  `sqlgrey` int(11) NOT NULL,
  `amavis` int(11) default NULL,
  `amavis_hits` float default NULL,
  PRIMARY KEY  (`received`,`received_us`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `domain_to_daily`
-- 

CREATE TABLE `domain_to_daily` (
  `received_start` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_end` timestamp NOT NULL default '0000-00-00 00:00:00',
  `domain` varchar(255) collate utf8_unicode_ci NOT NULL,
  `passed_clean` bigint(20) NOT NULL,
  `passed_spam` bigint(20) NOT NULL,
  `blocked_greylisted` bigint(20) NOT NULL,
  `blocked_blacklisted` bigint(20) NOT NULL,
  `blocked_virus` bigint(20) NOT NULL,
  `blocked_banned` bigint(20) NOT NULL,
  `blocked_spam` bigint(20) NOT NULL,
  PRIMARY KEY  (`received_start`,`received_end`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `domain_to_hourly`
-- 

CREATE TABLE `domain_to_hourly` (
  `received_start` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_end` timestamp NOT NULL default '0000-00-00 00:00:00',
  `domain` varchar(255) collate utf8_unicode_ci NOT NULL,
  `passed_clean` bigint(20) NOT NULL,
  `passed_spam` bigint(20) NOT NULL,
  `blocked_greylisted` bigint(20) NOT NULL,
  `blocked_blacklisted` bigint(20) NOT NULL,
  `blocked_virus` bigint(20) NOT NULL,
  `blocked_banned` bigint(20) NOT NULL,
  `blocked_spam` bigint(20) NOT NULL,
  PRIMARY KEY  (`received_start`,`received_end`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `mail_daily`
-- 

CREATE TABLE `mail_daily` (
  `received_start` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_end` timestamp NOT NULL default '0000-00-00 00:00:00',
  `passed_clean` bigint(20) NOT NULL,
  `passed_spam` bigint(20) NOT NULL,
  `blocked_greylisted` bigint(20) NOT NULL,
  `blocked_blacklisted` bigint(20) NOT NULL,
  `blocked_virus` bigint(20) NOT NULL,
  `blocked_banned` bigint(20) NOT NULL,
  `blocked_spam` bigint(20) NOT NULL,
  PRIMARY KEY  (`received_start`,`received_end`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `mail_hourly`
-- 

CREATE TABLE `mail_hourly` (
  `received_start` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_end` timestamp NOT NULL default '0000-00-00 00:00:00',
  `passed_clean` bigint(20) NOT NULL,
  `passed_spam` bigint(20) NOT NULL,
  `blocked_greylisted` bigint(20) NOT NULL,
  `blocked_blacklisted` bigint(20) NOT NULL,
  `blocked_virus` bigint(20) NOT NULL,
  `blocked_banned` bigint(20) NOT NULL,
  `blocked_spam` bigint(20) NOT NULL,
  PRIMARY KEY  (`received_start`,`received_end`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `mail_livelog`
-- 

CREATE TABLE `mail_livelog` (
  `received` timestamp NOT NULL default '0000-00-00 00:00:00',
  `received_us` bigint(20) NOT NULL,
  `received_log` datetime NOT NULL default '0000-00-00 00:00:00',
  `msg_id` varchar(255) collate utf8_unicode_ci default NULL,
  `mail_from` varchar(255) collate utf8_unicode_ci default NULL,
  `rcpt_to` varchar(255) collate utf8_unicode_ci default NULL,
  `client_ip` varchar(15) collate utf8_unicode_ci default NULL,
  `queue_nr` varchar(10) collate utf8_unicode_ci default NULL,
  `subject` varchar(255) collate utf8_unicode_ci default NULL,
  `sqlgrey` int(11) NOT NULL,
  `amavis` int(11) default NULL,
  `amavis_hits` float default NULL,
  `amavis_detail` varchar(50) collate utf8_unicode_ci default NULL,
  `delay` float default NULL,
  PRIMARY KEY  (`received`,`received_us`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `sqlgrey_status`
-- 

CREATE TABLE `sqlgrey_status` (
  `id` int(11) NOT NULL,
  `description` varchar(18) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


INSERT INTO `sqlgrey_status` (`id`, `description`) VALUES (10, 'update'),
(11, 'whitelist'),
(12, 'whitelist_sender'),
(13, 'outgoing'),
(20, 'new'),
(21, 'abuse'),
(22, 'blacklist'),
(23, 'blacklist_sender');
