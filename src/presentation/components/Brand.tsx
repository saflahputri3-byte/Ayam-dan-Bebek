import { Bird } from 'lucide-react';

export function Brand({ companyName }: { companyName?: string }) {
  return <div className="brand"><span className="brand-mark"><Bird size={21} /></span><span className="brand-copy">{(companyName || 'AGI AYAM & BEBEK').toUpperCase()}<small>BUSINESS CONTROL</small></span></div>;
}
