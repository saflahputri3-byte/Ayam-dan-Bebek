import type { ErpRepository } from '../../application/ports/ErpRepository';
import type {
  BatchTraceability,
  BranchContext,
  Customer,
  InventoryCostRow,
  InventoryMovement,
  InventoryRow,
  Invoice,
  Product,
  ProductUnit,
  ProductionReportRow,
  Purchase,
  PurchaseCommand,
  PurchaseReportRow,
  ReceiptCommand,
  SaleCommand,
  SaleListItem,
  SalesReportRow,
  ScanRecord,
  Supplier,
  TransactionResult,
  Warehouse,
} from '../../domain/erp/ErpTypes';
import { demoStore, DEMO_BRANCH_PUSAT_ID } from './DemoErpStore';

export class DemoErpRepository implements ErpRepository {
  async getProducts(_companyId: string): Promise<Product[]> {
    return [...demoStore.products];
  }

  async getProductUnits(_companyId: string): Promise<ProductUnit[]> {
    return [...demoStore.productUnits];
  }

  async getCustomers(_companyId: string): Promise<Customer[]> {
    return [...demoStore.customers];
  }

  async getSuppliers(_companyId: string): Promise<Supplier[]> {
    return [...demoStore.suppliers];
  }

  async getWarehouses(branchId: string): Promise<Warehouse[]> {
    return demoStore.warehouses
      .filter((w) => !branchId || w.branch_id === branchId)
      .map((w) => ({
        id: String(w.id),
        company_id: String(w.company_id),
        branch_id: String(w.branch_id),
        code: String(w.code),
        name: String(w.name),
        is_active: Boolean(w.is_active),
      }));
  }

  async getCashAccounts(_branchId: string): Promise<Array<{ id: string; name: string; account_type: string }>> {
    return demoStore.cashAccounts.map((a) => ({ id: a.id, name: a.name, account_type: a.account_type }));
  }

  async getInventory(context: BranchContext): Promise<InventoryRow[]> {
    return demoStore.inventory.filter((row) => row.branch_id === context.branchId);
  }

  async getInventoryReport(context: BranchContext): Promise<InventoryRow[]> {
    return this.getInventory(context);
  }

  async getInventoryMovements(context: BranchContext): Promise<InventoryMovement[]> {
    return demoStore.inventoryMovements.filter((m) => m.branch_id === context.branchId);
  }

  async getBatchTraceability(batchId: string): Promise<BatchTraceability> {
    const inv = demoStore.inventory.find((r) => r.batch_id === batchId);
    return {
      batch: {
        id: batchId,
        product_name: inv?.product_name ?? 'Ayam Broiler Utuh / Karkas',
        sku: inv?.sku ?? 'AGI-AYAM-KARKAS',
        batch_number: batchId,
        quality_status: inv?.quality_status ?? 'passed',
        source_type: 'production',
        created_at: new Date(Date.now() - 3600000 * 24).toISOString(),
        produced_at: new Date(Date.now() - 3600000 * 24).toISOString(),
        expires_at: new Date(Date.now() + 3600000 * 72).toISOString(),
        product_id: inv?.product_id ?? 'prod-ayam-karkas',
        base_unit: inv?.base_unit ?? 'kg',
        branch_id: DEMO_BRANCH_PUSAT_ID,
        branch_name: 'Cabang Utama (Pusat)',
      },
      events: [
        {
          event_type: 'receipt',
          happened_at: new Date(Date.now() - 3600000 * 24).toISOString(),
          description: 'Penerimaan unggas hidup dari peternak Makmur',
          reference: 'RCV-2026-11-001',
          party_name: 'PT Peternakan Unggas Makmur',
          quantity: 500,
          unit_code: 'kg',
          related_reference: null,
          related_batch_id: null,
          related_batch_number: null,
        },
        {
          event_type: 'production_input',
          happened_at: new Date(Date.now() - 3600000 * 20).toISOString(),
          description: 'Input pemotongan RPA Batch 01',
          reference: 'PRD-2026-11-001',
          quantity: 500,
          unit_code: 'kg',
          party_name: null,
          related_reference: null,
          related_batch_id: null,
          related_batch_number: null,
        },
        {
          event_type: 'production_output',
          happened_at: new Date(Date.now() - 3600000 * 18).toISOString(),
          description: 'Hasil potong karkas bersih & grading',
          reference: 'PRD-2026-11-001',
          quantity: 380,
          unit_code: 'kg',
          party_name: null,
          related_reference: null,
          related_batch_id: null,
          related_batch_number: null,
        },
        {
          event_type: 'inspection',
          happened_at: new Date(Date.now() - 3600000 * 17).toISOString(),
          description: 'Inspeksi mutu dan sanitasi lulus (Grade A)',
          notes: 'Suhu karkas 3°C, bebas residu, siap masuk cold storage',
          reference: null,
          related_reference: null,
          party_name: null,
          quantity: null,
          unit_code: null,
          related_batch_id: null,
          related_batch_number: null,
        },
        {
          event_type: 'sale',
          happened_at: new Date(Date.now() - 3600000 * 8).toISOString(),
          description: 'Penjualan ke Restoran Bebek Sambel Merah',
          reference: 'INV/2026/11/001',
          party_name: 'Restoran Bebek Sambel Merah',
          quantity: 40,
          unit_code: 'kg',
          related_reference: null,
          related_batch_id: null,
          related_batch_number: null,
        },
      ],
    };
  }

  async getSales(context: BranchContext): Promise<SaleListItem[]> {
    return demoStore.sales.filter((s) => (demoStore.saleBranchIds[s.id] ?? DEMO_BRANCH_PUSAT_ID) === context.branchId);
  }

  async postSale(command: SaleCommand, _idempotencyKey: string): Promise<TransactionResult> {
    const saleId = `sale-${Date.now()}`;
    const docNumber = `INV/2026/11/${String(demoStore.sales.length + 1).padStart(3, '0')}`;
    const cust = demoStore.customers.find((c) => c.id === command.customer_id);
    const subtotal = command.items.reduce((s, it) => s + it.quantity * it.unit_price, 0);
    const total = Math.max(0, subtotal - (command.discount_amount || 0) + (command.shipping_amount || 0));

    // Deduct inventory
    for (const item of command.items) {
      const invRow = demoStore.inventory.find(
        (r) => r.warehouse_id === command.warehouse_id && r.product_id === item.product_id && r.batch_id === item.batch_id
      );
      if (invRow) {
        invRow.quantity = Math.max(0, invRow.quantity - item.quantity);
      }
      const prod = demoStore.products.find((p) => p.id === item.product_id);
      demoStore.inventoryMovements.unshift({
        movement_id: `mov-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        branch_id: command.branchId,
        warehouse_id: command.warehouse_id,
        warehouse_name: demoStore.warehouses.find((w) => w.id === command.warehouse_id)?.name as string ?? 'Gudang Utama',
        product_id: item.product_id,
        product_name: prod?.name ?? 'Produk',
        sku: prod?.sku ?? '',
        batch_id: item.batch_id,
        batch_number: item.batch_id,
        movement_type: 'sale',
        quantity_delta: -item.quantity,
        unit_code: item.unit_code,
        source_type: 'sale',
        source_reference: docNumber,
        created_at: new Date().toISOString(),
      });
    }

    const newSaleItem: SaleListItem = {
      id: saleId,
      customer_id: command.customer_id,
      document_number: docNumber,
      customer_name: cust?.name ?? 'Pelanggan umum',
      total_amount: total,
      paid_amount: 0,
      status: 'posted',
      created_at: new Date().toISOString(),
    };
    demoStore.saleBranchIds[saleId] = command.branchId;
    demoStore.sales.unshift(newSaleItem);

    const branchInfo = demoStore.branches.find((b) => b.id === command.branchId);
    demoStore.saleDetails[saleId] = {
      id: saleId,
      document_number: docNumber,
      created_at: new Date().toISOString(),
      subtotal,
      discount_amount: command.discount_amount || 0,
      shipping_amount: command.shipping_amount || 0,
      total_amount: total,
      paid_amount: 0,
      notes: command.notes ?? '',
      branch: { name: String(branchInfo?.name ?? 'Cabang Utama (Pusat)'), address: String(branchInfo?.address ?? ''), phone: String(branchInfo?.phone ?? '') },
      customer: cust ? { id: cust.id, code: cust.code, name: cust.name, address: cust.address ?? null, phone: cust.phone ?? null } : null,
      items: command.items.map((it) => {
        const prod = demoStore.products.find((p) => p.id === it.product_id);
        return {
          product_name: prod?.name ?? 'Produk',
          sku: prod?.sku ?? '',
          quantity: it.quantity,
          unit_code: it.unit_code,
          unit_price: it.unit_price,
          line_total: it.quantity * it.unit_price,
        };
      }),
    };

    demoStore.auditLogs.unshift({
      id: `aud-${Date.now()}`,
      entity_type: 'sales',
      action: 'POST_SALE',
      actor_id: 'Dewi Lestari (Kasir)',
      reason: `Penerbitan ${docNumber}`,
      entity_id: saleId,
      created_at: new Date().toISOString(),
    });

    return {
      status: 'posted',
      document_number: docNumber,
      sale_id: saleId,
      total_amount: total,
    };
  }

  async getPurchases(context: BranchContext): Promise<Purchase[]> {
    return demoStore.purchases.filter((p) => (demoStore.purchaseBranchIds[p.id] ?? DEMO_BRANCH_PUSAT_ID) === context.branchId);
  }

  async createPurchase(command: PurchaseCommand, _idempotencyKey: string): Promise<TransactionResult> {
    const pId = `po-${Date.now()}`;
    const docNumber = `PO-2026-11-${String(demoStore.purchases.length + 1).padStart(3, '0')}`;
    const supp = demoStore.suppliers.find((s) => s.id === command.supplier_id);
    const total = command.items.reduce((s, it) => s + it.quantity * it.unit_price, 0);

    demoStore.purchaseBranchIds[pId] = command.branchId;
    demoStore.purchases.unshift({
      id: pId,
      supplier_id: command.supplier_id,
      supplier_name: supp?.name ?? 'Pemasok',
      document_number: docNumber,
      status: 'draft',
      total_amount: total,
      created_at: new Date().toISOString(),
      items: command.items.map((it, idx) => {
        const prod = demoStore.products.find((p) => p.id === it.product_id);
        const unit = demoStore.productUnits.find((u) => u.product_id === it.product_id && u.unit_code === it.unit_code);
        const ratio = unit?.base_units_per_unit ?? 1;
        return {
          id: `poi-${Date.now()}-${idx}`,
          product_id: it.product_id,
          product_name: prod?.name ?? 'Produk',
          sku: prod?.sku ?? '',
          quantity: it.quantity,
          unit_code: it.unit_code,
          unit_price: it.unit_price,
          base_quantity: it.quantity * ratio,
          received_base_quantity: 0,
        };
      }),
    });

    return { status: 'draft', document_number: docNumber, purchase_id: pId, total_amount: total };
  }

  async approvePurchase(purchaseId: string): Promise<void> {
    const po = demoStore.purchases.find((p) => p.id === purchaseId);
    if (po) po.status = 'approved';
  }

  async receivePurchase(command: ReceiptCommand, _idempotencyKey: string): Promise<TransactionResult> {
    const docNumber = `RCV-2026-11-${String(Date.now()).slice(-3)}`;
    const po = demoStore.purchases.find((p) => p.id === command.purchase_id);

    for (const item of command.items) {
      const prod = demoStore.products.find((p) => p.id === item.product_id);
      const unit = demoStore.productUnits.find((u) => u.product_id === item.product_id && u.unit_code === item.unit_code);
      const ratio = unit?.base_units_per_unit ?? 1;
      const receivedBase = item.quantity * ratio;

      if (po) {
        const poItem = po.items.find((entry) => entry.id === item.purchase_item_id || entry.product_id === item.product_id);
        if (poItem) {
          poItem.received_base_quantity = Math.min(poItem.base_quantity, poItem.received_base_quantity + receivedBase);
        }
      }

      const batchId = `BATCH-RCV-${String(Date.now()).slice(-4)}-${Math.random().toString(36).slice(2, 5).toUpperCase()}`;
      demoStore.inventory.unshift({
        branch_id: command.branchId,
        warehouse_id: command.warehouse_id,
        product_id: item.product_id,
        product_name: prod?.name ?? 'Produk Masuk',
        sku: prod?.sku ?? '',
        species: prod?.species ?? 'chicken',
        base_unit: prod?.base_unit ?? item.unit_code,
        batch_id: batchId,
        quantity: receivedBase,
        minimum_stock: prod?.minimum_stock ?? 10,
        quality_status: 'pending',
      });
      demoStore.inventoryMovements.unshift({
        movement_id: `mov-${Date.now()}-${Math.random().toString(36).slice(2, 5)}`,
        branch_id: command.branchId,
        warehouse_id: command.warehouse_id,
        warehouse_name: demoStore.warehouses.find((w) => w.id === command.warehouse_id)?.name as string ?? 'Gudang Utama',
        product_id: item.product_id,
        product_name: prod?.name ?? 'Produk Masuk',
        sku: prod?.sku ?? '',
        batch_id: batchId,
        batch_number: batchId,
        movement_type: 'receipt',
        quantity_delta: receivedBase,
        unit_code: prod?.base_unit ?? item.unit_code,
        source_type: 'receipt',
        source_reference: docNumber,
        created_at: new Date().toISOString(),
      });
    }

    if (po) {
      const allReceived = po.items.every((entry) => entry.received_base_quantity >= entry.base_quantity - 0.0001);
      po.status = allReceived ? 'received' : 'partially_received';
    }

    return { status: 'received', document_number: docNumber };
  }

  async postProduction(payload: Record<string, unknown>, _idempotencyKey: string): Promise<TransactionResult> {
    const batchNumber = `PRD-BATCH-${String(Date.now()).slice(-4)}`;
    const warehouseId = String(payload.warehouse_id ?? 'wh-utama');
    const inputs = (payload.inputs as Array<{ product_id: string; batch_id: string; quantity: number; unit_code: string }>) ?? [];
    const outputs = (payload.outputs as Array<{ product_id: string; quantity: number; unit_code: string }>) ?? [];

    for (const input of inputs) {
      const row = demoStore.inventory.find((r) => r.warehouse_id === warehouseId && r.batch_id === input.batch_id);
      if (row) row.quantity = Math.max(0, row.quantity - input.quantity);
    }

    for (const output of outputs) {
      const prod = demoStore.products.find((p) => p.id === output.product_id);
      const outBatchId = `BATCH-OUT-${String(Date.now()).slice(-4)}`;
      demoStore.inventory.unshift({
        branch_id: String(payload.branch_id ?? DEMO_BRANCH_PUSAT_ID),
        warehouse_id: warehouseId,
        product_id: output.product_id,
        product_name: prod?.name ?? 'Hasil Olahan',
        sku: prod?.sku ?? '',
        species: prod?.species ?? 'chicken',
        base_unit: output.unit_code,
        batch_id: outBatchId,
        quantity: output.quantity,
        minimum_stock: 15,
        quality_status: 'pending',
      });
    }

    return { status: 'completed', document_number: batchNumber, production_batch_id: batchNumber };
  }

  async inspectBatch(batchId: string, result: 'passed' | 'rejected' | 'quarantined', _notes: string): Promise<void> {
    const row = demoStore.inventory.find((r) => r.batch_id === batchId);
    if (row) row.quality_status = result;
  }

  async getInvoice(saleId: string): Promise<Invoice> {
    const found = demoStore.saleDetails[saleId];
    if (!found) throw new Error('Invoice tidak ditemukan.');
    return { ...found };
  }

  async recordPrint(_sourceType: string, _sourceId: string): Promise<void> {
    // Demo print recording succeeds
  }

  async recordPayment(payload: Record<string, unknown>, _idempotencyKey: string): Promise<TransactionResult> {
    const receiptNum = `PAY-2026-11-${String(Date.now()).slice(-3)}`;
    const amount = Number(payload.amount ?? 0);
    const allocations = (payload.allocations as Array<{ sale_id: string; amount: number }>) ?? [];

    for (const alloc of allocations) {
      const sale = demoStore.sales.find((s) => s.id === alloc.sale_id);
      if (sale) {
        sale.paid_amount += alloc.amount;
      }
      const detail = demoStore.saleDetails[alloc.sale_id];
      if (detail) {
        detail.paid_amount += alloc.amount;
      }
    }

    const cashAcc = demoStore.cashAccounts.find((a) => a.id === payload.cash_account_id);
    if (cashAcc) {
      cashAcc.balance += amount;
    }

    return { status: 'paid', document_number: receiptNum, amount };
  }

  async listScans(_context: BranchContext): Promise<ScanRecord[]> {
    return [...demoStore.scans];
  }

  async getScanPreviewUrl(_storagePath: string): Promise<string> {
    // Return sample invoice svg preview
    return 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300"><rect width="400" height="300" fill="%23f8fafc"/><text x="30" y="50" font-family="sans-serif" font-weight="bold" font-size="18" fill="%230f172a">FAKTUR PEMBELIAN AYAM</text><text x="30" y="80" font-family="sans-serif" font-size="14" fill="%23475569">Pemasok: PT Peternakan Unggas Makmur</text><text x="30" y="110" font-family="sans-serif" font-size="14" fill="%23475569">Item: Ayam Broiler Hidup Grade A - 600 kg</text><text x="30" y="140" font-family="sans-serif" font-size="14" fill="%23475569">Harga: Rp 22.000 / kg</text><text x="30" y="180" font-family="sans-serif" font-weight="bold" font-size="16" fill="%2316a34a">TOTAL: Rp 13.200.000</text></svg>';
  }

  async uploadScan(file: File, _context: BranchContext): Promise<ScanRecord> {
    const scanId = `scan-${Date.now()}`;
    const newScan: ScanRecord = {
      id: scanId,
      storage_path: `scans/${file.name}`,
      mime_type: file.type || 'image/jpeg',
      status: 'uploaded',
      created_at: new Date().toISOString(),
      extraction: null,
    };
    demoStore.scans.unshift(newScan);
    return newScan;
  }

  async runOcr(scanId: string): Promise<void> {
    const scan = demoStore.scans.find((s) => s.id === scanId);
    if (scan) {
      scan.status = 'needs_review';
      scan.extraction = {
        id: `ext-${Date.now()}`,
        confidence: 0.94,
        warnings: [],
        extracted_data: {
          document_type: 'invoice',
          document_number: `FAK/DEMO/${String(Date.now()).slice(-4)}`,
          document_date: new Date().toISOString().slice(0, 10),
          supplier_name: 'PT Peternakan Unggas Makmur',
          subtotal: 13200000,
          tax_amount: 0,
          total_amount: 13200000,
          items: [{ description: 'Ayam Broiler Hidup Grade A', quantity: 600, unit: 'kg', unit_price: 22000, line_total: 13200000 }],
        },
      };
    }
  }

  async confirmOcr(scanId: string, _data: Record<string, unknown>, duplicate: boolean): Promise<void> {
    const scan = demoStore.scans.find((s) => s.id === scanId);
    if (scan) {
      scan.status = duplicate ? 'duplicate_candidate' : 'confirmed';
      scan.reviewed_at = new Date().toISOString();
    }
  }

  async getSalesReport(_companyId: string, _branchId: string, _from: string, _to: string): Promise<SalesReportRow[]> {
    return [
      { day: new Date().toISOString().slice(0, 10), branch_id: DEMO_BRANCH_PUSAT_ID, sales_count: demoStore.sales.length, unpaid_count: demoStore.sales.filter((s) => s.paid_amount < s.total_amount).length, gross_sales: demoStore.sales.reduce((sum, s) => sum + s.total_amount, 0), paid_total: demoStore.sales.reduce((sum, s) => sum + s.paid_amount, 0), receivable_total: demoStore.sales.reduce((sum, s) => sum + Math.max(0, s.total_amount - s.paid_amount), 0) },
    ];
  }

  async getPurchaseReport(_companyId: string, _branchId: string, _from: string, _to: string): Promise<PurchaseReportRow[]> {
    return [
      { day: new Date().toISOString().slice(0, 10), supplier_id: 'sup-1', supplier_name: 'PT Peternakan Unggas Makmur', purchase_count: 2, ordered_total: 24_200_000, draft_count: 0, approved_count: 1, partial_count: 1, received_count: 0, voided_count: 0 },
      { day: new Date().toISOString().slice(0, 10), supplier_id: 'sup-3', supplier_name: 'Peternak Bebek Barokah Brebes', purchase_count: 1, ordered_total: 9_600_000, draft_count: 1, approved_count: 0, partial_count: 0, received_count: 0, voided_count: 0 },
    ];
  }

  async getProductionReport(_companyId: string, _branchId: string, _from: string, _to: string): Promise<ProductionReportRow[]> {
    return [
      {
        production_batch_id: 'prd-001',
        branch_id: DEMO_BRANCH_PUSAT_ID,
        batch_number: 'BATCH-RPA-2026-11-01',
        produced_at: new Date(Date.now() - 3600000 * 24).toISOString(),
        notes: 'Pemotongan 500 ekor ayam broiler hidup - RPA Utama',
        inputs: [{ product_name: 'Ayam Broiler Hidup', sku: 'AGI-AYAM-RAW', batch_number: 'RAW-001', quantity: 650, unit_code: 'kg' }],
        outputs: [
          { product_name: 'Ayam Broiler Utuh / Karkas', sku: 'AGI-AYAM-KARKAS', batch_number: 'BATCH-KARKAS-01', quantity: 380, unit_code: 'kg' },
          { product_name: 'Fillet Dada Boneless', sku: 'AGI-DADA-FILLET', batch_number: 'BATCH-FILLET-01', quantity: 80, unit_code: 'kg' },
          { product_name: 'Paha Utuh Segar', sku: 'AGI-PAHA-UTUH', batch_number: 'BATCH-PAHA-01', quantity: 70, unit_code: 'kg' },
        ],
        waste: [{ quantity: 120, unit_code: 'kg', reason: 'Susut bulu, darah, dan kotoran ayam' }],
      },
    ];
  }

  async getInventoryCostReport(_companyId: string): Promise<InventoryCostRow[]> {
    return [
      { product_id: 'prod-ayam-karkas', sku: 'AGI-AYAM-KARKAS', product_name: 'Ayam Broiler Utuh / Karkas', base_unit: 'kg', quantity: 380, average_unit_cost: 29500, inventory_value: 380 * 29500 },
      { product_id: 'prod-fillet-dada', sku: 'AGI-DADA-FILLET', product_name: 'Fillet Dada Ayam Boneless', base_unit: 'kg', quantity: 165, average_unit_cost: 44000, inventory_value: 165 * 44000 },
      { product_id: 'prod-paha-ayam', sku: 'AGI-PAHA-UTUH', product_name: 'Paha Utuh Ayam Segar', base_unit: 'kg', quantity: 140, average_unit_cost: 31000, inventory_value: 140 * 31000 },
      { product_id: 'prod-sayap-ayam', sku: 'AGI-SAYAP-AYAM', product_name: 'Sayap Ayam Broiler', base_unit: 'kg', quantity: 95, average_unit_cost: 26000, inventory_value: 95 * 26000 },
      { product_id: 'prod-bebek-karkas', sku: 'AGI-BEBEK-KARKAS', product_name: 'Bebek Karkas Super Fresh', base_unit: 'kg', quantity: 190, average_unit_cost: 36000, inventory_value: 190 * 36000 },
    ];
  }
}
