import React from 'react';
import { useMemo } from 'react';
import { createRoot } from 'react-dom/client';
import { AuthProvider, useWorkspace } from './infrastructure/supabase/AuthContext';
import { supabase } from './infrastructure/supabase/client';
import { SupabaseDashboardRepository } from './infrastructure/supabase/SupabaseDashboardRepository';
import { SupabaseErpRepository } from './infrastructure/supabase/SupabaseErpRepository';
import { SupabaseMasterDataRepository } from './infrastructure/supabase/SupabaseMasterDataRepository';
import { SupabaseOperationsRepository } from './infrastructure/supabase/SupabaseOperationsRepository';
import { SupabaseSettingsRepository } from './infrastructure/supabase/SupabaseSettingsRepository';
import { DemoDashboardRepository } from './infrastructure/demo/DemoDashboardRepository';
import { DemoErpRepository } from './infrastructure/demo/DemoErpRepository';
import { DemoMasterDataRepository } from './infrastructure/demo/DemoMasterDataRepository';
import { DemoOperationsRepository } from './infrastructure/demo/DemoOperationsRepository';
import { DemoSettingsRepository } from './infrastructure/demo/DemoSettingsRepository';
import { DEMO_USER_ID } from './infrastructure/demo/DemoErpStore';
import { modulesForRoles } from './domain/navigation/Module';
import { App } from './presentation/app/App';
import { LoginPage } from './presentation/pages/LoginPage';
import { SetupPage } from './presentation/pages/SetupPage';
import { PasswordRecoveryPage } from './presentation/pages/PasswordRecoveryPage';
import { PwaRegistrar } from './presentation/components/PwaRegistrar';
import './presentation/styles.css';

function AuthenticatedApplication() {
  const workspace = useWorkspace();
  const repository = useMemo(() => {
    if (workspace.isDemoMode) return new DemoDashboardRepository();
    return workspace.activeBranch && supabase ? new SupabaseDashboardRepository(supabase, workspace.activeBranch.company_id, workspace.activeBranch.id) : null;
  }, [workspace.isDemoMode, workspace.activeBranch?.company_id, workspace.activeBranch?.id]);

  const erpRepository = useMemo(() => {
    if (workspace.isDemoMode) return new DemoErpRepository();
    return new SupabaseErpRepository(supabase!);
  }, [workspace.isDemoMode]);

  const masterDataRepository = useMemo(() => {
    if (workspace.isDemoMode) return new DemoMasterDataRepository();
    return new SupabaseMasterDataRepository(supabase!);
  }, [workspace.isDemoMode]);

  const operationsRepository = useMemo(() => {
    if (workspace.isDemoMode) return new DemoOperationsRepository();
    return new SupabaseOperationsRepository(supabase!);
  }, [workspace.isDemoMode]);

  const settingsRepository = useMemo(() => {
    if (workspace.isDemoMode) return new DemoSettingsRepository();
    return new SupabaseSettingsRepository(supabase!);
  }, [workspace.isDemoMode]);

  const context = useMemo(() => {
    if (workspace.isDemoMode && workspace.activeBranch) {
      return { companyId: workspace.activeBranch.company_id, branchId: workspace.activeBranch.id, userId: DEMO_USER_ID };
    }
    return workspace.activeBranch && workspace.session ? ({ companyId: workspace.activeBranch.company_id, branchId: workspace.activeBranch.id, userId: workspace.session.user.id }) : null;
  }, [workspace.isDemoMode, workspace.activeBranch?.company_id, workspace.activeBranch?.id, workspace.session?.user.id]);

  const modules = useMemo(() => modulesForRoles(workspace.roles), [workspace.roles]);

  if (workspace.loading) return <main className="auth-screen"><div className="auth-loading">Memuat akun…</div></main>;
  if (new URLSearchParams(window.location.search).get('flow') === 'recovery') return <PasswordRecoveryPage />;
  if (workspace.workspaceLoading) return <main className="auth-screen"><div className="auth-loading">Memuat workspace…</div></main>;
  if (!workspace.session) return <LoginPage />;
  if (workspace.error) return <main className="auth-screen"><section className="auth-card"><p className="eyebrow">GAGAL MEMUAT AKSES</p><h1>Periksa konfigurasi akun</h1><p className="setup-copy">{workspace.error}</p><button className="auth-submit" onClick={() => void workspace.signOut()}>Keluar</button></section></main>;
  if (!workspace.activeBranch) return <main className="auth-screen"><section className="auth-card"><p className="eyebrow">WORKSPACE BELUM DITETAPKAN</p><h1>Hubungi administrator</h1><p className="setup-copy">Akun Anda belum memiliki peran perusahaan dan akses cabang aktif. Administrator perlu menambahkan peran serta cabang melalui Supabase sebelum aplikasi dapat digunakan.</p><button className="auth-submit" onClick={() => void workspace.signOut()}>Keluar</button></section></main>;
  if (!repository || !context) return null;

  const userName = workspace.isDemoMode
    ? 'Budi Santoso (Owner)'
    : workspace.session.user.email?.split('@')[0] ?? 'Pengguna';

  return (
    <App
      dashboardRepository={repository}
      erpRepository={erpRepository}
      masterDataRepository={masterDataRepository}
      operationsRepository={operationsRepository}
      settingsRepository={settingsRepository}
      context={context}
      modules={modules}
      roles={workspace.roles}
      branch={workspace.activeBranch}
      branches={workspace.branches}
      userName={userName}
      isDemoMode={workspace.isDemoMode}
      onResetDemo={workspace.resetDemoData}
      onBranchChange={workspace.setActiveBranch}
      onWorkspaceRefresh={workspace.refreshWorkspace}
      onSignOut={workspace.signOut}
    />
  );

}


createRoot(document.getElementById('root')!).render(<React.StrictMode><PwaRegistrar />
  {supabase ? <AuthProvider client={supabase}><AuthenticatedApplication /></AuthProvider> : <SetupPage />}
</React.StrictMode>);
