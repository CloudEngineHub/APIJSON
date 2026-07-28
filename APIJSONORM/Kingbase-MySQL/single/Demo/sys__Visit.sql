-- Generated from APIJSON-Demo/MySQL for KingbaseES V9R1 MySQL compatibility mode.
-- INSERT values are preserved; MySQL backslash escapes are rendered as standard SQL.
SET search_path TO public;
SET client_encoding TO 'UTF8';
SET standard_conforming_strings TO on;

BEGIN;
-- MySQL dump 10.13  Distrib 8.0.31, for macos12 (x86_64)
--
-- Host: apijson.cn    Database: sys
-- ------------------------------------------------------
-- Server version	5.7.43-log

--
-- Table structure for table `_Visit`
--

DROP TABLE IF EXISTS `_Visit`;

CREATE TABLE `_Visit` (
  `model` varchar(15) NOT NULL,
  `id` bigint NOT NULL,
  `operate` smallint NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `_Visit`
---- Dump completed on 2025-07-07  1:39:02
COMMIT;
