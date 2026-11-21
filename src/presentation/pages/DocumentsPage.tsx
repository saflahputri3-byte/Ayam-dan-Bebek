import { useEffect, useState } from 'react';
import { CircleAlert, Files, LoaderCircle, ReceiptText } from 'lucide-react';
import type { BranchContext, SaleListItem } from '../../domain/erp/ErpTypes';
import type { ErpRepository } from '../../application/ports/ErpRepository';

const money = (amount: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount);

export function DocumentsPage({ repository, context, onInvoice }: { repository: ErpRepository; context: BranchContext; onInvoice: (saleId: string) => void }) {
  const [sales, setSales] = useState<SaleListItem[]>([]); const [loading, setLoading] = useState(true); const [error, setError] = useState('');
  useEffect(() => {
    let active = true;
    void repository.getSales(context).then((rows) => { if (active) setSales(rows); }).catch((cause: unknown) => { if (active) setError(cause instanceof Error ? cause.message : 'Dokumen gagal dimuat.'); }).finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [repository, context.companyId, context.branchId]);
  return <div className="erp-page"><header className="page-heading"><div><p className="eyebrow">PENJUALAN · ARSIP</p><h1>Invoice & dokumen</h1><p className="page-subtitle">Lihat invoice penjualan tersimpan di cabang aktif dan buka untuk mencetak atau mencatat pembayaran.</p></div><span className="live-badge page-live"><i/> ARSIP LIVE</span></header>
    {error && <div className="load-error" role="alert"><CircleAlert size={16}/>{error}</div>}
    <section className="surface document-list"><div className="surface-heading"><div><h2><Files size={15}/> Invoice penjualan</h2><p>{sales.length} dokumen terbaru</p></div></div>
      {loading ? <div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat dokumen…</div> : sales.length === 0 ? <div className="empty-state">Belum ada invoice di cabang ini.</div> : <div className="responsive-list">{sales.map((sale) => <button className="sale-row" key={sale.id} onClick={() => onInvoice(sale.id)}><span className="sale-row-main"><strong><ReceiptText size={14}/> {sale.document_number}</strong><small>{sale.customer_name} · {new Date(sale.created_at).toLocaleString('id-ID')}</small></span><span className="sale-row-total">{money(Number(sale.total_amount))}<small>{Number(sale.paid_amount) >= Number(sale.total_amount) ? 'Lunas' : `Sisa ${money(Number(sale.total_amount) - Number(sale.paid_amount))}`}</small></span></button>)}</div>}
    </section>
  </div>;
}
