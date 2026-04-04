/**
 * Normalizes a mobile number to a standard 10-digit format.
 * Strips non-numeric characters and extracts the last 10 digits.
 */
export const normalizeMobile = (mobile: string): string => {
  const digits = mobile.replace(/\D/g, '');
  return digits.slice(-10);
};
