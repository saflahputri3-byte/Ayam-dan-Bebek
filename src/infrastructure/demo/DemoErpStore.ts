import type {
  Customer,
  InventoryMovement,
  InventoryRow,
  Invoice,
  Product,
  ProductUnit,
  Purchase,
  SaleListItem,
  ScanRecord,
  Supplier,
} from '../../domain/erp/ErpTypes';
import type { Row } from '../../domain/operations/OperationsTypes';
import type { SettingsRow } from '../../domain/settings/SettingsTypes';

export const DEMO_COMPANY_ID = 'demo-company-agi';
export const DEMO_BRANCH_PUSAT_ID = 'demo-branch-pusat';
export const DEMO_BRANCH_BARAT_ID = 'demo-branch-barat';
export const DEMO_USER_ID = 'demo-user-owner';

export class DemoErpStore {
  // Master data
  company: SettingsRow = {
    id: DEMO_COMPANY_ID,
    name: 'AGI Ayam & Bebek',
    legal_name: 'PT Agi Unggas Berkah Nusantara',
    currency_code: 'IDR',
    timezone: 'Asia/Jakarta',
    phone: '021-7890-1234',
    email: 'kontak@agi-unggas.id',
    address: 'Kawasan Sentra Niaga Rantai Dingin Kav. 8-10, Jakarta',
    logo_path: '',
    is_active: true,
  };

  branches: SettingsRow[] = [
    { id: DEMO_BRANCH_PUSAT_ID, company_id: DEMO_COMPANY_ID, code: 'PUSAT', name: 'Cabang Utama (Pusat)', address: 'Kawasan Sentra Niaga Rantai Dingin Kav. 8, Jakarta', phone: '021-7890-1234', is_active: true },
    { id: DEMO_BRANCH_BARAT_ID, company_id: DEMO_COMPANY_ID, code: 'BARAT', name: 'Cabang Barat', address: 'Jl. Daan Mogot KM 12, Jakarta Barat', phone: '021-5544-3322', is_active: true },
  ];

  warehouses: SettingsRow[] = [
    { id: 'wh-utama', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, code: 'UTAMA', name: 'Gudang Utama (Fresh)', is_active: true },
    { id: 'wh-cold', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, code: 'COLD-01', name: 'Cold Storage Frozen', is_active: true },
    { id: 'wh-barat', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_BARAT_ID, code: 'WH-BARAT', name: 'Gudang Cabang Barat', is_active: true },
  ];

  products: Product[] = [
    { id: 'prod-ayam-karkas', sku: 'AGI-AYAM-KARKAS', name: 'Ayam Broiler Utuh / Karkas', species: 'chicken', category: 'Karkas Segar', base_unit: 'kg', minimum_stock: 50, is_active: true },
    { id: 'prod-fillet-dada', sku: 'AGI-DADA-FILLET', name: 'Fillet Dada Ayam Tanpa Tulang (Boneless)', species: 'chicken', category: 'Daging Olahan', base_unit: 'kg', minimum_stock: 30, is_active: true },
    { id: 'prod-paha-ayam', sku: 'AGI-PAHA-UTUH', name: 'Paha Utuh Ayam Segar', species: 'chicken', category: 'Potongan Ayam', base_unit: 'kg', minimum_stock: 30, is_active: true },
    { id: 'prod-sayap-ayam', sku: 'AGI-SAYAP-AYAM', name: 'Sayap Ayam Broiler', species: 'chicken', category: 'Potongan Ayam', base_unit: 'kg', minimum_stock: 20, is_active: true },
    { id: 'prod-jeroan-ayam', sku: 'AGI-HATI-AMPELA', name: 'Hati & Ampela Ayam Bersih', species: 'chicken', category: 'Jeroan', base_unit: 'kg', minimum_stock: 15, is_active: true },
    { id: 'prod-bebek-karkas', sku: 'AGI-BEBEK-KARKAS', name: 'Bebek Karkas Super Fresh', species: 'duck', category: 'Karkas Bebek', base_unit: 'kg', minimum_stock: 40, is_active: true },
    { id: 'prod-bebek-ungkep', sku: 'AGI-BEBEK-UNGKEP', name: 'Bebek Ungkep Bumbu Kuning (Siap Goreng)', species: 'duck', category: 'Siap Masak', base_unit: 'pcs', minimum_stock: 25, is_active: true },
    { id: 'prod-ayam-hidup', sku: 'AGI-AYAM-RAW', name: 'Ayam Broiler Hidup (Bahan Masuk RPA)', species: 'chicken', category: 'Unggas Hidup', base_unit: 'kg', minimum_stock: 100, is_active: true },
    { id: 'prod-bebek-hidup', sku: 'AGI-BEBEK-RAW', name: 'Bebek Peking Hidup (Bahan Masuk RPA)', species: 'duck', category: 'Unggas Hidup', base_unit: 'kg', minimum_stock: 50, is_active: true },
  ];

  productUnits: ProductUnit[] = [
    { id: 'u-1', product_id: 'prod-ayam-karkas', unit_code: 'kg', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-2', product_id: 'prod-ayam-karkas', unit_code: 'ekor', base_units_per_unit: 1.3, is_sellable: true },
    { id: 'u-3', product_id: 'prod-fillet-dada', unit_code: 'kg', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-4', product_id: 'prod-paha-ayam', unit_code: 'kg', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-5', product_id: 'prod-sayap-ayam', unit_code: 'kg', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-6', product_id: 'prod-jeroan-ayam', unit_code: 'kg', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-7', product_id: 'prod-bebek-karkas', unit_code: 'kg', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-8', product_id: 'prod-bebek-karkas', unit_code: 'ekor', base_units_per_unit: 1.8, is_sellable: true },
    { id: 'u-9', product_id: 'prod-bebek-ungkep', unit_code: 'pcs', base_units_per_unit: 1, is_sellable: true },
    { id: 'u-10', product_id: 'prod-bebek-ungkep', unit_code: 'dus', base_units_per_unit: 10, is_sellable: true },
    { id: 'u-11', product_id: 'prod-ayam-hidup', unit_code: 'kg', base_units_per_unit: 1, is_sellable: false },
    { id: 'u-12', product_id: 'prod-ayam-hidup', unit_code: 'ekor', base_units_per_unit: 1.5, is_sellable: false },
    { id: 'u-13', product_id: 'prod-bebek-hidup', unit_code: 'kg', base_units_per_unit: 1, is_sellable: false },
  ];

  suppliers: Supplier[] = [
    { id: 'sup-1', code: 'PASOK-MAKMUR', name: 'PT Peternakan Unggas Makmur', phone: '0812-8899-1001', address: 'Kawasan Peternakan Unggas Sentul, Bogor', is_active: true },
    { id: 'sup-2', code: 'PASOK-BERKAH', name: 'CV Berkah Farm Mandiri', phone: '0813-7722-2002', address: 'Sentra Unggas Subang Selatan', is_active: true },
    { id: 'sup-3', code: 'PASOK-BREBES', name: 'Peternak Bebek Barokah Brebes', phone: '0819-3344-3003', address: 'Jl. Raya Randusanga Kulon, Brebes', is_active: true },
  ];

  customers: Customer[] = [
    { id: 'cust-1', code: 'PEL-KALEYO', name: 'Restoran Bebek Sambel Merah', phone: '0812-9900-1122', address: 'Jl. Margonda Raya No. 45, Depok', credit_limit: 20_000_000, is_active: true },
    { id: 'cust-2', code: 'PEL-GEPREK', name: 'Warung Makan Ayam Geprek Juara', phone: '0811-2233-4455', address: 'Jl. Tebet Timur Dalam No. 8, Jakarta Selatan', credit_limit: 15_000_000, is_active: true },
    { id: 'cust-3', code: 'PEL-SUPERINDO', name: 'Superindo Freshmart Cabang Barat', phone: '0815-6677-8899', address: 'Jl. Puri Indah Raya Blok A/3, Jakarta Barat', credit_limit: 35_000_000, is_active: true },
    { id: 'cust-4', code: 'PEL-KATERING', name: 'Katering Selera Nusantara', phone: '0818-4455-6677', address: 'Jl. Fatmawati No. 19, Jakarta Selatan', credit_limit: 10_000_000, is_active: true },
    { id: 'cust-5', code: 'PEL-ECERAN', name: 'Pelanggan Langsung (Walk-in)', phone: '—', address: 'Toko Kasir AGI', credit_limit: 0, is_active: true },
  ];

  // Employees & users
  employees: SettingsRow[] = [
    { id: 'emp-1', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, employee_code: 'EMP-001', full_name: 'Budi Santoso', position_title: 'Direktur Operasional & Pemilik', phone: '0812-1111-2222', email: 'owner@agi.id', notes: 'Founder & Penanggung Jawab Usaha', is_active: true },
    { id: 'emp-2', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, employee_code: 'EMP-002', full_name: 'Siti Rahmawati, S.E.', position_title: 'Manajer Keuangan & Akuntansi', phone: '0813-2222-3333', email: 'finance@agi.id', notes: 'Approval pembayaran & jurnal buku besar', is_active: true },
    { id: 'emp-3', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, employee_code: 'EMP-003', full_name: 'Hendra Pratama', position_title: 'Kepala Rumah Potong (RPA) & Mutu', phone: '0815-3333-4444', email: 'produksi@agi.id', notes: 'Pengawasan potong, susut, dan QC batch', is_active: true },
    { id: 'emp-4', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, employee_code: 'EMP-004', full_name: 'Joko Susilo', position_title: 'Supervisor Gudang & Cold Chain', phone: '0817-4444-5555', email: 'gudang@agi.id', notes: 'Penerimaan karkas, opname, dan transfer', is_active: true },
    { id: 'emp-5', company_id: DEMO_COMPANY_ID, branch_id: DEMO_BRANCH_PUSAT_ID, employee_code: 'EMP-005', full_name: 'Dewi Lestari', position_title: 'Kasir & Admin Penjualan', phone: '0819-5555-6666', email: 'kasir@agi.id', notes: 'Penerbitan invoice dan kasir POS', is_active: true },
  ];

  userDirectory: SettingsRow[] = [
    { user_id: DEMO_USER_ID, email: 'owner@agi.id', display_name: 'Budi Santoso (Owner)', roles: ['owner', 'super_admin', 'central_admin', 'branch_admin'], branch_ids: [DEMO_BRANCH_PUSAT_ID, DEMO_BRANCH_BARAT_ID] },
    { user_id: 'user-finance', email: 'finance@agi.id', display_name: 'Siti Rahmawati (Keuangan)', roles: ['finance'], branch_ids: [DEMO_BRANCH_PUSAT_ID] },
    { user_id: 'user-kasir', email: 'kasir@agi.id', display_name: 'Dewi Lestari (Kasir)', roles: ['cashier'], branch_ids: [DEMO_BRANCH_PUSAT_ID] },
    { user_id: 'user-produksi', email: 'produksi@agi.id', display_name: 'Hendra Pratama (Produksi)', roles: ['production', 'supervisor'], branch_ids: [DEMO_BRANCH_PUSAT_ID] },
    { user_id: 'user-gudang', email: 'gudang@agi.id', display_name: 'Joko Susilo (Gudang)', roles: ['warehouse'], branch_ids: [DEMO_BRANCH_PUSAT_ID] },
  ];

  // Inventory & batches
  inventory: InventoryRow[] = [
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-utama', product_id: 'prod-ayam-karkas', product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-KARKAS-01', quantity: 380, minimum_stock: 50, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', product_id: 'prod-fillet-dada', product_name: 'Fillet Dada Ayam Boneless', sku: 'AGI-DADA-FILLET', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-FILLET-01', quantity: 165, minimum_stock: 30, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', product_id: 'prod-paha-ayam', product_name: 'Paha Utuh Ayam Segar', sku: 'AGI-PAHA-UTUH', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-PAHA-01', quantity: 140, minimum_stock: 30, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-utama', product_id: 'prod-sayap-ayam', product_name: 'Sayap Ayam Broiler', sku: 'AGI-SAYAP-AYAM', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-SAYAP-01', quantity: 95, minimum_stock: 20, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', product_id: 'prod-jeroan-ayam', product_name: 'Hati & Ampela Ayam Bersih', sku: 'AGI-HATI-AMPELA', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-JEROAN-01', quantity: 42, minimum_stock: 15, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', product_id: 'prod-bebek-karkas', product_name: 'Bebek Karkas Super Fresh', sku: 'AGI-BEBEK-KARKAS', species: 'duck', base_unit: 'kg', batch_id: 'BATCH-BEBEK-01', quantity: 190, minimum_stock: 40, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', product_id: 'prod-bebek-ungkep', product_name: 'Bebek Ungkep Bumbu Kuning', sku: 'AGI-BEBEK-UNGKEP', species: 'duck', base_unit: 'pcs', batch_id: 'BATCH-UNGKEP-01', quantity: 85, minimum_stock: 25, quality_status: 'passed' },
    { branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-utama', product_id: 'prod-ayam-hidup', product_name: 'Ayam Broiler Hidup (Bahan Masuk RPA)', sku: 'AGI-AYAM-RAW', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-RAW-MASUK-02', quantity: 250, minimum_stock: 100, quality_status: 'pending' },
    { branch_id: DEMO_BRANCH_BARAT_ID, warehouse_id: 'wh-barat', product_id: 'prod-ayam-karkas', product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', species: 'chicken', base_unit: 'kg', batch_id: 'BATCH-BARAT-01', quantity: 60, minimum_stock: 20, quality_status: 'passed' },
  ];

  inventoryMovements: InventoryMovement[] = [
    { movement_id: 'mov-1', branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-utama', warehouse_name: 'Gudang Utama', product_id: 'prod-ayam-karkas', product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', batch_id: 'BATCH-KARKAS-01', batch_number: 'BATCH-KARKAS-01', movement_type: 'production_output', quantity_delta: 420, unit_code: 'kg', source_type: 'production', source_reference: 'PRD-2026-11-001', created_at: new Date(Date.now() - 3600000 * 24).toISOString() },
    { movement_id: 'mov-2', branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-utama', warehouse_name: 'Gudang Utama', product_id: 'prod-ayam-karkas', product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', batch_id: 'BATCH-KARKAS-01', batch_number: 'BATCH-KARKAS-01', movement_type: 'sale', quantity_delta: -40, unit_code: 'kg', source_type: 'sale', source_reference: 'INV/2026/11/001', created_at: new Date(Date.now() - 3600000 * 8).toISOString() },
    { movement_id: 'mov-3', branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', warehouse_name: 'Cold Storage Frozen', product_id: 'prod-fillet-dada', product_name: 'Fillet Dada Ayam', sku: 'AGI-DADA-FILLET', batch_id: 'BATCH-FILLET-01', batch_number: 'BATCH-FILLET-01', movement_type: 'production_output', quantity_delta: 180, unit_code: 'kg', source_type: 'production', source_reference: 'PRD-2026-11-001', created_at: new Date(Date.now() - 3600000 * 20).toISOString() },
    { movement_id: 'mov-4', branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', warehouse_name: 'Cold Storage Frozen', product_id: 'prod-fillet-dada', product_name: 'Fillet Dada Ayam', sku: 'AGI-DADA-FILLET', batch_id: 'BATCH-FILLET-01', batch_number: 'BATCH-FILLET-01', movement_type: 'sale', quantity_delta: -15, unit_code: 'kg', source_type: 'sale', source_reference: 'INV/2026/11/002', created_at: new Date(Date.now() - 3600000 * 5).toISOString() },
    { movement_id: 'mov-5', branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-cold', warehouse_name: 'Cold Storage Frozen', product_id: 'prod-bebek-karkas', product_name: 'Bebek Karkas Super Fresh', sku: 'AGI-BEBEK-KARKAS', batch_id: 'BATCH-BEBEK-01', batch_number: 'BATCH-BEBEK-01', movement_type: 'receipt', quantity_delta: 200, unit_code: 'kg', source_type: 'receipt', source_reference: 'RCV-2026-11-001', created_at: new Date(Date.now() - 3600000 * 30).toISOString() },
    { movement_id: 'mov-6', branch_id: DEMO_BRANCH_PUSAT_ID, warehouse_id: 'wh-utama', warehouse_name: 'Gudang Utama', product_id: 'prod-ayam-hidup', product_name: 'Ayam Broiler Hidup', sku: 'AGI-AYAM-RAW', batch_id: 'BATCH-RAW-MASUK-02', batch_number: 'BATCH-RAW-MASUK-02', movement_type: 'receipt', quantity_delta: 250, unit_code: 'kg', source_type: 'receipt', source_reference: 'RCV-2026-11-002', created_at: new Date(Date.now() - 3600000 * 2).toISOString() },
  ];

  // Sales
  sales: SaleListItem[] = [
    {
      id: 'sale-001',
      customer_id: 'cust-1',
      document_number: 'INV/2026/11/001',
      customer_name: 'Restoran Bebek Sambel Merah',
      total_amount: 5_850_000,
      paid_amount: 5_850_000,
      status: 'posted',
      created_at: new Date(Date.now() - 3600000 * 10).toISOString(),
    },
    {
      id: 'sale-002',
      customer_id: 'cust-2',
      document_number: 'INV/2026/11/002',
      customer_name: 'Warung Makan Ayam Geprek Juara',
      total_amount: 3_250_000,
      paid_amount: 1_500_000,
      status: 'posted',
      created_at: new Date(Date.now() - 3600000 * 6).toISOString(),
    },
    {
      id: 'sale-003',
      customer_id: 'cust-3',
      document_number: 'INV/2026/11/003',
      customer_name: 'Superindo Freshmart Cabang Barat',
      total_amount: 8_400_000,
      paid_amount: 0,
      status: 'posted',
      created_at: new Date(Date.now() - 3600000 * 3).toISOString(),
    },
    {
      id: 'sale-004',
      customer_id: 'cust-5',
      document_number: 'INV/2026/11/004',
      customer_name: 'Pelanggan Langsung (Walk-in)',
      total_amount: 950_000,
      paid_amount: 950_000,
      status: 'posted',
      created_at: new Date(Date.now() - 3600000 * 1).toISOString(),
    },
  ];

  saleDetails: Record<string, Invoice> = {
    'sale-001': {
      id: 'sale-001',
      document_number: 'INV/2026/11/001',
      created_at: new Date(Date.now() - 3600000 * 10).toISOString(),
      subtotal: 5_850_000,
      discount_amount: 0,
      shipping_amount: 0,
      total_amount: 5_850_000,
      paid_amount: 5_850_000,
      notes: 'Pengiriman cold box pagi hari - Bebek Karkas & Fillet',
      branch: { name: 'Cabang Utama (Pusat)', address: 'Kawasan Sentra Niaga Rantai Dingin Kav. 8, Jakarta', phone: '021-7890-1234' },
      customer: { id: 'cust-1', code: 'PEL-KALEYO', name: 'Restoran Bebek Sambel Merah', address: 'Jl. Margonda Raya No. 45, Depok', phone: '0812-9900-1122' },
      items: [
        { product_name: 'Bebek Karkas Super Fresh', sku: 'AGI-BEBEK-KARKAS', quantity: 90, unit_code: 'kg', unit_price: 45_000, line_total: 4_050_000 },
        { product_name: 'Fillet Dada Ayam Boneless', sku: 'AGI-DADA-FILLET', quantity: 30, unit_code: 'kg', unit_price: 60_000, line_total: 1_800_000 },
      ],
    },
    'sale-002': {
      id: 'sale-002',
      document_number: 'INV/2026/11/002',
      created_at: new Date(Date.now() - 3600000 * 6).toISOString(),
      subtotal: 3_250_000,
      discount_amount: 0,
      shipping_amount: 0,
      total_amount: 3_250_000,
      paid_amount: 1_500_000,
      notes: 'Tempo 7 hari - Paha & Sayap Ayam',
      branch: { name: 'Cabang Utama (Pusat)', address: 'Kawasan Sentra Niaga Rantai Dingin Kav. 8, Jakarta', phone: '021-7890-1234' },
      customer: { id: 'cust-2', code: 'PEL-GEPREK', name: 'Warung Makan Ayam Geprek Juara', address: 'Jl. Tebet Timur Dalam No. 8, Jakarta Selatan', phone: '0811-2233-4455' },
      items: [
        { product_name: 'Paha Utuh Ayam Segar', sku: 'AGI-PAHA-UTUH', quantity: 50, unit_code: 'kg', unit_price: 40_000, line_total: 2_000_000 },
        { product_name: 'Sayap Ayam Broiler', sku: 'AGI-SAYAP-AYAM', quantity: 35, unit_code: 'kg', unit_price: 35_000, line_total: 1_225_000 },
      ],
    },
    'sale-003': {
      id: 'sale-003',
      document_number: 'INV/2026/11/003',
      created_at: new Date(Date.now() - 3600000 * 3).toISOString(),
      subtotal: 8_400_000,
      discount_amount: 0,
      shipping_amount: 0,
      total_amount: 8_400_000,
      paid_amount: 0,
      notes: 'Tempo 14 hari - Pesanan Mingguan Supermarket',
      branch: { name: 'Cabang Utama (Pusat)', address: 'Kawasan Sentra Niaga Rantai Dingin Kav. 8, Jakarta', phone: '021-7890-1234' },
      customer: { id: 'cust-3', code: 'PEL-SUPERINDO', name: 'Superindo Freshmart Cabang Barat', address: 'Jl. Puri Indah Raya Blok A/3, Jakarta Barat', phone: '0815-6677-8899' },
      items: [
        { product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', quantity: 150, unit_code: 'kg', unit_price: 38_000, line_total: 5_700_000 },
        { product_name: 'Fillet Dada Ayam Boneless', sku: 'AGI-DADA-FILLET', quantity: 45, unit_code: 'kg', unit_price: 60_000, line_total: 2_700_000 },
      ],
    },
    'sale-004': {
      id: 'sale-004',
      document_number: 'INV/2026/11/004',
      created_at: new Date(Date.now() - 3600000 * 1).toISOString(),
      subtotal: 950_000,
      discount_amount: 0,
      shipping_amount: 0,
      total_amount: 950_000,
      paid_amount: 950_000,
      notes: 'Bayar tunai di kasir',
      branch: { name: 'Cabang Utama (Pusat)', address: 'Kawasan Sentra Niaga Rantai Dingin Kav. 8, Jakarta', phone: '021-7890-1234' },
      customer: { id: 'cust-5', code: 'PEL-ECERAN', name: 'Pelanggan Langsung (Walk-in)', address: 'Kasir Toko', phone: '—' },
      items: [
        { product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', quantity: 25, unit_code: 'kg', unit_price: 38_000, line_total: 950_000 },
      ],
    },
  };

  // Purchases
  purchases: Purchase[] = [
    {
      id: 'po-001',
      supplier_id: 'sup-1',
      supplier_name: 'PT Peternakan Unggas Makmur',
      document_number: 'PO-2026-11-001',
      status: 'approved',
      total_amount: 13_200_000,
      created_at: new Date(Date.now() - 3600000 * 18).toISOString(),
      items: [
        { id: 'poi-1', product_id: 'prod-ayam-hidup', product_name: 'Ayam Broiler Hidup (Bahan Masuk RPA)', sku: 'AGI-AYAM-RAW', quantity: 600, unit_code: 'kg', unit_price: 22_000, base_quantity: 600, received_base_quantity: 0 },
      ],
    },
    {
      id: 'po-002',
      supplier_id: 'sup-3',
      supplier_name: 'Peternak Bebek Barokah Brebes',
      document_number: 'PO-2026-11-002',
      status: 'draft',
      total_amount: 9_600_000,
      created_at: new Date(Date.now() - 3600000 * 4).toISOString(),
      items: [
        { id: 'poi-2', product_id: 'prod-bebek-hidup', product_name: 'Bebek Peking Hidup (Bahan Masuk RPA)', sku: 'AGI-BEBEK-RAW', quantity: 300, unit_code: 'kg', unit_price: 32_000, base_quantity: 300, received_base_quantity: 0 },
      ],
    },
    {
      id: 'po-003',
      supplier_id: 'sup-2',
      supplier_name: 'CV Berkah Farm Mandiri',
      document_number: 'PO-2026-11-003',
      status: 'partially_received',
      total_amount: 11_000_000,
      created_at: new Date(Date.now() - 3600000 * 48).toISOString(),
      items: [
        { id: 'poi-3', product_id: 'prod-ayam-hidup', product_name: 'Ayam Broiler Hidup (Bahan Masuk RPA)', sku: 'AGI-AYAM-RAW', quantity: 500, unit_code: 'kg', unit_price: 22_000, base_quantity: 500, received_base_quantity: 250 },
      ],
    },
  ];

  // Finance & Accounts
  cashAccounts = [
    { id: 'acc-kas-kasir', name: 'Kas Kecil Toko / Kasir', account_type: 'cash', balance: 4_850_000, is_active: true },
    { id: 'acc-bank-bca', name: 'BCA Operasional AGI (889-012-3344)', account_type: 'bank', balance: 85_400_000, is_active: true },
    { id: 'acc-bank-mandiri', name: 'Mandiri Giro Usaha (122-00-987654-1)', account_type: 'bank', balance: 42_100_000, is_active: true },
  ];

  financeAccounts: Row[] = [
    { id: 'fa-1100', code: '1100', name: 'Kas & Rekening Bank', account_type: 'asset', is_cash_flow: true },
    { id: 'fa-1200', code: '1200', name: 'Piutang Usaha Pelanggan', account_type: 'asset', is_cash_flow: false },
    { id: 'fa-1300', code: '1300', name: 'Persediaan Barang Dagang & Karkas', account_type: 'asset', is_cash_flow: false },
    { id: 'fa-2100', code: '2100', name: 'Utang Usaha Pemasok', account_type: 'liability', is_cash_flow: false },
    { id: 'fa-3100', code: '3100', name: 'Modal Disetor Pemilik', account_type: 'equity', is_cash_flow: false },
    { id: 'fa-4100', code: '4100', name: 'Pendapatan Penjualan Karkas & Olahan', account_type: 'revenue', is_cash_flow: true },
    { id: 'fa-5100', code: '5100', name: 'Harga Pokok Penjualan (HPP)', account_type: 'expense', is_cash_flow: false },
    { id: 'fa-6100', code: '6100', name: 'Beban Operasional & Distribusi', account_type: 'expense', is_cash_flow: false },
    { id: 'fa-6200', code: '6200', name: 'Beban Listrik Cold Storage & Es Balok', account_type: 'expense', is_cash_flow: false },
  ];

  periods: Row[] = [
    { id: 'period-2026', name: 'FY 2026', starts_on: '2026-01-01', ends_on: '2026-12-31', is_closed: false },
  ];

  // Scan & OCR records
  scans: ScanRecord[] = [
    {
      id: 'scan-001',
      storage_path: 'demo-scans/faktur_pembelian_ayam_makmur.jpg',
      mime_type: 'image/jpeg',
      status: 'needs_review',
      created_at: new Date(Date.now() - 3600000 * 2).toISOString(),
      extraction: {
        id: 'ext-001',
        confidence: 0.96,
        warnings: [],
        extracted_data: {
          document_type: 'invoice',
          document_number: 'FAK/MAKMUR/2026/892',
          document_date: '2026-11-19',
          supplier_name: 'PT Peternakan Unggas Makmur',
          subtotal: 13200000,
          tax_amount: 0,
          total_amount: 13200000,
          items: [
            { description: 'Ayam Broiler Hidup Grade A', quantity: 600, unit: 'kg', unit_price: 22000, line_total: 13200000 },
          ],
        },
      },
    },
  ];

  // Operations
  transfers: Row[] = [
    {
      id: 'trf-001',
      document_number: 'TRF/2026/11/001',
      source_branch_id: DEMO_BRANCH_PUSAT_ID,
      destination_branch_id: DEMO_BRANCH_BARAT_ID,
      source_warehouse_id: 'wh-utama',
      destination_warehouse_id: 'wh-barat',
      status: 'shipped',
      created_at: new Date(Date.now() - 3600000 * 7).toISOString(),
      stock_transfer_items: [
        { id: 'ti-1', product_id: 'prod-ayam-karkas', products: { name: 'Ayam Broiler Utuh / Karkas' }, shipped_quantity: 50, unit_code: 'kg' },
      ],
    },
  ];

  opnames: Row[] = [
    {
      id: 'opn-001',
      document_number: 'OPN/2026/11/001',
      warehouse_id: 'wh-utama',
      reason: 'Pemeriksaan fisik stok akhir pekan',
      status: 'submitted',
      created_at: new Date(Date.now() - 3600000 * 24).toISOString(),
    },
  ];

  returns: Row[] = [
    {
      id: 'ret-001',
      document_number: 'RET/2026/11/001',
      sale_id: 'sale-002',
      sales: { document_number: 'INV/2026/11/002' },
      reason: 'Kemasan rusak saat pengiriman (5 kg sayap dikarantina)',
      status: 'draft',
      created_at: new Date(Date.now() - 3600000 * 4).toISOString(),
    },
  ];

  deliveries: Row[] = [
    {
      id: 'del-001',
      document_number: 'SJ/2026/11/001',
      sale_id: 'sale-001',
      sales: { document_number: 'INV/2026/11/001', customers: { name: 'Restoran Bebek Sambel Merah' } },
      status: 'received',
      created_at: new Date(Date.now() - 3600000 * 9).toISOString(),
    },
    {
      id: 'del-002',
      document_number: 'SJ/2026/11/002',
      sale_id: 'sale-003',
      sales: { document_number: 'INV/2026/11/003', customers: { name: 'Superindo Freshmart Cabang Barat' } },
      status: 'prepared',
      created_at: new Date(Date.now() - 3600000 * 2).toISOString(),
    },
  ];

  notifications: Row[] = [
    { id: 'notif-1', title: 'Stok ayam karkas siap kirim', message: 'Stok karkas tersedia 380 kg di Gudang Utama siap memenuhi pesanan restoran.', read_at: null, created_at: new Date(Date.now() - 3600000 * 2).toISOString() },
    { id: 'notif-2', title: 'Batch ayam hidup menunggu inspeksi', message: 'Batch BATCH-RAW-MASUK-02 sebesar 250 kg memerlukan inspeksi kualitas QC.', read_at: null, created_at: new Date(Date.now() - 3600000 * 3).toISOString() },
    { id: 'notif-3', title: 'Jatuh tempo piutang', message: 'Tagihan INV/2026/11/002 Rp 1.750.000 mendekati jatuh tempo 7 hari.', read_at: null, created_at: new Date(Date.now() - 3600000 * 5).toISOString() },
  ];

  dueDates: Record<string, string> = {
    'sale-002': new Date(Date.now() + 3600000 * 24 * 7).toISOString().slice(0, 10),
    'sale-003': new Date(Date.now() + 3600000 * 24 * 14).toISOString().slice(0, 10),
    'po-003': new Date(Date.now() + 3600000 * 24 * 5).toISOString().slice(0, 10),
  };

  saleBranchIds: Record<string, string> = {
    'sale-001': DEMO_BRANCH_PUSAT_ID,
    'sale-002': DEMO_BRANCH_PUSAT_ID,
    'sale-003': DEMO_BRANCH_PUSAT_ID,
    'sale-004': DEMO_BRANCH_PUSAT_ID,
  };

  purchaseBranchIds: Record<string, string> = {
    'po-001': DEMO_BRANCH_PUSAT_ID,
    'po-002': DEMO_BRANCH_PUSAT_ID,
    'po-003': DEMO_BRANCH_PUSAT_ID,
  };

  purchasePaidTotals: Record<string, number> = {
    'po-003': 0,
  };

  auditLogs: SettingsRow[] = [
    { id: 'aud-1', entity_type: 'sales', action: 'POST_SALE', actor_id: 'Dewi Lestari (Kasir)', reason: 'Penerbitan invoice INV/2026/11/004', entity_id: 'sale-004', created_at: new Date(Date.now() - 3600000 * 1).toISOString() },
    { id: 'aud-2', entity_type: 'inventory', action: 'INSPECT_BATCH', actor_id: 'Hendra Pratama (RPA)', reason: 'Lolos uji mutu karkas BATCH-KARKAS-01', entity_id: 'batch-01', created_at: new Date(Date.now() - 3600000 * 22).toISOString() },
    { id: 'aud-3', entity_type: 'production', action: 'POST_PRODUCTION', actor_id: 'Hendra Pratama (RPA)', reason: 'Pemotongan 500 ekor ayam pedaging', entity_id: 'prd-001', created_at: new Date(Date.now() - 3600000 * 24).toISOString() },
  ];
}

// Global demo store singleton so all demo repositories share the exact same reactive data
export const demoStore = new DemoErpStore();
