import type { SupabaseClient } from '@supabase/supabase-js';
import type { BranchContext } from '../../domain/erp/ErpTypes';
import type { OperationsRepository, Row } from '../../domain/operations/OperationsTypes';

const rows = <T,>(data: unknown): T[] => (data ?? []) as T[];
const key = (): string => crypto.randomUUID();

export class SupabaseOperationsRepository implements OperationsRepository {
  constructor(private readonly client: SupabaseClient) {}
  private async list(table: string, companyId: string, branchId: string) {
    const { data, error } = await this.client.from(table).select('*').eq('company_id', companyId).eq('branch_id', branchId).order('created_at', { ascending: false }).limit(100);
    if (error) throw error; return rows<Row>(data);
  }
  async getTransfers(c: BranchContext) {
    const { data, error } = await this.client.from('stock_transfers').select('*,stock_transfer_items(*,products(name,sku),product_batches(batch_number))').eq('company_id', c.companyId).or(`source_branch_id.eq.${c.branchId},destination_branch_id.eq.${c.branchId}`).order('created_at', { ascending: false }).limit(100);
    if (error) throw error; return rows<Row>(data);
  }
  async createTransfer(payload: Row, idempotency: string) { const { data, error } = await this.client.rpc('create_stock_transfer', { p_payload: payload, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async approveTransfer(id: string, approve: boolean, reason = '') { const { error } = await this.client.rpc('approve_stock_transfer', { p_transfer_id: id, p_approve: approve, p_reason: reason }); if (error) throw error; }
  async dispatchTransfer(id: string, idempotency: string) { const { error } = await this.client.rpc('dispatch_stock_transfer', { p_transfer_id: id, p_idempotency_key: idempotency }); if (error) throw error; }
  async receiveTransfer(id: string, items: Row[], idempotency: string) { const { error } = await this.client.rpc('receive_stock_transfer', { p_transfer_id: id, p_items: items, p_idempotency_key: idempotency }); if (error) throw error; }
  async getOpnames(c: BranchContext) { return this.list('stock_opnames', c.companyId, c.branchId); }
  async createOpname(payload: Row, idempotency: string) { const { data, error } = await this.client.rpc('create_stock_opname', { p_payload: payload, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async postOpname(id: string, submit: boolean) { const { error } = await this.client.rpc('post_stock_opname', { p_opname_id: id, p_submit: submit }); if (error) throw error; }
  async getReturns(c: BranchContext) {
    const { data, error } = await this.client.from('sales_returns').select('*,sales(document_number),sales_return_items(*,products(name,sku))').eq('company_id', c.companyId).eq('branch_id', c.branchId).order('created_at', { ascending: false }).limit(100);
    if (error) throw error; return rows<Row>(data);
  }
  async getSaleLines(saleId: string) { const { data, error } = await this.client.from('sales_items').select('id,product_id,batch_id,quantity,unit_code,products(name,sku),product_batches(batch_number)').eq('sale_id', saleId); if (error) throw error; return rows<Row>(data); }
  async createReturn(payload: Row, idempotency: string) { const { data, error } = await this.client.rpc('create_sales_return', { p_payload: payload, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async postReturn(id: string) { const { error } = await this.client.rpc('post_sales_return', { p_return_id: id }); if (error) throw error; }
  async getDeliveries(c: BranchContext) { const { data, error } = await this.client.from('deliveries').select('*,sales(document_number,customers(name)),delivery_items(*)').eq('company_id', c.companyId).eq('branch_id', c.branchId).order('created_at', { ascending: false }).limit(100); if (error) throw error; return rows<Row>(data); }
  async createDelivery(payload: Row, idempotency: string) { const { data, error } = await this.client.rpc('create_delivery', { p_payload: payload, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async updateDelivery(id: string, status: string, recipient = '', notes = '') { const { error } = await this.client.rpc('update_delivery_status', { p_delivery_id: id, p_status: status, p_recipient: recipient, p_evidence_path: null, p_notes: notes }); if (error) throw error; }
  async getPayables(companyId: string, branchId: string, asOf: string) { const { data, error } = await this.client.rpc('get_payables_report', { p_company_id: companyId, p_branch_id: branchId, p_as_of: asOf }); if (error) throw error; return rows<Row>(data); }
  async getReceivables(companyId: string, branchId: string, asOf: string) { const { data, error } = await this.client.rpc('get_receivables_report', { p_company_id: companyId, p_branch_id: branchId, p_as_of: asOf }); if (error) throw error; return rows<Row>(data); }
  async setSalesDueDate(saleId: string, dueDate: string | null) { const { error } = await this.client.rpc('set_sales_due_date', { p_sale_id: saleId, p_due_date: dueDate }); if (error) throw error; }
  async setPurchaseDueDate(purchaseId: string, dueDate: string | null) { const { error } = await this.client.rpc('set_purchase_due_date', { p_purchase_id: purchaseId, p_due_date: dueDate }); if (error) throw error; }
  async recordSupplierPayment(payload: Row, idempotency: string) { const { data, error } = await this.client.rpc('record_supplier_payment', { p_payload: payload, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async getFinanceAccounts(companyId: string) { const { data, error } = await this.client.from('accounts').select('*').eq('company_id', companyId).order('code'); if (error) throw error; return rows<Row>(data); }
  async createFinanceAccount(companyId: string, code: string, name: string, type: string, cashFlow: boolean) { const { error } = await this.client.rpc('create_finance_account', { p_company_id: companyId, p_code: code, p_name: name, p_type: type, p_is_cash_flow: cashFlow }); if (error) throw error; }
  async getPeriods(companyId: string) { const { data, error } = await this.client.from('fiscal_periods').select('*').eq('company_id', companyId).order('starts_on', { ascending: false }); if (error) throw error; return rows<Row>(data); }
  async createPeriod(companyId: string, name: string, starts: string, ends: string) { const { error } = await this.client.rpc('create_fiscal_period', { p_company_id: companyId, p_name: name, p_starts: starts, p_ends: ends }); if (error) throw error; }
  async closePeriod(periodId: string) { const { error } = await this.client.rpc('close_fiscal_period', { p_period_id: periodId }); if (error) throw error; }
  async getCashAccounts(c: BranchContext) { return this.list('cash_accounts', c.companyId, c.branchId); }
  async createCashAccount(c: BranchContext, payload: Row) { const { error } = await this.client.rpc('create_cash_account', { p_company_id: c.companyId, p_branch_id: c.branchId, p_code: payload.code, p_name: payload.name, p_type: payload.account_type, p_opening: Number(payload.opening_balance), p_ledger_account_id: payload.ledger_account_id || null }); if (error) throw error; }
  async setAccountMapping(companyId: string, mappingKey: string, accountId: string) { const { error } = await this.client.rpc('set_account_mapping', { p_company_id: companyId, p_mapping_key: mappingKey, p_account_id: accountId }); if (error) throw error; }
  async postCashMovement(c: BranchContext, p: Row, idempotency = key()) { const { error } = await this.client.rpc('post_cash_movement', { p_company_id: c.companyId, p_branch_id: c.branchId, p_cash_account_id: p.cash_account_id, p_type: p.type, p_amount: Number(p.amount), p_description: p.description, p_idempotency_key: idempotency, p_destination_account_id: p.destination_account_id || null, p_counter_account_id: p.counter_account_id || null, p_occurred_at: p.occurred_at }); if (error) throw error; }
  async recordExpense(p: Row, idempotency = key()) { const { data, error } = await this.client.rpc('record_expense', { p_payload: p, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async postJournal(p: Row, idempotency = key()) { const { data, error } = await this.client.rpc('post_manual_journal', { p_payload: p, p_idempotency_key: idempotency }); if (error) throw error; return data as Row; }
  async getCashBalances(companyId: string, branchId: string) { const { data, error } = await this.client.rpc('get_cash_balances', { p_company_id: companyId, p_branch_id: branchId }); if (error) throw error; return rows<Row>(data); }
  async getTrialBalance(companyId: string, branchId: string, from: string, to: string) { const { data, error } = await this.client.rpc('get_trial_balance', { p_company_id: companyId, p_branch_id: branchId, p_from: from, p_to: to }); if (error) throw error; return rows<Row>(data); }
  async getIncomeStatement(companyId: string, branchId: string, from: string, to: string) { const { data, error } = await this.client.rpc('get_income_statement', { p_company_id: companyId, p_branch_id: branchId, p_from: from, p_to: to }); if (error) throw error; return rows<Row>(data); }
  async getCashFlow(companyId: string, branchId: string, from: string, to: string) { const { data, error } = await this.client.rpc('get_cash_flow_report', { p_company_id: companyId, p_branch_id: branchId, p_from: from, p_to: to }); if (error) throw error; return rows<Row>(data); }
  async getNotifications(c: BranchContext) { const { data, error } = await this.client.rpc('get_notifications', { p_company_id: c.companyId, p_branch_id: c.branchId, p_limit: 100 }); if (error) throw error; return rows<Row>(data); }
  async markNotificationRead(id: string) { const { error } = await this.client.rpc('mark_notification_read', { p_notification_id: id }); if (error) throw error; }
  async getInventory(context: BranchContext) { const { data, error } = await this.client.rpc('get_inventory_report', { p_company_id: context.companyId, p_branch_id: context.branchId, p_warehouse_id: null }); if (error) throw error; return rows<import('../../domain/erp/ErpTypes').InventoryRow>(data); }
  async getWarehouses(companyId: string, branchId: string) { const { data, error } = await this.client.from('warehouses').select('id,branch_id,code,name').eq('company_id', companyId).eq('branch_id', branchId).eq('is_active', true).order('name'); if (error) throw error; return rows<Row>(data); }
}
