/*
  Warnings:

  - Made the column `review` on table `DriverRating` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE `DriverRating` MODIFY `review` VARCHAR(191) NOT NULL;
