import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { CircleAlert, LoaderCircle, Plus, ReceiptText, ShoppingCart, Trash2 } from 'lucide-react';
import type { BranchContext, Customer, InventoryRow, Product, ProductUnit, SaleCommand, SaleListItem, Warehouse } from '../../domain/erp/ErpTypes';
import type { ErpRepository } from '../../application/ports/ErpRepository';
import { getErrorMessage } from '../../domain/shared/errorMessage';

type DraftLine = { product_id: string; batch_id: string; quantity: string; unit_code: string; unit_price: string };
const emptyLine = (): DraftLine => ({ product_id: '', batch_id: '', quantity: '', unit_code: '', unit_price: '' });
const money = (value: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value);

export function SalesPage({ repository, context, onInvoice }: { repository: ErpRepository; context: BranchContext; onInvoice: (saleId: string) => void }) {
  const [products, setProducts] = useState<Product[]>([]); const [units, setUnits] = useState<ProductUnit[]>([]); const [customers, setCustomers] = useState<Customer[]>([]); const [warehouses, setWarehouses] = useState<Warehouse[]>([]); const [inventory, setInventory] = useState<InventoryRow[]>([]); const [sales, setSales] = useState<SaleListItem[]>([]);
  const [customerId, setCustomerId] = useState(''); const [warehouseId, setWarehouseId] = useState(''); const [lines, setLines] = useState<DraftLine[]>([emptyLine()]); const [discount, setDiscount] = useState('0'); const [shipping, setShipping] = useState('0'); const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(true); const [saving, setSaving] = useState(false); const [error, setError] = useState(''); const [success, setSuccess] = useState('');
  const [requestKey, setRequestKey] = useState('');
  async function refresh() {
    setLoading(true); setError('');
    try { const [p,u,c,w,i,s] = await Promise.all([repository.getProducts(context.companyId), repository.getProductUnits(context.companyId), repository.getCustomers(context.companyId), repository.getWarehouses(context.branchId), repository.getInventory(context), repository.getSales(context)]); setProducts(p); setUnits(u); setCustomers(c); setWarehouses(w); setInventory(i); setSales(s); setWarehouseId((current) => w.some((item) => item.id === current) ? current : w[0]?.id ?? ''); }
    catch (cause) { setError(getErrorMessage(cause, 'Gagal memuat data penjualan.')); }
    finally { setLoading(false); }
  }
  useEffect(() => { void refresh(); }, [repository, context.companyId, context.branchId]);
  const lineTotals = useMemo(() => lines.map((line) => Math.max(0, Number(line.quantity || 0) * Number(line.unit_price || 0))), [lines]);
  const subtotal = lineTotals.reduce((sum, value) => sum + value, 0); const total = Math.max(0, subtotal - Number(discount || 0) + Number(shipping || 0));
  const updateLine = (index: number, update: Partial<DraftLine>) => setLines((current) => current.map((line, idx) => idx === index ? { ...line, ...update } : line));
  function selectProduct(index: number, productId: string) {
    const unit = units.find((item) => item.product_id === productId && item.is_sellable);
    const batch = inventory.find((item) => item.product_id === productId && item.quality_status === 'passed' && item.batch_id && item.quantity > 0 && item.warehouse_id === warehouseId);
    updateLine(index, { product_id: productId, unit_code: unit?.unit_code ?? '', batch_id: batch?.batch_id ?? '' });
  }
  async function submit(event: FormEvent) {
    event.preventDefault(); setSaving(true); setError(''); setSuccess('');
    try {
      const command: SaleCommand = { ...context, warehouse_id: warehouseId, customer_id: customerId || null, discount_amount: Number(discount || 0), shipping_amount: Number(shipping || 0), notes, items: lines.map((line) => ({ product_id: line.product_id, batch_id: line.batch_id, quantity: Number(line.quantity), unit_code: line.unit_code, unit_price: Number(line.unit_price), discount_amount: 0 })) };
      if (!warehouseId || command.items.some((line) => !line.product_id || !line.batch_id || !line.unit_code || !Number.isFinite(line.quantity) || line.quantity <= 0 || !Number.isFinite(line.unit_price) || line.unit_price < 0 || lines.some((raw) => raw.unit_price === ''))) throw new Error('Lengkapi gudang, produk, batch lolos inspeksi, jumlah, satuan, dan harga setiap baris.');
      if (command.discount_amount > subtotal) throw new Error('Diskon tidak boleh melebihi subtotal.');
      const key = requestKey || crypto.randomUUID(); setRequestKey(key);
      const result = await repository.postSale(command, key); setRequestKey(''); setSuccess(`Penjualan ${result.document_number} berhasil diposting.`); await refresh(); onInvoice(result.sale_id!);
    } catch (cause) { setError(getErrorMessage(cause, 'Penjualan gagal disimpan.')); }
    finally { setSaving(false); }
  }

  return <div className="erp-page"><header className="page-heading"><div><p className="eyebrow">TRANSAKSI · PENJUALAN & POS</p><h1>Penjualan</h1><p className="page-subtitle">Posting transaksi mengurangi saldo batch lewat ledger stok. Pembayaran dicatat dari invoice.</p></div><span className="live-badge page-live"><i/> SUPABASE</span></header>
    {error && <div className="load-error" role="alert"><CircleAlert size={16}/>{error}</div>}{success && <div className="success-notice">{success}</div>}
    <div className="erp-grid"><section className="surface erp-form-panel"><div className="surface-heading"><div><h2><ShoppingCart size={15}/> Buat penjualan</h2><p>Invoice bernomor server dibuat saat transaksi berhasil.</p></div></div>
      {loading ? <div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat data cabang…</div> : <form className="erp-form" noValidate onSubmit={(event) => void submit(event)}>
        <div className="field-row"><label>Pelanggan<select value={customerId} onChange={(event) => setCustomerId(event.target.value)}><option value="">Pelanggan umum</option>{customers.map((customer) => <option key={customer.id} value={customer.id}>{customer.name}</option>)}</select></label><label>Gudang sumber<select value={warehouseId} onChange={(event) => { const nextWh = event.target.value; setWarehouseId(nextWh); setLines((curr) => curr.map((l) => { const nextBatch = inventory.find((it) => it.product_id === l.product_id && it.quality_status === 'passed' && it.batch_id && it.quantity > 0 && it.warehouse_id === nextWh); return { ...l, batch_id: nextBatch?.batch_id ?? '' }; })); }} required><option value="">Pilih gudang</option>{warehouses.map((warehouse) => <option key={warehouse.id} value={warehouse.id}>{warehouse.name}</option>)}</select></label></div>
        <div className="line-items-heading"><strong>Produk</strong><button type="button" className="text-action" onClick={() => setLines((current) => [...current, emptyLine()])}><Plus size={14}/> Tambah produk</button></div>
        {lines.map((line,index) => { const product=products.find((item)=>item.id===line.product_id); const productUnits=units.filter((item)=>item.product_id===line.product_id && item.is_sellable); const batches=inventory.filter((item)=>item.product_id===line.product_id && item.quality_status==='passed' && item.batch_id && item.quantity>0 && item.warehouse_id===warehouseId); return <div className="sale-line" key={index}><div className="line-title"><span>Produk {index+1}</span>{lines.length>1&&<button type="button" className="icon-danger" aria-label="Hapus baris" onClick={()=>setLines((current)=>current.filter((_,idx)=>idx!==index))}><Trash2 size={14}/></button>}</div><div className="field-row"><label>Nama produk<select value={line.product_id} onChange={(event)=>selectProduct(index,event.target.value)} required><option value="">Pilih produk</option>{products.map((item)=><option key={item.id} value={item.id}>{item.name} · {item.sku}</option>)}</select></label><label>Batch & stok lolos inspeksi<select value={line.batch_id} onChange={(event)=>updateLine(index,{batch_id:event.target.value})} required disabled={!product}><option value="">Pilih batch</option>{batches.map((batch)=><option key={batch.batch_id!} value={batch.batch_id!}>{batch.batch_id!.slice(0,8)} · {batch.quantity} {batch.base_unit}</option>)}</select></label></div><div className="field-row three"><label>Jumlah<input type="number" min="0.001" step="0.001" value={line.quantity} onChange={(event)=>updateLine(index,{quantity:event.target.value})} required/></label><label>Satuan<select value={line.unit_code} onChange={(event)=>updateLine(index,{unit_code:event.target.value})} required><option value="">Satuan</option>{productUnits.map((unit)=><option key={unit.id} value={unit.unit_code}>{unit.unit_code}</option>)}</select></label><label>Harga per satuan<input type="number" min="0" step="1" value={line.unit_price} onChange={(event)=>updateLine(index,{unit_price:event.target.value})} required/></label></div></div>; })}
        <div className="field-row"><label>Diskon transaksi (Rp)<input type="number" min="0" step="1" value={discount} onChange={(event)=>setDiscount(event.target.value)}/></label><label>Biaya pengiriman (Rp)<input type="number" min="0" step="1" value={shipping} onChange={(event)=>setShipping(event.target.value)}/></label></div><label className="full-field">Catatan<input value={notes} onChange={(event)=>setNotes(event.target.value)} placeholder="Opsional"/></label>
        <div className="sale-total"><span>Subtotal <strong>{money(subtotal)}</strong></span><span>Total invoice <strong>{money(total)}</strong></span></div><button type="submit" className="auth-submit" disabled={saving||loading||warehouses.length===0}>{saving?<><LoaderCircle size={16} className="spin"/> Posting…</>:<>Posting penjualan & buat invoice <ReceiptText size={16}/></>}</button>
      </form>}
    </section><section className="surface list-panel"><div className="surface-heading"><div><h2>Invoice terbaru</h2><p>{sales.length} transaksi dari cabang aktif</p></div><span className="count-badge">Live</span></div>{loading?<div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat transaksi…</div>:sales.length===0?<div className="empty-state">Belum ada penjualan pada cabang ini.</div>:<div className="responsive-list">{sales.map((sale)=><button className="sale-row" key={sale.id} onClick={()=>onInvoice(sale.id)}><span className="sale-row-main"><strong>{sale.document_number}</strong><small>{sale.customer_name} · {new Date(sale.created_at).toLocaleDateString('id-ID')}</small></span><span className="sale-row-total">{money(sale.total_amount)}<small>{sale.paid_amount>=sale.total_amount?'Lunas':`Sisa ${money(sale.total_amount-sale.paid_amount)}`}</small></span></button>)}</div>}</section></div>
    {inventory.length===0&&<div className="empty-warning"><CircleAlert size={16}/> Stok akan muncul setelah penerimaan dikonfirmasi dan batch lulus inspeksi kualitas.</div>}
  </div>;
}
