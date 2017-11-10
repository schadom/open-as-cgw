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

CREATE DATABASE smtp_auth;
GRANT ALL ON `smtp_auth` . * TO 'smtp_auth-user'@'localhost' WITH GRANT OPTION;
SET PASSWORD for 'smtp_auth-user'@'localhost' = PASSWORD('loltruck2000');
USE smtp_auth;

CREATE TABLE `cache_auth` (
  `hashup` varchar(250) collate latin1_bin NOT NULL,
  `smtp_srv_ref` varchar(64) collate latin1_bin NOT NULL,
  `domain` varchar(250) collate latin1_bin NOT NULL,
  `last_hit` datetime NOT NULL,
  KEY `username` (`hashup`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='Store the last used server to authenticate an user';

-- --------------------------------------------------------

-- 
-- Table structure for table `domains`
-- 

CREATE TABLE `domains` (
  `name` varchar(250) collate latin1_bin NOT NULL,
  `smtp_srv_ref` varchar(128) collate latin1_bin NOT NULL,
  UNIQUE KEY `name` (`name`,`smtp_srv_ref`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

-- --------------------------------------------------------

-- 
-- Table structure for table `smtp_servers`
-- 

CREATE TABLE `smtp_servers` (
  `smtp_srv_ref` varchar(128) collate latin1_bin NOT NULL,
  `descr` varchar(250) collate latin1_bin NOT NULL,
  `addr` varchar(128) collate latin1_bin NOT NULL,
  `port` int(11) NOT NULL default '25',
  `auth_methods` tinyint(4) NOT NULL default '3',
  `ssl_validation` tinyint(4) NOT NULL default '2',
  `auth_enabled` tinyint(4) NOT NULL default '0',
  `use_fqdn` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`smtp_srv_ref`),
  KEY `ip` (`addr`,`port`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='Define SMTP servers';
