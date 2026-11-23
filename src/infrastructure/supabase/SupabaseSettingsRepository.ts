import type { SupabaseClient } from '@supabase/supabase-js';
import type { BranchContext } from '../../domain/erp/ErpTypes';
import type { SettingsRepository, SettingsRow } from '../../domain/settings/SettingsTypes';

const rows = (value: unknown): SettingsRow[] => (value ?? []) as SettingsRow[];

export class SupabaseSettingsRepository implements SettingsRepository {
  constructor(private readonly client: SupabaseClient) {}

  async getCompany(companyId: string) {
    const { data, error } = await this.client.from('companies').select('id,name,legal_name,currency_code,timezone,address,phone,email,logo_path').eq('id', companyId).single();
    if (error) throw error;
    return data as SettingsRow;
  }
  async updateCompany(companyId: string, values: SettingsRow) {
    const payload = {
      p_company_id: companyId,
      p_name: values.name,
      p_legal_name: values.legal_name || null,
      p_currency_code: (values.currency_code as string) || 'IDR',
      p_timezone: (values.timezone as string) || 'Asia/Jakarta',
      p_address: values.address || null,
      p_phone: values.phone || null,
      p_email: values.email || null,
      p_logo_path: values.logo_path || null,
    };
    const { error: rpcError } = await this.client.rpc('update_company_profile', payload);
    if (rpcError) {
      const { error: updateError } = await this.client.from('companies').update({
        name: values.name,
        legal_name: values.legal_name || null,
        currency_code: (values.currency_code as string) || 'IDR',
        timezone: (values.timezone as string) || 'Asia/Jakarta',
        address: values.address || null,
        phone: values.phone || null,
        email: values.email || null,
        logo_path: values.logo_path || null,
      }).eq('id', companyId);
      if (updateError) throw rpcError;
    }
  }
  async getBranches(companyId: string) {
    const { data, error } = await this.client.from('branches').select('id,company_id,code,name,address,phone,is_active').eq('company_id', companyId).order('name');
    if (error) throw error;
    return rows(data);
  }
  async createBranch(companyId: string, values: SettingsRow) {
    const { error } = await this.client.rpc('create_branch', { p_company_id: companyId, p_code: values.code, p_name: values.name, p_address: values.address || null, p_phone: values.phone || null });
    if (error) throw error;
  }
  async updateBranch(companyId: string, branchId: string, values: SettingsRow) {
    const { error } = await this.client.rpc('update_branch_profile', { p_company_id: companyId, p_branch_id: branchId, p_code: values.code, p_name: values.name, p_address: values.address || null, p_phone: values.phone || null });
    if (error) throw error;
  }
  async createWarehouse(companyId: string, branchId: string, code: string, name: string) {
    const { error } = await this.client.rpc('create_warehouse', { p_company_id: companyId, p_branch_id: branchId, p_code: code, p_name: name });
    if (error) throw error;
  }
  async getWarehouses(companyId: string, branchId: string) {
    const { data, error } = await this.client.from('warehouses').select('id,company_id,branch_id,code,name,is_active').eq('company_id', companyId).eq('branch_id', branchId).order('name');
    if (error) throw error;
    return rows(data);
  }
  async getAuditLog(context: BranchContext) {
    const { data, error } = await this.client.from('audit_logs').select('id,branch_id,actor_id,action,entity_type,entity_id,before_data,after_data,reason,created_at').eq('company_id', context.companyId).or(`branch_id.eq.${context.branchId},branch_id.is.null`).order('created_at', { ascending: false }).limit(100);
    if (error) throw error;
    return rows(data);
  }
  async getEmployees(context: BranchContext) {
    const { data, error } = await this.client.from('employees').select('*').eq('company_id', context.companyId).eq('branch_id', context.branchId).order('full_name');
    if (error) throw error;
    return rows(data);
  }
  async saveEmployee(context: BranchContext, values: SettingsRow) {
    const { error } = await this.client.rpc('upsert_employee', { p_company_id: context.companyId, p_employee_id: values.id || null, p_branch_id: values.branch_id || context.branchId, p_code: values.employee_code, p_name: values.full_name, p_position: values.position_title || null, p_phone: values.phone || null, p_email: values.email || null, p_notes: values.notes || null, p_is_active: values.is_active ?? true });
    if (error) throw error;
  }
  async getUserAccessDirectory(companyId: string) {
    const { data, error } = await this.client.rpc('get_user_access_directory', { p_company_id: companyId });
    if (error) throw error;
    return rows(data);
  }
  async setUserAccess(companyId: string, userId: string, roles: string[], branchIds: string[]) {
    const { error } = await this.client.rpc('set_user_access', { p_company_id: companyId, p_user_id: userId, p_roles: roles, p_branch_ids: branchIds });
    if (error) throw error;
  }
}
