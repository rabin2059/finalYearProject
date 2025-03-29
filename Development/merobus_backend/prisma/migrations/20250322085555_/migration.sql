-- DropForeignKey
ALTER TABLE `ChatGroup` DROP FOREIGN KEY `ChatGroup_vehicleId_fkey`;

-- DropIndex
DROP INDEX `ChatGroup_vehicleId_fkey` ON `ChatGroup`;

-- AlterTable
ALTER TABLE `ChatGroup` MODIFY `vehicleId` INTEGER NULL;

-- AlterTable
ALTER TABLE `Message` ADD COLUMN `readAt` DATETIME(3) NULL,
    MODIFY `text` TEXT NOT NULL,
    MODIFY `isRead` BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE `_UserChatGroups` (
    `A` INTEGER NOT NULL,
    `B` INTEGER NOT NULL,

    UNIQUE INDEX `_UserChatGroups_AB_unique`(`A`, `B`),
    INDEX `_UserChatGroups_B_index`(`B`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `ChatGroup` ADD CONSTRAINT `ChatGroup_vehicleId_fkey` FOREIGN KEY (`vehicleId`) REFERENCES `Vehicle`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `_UserChatGroups` ADD CONSTRAINT `_UserChatGroups_A_fkey` FOREIGN KEY (`A`) REFERENCES `ChatGroup`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `_UserChatGroups` ADD CONSTRAINT `_UserChatGroups_B_fkey` FOREIGN KEY (`B`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
