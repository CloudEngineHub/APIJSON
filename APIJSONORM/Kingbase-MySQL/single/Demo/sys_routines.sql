-- KingbaseES V9R1 MySQL compatibility mode
SET search_path TO public;
SET client_encoding TO 'UTF8';
SET standard_conforming_strings TO on;

BEGIN;
DROP VIEW IF EXISTS `ViewTable`;
CREATE VIEW `ViewTable` AS
SELECT
  `C`.`id` AS `commentId`,
  `C`.`toId` AS `toId`,
  `C`.`momentId` AS `momentId`,
  `C`.`content` AS `content`,
  `U`.`id` AS `id`,
  `U`.`sex` AS `sex`,
  `U`.`name` AS `name`,
  `U`.`tag` AS `tag`,
  `U`.`head` AS `head`,
  `U`.`contactIdList` AS `contactIdList`,
  `U`.`pictureList` AS `pictureList`,
  `U`.`date` AS `date`
FROM `Comment` AS `C`
JOIN `apijson_user` AS `U` ON `U`.`id` = `C`.`userId`;
COMMIT;
