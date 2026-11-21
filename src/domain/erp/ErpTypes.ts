export interface BranchContext { companyId: string; branchId: string; userId: string }
export interface Product { id: string; sku: string; name: string; species: string | null; category: string; base_unit: string; minimum_stock: number; is_active: boolean }
export interface ProductUnit { id: string; product_id: string; unit_code: string; base_units_per_unit: number; is_sellable: boolean }
export interface Customer { id: string; code: string; name: string; phone: string | null; address: string | null; is_active?: boolean; credit_limit?: number }
export interface Supplier { id: string; code: string; name: string; phone?: string | null; address?: string | null; is_active?: boolean }
export interface Warehouse { id: string; branch_id: string; name: string; code: string }
export interface InventoryRow { branch_id: string; warehouse_id: string; product_id: string; product_name: string; sku: string; species: string | null; batch_id: string | null; quality_status: string | null; quantity: number; base_unit: string; minimum_stock: number }
export interface InventoryMovement { movement_id: string; branch_id: string; warehouse_id: string; warehouse_name: string; product_id: string; product_name: string; sku: string; batch_id: string | null; batch_number: string | null; movement_type: string; quantity_delta: number; unit_code: string; source_type: string; source_reference: string; created_at: string }
export interface InventoryCostRow { product_id: string; sku: string; product_name: string; base_unit: string; quantity: number; inventory_value: number; average_unit_cost: number }
export interface BatchTraceabilityEvent { event_type: string; happened_at: string; description: string; reference: string | null; related_reference: string | null; party_name: string | null; quantity: number | null; unit_code: string | null; related_batch_id: string | null; related_batch_number: string | null; notes?: string | null }
export interface BatchTraceability { batch: { id: string; batch_number: string; source_type: string; created_at: string; produced_at: string | null; expires_at: string | null; quality_status: string; product_id: string; product_name: string; sku: string; base_unit: string; branch_id: string; branch_name: string }; events: BatchTraceabilityEvent[] }
export interface SaleListItem { id: string; document_number: string; customer_id: string | null; customer_name: string; created_at: string; status: string; total_amount: number; paid_amount: number }
export interface PurchaseItem { id: string; product_id: string; product_name: string; sku: string; quantity: number; unit_code: string; base_quantity: number; received_base_quantity: number; unit_price: number }
export interface Purchase { id: string; document_number: string; supplier_id: string; supplier_name: string; status: string; total_amount: number; created_at: string; items: PurchaseItem[] }
export interface TransactionResult { sale_id?: string; purchase_id?: string; receipt_id?: string; payment_id?: string; production_batch_id?: string; document_number: string; total_amount?: number; amount?: number; status: string }
export interface Invoice { id: string; document_number: string; created_at: string; subtotal: number; discount_amount: number; shipping_amount: number; total_amount: number; paid_amount: number; notes: string | null; customer: Customer | null; branch: { name: string; address: string | null; phone: string | null }; items: Array<{ product_name: string; sku: string; quantity: number; unit_code: string; unit_price: number; line_total: number }> }
export interface ScanRecord { id: string; storage_path: string; mime_type: string; status: string; created_at: string; reviewed_at?: string | null; source_hash?: string | null; extraction: { id: string; extracted_data: Record<string, unknown>; confidence: number | null; warnings: unknown[] } | null }
export interface SalesReportRow { day: string; branch_id: string; sales_count: number; unpaid_count: number; gross_sales: number; paid_total: number; receivable_total: number }
export interface PurchaseReportRow { day: string; supplier_id: string; supplier_name: string; purchase_count: number; draft_count: number; approved_count: number; partial_count: number; received_count: number; voided_count: number; ordered_total: number }
export interface ProductionReportRow { production_batch_id: string; branch_id: string; produced_at: string; batch_number: string; notes: string | null; inputs: Array<{ product_name: string; sku: string; batch_number: string; quantity: number; unit_code: string }>; outputs: Array<{ product_name: string; sku: string; batch_number: string; quantity: number; unit_code: string }>; waste: Array<{ quantity: number; unit_code: string; reason: string }> }

export interface SaleCommand extends BranchContext {
  warehouse_id: string; customer_id: string | null; discount_amount: number; shipping_amount: number; notes: string;
  items: Array<{ product_id: string; batch_id: string; quantity: number; unit_code: string; unit_price: number; discount_amount: number }>;
}
export interface PurchaseCommand extends BranchContext {
  supplier_id: string; notes: string;
  items: Array<{ product_id: string; quantity: number; unit_code: string; unit_price: number }>;
}
export interface ReceiptCommand extends BranchContext {
  warehouse_id: string; purchase_id: string;
  items: Array<{ purchase_item_id: string; product_id: string; quantity: number; unit_code: string; unit_cost: number; batch_number?: string }>;
}
export interface ProductMasterInput { sku: string; name: string; species: 'chicken' | 'duck' | 'other' | ''; category: string; base_unit: 'kg' | 'pcs' | 'bird'; minimum_stock: number }
export interface ProductUnitInput { product_id: string; unit_code: 'kg' | 'pcs' | 'bird'; base_units_per_unit: number; is_sellable: boolean }
export interface SupplierMasterInput { code: string; name: string; phone: string; address: string }
export interface CustomerMasterInput { code: string; name: string; phone: string; address: string; credit_limit: number }
