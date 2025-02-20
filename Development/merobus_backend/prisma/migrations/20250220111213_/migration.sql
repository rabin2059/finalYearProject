/*
  Warnings:

  - You are about to drop the column `paymentType` on the `Payment` table. All the data in the column will be lost.
  - Added the required column `paymentMethod` to the `Payment` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE `Payment` DROP COLUMN `paymentType`,
    ADD COLUMN `paymentMethod` VARCHAR(191) NOT NULL;
