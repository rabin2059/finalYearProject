/*
  Warnings:

  - You are about to alter the column `rating` on the `DriverRating` table. The data in that column could be lost. The data in that column will be cast from `Int` to `Double`.
  - Added the required column `userId` to the `DriverRating` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE `DriverRating` DROP FOREIGN KEY `DriverRating_driverId_fkey`;

-- DropIndex
DROP INDEX `DriverRating_driverId_fkey` ON `DriverRating`;

-- AlterTable
ALTER TABLE `DriverRating` ADD COLUMN `userId` INTEGER NOT NULL,
    MODIFY `rating` DOUBLE NOT NULL;

-- AddForeignKey
ALTER TABLE `DriverRating` ADD CONSTRAINT `DriverRating_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `DriverRating` ADD CONSTRAINT `DriverRating_driverId_fkey` FOREIGN KEY (`driverId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
