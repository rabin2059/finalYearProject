/*
  Warnings:

  - You are about to drop the `DriverStatus` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE `DriverStatus` DROP FOREIGN KEY `DriverStatus_driverId_fkey`;

-- DropTable
DROP TABLE `DriverStatus`;
