-- AlterTable: Syncing missing production fields
ALTER TABLE `order` ADD COLUMN `deliveryDate` DATETIME(3) NULL;
ALTER TABLE `order` ADD COLUMN `goldPriceAtPurchase` DECIMAL(15, 2) NULL;
ALTER TABLE `order` ADD COLUMN `invoiceNo` VARCHAR(191) NULL;

-- AlterTable: Product fields
ALTER TABLE `product` ADD COLUMN `readyStock` INTEGER NOT NULL DEFAULT 0;
ALTER TABLE `product` ADD COLUMN `fixedPrice` DECIMAL(15, 2) NOT NULL DEFAULT 0.00;
ALTER TABLE `product` ADD COLUMN `makingCharges` DECIMAL(15, 2) NOT NULL DEFAULT 0.00;

-- CreateIndex
CREATE UNIQUE INDEX `Order_invoiceNo_key` ON `order`(`invoiceNo`);
