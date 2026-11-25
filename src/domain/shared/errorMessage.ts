export function getErrorMessage(cause: unknown, fallback: string): string {
  if (cause && typeof cause === 'object' && 'message' in cause && typeof (cause as { message: unknown }).message === 'string') {
    const msg = (cause as { message: string }).message.trim();
    if (msg) return msg;
  }
  if (cause instanceof Error && cause.message.trim()) {
    return cause.message.trim();
  }
  return fallback;
}
