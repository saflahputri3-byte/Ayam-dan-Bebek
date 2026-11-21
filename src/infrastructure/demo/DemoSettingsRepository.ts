import type { SettingsRepository, SettingsRow } from '../../domain/settings/SettingsTypes';
import type { BranchContext } from '../../domain/erp/ErpTypes';
import { demoStore, DEMO_COMPANY_ID } from './DemoErpStore';

export class DemoSettingsRepository implements SettingsRepository {
  async getCompany(_companyId: string): Promise<SettingsRow> {
    return { ...demoStore.company };
  }

  async updateCompany(_companyId: string, values: SettingsRow): Promise<void> {
    demoStore.company = { ...demoStore.company, ...values };
  }

  async getBranches(_companyId: string): Promise<SettingsRow[]> {
    return [...demoStore.branches];
  }

  async createBranch(companyId: string, values: SettingsRow): Promise<void> {
    demoStore.branches.push({
      id: `branch-${Date.now()}`,
      company_id: companyId,
      code: values.code,
      name: values.name,
      address: values.address,
      phone: values.phone,
      is_active: true,
    });
  }

  async updateBranch(_companyId: string, branchId: string, values: SettingsRow): Promise<void> {
    const br = demoStore.branches.find((b) => b.id === branchId);
    if (br) {
      if (values.code) br.code = values.code;
      if (values.name) br.name = values.name;
      if (values.address) br.address = values.address;
      if (values.phone) br.phone = values.phone;
    }
  }

  async createWarehouse(companyId: string, branchId: string, code: string, name: string): Promise<void> {
    demoStore.warehouses.push({
      id: `wh-${Date.now()}`,
      company_id: companyId,
      branch_id: branchId,
      code,
      name,
      is_active: true,
    });
  }

  async getWarehouses(_companyId: string, branchId: string): Promise<SettingsRow[]> {
    return demoStore.warehouses.filter((w) => !branchId || w.branch_id === branchId);
  }

  async getAuditLog(_context: BranchContext): Promise<SettingsRow[]> {
    return [...demoStore.auditLogs];
  }

  async getEmployees(_context: BranchContext): Promise<SettingsRow[]> {
    return [...demoStore.employees];
  }

  async saveEmployee(_context: BranchContext, values: SettingsRow): Promise<void> {
    const existing = demoStore.employees.find((e) => e.id === values.id);
    if (existing) {
      Object.assign(existing, values);
    } else {
      demoStore.employees.push({
        ...values,
        id: `emp-${Date.now()}`,
        company_id: DEMO_COMPANY_ID,
      });
    }
  }

  async getUserAccessDirectory(_companyId: string): Promise<SettingsRow[]> {
    return [...demoStore.userDirectory];
  }

  async setUserAccess(_companyId: string, userId: string, roles: string[], branchIds: string[]): Promise<void> {
    const user = demoStore.userDirectory.find((u) => u.user_id === userId);
    if (user) {
      user.roles = roles;
      user.branch_ids = branchIds;
    }
  }
}
