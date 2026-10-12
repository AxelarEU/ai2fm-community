-- MariaDB fixture for Execute_SQL_Example_11.fmscript and
-- Execute_SQL_Example_12.fmscript.
--
-- Run this file as a MariaDB administrator. It does not contain the
-- administrator password and does not replace existing person records.

CREATE DATABASE IF NOT EXISTS `gemini`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `gemini`;

CREATE TABLE IF NOT EXISTS `persons` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `first_name` VARCHAR(100) NOT NULL,
    `last_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(255) NOT NULL,
    `phone_number` VARCHAR(20) DEFAULT NULL,
    `address` VARCHAR(255) DEFAULT NULL,
    `city` VARCHAR(100) DEFAULT NULL,
    `state` VARCHAR(100) DEFAULT NULL,
    `zip_code` VARCHAR(10) DEFAULT NULL,
    `country` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP(),
    `PrimaryKey` VARCHAR(36) NOT NULL DEFAULT UUID(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

-- INSERT IGNORE makes the seed repeatable. Existing IDs or email addresses
-- are left unchanged.
INSERT IGNORE INTO `persons`
    (`id`, `first_name`, `last_name`, `email`, `phone_number`,
     `address`, `city`, `state`, `zip_code`, `country`)
VALUES
    (1, 'John', 'Doe', 'john.doe@example.com', '123-456-7890',
     NULL, NULL, NULL, NULL, NULL),
    (2, 'Jane', 'Smith', 'jane.smith@example.com', '098-765-4321',
     NULL, NULL, NULL, NULL, NULL),
    (3, 'Antonis', 'Xatzimanolis', 'whatever@gmail.com', NULL,
     NULL, NULL, NULL, NULL, NULL),
    (4, 'Andreas', 'Kotsiras', 'whatever2@gmail.com', NULL,
     NULL, NULL, NULL, NULL, NULL);

-- Local demonstration account used by Examples 11 and 12. It can read,
-- insert, and update only gemini.persons. It cannot delete rows or alter schema.
CREATE USER IF NOT EXISTS 'ai2fm_example'@'localhost'
    IDENTIFIED BY 'ai2fm-demo-only';
ALTER USER 'ai2fm_example'@'localhost'
    IDENTIFIED BY 'ai2fm-demo-only';

CREATE USER IF NOT EXISTS 'ai2fm_example'@'127.0.0.1'
    IDENTIFIED BY 'ai2fm-demo-only';
ALTER USER 'ai2fm_example'@'127.0.0.1'
    IDENTIFIED BY 'ai2fm-demo-only';

GRANT SELECT, INSERT, UPDATE ON `gemini`.`persons`
    TO 'ai2fm_example'@'localhost';
GRANT SELECT, INSERT, UPDATE ON `gemini`.`persons`
    TO 'ai2fm_example'@'127.0.0.1';

FLUSH PRIVILEGES;

-- Verification output.
SELECT `id`, `first_name`, `last_name`, `email`
FROM `persons`
ORDER BY `id`;

SHOW GRANTS FOR 'ai2fm_example'@'localhost';

-- Optional test-data cleanup. Run deliberately; it is not automatic.
-- DELETE FROM `persons` WHERE `email` LIKE 'calculated.sql.%@example.test';
