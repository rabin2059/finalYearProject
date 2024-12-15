/*
  Warnings:

  - You are about to drop the `Driver` table. If the table is not empty, all the data it contains will be lost.

*/
-- AlterTable
ALTER TABLE `User` ADD COLUMN `licenseNo` VARCHAR(191) NULL,
    MODIFY `role` INTEGER NOT NULL DEFAULT 1;

-- DropTable
DROP TABLE `Driver`;
