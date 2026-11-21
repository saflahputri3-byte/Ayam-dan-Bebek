import type { SupabaseClient } from '@supabase/supabase-js';
import type { Customer, CustomerMasterInput, Product, ProductMasterInput, ProductUnit, ProductUnitInput, Supplier, SupplierMasterInput } from '../../domain/erp/ErpTypes';
import type { MasterDataRepository } from '../../application/ports/MasterDataRepository';

const rows = <T,>(data: unknown): T[] => (data ?? []) as T[];

export class SupabaseMasterDataRepository implements MasterDataRepository {
  constructor(private readonly client: SupabaseClient) {}

  async listProducts(companyId: string) {
    const { data, error } = await this.client.from('products').select('id,sku,name,species,category,base_unit,minimum_stock,is_active').eq('company_id', companyId).order('name');
    if (error) throw error; return rows<Product>(data);
  }
  async listProductUnits(companyId: string) {
    const { data, error } = await this.client.from('product_units').select('id,product_id,unit_code,base_units_per_unit,is_sellable').eq('company_id', companyId).order('unit_code');
    if (error) throw error; return rows<ProductUnit>(data);
  }
  async listSuppliers(companyId: string) {
    const { data, error } = await this.client.from('suppliers').select('id,code,name,phone,address,is_active').eq('company_id', companyId).order('name');
    if (error) throw error; return rows<Supplier>(data);
  }
  async listCustomers(companyId: string) {
    const { data, error } = await this.client.from('customers').select('id,code,name,phone,address,credit_limit,is_active').eq('company_id', companyId).order('name');
    if (error) throw error; return rows<Customer>(data);
  }
  async createProduct(companyId: string, input: ProductMasterInput) {
    const { data, error } = await this.client.rpc('create_product_master', { p_payload: { ...input, company_id: companyId, species: input.species || null } });
    if (error) throw error; return data as string;
  }
  async updateProduct(productId: string, input: Partial<ProductMasterInput> & { is_active?: boolean }) {
    const { error } = await this.client.rpc('update_product_master', { p_product_id: productId, p_payload: { ...input, species: input.species === '' ? null : input.species } });
    if (error) throw error;
  }
  async addProductUnit(companyId: string, input: ProductUnitInput) {
    const { error } = await this.client.from('product_units').insert({ ...input, company_id: companyId });
    if (error) throw error;
  }
  async updateProductUnit(unitId: string, baseUnitsPerUnit: number, isSellable: boolean) {
    const { error } = await this.client.from('product_units').update({ base_units_per_unit: baseUnitsPerUnit, is_sellable: isSellable }).eq('id', unitId).select('id').single();
    if (error) throw error;
  }
  async createSupplier(companyId: string, input: SupplierMasterInput) {
    const { error } = await this.client.from('suppliers').insert({ ...input, company_id: companyId });
    if (error) throw error;
  }
  async updateSupplier(supplierId: string, input: SupplierMasterInput & { is_active: boolean }) {
    const { error } = await this.client.from('suppliers').update(input).eq('id', supplierId).select('id').single();
    if (error) throw error;
  }
  async createCustomer(companyId: string, input: CustomerMasterInput) {
    const { error } = await this.client.from('customers').insert({ ...input, company_id: companyId });
    if (error) throw error;
  }
  async updateCustomer(customerId: string, input: CustomerMasterInput & { is_active: boolean }) {
    const { error } = await this.client.from('customers').update(input).eq('id', customerId).select('id').single();
    if (error) throw error;
  }
}
