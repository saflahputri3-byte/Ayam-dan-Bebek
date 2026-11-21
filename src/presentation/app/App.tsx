import { useState } from 'react';
import type { DashboardRepository } from '../../application/ports/DashboardRepository';
import type { ErpRepository } from '../../application/ports/ErpRepository';
import type { MasterDataRepository } from '../../application/ports/MasterDataRepository';
import type { OperationsRepository } from '../../domain/operations/OperationsTypes';
import type { SettingsRepository } from '../../domain/settings/SettingsTypes';
import type { BranchContext } from '../../domain/erp/ErpTypes';
import type { AppModule, ModuleId } from '../../domain/navigation/Module';
import type { WorkspaceBranch } from '../../infrastructure/supabase/AuthContext';
import { BottomNavigation } from '../components/BottomNavigation';
import { Sidebar } from '../components/Sidebar';
import { Topbar } from '../components/Topbar';
import { DashboardPage } from '../pages/DashboardPage';
import { ModulePage } from '../pages/ModulePage';
import { SalesPage } from '../pages/SalesPage';
import { PurchasesPage } from '../pages/PurchasesPage';
import { ProductionPage } from '../pages/ProductionPage';
import { InventoryPage } from '../pages/InventoryPage';
import { ReportsPage } from '../pages/ReportsPage';
import { InvoicePage } from '../pages/InvoicePage';
import { ScanPage } from '../pages/ScanPage';
import { DocumentsPage } from '../pages/DocumentsPage';
import { MasterDataPage } from '../pages/MasterDataPage';
import { OperationsPage } from '../pages/OperationsPage';
import { ReceivablesPage } from '../pages/ReceivablesPage';
import { SettingsPage } from '../pages/SettingsPage';
import { EmployeesPage } from '../pages/EmployeesPage';

export function App({
  dashboardRepository,
  erpRepository,
  masterDataRepository,
  operationsRepository,
  settingsRepository,
  context,
  modules,
  roles,
  branch,
  branches,
  userName,
  isDemoMode,
  onResetDemo,
  onBranchChange,
  onWorkspaceRefresh,
  onSignOut,
}: {
  dashboardRepository: DashboardRepository;
  erpRepository: ErpRepository;
  masterDataRepository: MasterDataRepository;
  operationsRepository: OperationsRepository;
  settingsRepository: SettingsRepository;
  context: BranchContext;
  modules: AppModule[];
  roles: string[];
  branch: WorkspaceBranch;
  branches: WorkspaceBranch[];
  userName: string;
  isDemoMode?: boolean;
  onResetDemo?: () => void;
  onBranchChange: (id: string) => void;
  onWorkspaceRefresh: () => void;
  onSignOut: () => Promise<void>;
}) {

  const [activeModule, setActiveModule] = useState<ModuleId>('dashboard');
  const [invoiceSaleId, setInvoiceSaleId] = useState<string | null>(null);
  const allowedModules = modules;
  const currentModule = allowedModules.find((module) => module.id === activeModule) ?? allowedModules[0];
  const selectModule = (id: ModuleId) => { if (allowedModules.some((module) => module.id === id)) setActiveModule(id); };

  if (!currentModule) return <main className="auth-screen"><section className="auth-card"><h1>Tidak ada modul yang ditetapkan</h1><p className="setup-copy">Hubungi administrator untuk memeriksa peran akun.</p><button className="auth-submit" onClick={() => void onSignOut()}>Keluar</button></section></main>;

  const openInvoice = (saleId: string) => setInvoiceSaleId(saleId);
  const canApprovePurchase = roles.some((role) => ['owner','super_admin','central_admin','branch_admin','supervisor'].includes(role));
  const canRecordPayment = roles.some((role) => ['owner','super_admin','central_admin','branch_admin','cashier','finance'].includes(role));
  const operationModules: ModuleId[] = ['transfers','opname','returns','shipping','payables','finance','notifications'];
  const page = invoiceSaleId ? <InvoicePage repository={erpRepository} context={context} saleId={invoiceSaleId} canRecordPayment={canRecordPayment} onBack={() => setInvoiceSaleId(null)}/> : activeModule === 'dashboard' ? <DashboardPage repository={dashboardRepository} modules={allowedModules} onSelect={selectModule} userName={userName}/> : activeModule === 'sales' ? <SalesPage repository={erpRepository} context={context} onInvoice={openInvoice}/> : activeModule === 'documents' ? <DocumentsPage repository={erpRepository} context={context} onInvoice={openInvoice}/> : activeModule === 'purchases' || activeModule === 'receiving' ? <PurchasesPage key={activeModule} repository={erpRepository} context={context} receiptMode={activeModule === 'receiving'} canApprove={canApprovePurchase}/> : activeModule === 'production' ? <ProductionPage repository={erpRepository} context={context}/> : activeModule === 'inventory' ? <InventoryPage repository={erpRepository} context={context}/> : activeModule === 'reports' ? <ReportsPage repository={erpRepository} context={context} roles={roles}/> : activeModule === 'document-scan' ? <ScanPage repository={erpRepository} context={context}/> : activeModule === 'master-data' ? <MasterDataPage repository={masterDataRepository} context={context} roles={roles}/> : activeModule === 'customers' ? <MasterDataPage key="customers" repository={masterDataRepository} context={context} roles={roles} initialTab="customers"/> : activeModule === 'receivables' ? <ReceivablesPage repository={operationsRepository} context={context} onInvoice={openInvoice}/> : activeModule === 'employees' ? <EmployeesPage context={context} repository={settingsRepository} branches={branches} roles={roles}/> : activeModule === 'settings' ? <SettingsPage context={context} repository={settingsRepository} onWorkspaceRefresh={onWorkspaceRefresh}/> : operationModules.includes(activeModule) ? <OperationsPage module={activeModule} repository={operationsRepository} erp={erpRepository} context={context} roles={roles} branches={branches}/> : <ModulePage module={currentModule} modules={allowedModules} onSelect={selectModule}/>;
  return (
    <div className="app-shell">
      <Sidebar
        modules={allowedModules}
        active={invoiceSaleId ? 'documents' : activeModule}
        branchName={branch.name}
        onSelect={(id) => {
          setInvoiceSaleId(null);
          selectModule(id);
        }}
      />
      <main className="main-area">
        <Topbar
          title={invoiceSaleId ? 'Invoice' : currentModule.label}
          branch={branch}
          branches={branches}
          userName={userName}
          isDemoMode={isDemoMode}
          onResetDemo={onResetDemo}
          onBranchChange={(id) => {
            setInvoiceSaleId(null);
            onBranchChange(id);
          }}
          onSignOut={onSignOut}
          onNotifications={() => selectModule('notifications')}
        />
        <div className="main-content">{page}</div>
      </main>
      <BottomNavigation
        active={invoiceSaleId ? 'documents' : activeModule}
        modules={allowedModules}
        onSelect={(id) => {
          setInvoiceSaleId(null);
          selectModule(id);
        }}
      />
    </div>
  );

}
