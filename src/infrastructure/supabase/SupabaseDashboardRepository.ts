import type { DashboardRepository } from '../../application/ports/DashboardRepository';
import type { DashboardSummary, OperationalNotice } from '../../domain/dashboard/DashboardSummary';
import type { SupabaseClient } from '@supabase/supabase-js';

interface SalesReportRow { day: string; sales_count: number; unpaid_count: number; gross_sales: number; receivable_total: number }
interface InventoryReportRow { product_id: string; product_name: string; species: string | null; quality_status: string | null; quantity: number; minimum_stock: number; base_unit: string }

function jakartaDate(date: Date): string {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jakarta', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

export class SupabaseDashboardRepository implements DashboardRepository {
  constructor(private readonly client: SupabaseClient, private readonly companyId: string, private readonly branchId: string) {}

  async getSummary(): Promise<DashboardSummary> {
    const today = jakartaDate(new Date());
    const [{ data: sales, error: salesError }, { data: inventory, error: stockError }, { data: receivables, error: receivablesError }] = await Promise.all([
      this.client.rpc('get_sales_report', { p_company_id: this.companyId, p_branch_id: this.branchId, p_from: today, p_to: today }),
      this.client.rpc('get_inventory_report', { p_company_id: this.companyId, p_branch_id: this.branchId, p_warehouse_id: null }),
      this.client.rpc('get_receivables_total', { p_company_id: this.companyId, p_branch_id: this.branchId }),
    ]);
    if (salesError) throw salesError;
    if (stockError) throw stockError;
    if (receivablesError) throw receivablesError;
    const salesRows = (sales ?? []) as SalesReportRow[];
    const inventoryRows = (inventory ?? []) as InventoryReportRow[];
    return {
      salesToday: salesRows.reduce((sum, row) => sum + Number(row.gross_sales), 0),
      salesCount: salesRows.reduce((sum, row) => sum + Number(row.sales_count), 0),
      unpaidCount: salesRows.reduce((sum, row) => sum + Number(row.unpaid_count), 0),
      readyStockKg: inventoryRows.filter((row) => row.base_unit === 'kg' && row.quality_status === 'passed').reduce((sum, row) => sum + Number(row.quantity), 0),
      chickenStockKg: inventoryRows.filter((row) => row.base_unit === 'kg' && row.species === 'chicken' && row.quality_status === 'passed').reduce((sum, row) => sum + Number(row.quantity), 0),
      duckStockKg: inventoryRows.filter((row) => row.base_unit === 'kg' && row.species === 'duck' && row.quality_status === 'passed').reduce((sum, row) => sum + Number(row.quantity), 0),
      receivables: Number(receivables ?? 0),
    };
  }

  async getNotices(): Promise<OperationalNotice[]> {
    const { data, error } = await this.client.rpc('get_inventory_report', {
      p_company_id: this.companyId, p_branch_id: this.branchId, p_warehouse_id: null,
    });
    if (error) throw error;
    const rows = (data ?? []) as InventoryReportRow[];
    const totals = new Map<string, InventoryReportRow>();
    for (const row of rows) {
      const available = row.quality_status === 'passed' ? Number(row.quantity) : 0;
      const current = totals.get(row.product_id);
      totals.set(row.product_id, { ...row, quantity: (current?.quantity ?? 0) + available });
    }
    return [...totals.values()].filter((row) => Number(row.quantity) <= Number(row.minimum_stock)).slice(0, 5).map((row) => ({
      id: `low-${row.product_id}`, title: 'Stok layak jual mencapai batas minimum', detail: `${row.product_name} · ${row.quantity} ${row.base_unit}`, kind: 'warning',
    }));
  }
}
