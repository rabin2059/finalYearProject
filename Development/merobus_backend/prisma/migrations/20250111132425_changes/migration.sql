/*
  Warnings:

  - You are about to drop the column `destination` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `distance` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `routeStatus` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `source` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `vehicleId` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the `Image` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[vehicleID]` on the table `Route` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE `Image` DROP FOREIGN KEY `Image_vehicleId_fkey`;

-- DropForeignKey
ALTER TABLE `Route` DROP FOREIGN KEY `Route_vehicleId_fkey`;

-- AlterTable
ALTER TABLE `Route` DROP COLUMN `destination`,
    DROP COLUMN `distance`,
    DROP COLUMN `routeStatus`,
    DROP COLUMN `source`,
    DROP COLUMN `vehicleId`,
    ADD COLUMN `endPoint` VARCHAR(191) NULL,
    ADD COLUMN `name` VARCHAR(191) NULL,
    ADD COLUMN `startPoint` VARCHAR(191) NULL,
    ADD COLUMN `vehicleID` INTEGER NULL;

-- DropTable
DROP TABLE `Image`;

-- CreateTable
CREATE TABLE `BusStop` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(191) NOT NULL,
    `latitude` DOUBLE NOT NULL,
    `longitude` DOUBLE NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `RouteBusStop` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `routeId` INTEGER NOT NULL,
    `busStopId` INTEGER NOT NULL,
    `sequence` INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateIndex
CREATE UNIQUE INDEX `Route_vehicleID_key` ON `Route`(`vehicleID`);

-- AddForeignKey
ALTER TABLE `Route` ADD CONSTRAINT `Route_vehicleID_fkey` FOREIGN KEY (`vehicleID`) REFERENCES `Vehicle`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `RouteBusStop` ADD CONSTRAINT `RouteBusStop_routeId_fkey` FOREIGN KEY (`routeId`) REFERENCES `Route`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `RouteBusStop` ADD CONSTRAINT `RouteBusStop_busStopId_fkey` FOREIGN KEY (`busStopId`) REFERENCES `BusStop`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
