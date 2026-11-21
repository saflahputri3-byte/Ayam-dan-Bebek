import type { Customer, CustomerMasterInput, Product, ProductMasterInput, ProductUnit, ProductUnitInput, Supplier, SupplierMasterInput } from '../../domain/erp/ErpTypes';

export interface MasterDataRepository {
  listProducts(companyId: string): Promise<Product[]>;
  listProductUnits(companyId: string): Promise<ProductUnit[]>;
  listSuppliers(companyId: string): Promise<Supplier[]>;
  listCustomers(companyId: string): Promise<Customer[]>;
  createProduct(companyId: string, input: ProductMasterInput): Promise<string>;
  updateProduct(productId: string, input: Partial<ProductMasterInput> & { is_active?: boolean }): Promise<void>;
  addProductUnit(companyId: string, input: ProductUnitInput): Promise<void>;
  updateProductUnit(unitId: string, baseUnitsPerUnit: number, isSellable: boolean): Promise<void>;
  createSupplier(companyId: string, input: SupplierMasterInput): Promise<void>;
  updateSupplier(supplierId: string, input: SupplierMasterInput & { is_active: boolean }): Promise<void>;
  createCustomer(companyId: string, input: CustomerMasterInput): Promise<void>;
  updateCustomer(customerId: string, input: CustomerMasterInput & { is_active: boolean }): Promise<void>;
}
