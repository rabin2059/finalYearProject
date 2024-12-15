-- AlterTable
ALTER TABLE `Driver` ADD COLUMN `otp` VARCHAR(191) NULL,
    ADD COLUMN `otp_expiry` DATETIME(3) NULL;

-- AlterTable
ALTER TABLE `User` ADD COLUMN `otp` VARCHAR(191) NULL,
    ADD COLUMN `otp_expiry` DATETIME(3) NULL;
