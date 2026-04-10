UPDATE `order` SET status = 'BUYBACK' WHERE status = 'RESOLD';
UPDATE `transaction` SET `type` = 'CREDIT' WHERE `type` = 'PROFIT';
