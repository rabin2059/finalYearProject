/*
  Warnings:

  - You are about to drop the column `experience` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `userId` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `vehicleId` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `User` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[email]` on the table `Driver` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `email` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Added the required column `password` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Added the required column `username` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Made the column `licenseNo` on table `Driver` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE `Driver` DROP FOREIGN KEY `Driver_userId_fkey`;

-- DropIndex
DROP INDEX `Driver_userId_key` ON `Driver`;

-- AlterTable
ALTER TABLE `Driver` DROP COLUMN `experience`,
    DROP COLUMN `userId`,
    DROP COLUMN `vehicleId`,
    ADD COLUMN `address` VARCHAR(191) NULL,
    ADD COLUMN `email` VARCHAR(191) NOT NULL,
    ADD COLUMN `password` VARCHAR(191) NOT NULL,
    ADD COLUMN `phone` VARCHAR(191) NULL,
    ADD COLUMN `username` VARCHAR(191) NOT NULL,
    MODIFY `licenseNo` VARCHAR(191) NOT NULL;

-- AlterTable
ALTER TABLE `User` DROP COLUMN `status`;

-- CreateIndex
CREATE UNIQUE INDEX `Driver_email_key` ON `Driver`(`email`);
