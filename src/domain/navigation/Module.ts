export type ModuleId =
  | 'dashboard' | 'purchases' | 'receiving' | 'production' | 'inventory'
  | 'transfers' | 'sales' | 'customers' | 'shipping' | 'documents'
  | 'document-scan' | 'finance' | 'payables' | 'receivables' | 'reports'
  | 'master-data' | 'employees' | 'settings' | 'opname' | 'returns' | 'notifications';

export interface AppModule {
  id: ModuleId;
  label: string;
  description: string;
  group: 'home' | 'operations' | 'sales' | 'finance' | 'control';
  status: 'live' | 'ui-only' | 'planned';
  icon: string;
}

export const appModules: AppModule[] = [
  { id: 'dashboard', label: 'Dashboard', description: 'Ringkasan operasional', group: 'home', status: 'live', icon: 'LayoutDashboard' },
  { id: 'purchases', label: 'Pembelian', description: 'Pesanan ke pemasok', group: 'operations', status: 'live', icon: 'ShoppingBasket' },
  { id: 'receiving', label: 'Penerimaan', description: 'Barang masuk dan pemeriksaan', group: 'operations', status: 'live', icon: 'PackageCheck' },
  { id: 'production', label: 'Produksi', description: 'Batch pemotongan dan hasil', group: 'operations', status: 'live', icon: 'Cog' },
  { id: 'inventory', label: 'Persediaan', description: 'Stok per batch dan gudang', group: 'operations', status: 'live', icon: 'Boxes' },
  { id: 'transfers', label: 'Transfer', description: 'Perpindahan antar gudang', group: 'operations', status: 'live', icon: 'ArrowLeftRight' },
  { id: 'opname', label: 'Stok opname', description: 'Hitung fisik dan penyesuaian stok', group: 'operations', status: 'live', icon: 'ClipboardCheck' },
  { id: 'sales', label: 'Penjualan', description: 'POS, nota, dan retur', group: 'sales', status: 'live', icon: 'ShoppingCart' },
  { id: 'returns', label: 'Retur', description: 'Penerimaan dan pemeriksaan barang retur', group: 'sales', status: 'live', icon: 'Undo2' },
  { id: 'customers', label: 'Pelanggan', description: 'Data dan riwayat pelanggan', group: 'sales', status: 'live', icon: 'Users' },
  { id: 'shipping', label: 'Pengiriman', description: 'Jadwal dan serah terima', group: 'sales', status: 'live', icon: 'Truck' },
  { id: 'documents', label: 'Invoice & Dokumen', description: 'Dokumen transaksi', group: 'sales', status: 'live', icon: 'Files' },
  { id: 'document-scan', label: 'Scan Nota', description: 'Ekstraksi dokumen untuk ditinjau', group: 'sales', status: 'live', icon: 'ScanLine' },
  { id: 'finance', label: 'Kas & Bank', description: 'Saldo, pengeluaran, dan jurnal', group: 'finance', status: 'live', icon: 'Wallet' },
  { id: 'payables', label: 'Utang', description: 'Tagihan pemasok', group: 'finance', status: 'live', icon: 'Receipt' },
  { id: 'receivables', label: 'Piutang', description: 'Tagihan pelanggan dan umur piutang', group: 'finance', status: 'live', icon: 'HandCoins' },
  { id: 'reports', label: 'Laporan', description: 'Analisis usaha', group: 'control', status: 'live', icon: 'ChartNoAxesCombined' },
  { id: 'master-data', label: 'Master Data', description: 'Produk, satuan, pelanggan, dan pemasok', group: 'control', status: 'live', icon: 'Database' },
  { id: 'employees', label: 'Karyawan & Pengguna', description: 'Data karyawan, akun, dan peran', group: 'control', status: 'live', icon: 'ContactRound' },
  { id: 'settings', label: 'Pengaturan', description: 'Identitas perusahaan, cabang, dan gudang', group: 'control', status: 'live', icon: 'Settings' },
  { id: 'notifications', label: 'Notifikasi', description: 'Persetujuan dan peringatan operasional', group: 'control', status: 'live', icon: 'Bell' },
];

const modulesByRole: Record<string, ModuleId[]> = {
  owner: appModules.map((module) => module.id),
  super_admin: appModules.map((module) => module.id),
  central_admin: appModules.map((module) => module.id),
  branch_admin: appModules.map((module) => module.id),
  purchasing: ['dashboard', 'purchases', 'receiving', 'inventory', 'documents', 'document-scan', 'master-data','notifications'],
  production: ['dashboard', 'production', 'inventory', 'reports','notifications'],
  warehouse: ['dashboard', 'receiving', 'inventory', 'transfers','opname', 'shipping', 'reports','notifications'],
  cashier: ['dashboard', 'sales','returns', 'customers', 'shipping', 'documents', 'document-scan', 'receivables', 'master-data','notifications'],
  finance: ['dashboard', 'customers', 'documents', 'document-scan', 'finance', 'payables', 'receivables', 'reports', 'master-data','returns','notifications'],
  supervisor: ['dashboard', 'purchases', 'receiving', 'production', 'inventory', 'transfers','opname','returns', 'shipping', 'reports','notifications'],
  delivery: ['dashboard', 'shipping','notifications'],
};

export function modulesForRoles(roles: string[]): AppModule[] {
  const allowed = new Set(roles.flatMap((role) => modulesByRole[role] ?? []));
  return appModules.filter((module) => allowed.has(module.id));
}
