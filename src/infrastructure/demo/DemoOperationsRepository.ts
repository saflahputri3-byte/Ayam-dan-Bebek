import type { OperationsRepository, Row } from '../../domain/operations/OperationsTypes';
import type { BranchContext, InventoryRow } from '../../domain/erp/ErpTypes';
import { DEMO_BRANCH_PUSAT_ID, demoStore } from './DemoErpStore';

export class DemoOperationsRepository implements OperationsRepository {
  async getTransfers(context: BranchContext): Promise<Row[]> {
    return demoStore.transfers.filter((t) => t.source_branch_id === context.branchId || t.destination_branch_id === context.branchId);
  }

  async createTransfer(payload: Row, _key: string): Promise<Row> {
    const docNumber = `TRF/2026/11/${String(demoStore.transfers.length + 1).padStart(3, '0')}`;
    const newTrf: Row = {
      id: `trf-${Date.now()}`,
      document_number: docNumber,
      source_branch_id: payload.source_branch_id,
      destination_branch_id: payload.destination_branch_id,
      source_warehouse_id: payload.source_warehouse_id,
      destination_warehouse_id: payload.destination_warehouse_id,
      status: 'requested',
      created_at: new Date().toISOString(),
      stock_transfer_items: payload.items,
    };
    demoStore.transfers.unshift(newTrf);
    return newTrf;
  }

  async approveTransfer(id: string, approve: boolean, _reason?: string): Promise<void> {
    const trf = demoStore.transfers.find((t) => t.id === id);
    if (trf) trf.status = approve ? 'approved' : 'rejected';
  }

  async dispatchTransfer(id: string, _key: string): Promise<void> {
    const trf = demoStore.transfers.find((t) => t.id === id);
    if (trf) trf.status = 'shipped';
  }

  async receiveTransfer(id: string, _items: Row[], _key: string): Promise<void> {
    const trf = demoStore.transfers.find((t) => t.id === id);
    if (trf) trf.status = 'received';
  }

  async getOpnames(_context: BranchContext): Promise<Row[]> {
    return [...demoStore.opnames];
  }

  async createOpname(payload: Row, _key: string): Promise<Row> {
    const docNumber = `OPN/2026/11/${String(demoStore.opnames.length + 1).padStart(3, '0')}`;
    const newOpn: Row = {
      id: `opn-${Date.now()}`,
      document_number: docNumber,
      warehouse_id: payload.warehouse_id,
      reason: payload.reason,
      status: 'draft',
      created_at: new Date().toISOString(),
    };
    demoStore.opnames.unshift(newOpn);
    return newOpn;
  }

  async postOpname(id: string, submit: boolean): Promise<void> {
    const opn = demoStore.opnames.find((o) => o.id === id);
    if (opn) opn.status = submit ? 'submitted' : 'approved';
  }

  async getReturns(_context: BranchContext): Promise<Row[]> {
    return [...demoStore.returns];
  }

  async getSaleLines(saleId: string): Promise<Row[]> {
    const detail = demoStore.saleDetails[saleId];
    if (!detail) return [];
    return detail.items.map((it, idx) => ({
      id: `item-${idx}`,
      product_id: it.sku,
      quantity: it.quantity,
      unit_code: it.unit_code,
      products: { name: it.product_name },
    }));
  }

  async createReturn(payload: Row, _key: string): Promise<Row> {
    const docNumber = `RET/2026/11/${String(demoStore.returns.length + 1).padStart(3, '0')}`;
    const newRet: Row = {
      id: `ret-${Date.now()}`,
      document_number: docNumber,
      sale_id: payload.sale_id,
      sales: { document_number: demoStore.saleDetails[String(payload.sale_id)]?.document_number ?? 'INV' },
      reason: payload.reason,
      status: 'draft',
      created_at: new Date().toISOString(),
    };
    demoStore.returns.unshift(newRet);
    return newRet;
  }

  async postReturn(id: string): Promise<void> {
    const ret = demoStore.returns.find((r) => r.id === id);
    if (ret) ret.status = 'posted';
  }

  async getDeliveries(_context: BranchContext): Promise<Row[]> {
    return [...demoStore.deliveries];
  }

  async createDelivery(payload: Row, _key: string): Promise<Row> {
    const docNumber = `SJ/2026/11/${String(demoStore.deliveries.length + 1).padStart(3, '0')}`;
    const detail = demoStore.saleDetails[String(payload.sale_id)];
    const newDel: Row = {
      id: `del-${Date.now()}`,
      document_number: docNumber,
      sale_id: payload.sale_id,
      sales: { document_number: detail?.document_number ?? 'INV', customers: { name: detail?.customer?.name ?? 'Pelanggan' } },
      status: 'prepared',
      created_at: new Date().toISOString(),
    };
    demoStore.deliveries.unshift(newDel);
    return newDel;
  }

  async updateDelivery(id: string, status: string, _recipient?: string, _notes?: string): Promise<void> {
    const del = demoStore.deliveries.find((d) => d.id === id);
    if (del) del.status = status;
  }

  async getPayables(_companyId: string, branchId: string, _asOf: string): Promise<Row[]> {
    return demoStore.purchases
      .filter((po) => (demoStore.purchaseBranchIds[po.id] ?? DEMO_BRANCH_PUSAT_ID) === branchId)
      .map((po) => {
        const receivedTotal = po.items.reduce((sum, item) => {
          const unit = demoStore.productUnits.find((u) => u.product_id === item.product_id && u.unit_code === item.unit_code);
          const ratio = unit?.base_units_per_unit ?? 1;
          const receivedQty = item.received_base_quantity / ratio;
          return sum + Math.round(receivedQty * item.unit_price);
        }, 0);
        const paidTotal = demoStore.purchasePaidTotals[po.id] ?? 0;
        const balance = Math.max(0, receivedTotal - paidTotal);
        return {
          purchase_id: po.id,
          document_number: po.document_number,
          supplier_name: po.supplier_name,
          balance,
          received_total: receivedTotal,
          paid_total: paidTotal,
          due_date: demoStore.dueDates[po.id] ?? '2026-11-25',
          days_overdue: 0,
        };
      })
      .filter((row) => row.received_total > 0 && row.balance > 0);
  }

  async getReceivables(_companyId: string, branchId: string, _asOf: string): Promise<Row[]> {
    return demoStore.sales
      .filter((s) => (demoStore.saleBranchIds[s.id] ?? DEMO_BRANCH_PUSAT_ID) === branchId && s.paid_amount < s.total_amount)
      .map((s) => ({
        sale_id: s.id,
        document_number: s.document_number,
        customer_name: s.customer_name,
        invoice_date: s.created_at.slice(0, 10),
        due_date: demoStore.dueDates[s.id] ?? '2026-11-28',
        days_overdue: 0,
        aging_bucket: '0–30 hari (Lancar)',
        invoice_total: s.total_amount,
        paid_total: s.paid_amount,
        outstanding: s.total_amount - s.paid_amount,
      }));
  }

  async setSalesDueDate(saleId: string, dueDate: string | null): Promise<void> {
    if (dueDate) demoStore.dueDates[saleId] = dueDate;
  }

  async setPurchaseDueDate(purchaseId: string, dueDate: string | null): Promise<void> {
    if (dueDate) demoStore.dueDates[purchaseId] = dueDate;
  }

  async recordSupplierPayment(payload: Row, _key: string): Promise<Row> {
    const docNumber = `PAY-SUP-2026-${String(Date.now()).slice(-3)}`;
    const amount = Number(payload.amount || 0);
    const allocations = Array.isArray(payload.allocations) ? (payload.allocations as Array<{ purchase_id: string; amount: number }>) : [];
    for (const alloc of allocations) {
      demoStore.purchasePaidTotals[alloc.purchase_id] = (demoStore.purchasePaidTotals[alloc.purchase_id] ?? 0) + Number(alloc.amount || 0);
    }
    const cashAcc = demoStore.cashAccounts.find((a) => a.id === payload.cash_account_id);
    if (cashAcc) {
      cashAcc.balance = Math.max(0, cashAcc.balance - amount);
    }
    return { id: `pay-${Date.now()}`, document_number: docNumber, amount };
  }

  async getFinanceAccounts(_companyId: string): Promise<Row[]> {
    return [...demoStore.financeAccounts];
  }

  async createFinanceAccount(_companyId: string, code: string, name: string, type: string, cashFlow: boolean): Promise<void> {
    demoStore.financeAccounts.push({
      id: `fa-${Date.now()}`,
      code,
      name,
      account_type: type,
      is_cash_flow: cashFlow,
    });
  }

  async getPeriods(_companyId: string): Promise<Row[]> {
    return [...demoStore.periods];
  }

  async createPeriod(_companyId: string, name: string, starts: string, ends: string): Promise<void> {
    demoStore.periods.push({
      id: `per-${Date.now()}`,
      name,
      starts_on: starts,
      ends_on: ends,
      is_closed: false,
    });
  }

  async closePeriod(periodId: string): Promise<void> {
    const p = demoStore.periods.find((x) => x.id === periodId);
    if (p) p.is_closed = true;
  }

  async getCashAccounts(_context: BranchContext): Promise<Row[]> {
    return demoStore.cashAccounts.map((a) => ({ id: a.id, name: a.name, account_type: a.account_type, balance: a.balance }));
  }

  async createCashAccount(_context: BranchContext, payload: Row): Promise<void> {
    demoStore.cashAccounts.push({
      id: `cash-${Date.now()}`,
      name: String(payload.name),
      account_type: String(payload.account_type),
      balance: Number(payload.opening_balance || 0),
      is_active: true,
    });
  }

  async setAccountMapping(_companyId: string, _key: string, _accountId: string): Promise<void> {
    // Demo mapping accepted
  }

  async postCashMovement(_context: BranchContext, payload: Row, _key?: string): Promise<void> {
    const acc = demoStore.cashAccounts.find((a) => a.id === payload.cash_account_id);
    if (acc) {
      const delta = payload.type === 'receipt' ? Number(payload.amount) : -Number(payload.amount);
      acc.balance += delta;
    }
  }

  async recordExpense(payload: Row, _key?: string): Promise<Row> {
    const acc = demoStore.cashAccounts.find((a) => a.id === payload.cash_account_id);
    if (acc) acc.balance -= Number(payload.amount);
    return { id: `exp-${Date.now()}`, document_number: `BIAYA-${Date.now()}` };
  }

  async postJournal(_payload: Row, _key?: string): Promise<Row> {
    return { id: `jrn-${Date.now()}`, document_number: `JRN-2026-${Date.now()}` };
  }

  async getCashBalances(_companyId: string, _branchId: string): Promise<Row[]> {
    return demoStore.cashAccounts.map((a) => ({
      account_id: a.id,
      account_name: a.name,
      account_type: a.account_type === 'cash' ? 'Kas Kecil Tunai' : 'Rekening Bank Terverifikasi',
      balance: a.balance,
    }));
  }

  async getTrialBalance(_companyId: string, _branchId: string, _from: string, _to: string): Promise<Row[]> {
    return [
      { account_code: '1100', account_name: 'Kas & Rekening Bank', account_type: 'asset', debit_total: 132_350_000, credit_total: 0, net_balance: 132_350_000 },
      { account_code: '1200', account_name: 'Piutang Usaha Pelanggan', account_type: 'asset', debit_total: 10_150_000, credit_total: 0, net_balance: 10_150_000 },
      { account_code: '1300', account_name: 'Persediaan Karkas & Unggas', account_type: 'asset', debit_total: 35_800_000, credit_total: 0, net_balance: 35_800_000 },
      { account_code: '2100', account_name: 'Utang Usaha Pemasok', account_type: 'liability', debit_total: 0, credit_total: 5_500_000, net_balance: -5_500_000 },
      { account_code: '3100', account_name: 'Modal Disetor Pemilik', account_type: 'equity', debit_total: 0, credit_total: 154_350_000, net_balance: -154_350_000 },
      { account_code: '4100', account_name: 'Pendapatan Penjualan', account_type: 'revenue', debit_total: 0, credit_total: 18_450_000, net_balance: -18_450_000 },
      { account_code: '5100', account_name: 'HPP Penjualan Karkas', account_type: 'expense', debit_total: 12_800_000, credit_total: 0, net_balance: 12_800_000 },
      { account_code: '6100', account_name: 'Beban Operasional & Distribusi', account_type: 'expense', debit_total: 3_200_000, credit_total: 0, net_balance: 3_200_000 },
    ];
  }

  async getIncomeStatement(_companyId: string, _branchId: string, _from: string, _to: string): Promise<Row[]> {
    return [
      { account_name: 'Pendapatan Penjualan Karkas & Olahan', account_type: 'revenue', amount: 18_450_000 },
      { account_name: 'Harga Pokok Penjualan (HPP)', account_type: 'expense', amount: -12_800_000 },
      { account_name: 'Laba Kotor Operasional', account_type: 'gross_profit', amount: 5_650_000 },
      { account_name: 'Beban Operasional & Distribusi', account_type: 'expense', amount: -2_100_000 },
      { account_name: 'Beban Listrik Cold Storage & Es Balok', account_type: 'expense', amount: -1_100_000 },
      { account_name: 'Laba Bersih Berjalan', account_type: 'net_income', amount: 2_450_000 },
    ];
  }

  async getCashFlow(_companyId: string, _branchId: string, _from: string, _to: string): Promise<Row[]> {
    return [
      { day: new Date().toISOString().slice(0, 10), inflow: 8_300_000, outflow: 3_200_000, net: 5_100_000 },
      { day: new Date(Date.now() - 3600000 * 24).toISOString().slice(0, 10), inflow: 12_500_000, outflow: 6_800_000, net: 5_700_000 },
    ];
  }

  async getNotifications(_context: BranchContext): Promise<Row[]> {
    return [...demoStore.notifications];
  }

  async markNotificationRead(id: string): Promise<void> {
    const notif = demoStore.notifications.find((n) => n.id === id);
    if (notif) notif.read_at = new Date().toISOString();
  }

  async getInventory(context: BranchContext): Promise<InventoryRow[]> {
    return demoStore.inventory.filter((r) => r.branch_id === context.branchId);
  }

  async getWarehouses(_companyId: string, branchId: string): Promise<Row[]> {
    return demoStore.warehouses
      .filter((w) => !branchId || w.branch_id === branchId)
      .map((w) => ({ id: w.id, name: w.name, code: w.code, is_active: w.is_active }));
  }
}
