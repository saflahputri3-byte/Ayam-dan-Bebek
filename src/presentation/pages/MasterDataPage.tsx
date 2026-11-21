import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { Archive, CircleAlert, Database, LoaderCircle, Plus, Save, Search } from 'lucide-react';
import type { BranchContext, Customer, CustomerMasterInput, Product, ProductMasterInput, ProductUnit, Supplier, SupplierMasterInput } from '../../domain/erp/ErpTypes';
import type { MasterDataRepository } from '../../application/ports/MasterDataRepository';

type Tab = 'products' | 'suppliers' | 'customers';
const emptyProduct = (): ProductMasterInput => ({ sku: '', name: '', species: '', category: '', base_unit: 'kg', minimum_stock: 0 });
const emptySupplier = (): SupplierMasterInput => ({ code: '', name: '', phone: '', address: '' });
const emptyCustomer = (): CustomerMasterInput => ({ code: '', name: '', phone: '', address: '', credit_limit: 0 });

export function MasterDataPage({ repository, context, roles, initialTab='products' }: { repository: MasterDataRepository; context: BranchContext; roles: string[]; initialTab?: Tab }) {
  const adminRoles = ['owner', 'super_admin', 'central_admin', 'branch_admin'];
  const canManageProducts = roles.some((role) => [...adminRoles, 'purchasing'].includes(role));
  const canManageCustomers = roles.some((role) => [...adminRoles, 'cashier', 'finance'].includes(role));
  const tabs: Tab[] = [...(canManageProducts ? ['products', 'suppliers'] as Tab[] : []), ...(canManageCustomers ? ['customers'] as Tab[] : [])];
  const [tab, setTab] = useState<Tab>(tabs.includes(initialTab) ? initialTab : tabs[0] ?? 'products');
  const [products, setProducts] = useState<Product[]>([]); const [units, setUnits] = useState<ProductUnit[]>([]); const [suppliers, setSuppliers] = useState<Supplier[]>([]); const [customers, setCustomers] = useState<Customer[]>([]);
  const [productForm, setProductForm] = useState(emptyProduct); const [supplierForm, setSupplierForm] = useState(emptySupplier); const [customerForm, setCustomerForm] = useState(emptyCustomer);
  const [editingId, setEditingId] = useState(''); const [search, setSearch] = useState(''); const [busy, setBusy] = useState(false); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [notice, setNotice] = useState('');
  const [selectedProductId, setSelectedProductId] = useState(''); const [newUnitCode, setNewUnitCode] = useState(''); const [newUnitRatio, setNewUnitRatio] = useState(''); const [newUnitSellable, setNewUnitSellable] = useState(false);

  async function refresh() {
    setLoading(true); setError('');
    try { const [p,u,s,c] = await Promise.all([repository.listProducts(context.companyId), repository.listProductUnits(context.companyId), repository.listSuppliers(context.companyId), repository.listCustomers(context.companyId)]); setProducts(p); setUnits(u); setSuppliers(s); setCustomers(c); setSelectedProductId((current) => p.some((item) => item.id === current) ? current : p.find((item) => item.is_active)?.id ?? ''); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Data master gagal dimuat.'); }
    finally { setLoading(false); }
  }
  useEffect(() => { void refresh(); }, [repository, context.companyId]);
  useEffect(() => { if (tabs.length && !tabs.includes(tab)) setTab(tabs[0]); }, [tabs.join(','), tab]);

  const filteredProducts = useMemo(() => products.filter((item) => `${item.sku} ${item.name} ${item.category}`.toLowerCase().includes(search.toLowerCase())), [products, search]);
  const filteredSuppliers = useMemo(() => suppliers.filter((item) => `${item.code} ${item.name}`.toLowerCase().includes(search.toLowerCase())), [suppliers, search]);
  const filteredCustomers = useMemo(() => customers.filter((item) => `${item.code} ${item.name} ${item.phone ?? ''}`.toLowerCase().includes(search.toLowerCase())), [customers, search]);
  const productUnits = units.filter((unit) => unit.product_id === selectedProductId);

  function editProduct(item: Product) { setTab('products'); setEditingId(item.id); setSelectedProductId(item.id); setProductForm({ sku: item.sku, name: item.name, species: (item.species ?? '') as ProductMasterInput['species'], category: item.category, base_unit: item.base_unit as 'kg'|'pcs'|'bird', minimum_stock: Number(item.minimum_stock) }); }
  function editSupplier(item: Supplier) { setEditingId(item.id); setSupplierForm({ code: item.code, name: item.name, phone: item.phone ?? '', address: item.address ?? '' }); }
  function editCustomer(item: Customer) { setEditingId(item.id); setCustomerForm({ code: item.code, name: item.name, phone: item.phone ?? '', address: item.address ?? '', credit_limit: Number(item.credit_limit ?? 0) }); }
  function clearForm() { setEditingId(''); setProductForm(emptyProduct()); setSupplierForm(emptySupplier()); setCustomerForm(emptyCustomer()); }

  async function save(event: FormEvent) {
    event.preventDefault(); setBusy(true); setError(''); setNotice('');
    try {
      if (tab === 'products') {
        if (editingId) await repository.updateProduct(editingId, { name: productForm.name, species: productForm.species, category: productForm.category, minimum_stock: productForm.minimum_stock });
        else { const createdId = await repository.createProduct(context.companyId, productForm); setSelectedProductId(createdId); }
        setNotice(editingId ? 'Produk diperbarui.' : 'Produk dibuat dengan satuan dasar berkonversi 1:1.');
      } else if (tab === 'suppliers') {
        if (editingId) { const current = suppliers.find((item) => item.id === editingId); await repository.updateSupplier(editingId, { ...supplierForm, is_active: current?.is_active ?? true }); }
        else await repository.createSupplier(context.companyId, supplierForm);
        setNotice(editingId ? 'Pemasok diperbarui.' : 'Pemasok ditambahkan.');
      } else {
        if (editingId) { const current = customers.find((item) => item.id === editingId); await repository.updateCustomer(editingId, { ...customerForm, is_active: current?.is_active ?? true }); }
        else await repository.createCustomer(context.companyId, customerForm);
        setNotice(editingId ? 'Pelanggan diperbarui.' : 'Pelanggan ditambahkan.');
      }
      clearForm(); await refresh();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Data master gagal disimpan.'); }
    finally { setBusy(false); }
  }
  async function toggleActive(kind: Tab, id: string, active: boolean) {
    setBusy(true); setError(''); setNotice('');
    try {
      if (kind === 'products') await repository.updateProduct(id, { is_active: !active });
      else if (kind === 'suppliers') { const item = suppliers.find((row) => row.id === id)!; await repository.updateSupplier(id, { code: item.code, name: item.name, phone: item.phone ?? '', address: item.address ?? '', is_active: !active }); }
      else { const item = customers.find((row) => row.id === id)!; await repository.updateCustomer(id, { code: item.code, name: item.name, phone: item.phone ?? '', address: item.address ?? '', credit_limit: Number(item.credit_limit ?? 0), is_active: !active }); }
      setNotice(active ? 'Data dinonaktifkan; riwayat transaksi dipertahankan.' : 'Data diaktifkan kembali.'); await refresh();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Status master gagal diubah.'); }
    finally { setBusy(false); }
  }
  async function addUnit(event: FormEvent) {
    event.preventDefault(); if (!selectedProductId || !newUnitCode) return; setBusy(true); setError(''); setNotice('');
    try { await repository.addProductUnit(context.companyId, { product_id: selectedProductId, unit_code: newUnitCode as 'kg'|'pcs'|'bird', base_units_per_unit: Number(newUnitRatio), is_sellable: newUnitSellable }); setNewUnitCode(''); setNewUnitRatio(''); setNewUnitSellable(false); setNotice('Konversi satuan disimpan sesuai rasio yang Anda masukkan.'); await refresh(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Konversi satuan gagal disimpan.'); }
    finally { setBusy(false); }
  }
  async function updateUnit(unit: ProductUnit) {
    const raw = window.prompt(`Jumlah satuan dasar (${products.find((product) => product.id === unit.product_id)?.base_unit}) untuk 1 ${unit.unit_code}:`, String(unit.base_units_per_unit));
    if (raw === null) return; const ratio = Number(raw); if (!Number.isFinite(ratio) || ratio <= 0) { setError('Rasio konversi harus lebih besar dari nol.'); return; }
    const sellable = window.confirm(`Apakah satuan ${unit.unit_code} boleh dipakai untuk penjualan?`); setBusy(true); setError('');
    try { await repository.updateProductUnit(unit.id, ratio, sellable); setNotice('Rasio satuan diperbarui; transaksi baru memakai rasio ini.'); await refresh(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Konversi satuan gagal diperbarui.'); }
    finally { setBusy(false); }
  }

  if (!tabs.length) return <div className="erp-page"><div className="load-error">Akun tidak memiliki izin untuk mengelola data master.</div></div>;
  return <div className="erp-page"><header className="page-heading"><div><p className="eyebrow">PENGATURAN PERUSAHAAN</p><h1>Master data</h1><p className="page-subtitle">Kelola katalog, pemasok, pelanggan, dan status aktif. Data yang pernah dipakai transaksi diarsipkan, bukan dihapus.</p></div><span className="live-badge page-live"><i/> SUPABASE</span></header>
    {error && <div className="load-error" role="alert"><CircleAlert size={16}/>{error}</div>}{notice && <div className="success-notice">{notice}</div>}
    <div className="master-tabs">{tabs.map((item) => <button key={item} className={tab === item ? 'active' : ''} onClick={() => { setTab(item); clearForm(); }} disabled={busy}>{item === 'products' ? 'Produk & satuan' : item === 'suppliers' ? 'Pemasok' : 'Pelanggan'}</button>)}</div>
    <div className="erp-grid master-grid"><section className="surface erp-form-panel"><div className="surface-heading"><div><h2>{editingId ? <Save size={15}/> : <Plus size={15}/>} {editingId ? 'Ubah' : 'Tambah'} {tab === 'products' ? 'produk' : tab === 'suppliers' ? 'pemasok' : 'pelanggan'}</h2><p>Perubahan disimpan dan masuk audit log.</p></div></div>
      <form className="erp-form" onSubmit={(event) => void save(event)}>
        {tab === 'products' && <><div className="field-row"><label>SKU<input value={productForm.sku} onChange={(event)=>setProductForm({...productForm,sku:event.target.value})} required disabled={Boolean(editingId)}/></label><label>Nama produk<input value={productForm.name} onChange={(event)=>setProductForm({...productForm,name:event.target.value})} required/></label></div><div className="field-row"><label>Kategori<input value={productForm.category} onChange={(event)=>setProductForm({...productForm,category:event.target.value})} required/></label><label>Jenis<select value={productForm.species} onChange={(event)=>setProductForm({...productForm,species:event.target.value as typeof productForm.species})}><option value="">Tidak ditentukan</option><option value="chicken">Ayam</option><option value="duck">Bebek</option><option value="other">Lainnya</option></select></label></div><div className="field-row"><label>Satuan dasar<select value={productForm.base_unit} onChange={(event)=>setProductForm({...productForm,base_unit:event.target.value as typeof productForm.base_unit})} disabled={Boolean(editingId)}><option value="kg">kg</option><option value="pcs">pcs</option><option value="bird">bird (ekor)</option></select></label><label>Stok minimum<input type="number" min="0" step="0.001" value={productForm.minimum_stock} onChange={(event)=>setProductForm({...productForm,minimum_stock:Number(event.target.value)})} required/></label></div>{editingId&&<div className="info-strip">SKU dan satuan dasar dikunci setelah produk dibuat agar transaksi lama tetap konsisten.</div>}</>}
        {tab === 'suppliers' && <><div className="field-row"><label>Kode pemasok<input value={supplierForm.code} onChange={(event)=>setSupplierForm({...supplierForm,code:event.target.value})} required/></label><label>Nama pemasok<input value={supplierForm.name} onChange={(event)=>setSupplierForm({...supplierForm,name:event.target.value})} required/></label></div><div className="field-row"><label>Telepon<input value={supplierForm.phone} onChange={(event)=>setSupplierForm({...supplierForm,phone:event.target.value})}/></label><label>Alamat<input value={supplierForm.address} onChange={(event)=>setSupplierForm({...supplierForm,address:event.target.value})}/></label></div></>}
        {tab === 'customers' && <><div className="field-row"><label>Kode pelanggan<input value={customerForm.code} onChange={(event)=>setCustomerForm({...customerForm,code:event.target.value})} required/></label><label>Nama pelanggan<input value={customerForm.name} onChange={(event)=>setCustomerForm({...customerForm,name:event.target.value})} required/></label></div><div className="field-row"><label>Telepon<input value={customerForm.phone} onChange={(event)=>setCustomerForm({...customerForm,phone:event.target.value})}/></label><label>Alamat<input value={customerForm.address} onChange={(event)=>setCustomerForm({...customerForm,address:event.target.value})}/></label></div><label className="full-field">Batas kredit (Rp)<input type="number" min="0" step="1" value={customerForm.credit_limit} onChange={(event)=>setCustomerForm({...customerForm,credit_limit:Number(event.target.value)})}/></label></>}
        <div className="master-form-actions"><button className="auth-submit" disabled={busy||loading}>{busy?<><LoaderCircle size={15} className="spin"/> Menyimpan…</>:<><Save size={15}/> {editingId?'Simpan perubahan':'Tambah data'}</>}</button>{editingId&&<button type="button" className="secondary-button" onClick={clearForm}>Batal</button>}</div>
      </form>
      {tab === 'products' && editingId && <div className="unit-manager"><div className="section-heading"><div><h2>Satuan & konversi</h2><p>Rasio: berapa unit dasar dalam satu unit jual/pakai.</p></div></div>{productUnits.map((unit)=><div className="unit-row" key={unit.id}><span><strong>{unit.unit_code}</strong><small>{unit.base_units_per_unit} {products.find((product)=>product.id===selectedProductId)?.base_unit} per {unit.unit_code}{unit.is_sellable?' · dapat dijual':''}</small></span><button className="text-action" disabled={busy||unit.unit_code===products.find((product)=>product.id===selectedProductId)?.base_unit} onClick={()=>void updateUnit(unit)}>Ubah rasio</button></div>)}<form className="unit-add-form" onSubmit={(event)=>void addUnit(event)}><label>Satuan<select value={newUnitCode} onChange={(event)=>setNewUnitCode(event.target.value)} required><option value="">Pilih satuan lain</option>{(['kg','pcs','bird'] as const).filter((code)=>!productUnits.some((unit)=>unit.unit_code===code)).map((code)=><option key={code} value={code}>{code}</option>)}</select></label><label>Unit dasar per satuan<input type="number" min="0.000001" step="any" value={newUnitRatio} onChange={(event)=>setNewUnitRatio(event.target.value)} required/></label><label className="unit-checkbox"><input type="checkbox" checked={newUnitSellable} onChange={(event)=>setNewUnitSellable(event.target.checked)}/> Dapat dijual</label><button className="secondary-button" disabled={busy||!newUnitCode}><Plus size={14}/> Tambah satuan</button></form></div>}
    </section>
    <section className="surface list-panel"><div className="surface-heading"><div><h2><Database size={15}/> {tab==='products'?'Daftar produk':tab==='suppliers'?'Daftar pemasok':'Daftar pelanggan'}</h2><p>Data aktif dan arsip · {tab==='products'?products.length:tab==='suppliers'?suppliers.length:customers.length} baris</p></div></div><label className="master-search"><Search size={15}/><input value={search} onChange={(event)=>setSearch(event.target.value)} placeholder="Cari kode atau nama"/></label>
      {loading?<div className="inline-loading"><LoaderCircle size={16} className="spin"/> Memuat master data…</div>:tab==='products'?filteredProducts.map((item)=><article className="master-row" key={item.id}><span><strong>{item.name}</strong><small>{item.sku} · {item.category} · dasar {item.base_unit} · minimum {item.minimum_stock}</small></span><span className={`status-pill ${item.is_active?'quality-passed':''}`}>{item.is_active?'Aktif':'Arsip'}</span><div><button className="text-action" onClick={()=>editProduct(item)}>Ubah</button><button className="text-action" disabled={busy} onClick={()=>void toggleActive('products',item.id,item.is_active)}><Archive size={13}/>{item.is_active?'Nonaktifkan':'Aktifkan'}</button></div></article>) : tab==='suppliers'?filteredSuppliers.map((item)=><article className="master-row" key={item.id}><span><strong>{item.name}</strong><small>{item.code} · {item.phone||'tanpa telepon'} · {item.address||'tanpa alamat'}</small></span><span className={`status-pill ${item.is_active?'quality-passed':''}`}>{item.is_active?'Aktif':'Arsip'}</span><div><button className="text-action" onClick={()=>editSupplier(item)}>Ubah</button><button className="text-action" disabled={busy} onClick={()=>void toggleActive('suppliers',item.id,Boolean(item.is_active))}><Archive size={13}/>{item.is_active?'Nonaktifkan':'Aktifkan'}</button></div></article>) : filteredCustomers.map((item)=><article className="master-row" key={item.id}><span><strong>{item.name}</strong><small>{item.code} · {item.phone||'tanpa telepon'} · batas kredit {new Intl.NumberFormat('id-ID').format(Number(item.credit_limit??0))}</small></span><span className={`status-pill ${item.is_active?'quality-passed':''}`}>{item.is_active?'Aktif':'Arsip'}</span><div><button className="text-action" onClick={()=>editCustomer(item)}>Ubah</button><button className="text-action" disabled={busy} onClick={()=>void toggleActive('customers',item.id,Boolean(item.is_active))}><Archive size={13}/>{item.is_active?'Nonaktifkan':'Aktifkan'}</button></div></article>)}
      {!loading && ((tab==='products'&&filteredProducts.length===0)||(tab==='suppliers'&&filteredSuppliers.length===0)||(tab==='customers'&&filteredCustomers.length===0))&&<div className="empty-state">Tidak ada data yang cocok.</div>}
    </section></div>
  </div>;
}
