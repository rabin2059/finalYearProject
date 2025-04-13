/*
  Warnings:

  - You are about to drop the column `actualArrivalTime` on the `Vehicle` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `Vehicle` DROP COLUMN `actualArrivalTime`,
    ADD COLUMN `actualArrival` TIME NULL;
