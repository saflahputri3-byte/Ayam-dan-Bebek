export interface DashboardSummary {
  salesToday: number;
  salesCount: number;
  unpaidCount: number;
  readyStockKg: number;
  chickenStockKg: number;
  duckStockKg: number;
  receivables: number;
}

export interface OperationalNotice {
  id: string;
  title: string;
  detail: string;
  kind: 'warning' | 'critical' | 'info' | 'success';
}
