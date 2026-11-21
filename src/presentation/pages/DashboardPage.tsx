import { ArrowDownLeft, Boxes, CircleAlert, ClipboardList, PackageCheck, Wallet } from 'lucide-react';
import { getDashboard } from '../../application/use-cases/GetDashboard';
import type { DashboardRepository } from '../../application/ports/DashboardRepository';
import type { DashboardSummary, OperationalNotice } from '../../domain/dashboard/DashboardSummary';
import { MenuCard } from '../components/MenuCard';
import type { AppModule, ModuleId } from '../../domain/navigation/Module';
import { useEffect, useState } from 'react';

const rupiah = (value: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value);
const todayLabel = new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'long' }).format(new Date()).toLocaleUpperCase('id-ID');
const notices: Record<OperationalNotice['kind'], typeof CircleAlert> = { warning: CircleAlert, critical: CircleAlert, info: ClipboardList, success: PackageCheck };

function StatCard({ label, value, hint, icon: Icon, tone }: { label: string; value: string; hint: string; icon: typeof Wallet; tone: string }) {
  return <article className="stat-card"><div className="stat-heading"><span>{label}</span><span className={`stat-icon ${tone}`}><Icon size={18} /></span></div><strong className="stat-value">{value}</strong><div className="stat-foot">{hint}</div></article>;
}

function MiniChart() {
  return <div className="chart-wrap"><div className="chart-y-labels"><span>20 jt</span><span>15 jt</span><span>10 jt</span><span>5 jt</span></div><div className="chart-area"><div className="chart-grid"><i /><i /><i /><i /></div><svg viewBox="0 0 600 190" preserveAspectRatio="none" role="img" aria-label="Grafik ilustrasi penjualan tujuh hari"><defs><linearGradient id="chartFill" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#208565" stopOpacity=".2"/><stop offset="100%" stopColor="#208565" stopOpacity="0"/></linearGradient></defs><path d="M0 145 C45 132 52 112 93 125 S147 91 187 110 S235 73 280 89 S324 113 365 80 S419 100 454 58 S505 82 540 48 S580 58 600 24 L600 190 L0 190Z" fill="url(#chartFill)"/><path d="M0 145 C45 132 52 112 93 125 S147 91 187 110 S235 73 280 89 S324 113 365 80 S419 100 454 58 S505 82 540 48 S580 58 600 24" fill="none" stroke="#188260" strokeWidth="3" vectorEffect="non-scaling-stroke"/><circle cx="600" cy="24" r="5" fill="#188260" /></svg><div className="chart-x-labels"><span>Jum</span><span>Sab</span><span>Min</span><span>Sen</span><span>Sel</span><span>Rab</span><span>Kam</span></div></div></div>;
}

export function DashboardPage({ repository, modules, onSelect, userName }: { repository: DashboardRepository; modules: AppModule[]; onSelect: (id: ModuleId) => void; userName: string }) {
  const [data, setData] = useState<{ summary: DashboardSummary; notices: OperationalNotice[] } | null>(null);
  const [loadError, setLoadError] = useState('');
  useEffect(() => { let mounted = true; void getDashboard(repository).then((result) => { if (mounted) setData(result); }).catch((cause: unknown) => { if (mounted) setLoadError(cause instanceof Error ? cause.message : 'Gagal memuat dashboard.'); }); return () => { mounted = false; }; }, [repository]);
  const summary = data?.summary;
  const primaryModules = modules.filter((module) => ['purchases', 'receiving', 'production', 'inventory', 'transfers', 'sales', 'customers', 'shipping', 'documents', 'document-scan', 'finance', 'payables', 'receivables', 'reports', 'master-data', 'employees', 'settings'].includes(module.id));

  return <div className="dashboard-page"><div className="page-heading"><div><p className="eyebrow">RINGKASAN OPERASIONAL <span>·</span> {todayLabel}</p><h1>Selamat pagi, {userName} <span>👋</span></h1><p className="page-subtitle">Pantau aktivitas usaha dan hal yang perlu ditindaklanjuti.</p></div><div className="heading-meta"><button className="date-filter">Hari ini <span>⌄</span></button></div></div>
    {loadError ? <div className="load-error" role="alert"><CircleAlert size={17}/><span>Ringkasan gagal dimuat: {loadError}</span></div> : <div className="data-source-notice"><span className="live-dot"/><span>Data dari workspace aktif · pembaruan saat halaman dibuka</span></div>}
    <div className="stats-grid"><StatCard label="Omzet hari ini" value={summary ? rupiah(summary.salesToday) : '—'} hint="Perbandingan periode belum tersedia" icon={Wallet} tone="mint"/><StatCard label="Transaksi penjualan" value={summary ? `${summary.salesCount} nota` : '—'} hint={summary ? `${summary.unpaidCount} belum lunas hari ini` : 'Menunggu data'} icon={ClipboardList} tone="blue"/><StatCard label="Stok siap jual" value={summary ? `${summary.readyStockKg} kg` : '—'} hint={summary ? `Ayam ${summary.chickenStockKg} kg · Bebek ${summary.duckStockKg} kg` : 'Menunggu data'} icon={Boxes} tone="orange"/><StatCard label="Piutang pelanggan" value={summary ? rupiah(summary.receivables) : '—'} hint="Sisa tagihan seluruh invoice aktif" icon={ArrowDownLeft} tone="violet"/></div>
    <div className="dashboard-panels"><section className="surface chart-panel"><div className="surface-heading"><div><h2>Tren penjualan</h2><p>Nilai transaksi selama tujuh hari terakhir <span className="demo-inline">· ilustrasi</span></p></div><button className="select-button">7 hari terakhir <span>⌄</span></button></div><MiniChart /></section><section className="surface attention-panel"><div className="surface-heading"><div><h2>Perlu perhatian</h2><p>Peringatan stok cabang aktif</p></div><span className="count-badge">{data?.notices.length ?? '—'} item</span></div><div className="notice-list">{data?.notices.map((notice) => { const Icon = notices[notice.kind]; const destination: ModuleId = notice.id.startsWith('low-') ? 'inventory' : notice.kind === 'critical' ? 'inventory' : notice.kind === 'info' ? 'shipping' : 'receiving'; return <button className="notice-item" key={notice.id} onClick={() => onSelect(destination)}><span className={`notice-icon ${notice.kind}`}><Icon size={17}/></span><span className="notice-copy"><strong>{notice.title}</strong><small>{notice.detail}</small></span><span className="notice-chevron">›</span></button>; })}</div></section></div>
    <section className="launcher-section"><div className="section-heading"><div><h2>Menu utama</h2><p>Pilih modul untuk melihat ruang kerjanya.</p></div><span className="module-count">{primaryModules.length} modul</span></div><div className="launcher-grid">{primaryModules.map((module) => <MenuCard key={module.id} module={module} onSelect={onSelect} />)}</div></section>
  </div>;
}
