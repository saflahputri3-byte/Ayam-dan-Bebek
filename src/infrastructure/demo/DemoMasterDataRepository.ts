import type { MasterDataRepository } from '../../application/ports/MasterDataRepository';
import type {
  Customer,
  CustomerMasterInput,
  Product,
  ProductMasterInput,
  ProductUnit,
  ProductUnitInput,
  Supplier,
  SupplierMasterInput,
} from '../../domain/erp/ErpTypes';
import { demoStore } from './DemoErpStore';

export class DemoMasterDataRepository implements MasterDataRepository {
  async listProducts(_companyId: string): Promise<Product[]> {
    return [...demoStore.products];
  }

  async listProductUnits(_companyId: string): Promise<ProductUnit[]> {
    return [...demoStore.productUnits];
  }

  async listSuppliers(_companyId: string): Promise<Supplier[]> {
    return [...demoStore.suppliers];
  }

  async listCustomers(_companyId: string): Promise<Customer[]> {
    return [...demoStore.customers];
  }

  async createProduct(_companyId: string, input: ProductMasterInput): Promise<string> {
    const id = `prod-${Date.now()}`;
    const newProd: Product = {
      id,
      sku: input.sku,
      name: input.name,
      species: input.species || null,
      category: input.category,
      base_unit: input.base_unit,
      minimum_stock: input.minimum_stock,
      is_active: true,
    };
    demoStore.products.unshift(newProd);

    // Automatically add 1:1 base unit
    demoStore.productUnits.push({
      id: `unit-${Date.now()}`,
      product_id: id,
      unit_code: input.base_unit,
      base_units_per_unit: 1,
      is_sellable: true,
    });

    return id;
  }

  async updateProduct(productId: string, input: Partial<ProductMasterInput> & { is_active?: boolean }): Promise<void> {
    const prod = demoStore.products.find((p) => p.id === productId);
    if (prod) {
      if (input.name !== undefined) prod.name = input.name;
      if (input.category !== undefined) prod.category = input.category;
      if (input.species !== undefined) prod.species = input.species || null;
      if (input.minimum_stock !== undefined) prod.minimum_stock = input.minimum_stock;
      if (input.is_active !== undefined) prod.is_active = input.is_active;
    }
  }

  async addProductUnit(_companyId: string, input: ProductUnitInput): Promise<void> {
    demoStore.productUnits.push({
      id: `unit-${Date.now()}`,
      product_id: input.product_id,
      unit_code: input.unit_code,
      base_units_per_unit: input.base_units_per_unit,
      is_sellable: input.is_sellable,
    });
  }

  async updateProductUnit(unitId: string, baseUnitsPerUnit: number, isSellable: boolean): Promise<void> {
    const unit = demoStore.productUnits.find((u) => u.id === unitId);
    if (unit) {
      unit.base_units_per_unit = baseUnitsPerUnit;
      unit.is_sellable = isSellable;
    }
  }

  async createSupplier(_companyId: string, input: SupplierMasterInput): Promise<void> {
    demoStore.suppliers.push({
      id: `sup-${Date.now()}`,
      code: input.code,
      name: input.name,
      phone: input.phone || null,
      address: input.address || null,
      is_active: true,
    });
  }

  async updateSupplier(supplierId: string, input: SupplierMasterInput & { is_active: boolean }): Promise<void> {
    const supp = demoStore.suppliers.find((s) => s.id === supplierId);
    if (supp) {
      supp.name = input.name;
      supp.phone = input.phone || null;
      supp.address = input.address || null;
      supp.is_active = input.is_active;
    }
  }

  async createCustomer(_companyId: string, input: CustomerMasterInput): Promise<void> {
    demoStore.customers.push({
      id: `cust-${Date.now()}`,
      code: input.code,
      name: input.name,
      phone: input.phone || null,
      address: input.address || null,
      credit_limit: input.credit_limit,
      is_active: true,
    });
  }

  async updateCustomer(customerId: string, input: CustomerMasterInput & { is_active: boolean }): Promise<void> {
    const cust = demoStore.customers.find((c) => c.id === customerId);
    if (cust) {
      cust.name = input.name;
      cust.phone = input.phone || null;
      cust.address = input.address || null;
      cust.credit_limit = input.credit_limit;
      cust.is_active = input.is_active;
    }
  }
}
