-- CreateTable
CREATE TABLE `auditlog` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NULL,
    `action` VARCHAR(191) NOT NULL,
    `details` JSON NULL,
    `ipAddress` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `category` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `imageUrl` VARCHAR(191) NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `category_name_key`(`name`),
    UNIQUE INDEX `category_slug_key`(`slug`),
    INDEX `category_isActive_idx`(`isActive`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `goldprice` (
    `id` VARCHAR(191) NOT NULL,
    `sellPrice` DECIMAL(15, 2) NOT NULL,
    `buyPrice` DECIMAL(15, 2) NOT NULL,
    `timestamp` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `goldprice_timestamp_idx`(`timestamp`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `order` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `productId` VARCHAR(191) NOT NULL,
    `quantity` INTEGER NOT NULL DEFAULT 1,
    `weight` DECIMAL(10, 3) NULL,
    `amount` DECIMAL(15, 2) NOT NULL,
    `gst` DECIMAL(15, 2) NOT NULL,
    `total` DECIMAL(15, 2) NOT NULL,
    `status` ENUM('PAYMENT_PENDING', 'PAYMENT_SUCCESSFUL', 'ORDER_CONFIRMED', 'PROCESSING', 'QUALITY_CHECKING', 'READY_FOR_PICKUP', 'PICKED_UP', 'BUYBACK', 'CANCELLED', 'REFUNDED') NOT NULL DEFAULT 'PAYMENT_PENDING',
    `paymentId` VARCHAR(191) NULL,
    `paymentStatus` VARCHAR(191) NULL,
    `deliveryDate` DATETIME(3) NULL,
    `goldPriceAtPurchase` DECIMAL(15, 2) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `referralCode` VARCHAR(191) NULL,
    `invoiceNo` VARCHAR(191) NULL,
    `invoiceUrl` VARCHAR(191) NULL,

    UNIQUE INDEX `order_paymentId_key`(`paymentId`),
    UNIQUE INDEX `order_invoiceNo_key`(`invoiceNo`),
    INDEX `order_status_idx`(`status`),
    INDEX `order_userId_idx`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `otp` (
    `id` VARCHAR(191) NOT NULL,
    `phone` VARCHAR(191) NOT NULL,
    `code` VARCHAR(191) NOT NULL,
    `verified` BOOLEAN NOT NULL DEFAULT false,
    `expiresAt` DATETIME(3) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `otp_phone_key`(`phone`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `product` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` TEXT NULL,
    `weight` DECIMAL(10, 3) NOT NULL,
    `purity` VARCHAR(191) NOT NULL DEFAULT '24K',
    `imageUrl` VARCHAR(191) NULL,
    `stock` INTEGER NOT NULL DEFAULT 0,
    `readyStock` INTEGER NOT NULL DEFAULT 0,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `categoryId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `fixedPrice` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `makingCharges` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `isPremium` BOOLEAN NOT NULL DEFAULT false,
    `isPromoted` BOOLEAN NOT NULL DEFAULT false,

    INDEX `product_isActive_idx`(`isActive`),
    INDEX `product_categoryId_idx`(`categoryId`),
    INDEX `product_isPremium_idx`(`isPremium`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `setting` (
    `id` VARCHAR(191) NOT NULL,
    `key` VARCHAR(191) NOT NULL,
    `value` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `setting_key_key`(`key`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `transaction` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `type` ENUM('DEPOSIT', 'PURCHASE', 'WITHDRAWAL', 'CREDIT', 'REFERRAL', 'REWARD', 'REFERRAL_REWARD', 'SELL_BACK') NOT NULL,
    `amount` DECIMAL(15, 2) NOT NULL,
    `description` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'COMPLETED',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `invoiceNo` VARCHAR(191) NULL,

    UNIQUE INDEX `transaction_invoiceNo_key`(`invoiceNo`),
    INDEX `transaction_userId_idx`(`userId`),
    INDEX `transaction_type_idx`(`type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `phone` VARCHAR(191) NOT NULL,
    `password` VARCHAR(191) NOT NULL,
    `role` ENUM('ADMIN', 'CUSTOMER', 'STAFF') NOT NULL DEFAULT 'CUSTOMER',
    `kycStatus` ENUM('PENDING', 'VERIFIED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    `aadharNo` VARCHAR(191) NULL,
    `panNo` VARCHAR(191) NULL,
    `address` VARCHAR(191) NULL,
    `photo` VARCHAR(191) NULL,
    `referrerId` VARCHAR(191) NULL,
    `staffId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `referralCode` VARCHAR(191) NOT NULL,
    `bankAccountNo` VARCHAR(191) NULL,
    `bankHolderName` VARCHAR(191) NULL,
    `bankIfsc` VARCHAR(191) NULL,
    `bankName` VARCHAR(191) NULL,
    `bankStatus` ENUM('PENDING', 'VERIFIED', 'REJECTED') NOT NULL DEFAULT 'PENDING',

    UNIQUE INDEX `user_email_key`(`email`),
    UNIQUE INDEX `user_phone_key`(`phone`),
    UNIQUE INDEX `user_referralCode_key`(`referralCode`),
    INDEX `user_phone_idx`(`phone`),
    INDEX `user_role_idx`(`role`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `wallet` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `balance` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `goldAdvance` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `referralRewards` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `wallet_userId_key`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `payment` (
    `id` VARCHAR(191) NOT NULL,
    `orderId` VARCHAR(191) NOT NULL,
    `razorpayOrderId` VARCHAR(191) NOT NULL,
    `razorpayPaymentId` VARCHAR(191) NULL,
    `razorpaySignature` VARCHAR(191) NULL,
    `amount` DECIMAL(15, 2) NOT NULL,
    `currency` VARCHAR(191) NOT NULL DEFAULT 'INR',
    `status` VARCHAR(191) NOT NULL DEFAULT 'PENDING',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `payment_razorpayOrderId_key`(`razorpayOrderId`),
    UNIQUE INDEX `payment_razorpayPaymentId_key`(`razorpayPaymentId`),
    INDEX `payment_orderId_fkey`(`orderId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `app_config` (
    `key` VARCHAR(191) NOT NULL,
    `value` VARCHAR(191) NOT NULL,

    PRIMARY KEY (`key`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `withdrawal_request` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `amount` DECIMAL(15, 2) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'PENDING',
    `bankDetails` JSON NULL,
    `adminNotes` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `withdrawal_request_userId_idx`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `order_status_history` (
    `id` VARCHAR(191) NOT NULL,
    `orderId` VARCHAR(191) NOT NULL,
    `status` ENUM('PAYMENT_PENDING', 'PAYMENT_SUCCESSFUL', 'ORDER_CONFIRMED', 'PROCESSING', 'QUALITY_CHECKING', 'READY_FOR_PICKUP', 'PICKED_UP', 'BUYBACK', 'CANCELLED', 'REFUNDED') NOT NULL,
    `notes` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `order_status_history_orderId_idx`(`orderId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `auditlog` ADD CONSTRAINT `AuditLog_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `order` ADD CONSTRAINT `Order_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `product`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `order` ADD CONSTRAINT `Order_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `product` ADD CONSTRAINT `Product_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `category`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transaction` ADD CONSTRAINT `Transaction_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user` ADD CONSTRAINT `User_referrerId_fkey` FOREIGN KEY (`referrerId`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user` ADD CONSTRAINT `User_staffId_fkey` FOREIGN KEY (`staffId`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `wallet` ADD CONSTRAINT `Wallet_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `payment` ADD CONSTRAINT `payment_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `order`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `withdrawal_request` ADD CONSTRAINT `WithdrawalRequest_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `order_status_history` ADD CONSTRAINT `order_status_history_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `order`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
