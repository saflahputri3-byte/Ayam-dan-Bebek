import { useEffect } from 'react';

export function PwaRegistrar() {
  useEffect(() => {
    if (import.meta.env.PROD && 'serviceWorker' in navigator) void navigator.serviceWorker.register('/service-worker.js', { scope: '/' });
  }, []);
  return null;
}
