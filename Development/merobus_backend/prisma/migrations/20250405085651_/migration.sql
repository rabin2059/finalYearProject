/*
  Warnings:

  - You are about to drop the column `categoryId` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the `VehicleCategory` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE `Vehicle` DROP FOREIGN KEY `Vehicle_categoryId_fkey`;

-- DropIndex
DROP INDEX `Vehicle_categoryId_fkey` ON `Vehicle`;

-- AlterTable
ALTER TABLE `Vehicle` DROP COLUMN `categoryId`,
    MODIFY `timingCategory` ENUM('early', 'onTime', 'late', 'earlyStartLateArrival', 'lateStartEarlyArrival') NULL;

-- AlterTable
ALTER TABLE `VehiclePerformance` ADD COLUMN `earlyStartLateArrivalCount` INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN `lateStartEarlyArrivalCount` INTEGER NOT NULL DEFAULT 0,
    MODIFY `category` ENUM('early', 'onTime', 'late', 'earlyStartLateArrival', 'lateStartEarlyArrival') NOT NULL,
    MODIFY `totalTrips` INTEGER NOT NULL DEFAULT 0,
    MODIFY `earlyCount` INTEGER NOT NULL DEFAULT 0,
    MODIFY `onTimeCount` INTEGER NOT NULL DEFAULT 0,
    MODIFY `lateCount` INTEGER NOT NULL DEFAULT 0;

-- DropTable
DROP TABLE `VehicleCategory`;
