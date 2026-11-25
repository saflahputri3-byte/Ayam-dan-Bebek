import type { SupabaseClient } from '@supabase/supabase-js';
import type { BatchTraceability, BranchContext, Customer, InventoryCostRow, InventoryMovement, InventoryRow, Invoice, Product, ProductUnit, ProductionReportRow, Purchase, PurchaseCommand, PurchaseReportRow, ReceiptCommand, SaleCommand, SaleListItem, SalesReportRow, ScanRecord, Supplier, TransactionResult, Warehouse } from '../../domain/erp/ErpTypes';
import type { ErpRepository } from '../../application/ports/ErpRepository';

const bucket = 'business-documents';
const asRows = <T,>(data: unknown): T[] => (data ?? []) as T[];

export class SupabaseErpRepository implements ErpRepository {
  constructor(private readonly client: SupabaseClient) {}

  async getProducts(companyId: string) {
    const { data, error } = await this.client.from('products').select('id,sku,name,species,category,base_unit,minimum_stock,is_active').eq('company_id', companyId).eq('is_active', true).order('name');
    if (error) throw error; return asRows<Product>(data);
  }
  async getProductUnits(companyId: string) {
    const { data, error } = await this.client.from('product_units').select('id,product_id,unit_code,base_units_per_unit,is_sellable').eq('company_id', companyId).order('unit_code');
    if (error) throw error; return asRows<ProductUnit>(data);
  }
  async getCustomers(companyId: string) {
    const { data, error } = await this.client.from('customers').select('id,code,name,phone,address').eq('company_id', companyId).eq('is_active', true).order('name').limit(200);
    if (error) throw error; return asRows<Customer>(data);
  }
  async getSuppliers(companyId: string) {
    const { data, error } = await this.client.from('suppliers').select('id,code,name').eq('company_id', companyId).eq('is_active', true).order('name').limit(200);
    if (error) throw error; return asRows<Supplier>(data);
  }
  async getWarehouses(branchId: string) {
    const { data, error } = await this.client.from('warehouses').select('id,branch_id,code,name').eq('branch_id', branchId).eq('is_active', true).order('name');
    if (error) throw error; return asRows<Warehouse>(data);
  }
  async getCashAccounts(branchId: string) {
    const { data, error } = await this.client.from('cash_accounts').select('id,name,account_type').eq('branch_id', branchId).eq('is_active', true).order('name');
    if (error) throw error; return asRows<{id:string;name:string;account_type:string}>(data);
  }
  async getInventory(context: BranchContext) {
    const { data, error } = await this.client.rpc('get_inventory_report', { p_company_id: context.companyId, p_branch_id: context.branchId, p_warehouse_id: null });
    if (error) throw error; return asRows<InventoryRow>(data);
  }
  async getInventoryMovements(context: BranchContext) {
    const { data, error } = await this.client.rpc('get_inventory_movement_report', { p_company_id: context.companyId, p_branch_id: context.branchId, p_warehouse_id: null, p_product_id: null, p_limit: 100 });
    if (error) throw error; return asRows<InventoryMovement>(data);
  }
  async getBatchTraceability(batchId: string) {
    const { data, error } = await this.client.rpc('get_batch_traceability_extended', { p_batch_id: batchId });
    if (error) throw error; if (!data) throw new Error('Batch tidak ditemukan atau tidak dapat diakses.'); return data as BatchTraceability;
  }
  async getSales(context: BranchContext) {
    const { data, error } = await this.client.from('sales').select('id,document_number,customer_id,created_at,status,total_amount,paid_amount,customers(name)').eq('company_id', context.companyId).eq('branch_id', context.branchId).order('created_at', { ascending: false }).limit(100);
    if (error) throw error;
    return asRows<Record<string, unknown>>(data).map((row) => ({ ...row, customer_name: (row.customers as { name?: string } | null)?.name ?? 'Pelanggan umum' } as SaleListItem));
  }
  async postSale(command: SaleCommand, key: string) {
    const { data, error } = await this.client.rpc('post_sale', { p_payload: { company_id: command.companyId, branch_id: command.branchId, warehouse_id: command.warehouse_id, customer_id: command.customer_id, discount_amount: command.discount_amount, shipping_amount: command.shipping_amount, notes: command.notes, items: command.items }, p_idempotency_key: key });
    if (error) throw error; return data as TransactionResult;
  }
  async getPurchases(context: BranchContext) {
    const { data, error } = await this.client.from('purchases').select('id,document_number,supplier_id,status,total_amount,created_at,suppliers(name),purchase_items(id,product_id,quantity,unit_code,base_quantity,unit_price,products(name,sku),goods_receipt_items(base_quantity,goods_receipts(status)))').eq('company_id', context.companyId).eq('branch_id', context.branchId).order('created_at', { ascending: false }).limit(100);
    if (error) throw error;
    return asRows<Record<string, unknown>>(data).map((row) => ({
      ...row,
      supplier_name: (row.suppliers as { name?: string } | null)?.name ?? 'Pemasok',
      items: ((row.purchase_items ?? []) as Array<Record<string, unknown>>).map((item) => ({ ...item, received_base_quantity: ((item.goods_receipt_items ?? []) as Array<Record<string, unknown>>).filter((receipt) => ((receipt.goods_receipts as { status?: string } | null)?.status === 'posted')).reduce((sum, receipt) => sum + Number(receipt.base_quantity), 0), product_name: (item.products as { name?: string } | null)?.name ?? 'Produk', sku: (item.products as { sku?: string } | null)?.sku ?? '' })),
    } as Purchase));
  }
  async createPurchase(command: PurchaseCommand, key: string) {
    const { data, error } = await this.client.rpc('create_purchase_draft', { p_payload: { company_id: command.companyId, branch_id: command.branchId, supplier_id: command.supplier_id, notes: command.notes, items: command.items }, p_idempotency_key: key });
    if (error) throw error; return data as TransactionResult;
  }
  async approvePurchase(purchaseId: string) {
    const { error } = await this.client.rpc('approve_purchase', { p_purchase_id: purchaseId }); if (error) throw error;
  }
  async receivePurchase(command: ReceiptCommand, key: string) {
    const { data, error } = await this.client.rpc('post_goods_receipt', { p_payload: { company_id: command.companyId, branch_id: command.branchId, warehouse_id: command.warehouse_id, purchase_id: command.purchase_id, items: command.items }, p_idempotency_key: key });
    if (error) throw error; return data as TransactionResult;
  }
  async postProduction(payload: Record<string, unknown>, key: string) {
    const { data, error } = await this.client.rpc('post_production_batch', { p_payload: payload, p_idempotency_key: key }); if (error) throw error; return data as TransactionResult;
  }
  async inspectBatch(batchId: string, result: 'passed' | 'rejected' | 'quarantined', notes: string) {
    const { error } = await this.client.rpc('inspect_product_batch', { p_batch_id: batchId, p_result: result, p_notes: notes }); if (error) throw error;
  }
  async getInvoice(saleId: string) {
    const { data: sale, error: saleError } = await this.client.from('sales').select('id,document_number,created_at,subtotal,discount_amount,shipping_amount,total_amount,paid_amount,notes,customers(id,code,name,phone,address),branches(name,address,phone)').eq('id', saleId).single();
    if (saleError) throw saleError;
    const { data: items, error: itemsError } = await this.client.from('sales_items').select('quantity,unit_code,unit_price,line_total,products(name,sku)').eq('sale_id', saleId);
    if (itemsError) throw itemsError;
    const customer = sale.customers as unknown as Customer | null;
    const branch = sale.branches as unknown as Invoice['branch'];
    return { ...sale, customer, branch, items: asRows<Record<string, unknown>>(items).map((item) => ({ product_name: (item.products as { name?: string } | null)?.name ?? 'Produk', sku: (item.products as { sku?: string } | null)?.sku ?? '', quantity: Number(item.quantity), unit_code: String(item.unit_code), unit_price: Number(item.unit_price), line_total: Number(item.line_total) })) } as Invoice;
  }
  async recordPrint(sourceType: string, sourceId: string) {
    const { error } = await this.client.rpc('record_document_print', { p_source_type: sourceType, p_source_id: sourceId }); if (error) throw error;
  }
  async recordPayment(payload: Record<string, unknown>, key: string) {
    const { data, error } = await this.client.rpc('record_customer_payment_v2', { p_payload: payload, p_idempotency_key: key }); if (error) throw error; return data as TransactionResult;
  }
  async listScans(context: BranchContext) {
    const { data, error } = await this.client.from('scanned_documents').select('id,storage_path,mime_type,status,created_at,reviewed_at,source_hash,ocr_extractions!ocr_extractions_scanned_document_id_fkey(id,extracted_data,confidence,warnings)').eq('company_id', context.companyId).eq('branch_id', context.branchId).order('created_at', { ascending: false }).limit(50);
    if (error) throw error;
    return asRows<Record<string, unknown>>(data).map((row) => ({ ...row, extraction: Array.isArray(row.ocr_extractions) ? (row.ocr_extractions[0] ?? null) : null } as ScanRecord));
  }
  async getScanPreviewUrl(storagePath: string) {
    const { data, error } = await this.client.storage.from(bucket).createSignedUrl(storagePath, 300); if (error) throw error; return data.signedUrl;
  }
  async uploadScan(file: File, context: BranchContext) {
    if (file.size > 12 * 1024 * 1024) throw new Error('Ukuran file maksimum 12 MB.');
    const hashBuffer = await crypto.subtle.digest('SHA-256', await file.arrayBuffer());
    const hash = [...new Uint8Array(hashBuffer)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
    const safeName = file.name.toLowerCase().replace(/[^a-z0-9._-]/g, '-').slice(-80) || 'nota';
    const path = `${context.companyId}/${context.branchId}/${context.userId}/${crypto.randomUUID()}-${safeName}`;
    const { error: uploadError } = await this.client.storage.from(bucket).upload(path, file, { contentType: file.type, upsert: false });
    if (uploadError) throw uploadError;
    const { data, error } = await this.client.from('scanned_documents').insert({ company_id: context.companyId, branch_id: context.branchId, storage_path: path, mime_type: file.type, source_hash: hash, created_by: context.userId, status: 'uploaded' }).select('id,storage_path,mime_type,status,created_at,source_hash').single();
    if (error) { await this.client.storage.from(bucket).remove([path]); throw error; }
    return data as ScanRecord;
  }
  async runOcr(scanId: string) {
    const { error } = await this.client.functions.invoke('extract-document', { body: { scan_id: scanId, consent_to_ai_processing: true } }); if (error) throw error;
  }
  async confirmOcr(scanId: string, data: Record<string, unknown>, duplicate: boolean) {
    const { error } = await this.client.rpc('confirm_ocr_review', { p_scan_id: scanId, p_reviewed_data: data, p_duplicate: duplicate }); if (error) throw error;
  }
  async getSalesReport(companyId: string, branchId: string, from: string, to: string) {
    const { data, error } = await this.client.rpc('get_sales_report', { p_company_id: companyId, p_branch_id: branchId, p_from: from, p_to: to });
    if (error) throw error; return asRows<SalesReportRow>(data);
  }
  async getPurchaseReport(companyId: string, branchId: string, from: string, to: string) {
    const { data, error } = await this.client.rpc('get_purchase_report', { p_company_id: companyId, p_branch_id: branchId, p_from: from, p_to: to });
    if (error) throw error; return asRows<PurchaseReportRow>(data);
  }
  async getProductionReport(companyId: string, branchId: string, from: string, to: string) {
    const { data, error } = await this.client.rpc('get_production_report', { p_company_id: companyId, p_branch_id: branchId, p_from: from, p_to: to });
    if (error) throw error; return asRows<ProductionReportRow>(data);
  }
  async getInventoryReport(context: BranchContext) { return this.getInventory(context); }
  async getInventoryCostReport(companyId: string) {
    const { data, error } = await this.client.from('inventory_cost_balances').select('product_id,quantity,inventory_value,average_unit_cost,products(name,sku,base_unit)').eq('company_id', companyId).order('inventory_value', { ascending: false });
    if (error) throw error;
    return asRows<Record<string, unknown>>(data).map((row) => {
      const product = row.products as { name?: string; sku?: string; base_unit?: string } | null;
      return { product_id: String(row.product_id), quantity: Number(row.quantity), inventory_value: Number(row.inventory_value), average_unit_cost: Number(row.average_unit_cost), product_name: product?.name ?? 'Produk tidak aktif', sku: product?.sku ?? '', base_unit: product?.base_unit ?? '' } as InventoryCostRow;
    });
  }
}
