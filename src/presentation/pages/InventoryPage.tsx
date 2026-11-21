import { useEffect, useState } from 'react';
import { ArrowDownLeft, ArrowUpRight, Check, CircleAlert, Clock3, LoaderCircle, PackageCheck, Search, ShieldAlert } from 'lucide-react';
import type { BatchTraceability, BranchContext, InventoryMovement, InventoryRow } from '../../domain/erp/ErpTypes';
import type { ErpRepository } from '../../application/ports/ErpRepository';

const statusLabels: Record<string, string> = { passed: 'Lolos inspeksi', pending: 'Menunggu inspeksi', rejected: 'Ditolak', quarantined: 'Karantina' };
const movementLabels: Record<string, string> = { receipt: 'Penerimaan', sale: 'Penjualan', production_input: 'Input produksi', production_output: 'Output produksi', transfer_in: 'Transfer masuk', transfer_out: 'Transfer keluar', adjustment: 'Penyesuaian', reversal: 'Reversal' };

export function InventoryPage({ repository, context }: { repository: ErpRepository; context: BranchContext }) {
  const [rows, setRows] = useState<InventoryRow[]>([]); const [movements, setMovements] = useState<InventoryMovement[]>([]);
  const [loading, setLoading] = useState(true); const [busy, setBusy] = useState(''); const [error, setError] = useState(''); const [notice, setNotice] = useState('');
  const [trace, setTrace] = useState<BatchTraceability | null>(null); const [traceLoading, setTraceLoading] = useState(false); const [traceError, setTraceError] = useState('');

  async function refresh() {
    setLoading(true); setError('');
    try { const [balances, ledger] = await Promise.all([repository.getInventoryReport(context), repository.getInventoryMovements(context)]); setRows(balances); setMovements(ledger); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Gagal memuat stok dan kartu mutasi cabang.'); }
    finally { setLoading(false); }
  }
  useEffect(() => { void refresh(); }, [repository, context.companyId, context.branchId]);

  async function inspect(batchId: string, result: 'passed' | 'rejected' | 'quarantined') {
    const explanation = result === 'passed' ? 'Batch dinyatakan lolos dan dapat digunakan/terjual.' : result === 'rejected' ? 'Batch ditolak dan tidak dapat dijual.' : 'Batch dikarantina dan tidak dapat dijual.';
    if (!window.confirm(`Konfirmasi inspeksi kualitas? ${explanation}`)) return;
    setBusy(batchId); setError(''); setNotice('');
    try { await repository.inspectBatch(batchId, result, 'Inspeksi dikonfirmasi dari aplikasi.'); setNotice('Hasil inspeksi tersimpan pada riwayat kualitas.'); await refresh(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Inspeksi gagal disimpan.'); }
    finally { setBusy(''); }
  }
  async function openTrace(batchId: string) {
    setTraceLoading(true); setTraceError('');
    try { setTrace(await repository.getBatchTraceability(batchId)); }
    catch (cause) { setTraceError(cause instanceof Error ? cause.message : 'Riwayat asal-usul batch gagal dimuat.'); }
    finally { setTraceLoading(false); }
  }

  const visible = rows.filter((row) => Number(row.quantity) !== 0);
  return <div className="erp-page">
    <header className="page-heading"><div><p className="eyebrow">OPERASIONAL · BATCH TRACEABILITY</p><h1>Persediaan</h1><p className="page-subtitle">Saldo dan riwayat pergerakan dibaca dari ledger. Telusuri batch dari penerimaan, proses produksi, inspeksi, hingga penjualan.</p></div><span className="live-badge page-live"><i/> LEDGER LIVE</span></header>
    {error && <div className="load-error" role="alert"><CircleAlert size={16}/>{error}</div>}{notice && <div className="success-notice">{notice}</div>}
    <section className="surface list-panel inventory-panel"><div className="surface-heading"><div><h2><PackageCheck size={15}/> Stok cabang dan gudang</h2><p>{visible.length} saldo batch · status kualitas dan lokasi tercatat per batch</p></div><span className="count-badge">Per batch</span></div>
      {loading ? <div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat saldo ledger…</div> : visible.length === 0 ? <div className="empty-state">Belum ada mutasi stok. Mulai dari pembelian dan penerimaan terkonfirmasi.</div> : <div className="inventory-list">{visible.map((row, index) => <article className="inventory-row" key={`${row.warehouse_id}-${row.product_id}-${row.batch_id ?? index}`}>
        <div className="inventory-product"><span className="inventory-product-icon"><PackageCheck size={17}/></span><span><strong>{row.product_name}</strong><small>{row.sku} · batch {row.batch_id?.slice(0, 8) ?? 'tanpa batch'}</small></span></div>
        <div className="inventory-qty"><strong>{row.quantity} {row.base_unit}</strong><small>{row.warehouse_id.slice(0, 8)} · minimum {row.minimum_stock} {row.base_unit}</small></div>
        <span className={`status-pill quality-${row.quality_status ?? 'pending'}`}>{statusLabels[row.quality_status ?? 'pending'] ?? 'Status belum diketahui'}</span>
        {row.batch_id && <div className="inspection-actions"><button className="secondary-button" onClick={() => void openTrace(row.batch_id!)}><Search size={13}/> Lacak batch</button>{row.quality_status === 'pending' && <><button className="secondary-button pass" disabled={busy === row.batch_id} onClick={() => void inspect(row.batch_id!, 'passed')}><Check size={13}/> Lulus inspeksi</button><button className="secondary-button quarantine" disabled={busy === row.batch_id} onClick={() => void inspect(row.batch_id!, 'quarantined')}><ShieldAlert size={13}/> Karantina</button></>}{busy === row.batch_id && <LoaderCircle size={15} className="spin"/>}</div>}
      </article>)}</div>}
    </section>

    {traceLoading && <div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat riwayat batch…</div>}
    {traceError && <div className="load-error" role="alert"><CircleAlert size={16}/>{traceError}</div>}
    {trace && <section className="surface trace-panel"><div className="surface-heading"><div><h2><Search size={15}/> Riwayat asal-usul batch</h2><p>{trace.batch.product_name} · {trace.batch.batch_number} · {trace.batch.branch_name}</p></div><button className="text-action" onClick={() => setTrace(null)}>Tutup</button></div>
      <div className="trace-summary"><span><small>PRODUK</small><strong>{trace.batch.product_name} · {trace.batch.sku}</strong></span><span><small>STATUS KUALITAS</small><strong>{statusLabels[trace.batch.quality_status] ?? trace.batch.quality_status}</strong></span><span><small>SUMBER</small><strong>{trace.batch.source_type === 'receipt' ? 'Penerimaan pembelian' : trace.batch.source_type === 'production' ? 'Batch produksi' : trace.batch.source_type}</strong></span></div>
      {trace.events.length === 0 ? <div className="empty-state">Belum ada peristiwa untuk batch ini.</div> : <ol className="trace-events">{trace.events.map((event, index) => <li key={`${event.event_type}-${event.happened_at}-${event.reference ?? index}`}><span className="trace-event-icon">{event.event_type === 'sale' ? <ArrowUpRight size={15}/> : event.event_type === 'production_input' ? <ArrowDownLeft size={15}/> : <Clock3 size={15}/>}</span><div className="trace-event-copy"><strong>{event.description}</strong><small>{new Date(event.happened_at).toLocaleString('id-ID')}{event.reference ? ` · ${event.reference}` : ''}{event.related_reference ? ` · ${event.related_reference}` : ''}{event.party_name ? ` · ${event.party_name}` : ''}</small>{event.quantity != null && <small>Jumlah: {event.quantity} {event.unit_code}</small>}{event.notes && <small>Catatan: {event.notes}</small>}{event.related_batch_id && <button className="text-action" onClick={() => void openTrace(event.related_batch_id!)}>Telusuri batch hasil {event.related_batch_number}</button>}</div></li>)}</ol>}
    </section>}

    <section className="surface movement-panel"><div className="surface-heading"><div><h2><Clock3 size={15}/> Kartu mutasi stok</h2><p>100 mutasi terbaru pada cabang aktif · nilai bertanda menunjukkan stok masuk/keluar</p></div><span className="count-badge">{movements.length} mutasi</span></div>
      {loading ? <div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat kartu mutasi…</div> : movements.length === 0 ? <div className="empty-state">Belum ada mutasi stok.</div> : <div className="responsive-list">{movements.map((movement) => <article className="movement-row" key={movement.movement_id}><span className={`movement-direction ${Number(movement.quantity_delta) > 0 ? 'movement-in' : 'movement-out'}`}>{Number(movement.quantity_delta) > 0 ? <ArrowDownLeft size={15}/> : <ArrowUpRight size={15}/>}</span><span className="movement-main"><strong>{movement.product_name} · {movement.batch_number ?? 'tanpa batch'}</strong><small>{movementLabels[movement.movement_type] ?? movement.movement_type} · {movement.warehouse_name} · {movement.source_reference}</small></span><strong className={Number(movement.quantity_delta) > 0 ? 'movement-positive' : 'movement-negative'}>{Number(movement.quantity_delta) > 0 ? '+' : ''}{movement.quantity_delta} {movement.unit_code}</strong><small className="movement-date">{new Date(movement.created_at).toLocaleString('id-ID')}</small></article>)}</div>}
    </section>
    <div className="info-strip inventory-note"><CircleAlert size={15}/> Koreksi stok dicatat melalui stok opname dengan alasan dan persetujuan. Selisih positif menggunakan biaya rata-rata berjalan; selisih negatif mengurangi persediaan dengan biaya yang sama.</div>
  </div>;
}
