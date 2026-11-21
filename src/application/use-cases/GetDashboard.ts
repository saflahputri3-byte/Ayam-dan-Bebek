import type { DashboardRepository } from '../ports/DashboardRepository';

export function getDashboard(repository: DashboardRepository) {
  return Promise.all([repository.getSummary(), repository.getNotices()]).then(([summary, notices]) => ({ summary, notices }));
}
