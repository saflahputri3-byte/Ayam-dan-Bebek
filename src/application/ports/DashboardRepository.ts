import type { DashboardSummary, OperationalNotice } from '../../domain/dashboard/DashboardSummary';

export interface DashboardRepository {
  getSummary(): Promise<DashboardSummary>;
  getNotices(): Promise<OperationalNotice[]>;
}
