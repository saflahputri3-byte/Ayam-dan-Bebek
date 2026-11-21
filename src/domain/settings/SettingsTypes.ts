import type { BranchContext } from '../erp/ErpTypes';

export type SettingsRow = Record<string, unknown>;

export interface SettingsRepository {
  getCompany(companyId: string): Promise<SettingsRow>;
  updateCompany(companyId: string, values: SettingsRow): Promise<void>;
  getBranches(companyId: string): Promise<SettingsRow[]>;
  createBranch(companyId: string, values: SettingsRow): Promise<void>;
  updateBranch(companyId: string, branchId: string, values: SettingsRow): Promise<void>;
  createWarehouse(companyId: string, branchId: string, code: string, name: string): Promise<void>;
  getWarehouses(companyId: string, branchId: string): Promise<SettingsRow[]>;
  getAuditLog(context: BranchContext): Promise<SettingsRow[]>;
  getEmployees(context: BranchContext): Promise<SettingsRow[]>;
  saveEmployee(context: BranchContext, values: SettingsRow): Promise<void>;
  getUserAccessDirectory(companyId: string): Promise<SettingsRow[]>;
  setUserAccess(companyId: string, userId: string, roles: string[], branchIds: string[]): Promise<void>;
}
