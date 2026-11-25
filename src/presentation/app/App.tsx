import { useEffect, useState } from 'react';
import { Search, X } from 'lucide-react';
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
  const [companyName, setCompanyName] = useState('Agi Ayam & Bebek');
  const [companyVersion, setCompanyVersion] = useState(0);
  const [unreadCount, setUnreadCount] = useState(0);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const allowedModules = modules;
  const currentModule = allowedModules.find((module) => module.id === activeModule) ?? allowedModules[0];
  const selectModule = (id: ModuleId) => { if (allowedModules.some((module) => module.id === id)) setActiveModule(id); };

  useEffect(() => {
    let alive = true;
    void settingsRepository.getCompany(context.companyId).then((company) => {
      if (alive && company?.name) setCompanyName(String(company.name));
    }).catch(() => {});
    return () => { alive = false; };
  }, [settingsRepository, context.companyId, companyVersion, activeModule]);

  useEffect(() => {
    let alive = true;
    void operationsRepository.getNotifications(context).then((items) => {
      if (alive) setUnreadCount(items.filter((n) => !n.read_at).length);
    }).catch(() => {});
    return () => { alive = false; };
  }, [operationsRepository, context, activeModule]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); setSearchOpen(true); setSearchQuery(''); }
      if (e.key === 'Escape') setSearchOpen(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  if (!currentModule) return <main className="auth-screen"><section className="auth-card"><h1>Tidak ada modul yang ditetapkan</h1><p className="setup-copy">Hubungi administrator untuk memeriksa peran akun.</p><button className="auth-submit" onClick={() => void onSignOut()}>Keluar</button></section></main>;

  const openInvoice = (saleId: string) => setInvoiceSaleId(saleId);
  const canApprovePurchase = roles.some((role) => ['owner','super_admin','central_admin','branch_admin','supervisor'].includes(role));
  const canRecordPayment = roles.some((role) => ['owner','super_admin','central_admin','branch_admin','cashier','finance'].includes(role));
  const operationModules: ModuleId[] = ['transfers','opname','returns','shipping','payables','finance','notifications'];
  const refreshAndNotify = () => {
    setCompanyVersion((v) => v + 1);
    onWorkspaceRefresh();
  };
  const page = invoiceSaleId ? <InvoicePage repository={erpRepository} context={context} saleId={invoiceSaleId} companyName={companyName} canRecordPayment={canRecordPayment} onBack={() => setInvoiceSaleId(null)}/> : activeModule === 'dashboard' ? <DashboardPage repository={dashboardRepository} modules={allowedModules} onSelect={selectModule} userName={userName}/> : activeModule === 'sales' ? <SalesPage repository={erpRepository} context={context} onInvoice={openInvoice}/> : activeModule === 'documents' ? <DocumentsPage repository={erpRepository} context={context} onInvoice={openInvoice}/> : activeModule === 'purchases' || activeModule === 'receiving' ? <PurchasesPage key={activeModule} repository={erpRepository} context={context} receiptMode={activeModule === 'receiving'} canApprove={canApprovePurchase}/> : activeModule === 'production' ? <ProductionPage repository={erpRepository} context={context}/> : activeModule === 'inventory' ? <InventoryPage repository={erpRepository} context={context}/> : activeModule === 'reports' ? <ReportsPage repository={erpRepository} context={context} roles={roles}/> : activeModule === 'document-scan' ? <ScanPage repository={erpRepository} context={context}/> : activeModule === 'master-data' ? <MasterDataPage repository={masterDataRepository} context={context} roles={roles}/> : activeModule === 'customers' ? <MasterDataPage key="customers" repository={masterDataRepository} context={context} roles={roles} initialTab="customers"/> : activeModule === 'receivables' ? <ReceivablesPage repository={operationsRepository} context={context} onInvoice={openInvoice}/> : activeModule === 'employees' ? <EmployeesPage context={context} repository={settingsRepository} branches={branches} roles={roles}/> : activeModule === 'settings' ? <SettingsPage context={context} repository={settingsRepository} onWorkspaceRefresh={refreshAndNotify}/> : operationModules.includes(activeModule) ? <OperationsPage key={activeModule} module={activeModule} repository={operationsRepository} erp={erpRepository} context={context} roles={roles} branches={branches}/> : <ModulePage module={currentModule} modules={allowedModules} onSelect={selectModule}/>;
  const searchResults = allowedModules.filter((m) => `${m.label} ${m.description}`.toLowerCase().includes(searchQuery.toLowerCase()));
  return (
    <div className="app-shell">
      <Sidebar
        modules={allowedModules}
        active={invoiceSaleId ? 'documents' : activeModule}
        branchName={branch.name}
        branchId={branch.id}
        branches={branches}
        companyName={companyName}
        onBranchChange={(id) => {
          setInvoiceSaleId(null);
          onBranchChange(id);
        }}
        onSelect={(id) => {
          setInvoiceSaleId(null);
          selectModule(id);
        }}
      />
      <main className="main-area">
        <Topbar
          title={invoiceSaleId ? 'Invoice' : currentModule.label}
          companyName={companyName}
          branch={branch}
          branches={branches}
          userName={userName}
          unreadCount={unreadCount}
          isDemoMode={isDemoMode}
          onResetDemo={onResetDemo}
          onBranchChange={(id) => {
            setInvoiceSaleId(null);
            onBranchChange(id);
          }}
          onSignOut={onSignOut}
          onNotifications={() => {
            setInvoiceSaleId(null);
            selectModule('notifications');
          }}
          onSettings={allowedModules.some((m) => m.id === 'settings') ? () => {
            setInvoiceSaleId(null);
            selectModule('settings');
          } : undefined}
          onSearch={() => { setSearchOpen(true); setSearchQuery(''); }}
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
      {searchOpen && (
        <div className="quick-search-backdrop" role="dialog" aria-modal="true" aria-label="Pencarian cepat modul" onClick={() => setSearchOpen(false)}>
          <div className="quick-search-modal" onClick={(e) => e.stopPropagation()}>
            <div className="quick-search-bar">
              <Search size={16} />
              <input
                autoFocus
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Cari modul atau fitur (mis. Penjualan, Utang, Pengaturan)…"
              />
              <button type="button" className="icon-close" aria-label="Tutup pencarian" onClick={() => setSearchOpen(false)}>
                <X size={16} />
              </button>
            </div>
            <div className="quick-search-list">
              {searchResults.length === 0 ? (
                <div className="empty-state">Modul tidak ditemukan.</div>
              ) : (
                searchResults.map((m) => (
                  <button
                    key={m.id}
                    type="button"
                    className="quick-search-item"
                    onClick={() => {
                      setSearchOpen(false);
                      setInvoiceSaleId(null);
                      selectModule(m.id);
                    }}
                  >
                    <strong>{m.label}</strong>
                    <small>{m.description}</small>
                  </button>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );

}
