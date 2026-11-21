import type { BatchTraceability, BranchContext, Customer, InventoryCostRow, InventoryMovement, InventoryRow, Invoice, Product, ProductUnit, ProductionReportRow, Purchase, PurchaseCommand, PurchaseReportRow, ReceiptCommand, SaleCommand, SaleListItem, SalesReportRow, ScanRecord, Supplier, TransactionResult, Warehouse } from '../../domain/erp/ErpTypes';

export interface ErpRepository {
  getProducts(companyId: string): Promise<Product[]>;
  getProductUnits(companyId: string): Promise<ProductUnit[]>;
  getCustomers(companyId: string): Promise<Customer[]>;
  getSuppliers(companyId: string): Promise<Supplier[]>;
  getWarehouses(branchId: string): Promise<Warehouse[]>;
  getCashAccounts(branchId: string): Promise<Array<{ id: string; name: string; account_type: string }>>;
  getInventory(context: BranchContext): Promise<InventoryRow[]>;
  getInventoryMovements(context: BranchContext): Promise<InventoryMovement[]>;
  getBatchTraceability(batchId: string): Promise<BatchTraceability>;
  getSales(context: BranchContext): Promise<SaleListItem[]>;
  postSale(command: SaleCommand, idempotencyKey: string): Promise<TransactionResult>;
  getPurchases(context: BranchContext): Promise<Purchase[]>;
  createPurchase(command: PurchaseCommand, idempotencyKey: string): Promise<TransactionResult>;
  approvePurchase(purchaseId: string): Promise<void>;
  receivePurchase(command: ReceiptCommand, idempotencyKey: string): Promise<TransactionResult>;
  postProduction(payload: Record<string, unknown>, idempotencyKey: string): Promise<TransactionResult>;
  inspectBatch(batchId: string, result: 'passed' | 'rejected' | 'quarantined', notes: string): Promise<void>;
  getInvoice(saleId: string): Promise<Invoice>;
  recordPrint(sourceType: string, sourceId: string): Promise<void>;
  recordPayment(payload: Record<string, unknown>, idempotencyKey: string): Promise<TransactionResult>;
  listScans(context: BranchContext): Promise<ScanRecord[]>;
  getScanPreviewUrl(storagePath: string): Promise<string>;
  uploadScan(file: File, context: BranchContext): Promise<ScanRecord>;
  runOcr(scanId: string): Promise<void>;
  confirmOcr(scanId: string, data: Record<string, unknown>, duplicate: boolean): Promise<void>;
  getSalesReport(companyId: string, branchId: string, from: string, to: string): Promise<SalesReportRow[]>;
  getPurchaseReport(companyId: string, branchId: string, from: string, to: string): Promise<PurchaseReportRow[]>;
  getProductionReport(companyId: string, branchId: string, from: string, to: string): Promise<ProductionReportRow[]>;
  getInventoryReport(context: BranchContext): Promise<InventoryRow[]>;
  getInventoryCostReport(companyId: string): Promise<InventoryCostRow[]>;
}
