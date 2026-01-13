-- Create the vehicle_harnesses table
CREATE TABLE IF NOT EXISTS `vehicle_harnesses` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `plate` VARCHAR(50) NOT NULL,
  `installed` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;