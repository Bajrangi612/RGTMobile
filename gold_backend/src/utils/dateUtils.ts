/**
 * Utility for Indian Standard Time (IST) handle
 * Ensures all backend calculations and formatting match Asia/Kolkata timezone.
 */

/**
 * Returns a new Date object representing the current moment.
 * While Date objects in JS represent a single point in time,
 * this utility helps when we need to calculate 'local' offsets.
 */
export const getISTNow = (): Date => {
  return new Date();
};

/**
 * Formats a date specifically to IST for display or invoice generation.
 * @param date The date object to format
 * @param formatStr Pattern (e.g., 'dd/MM/yyyy h:mm a')
 */
export const formatToIST = (date: Date, options: Intl.DateTimeFormatOptions = {}): string => {
  return new Intl.DateTimeFormat('en-IN', {
    ...options,
    timeZone: 'Asia/Kolkata',
  }).format(date);
};

/**
 * Returns a formatted date string for invoices (e.g., '16/04/2026 11:15 AM')
 */
export const getFormattedIST = (date: Date): string => {
  return new Intl.DateTimeFormat('en-IN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
    timeZone: 'Asia/Kolkata',
  }).format(date);
};

/**
 * Calculates a delivery date based on IST midnight logic.
 * @param fromDate Starting date (usually 'now')
 * @param daysToAdd Number of days until delivery
 */
export const calculateISTDeliveryDate = (fromDate: Date, daysToAdd: number): Date => {
  const istOffset = 5.5 * 60 * 60 * 1000;
  
  // 1. Move to IST
  const targetIST = new Date(fromDate.getTime() + (daysToAdd * 24 * 60 * 60 * 1000) + istOffset);
  
  // 2. Snap to IST Midnight
  targetIST.setUTCHours(0, 0, 0, 0);
  
  // 3. Convert back to UTC for database storage
  return new Date(targetIST.getTime() - istOffset);
};
