import { toast } from "sonner";

import { ApiError } from "./api";

/** Single choke point for "an API call failed" handling: fires a toast for
 * immediate visibility and returns the extracted message so callers that
 * also render an inline banner can do `setError(reportError(err, "..."))`
 * in one line. The toast and the banner are complementary, not redundant -
 * the toast auto-dismisses in a few seconds, the banner stays until the
 * user acts, so someone who glances away doesn't lose the failure entirely. */
export function reportError(err: unknown, fallback: string): string {
  const message = err instanceof ApiError ? err.message : fallback;
  toast.error(message);
  return message;
}
