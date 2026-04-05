/*
  Warnings:

  - A unique constraint covering the columns `[referralCode]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - The required column `referralCode` was added to the `User` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.

*/
-- AlterTable
ALTER TABLE `order` ADD COLUMN `referralCode` VARCHAR(191) NULL;

-- AlterTable
ALTER TABLE `user` ADD COLUMN `referralCode` VARCHAR(191) NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `User_referralCode_key` ON `User`(`referralCode`);
