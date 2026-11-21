import type { DashboardSummary, OperationalNotice } from '../../domain/dashboard/DashboardSummary';
import type { DashboardRepository } from '../../application/ports/DashboardRepository';
import { demoStore } from './DemoErpStore';

export class DemoDashboardRepository implements DashboardRepository {
  async getSummary(): Promise<DashboardSummary> {
    const salesTotal = demoStore.sales.reduce((sum, s) => sum + s.total_amount, 0);
    const unpaidCount = demoStore.sales.filter((s) => s.paid_amount < s.total_amount).length;
    const receivables = demoStore.sales.reduce((sum, s) => sum + Math.max(0, s.total_amount - s.paid_amount), 0);

    const chickenStock = demoStore.inventory
      .filter((r) => r.product_id.includes('ayam') && r.quality_status === 'passed')
      .reduce((sum, r) => sum + r.quantity, 0);

    const duckStock = demoStore.inventory
      .filter((r) => r.product_id.includes('bebek') && r.quality_status === 'passed')
      .reduce((sum, r) => sum + r.quantity, 0);

    return {
      salesToday: salesTotal,
      salesCount: demoStore.sales.length,
      unpaidCount,
      readyStockKg: Math.round(chickenStock + duckStock),
      chickenStockKg: Math.round(chickenStock),
      duckStockKg: Math.round(duckStock),
      receivables,
    };
  }

  async getNotices(): Promise<OperationalNotice[]> {
    return [
      { id: 'notice-1', title: 'Batch ayam hidup menunggu QC', detail: '250 kg bahan baku di Gudang Utama', kind: 'critical' },
      { id: 'notice-2', title: 'Piutang mendekati jatuh tempo', detail: '2 pelanggan aktif · Rp 10,1 jt', kind: 'warning' },
      { id: 'notice-3', title: 'Pesanan siap kirim', detail: 'Surat jalan Superindo Freshmart', kind: 'info' },
      { id: 'notice-4', title: 'Penerimaan terjadwal', detail: 'PT Unggas Makmur · 600 kg', kind: 'success' },
    ];
  }
}
