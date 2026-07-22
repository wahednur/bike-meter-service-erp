import type { MileageCorrectionDevice, Meter } from "./types";

/** Mirrors Meter.ALLOWED_CORRECTION_TOOLS on the backend (apps/meters/models.py) -
 * MCU meters can only use "VVDI Prog"; EEPROM meters allow the other four tools.
 * Matched by exact device name, same as the server-side validator. */
const ALLOWED_CORRECTION_TOOLS: Record<Meter["memory_type"], string[]> = {
  MCU: ["VVDI Prog"],
  EEPROM: ["RT809F", "TOP2013", "UPA USB 1.3", "EasyPro2025"],
};

export function compatibleCorrectionDevices(
  devices: MileageCorrectionDevice[],
  memoryType: Meter["memory_type"],
): MileageCorrectionDevice[] {
  const allowedNames = ALLOWED_CORRECTION_TOOLS[memoryType];
  return devices.filter(
    (device) =>
      (device.memory_type_support === "BOTH" || device.memory_type_support === memoryType) &&
      allowedNames.includes(device.name),
  );
}

/** Invoice service-layer errors (InvoiceError) surface through DRF as
 * {"detail": "<message>"}, but for the two validation paths that route
 * through _run_validation() (mileage-correction device/field checks), that
 * message is itself the str() of a DRF ValidationError - a stringified
 * Python list/ErrorDetail repr, e.g. "[ErrorDetail(string='...', code='invalid')]".
 * Best-effort unwrap that back to plain text for display. */
export function cleanInvoiceErrorMessage(raw: string): string {
  const message = raw.trim();

  const errorDetailMatch = message.match(/ErrorDetail\(string=(['"])(.*?)\1/);
  if (errorDetailMatch) return errorDetailMatch[2];

  const listMatch = message.match(/^\[(['"])(.*)\1\]$/);
  if (listMatch) return listMatch[2];

  return message;
}
