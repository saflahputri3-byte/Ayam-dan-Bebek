import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { Session, SupabaseClient } from '@supabase/supabase-js';
import { DEMO_COMPANY_ID, DEMO_BRANCH_PUSAT_ID, DEMO_BRANCH_BARAT_ID, DEMO_USER_ID, demoStore, DemoErpStore } from '../demo/DemoErpStore';

export interface WorkspaceBranch { id: string; company_id: string; code: string; name: string }
interface WorkspaceState {
  session: Session | null;
  loading: boolean;
  workspaceLoading: boolean;
  branches: WorkspaceBranch[];
  activeBranch: WorkspaceBranch | null;
  roles: string[];
  error: string | null;
  isDemoMode: boolean;
  enterDemoMode: (presetRole?: string) => void;
  resetDemoData: () => void;
  setActiveBranch: (id: string) => void;
  refreshWorkspace: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  requestPasswordReset: (email: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const WorkspaceContext = createContext<WorkspaceState | null>(null);

const DEMO_BRANCHES: WorkspaceBranch[] = [
  { id: DEMO_BRANCH_PUSAT_ID, company_id: DEMO_COMPANY_ID, code: 'PUSAT', name: 'Cabang Utama (Pusat)' },
  { id: DEMO_BRANCH_BARAT_ID, company_id: DEMO_COMPANY_ID, code: 'BARAT', name: 'Cabang Barat' },
];

export function AuthProvider({ client, children }: { client: SupabaseClient; children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [workspaceLoading, setWorkspaceLoading] = useState(false);
  const [branches, setBranches] = useState<WorkspaceBranch[]>([]);
  const [selectedBranchId, setSelectedBranchId] = useState('');
  const [roles, setRoles] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [workspaceRevision, setWorkspaceRevision] = useState(0);
  const [isDemoMode, setIsDemoMode] = useState<boolean>(() => {
    return localStorage.getItem('agi_demo_mode') === 'true';
  });

  const enterDemoMode = useCallback((presetRole = 'owner') => {
    localStorage.setItem('agi_demo_mode', 'true');
    setIsDemoMode(true);
    const roleList = presetRole === 'owner'
      ? ['owner', 'super_admin', 'central_admin', 'branch_admin']
      : [presetRole];
    setRoles(roleList);
    setBranches(DEMO_BRANCHES);
    setSelectedBranchId(DEMO_BRANCH_PUSAT_ID);
    setSession({ user: { id: DEMO_USER_ID, email: `${presetRole}@agi.id` } } as unknown as Session);
    setError(null);
    setWorkspaceLoading(false);
    setLoading(false);
  }, []);

  const resetDemoData = useCallback(() => {
    const fresh = new DemoErpStore();
    Object.assign(demoStore, fresh);
    setWorkspaceRevision((r) => r + 1);
  }, []);

  useEffect(() => {
    if (isDemoMode) {
      setBranches(DEMO_BRANCHES);
      setSelectedBranchId((current) => current || DEMO_BRANCH_PUSAT_ID);
      setRoles((current) => current.length ? current : ['owner', 'super_admin', 'central_admin', 'branch_admin']);
      setSession({ user: { id: DEMO_USER_ID, email: 'owner@agi.id' } } as unknown as Session);
      setLoading(false);
      setWorkspaceLoading(false);
      return;
    }

    void client.auth.getSession().then(({ data, error: sessionError }) => {
      if (sessionError) setError(sessionError.message);
      setSession(data.session);
      setLoading(false);
    });
    const { data: listener } = client.auth.onAuthStateChange((_event, nextSession) => {
      if (!isDemoMode) {
        setSession(nextSession);
        setLoading(false);
        setError(null);
      }
    });
    return () => listener.subscription.unsubscribe();
  }, [client, isDemoMode]);

  useEffect(() => {
    if (isDemoMode) return;
    if (!session?.user.id) { setBranches([]); setRoles([]); setSelectedBranchId(''); setWorkspaceLoading(false); return; }
    let cancelled = false;
    setWorkspaceLoading(true);
    void (async () => {
      const { data: roleData, error: roleError } = await client.from('user_roles').select('company_id,role').eq('user_id', session.user.id);
      if (roleError) throw roleError;
      const roleRows = (roleData ?? []) as Array<{ company_id: string; role: string }>;
      const companyIds = [...new Set(roleRows.map((item) => item.company_id))];
      const roleNames = [...new Set(roleRows.map((item) => item.role))];
      if (companyIds.length === 0) { if (!cancelled) { setBranches([]); setRoles([]); setWorkspaceLoading(false); } return; }
      const { data: accessData, error: accessError } = await client.from('user_branch_access').select('branch_id,company_id').eq('user_id', session.user.id);
      if (accessError) throw accessError;
      const accessRows = (accessData ?? []) as Array<{ branch_id: string; company_id: string }>;
      const hasCentralRole = roleNames.some((role) => ['owner','super_admin','central_admin'].includes(role));
      let branchQuery = client.from('branches').select('id,company_id,code,name').in('company_id', companyIds).eq('is_active', true);
      if (!hasCentralRole) {
        const branchIds = accessRows.map((item) => item.branch_id);
        if (branchIds.length === 0) { if (!cancelled) { setBranches([]); setRoles(roleNames); setWorkspaceLoading(false); } return; }
        branchQuery = branchQuery.in('id', branchIds);
      }
      const { data: branchData, error: branchError } = await branchQuery.order('name');
      if (branchError) throw branchError;
      const available = (branchData ?? []) as WorkspaceBranch[];
      if (!cancelled) {
        setBranches(available); setRoles(roleNames);
        setSelectedBranchId((current) => available.some((branch) => branch.id === current) ? current : available[0]?.id ?? '');
        setWorkspaceLoading(false);
      }
    })().catch((cause: unknown) => {
      if (!cancelled) { setError(cause instanceof Error ? cause.message : 'Gagal memuat hak akses workspace.'); setWorkspaceLoading(false); }
    });
    return () => { cancelled = true; };
  }, [client, session?.user.id, workspaceRevision, isDemoMode]);

  const setActiveBranch = useCallback((id: string) => {
    if (branches.some((branch) => branch.id === id)) setSelectedBranchId(id);
  }, [branches]);
  const refreshWorkspace = useCallback(() => setWorkspaceRevision((revision) => revision + 1), []);
  const signIn = useCallback(async (email: string, password: string) => {
    const { error: signInError } = await client.auth.signInWithPassword({ email, password });
    if (signInError) throw signInError;
  }, [client]);
  const requestPasswordReset = useCallback(async (email: string) => {
    const { error: resetError } = await client.auth.resetPasswordForEmail(email, { redirectTo: `${window.location.origin}/?flow=recovery` });
    if (resetError) throw resetError;
  }, [client]);
  const updatePassword = useCallback(async (password: string) => {
    const { error: updateError } = await client.auth.updateUser({ password });
    if (updateError) throw updateError;
  }, [client]);
  const signOut = useCallback(async () => {
    if (isDemoMode) {
      localStorage.removeItem('agi_demo_mode');
      setIsDemoMode(false);
      setSession(null);
      setBranches([]);
      setRoles([]);
      setSelectedBranchId('');
      return;
    }
    const { error: signOutError } = await client.auth.signOut();
    if (signOutError) throw signOutError;
  }, [client, isDemoMode]);

  const value = useMemo(() => ({
    session,
    loading,
    workspaceLoading,
    branches,
    activeBranch: branches.find((branch) => branch.id === selectedBranchId) ?? null,
    roles,
    error,
    isDemoMode,
    enterDemoMode,
    resetDemoData,
    setActiveBranch,
    refreshWorkspace,
    signIn,
    requestPasswordReset,
    updatePassword,
    signOut
  }), [session, loading, workspaceLoading, branches, selectedBranchId, roles, error, isDemoMode, enterDemoMode, resetDemoData, setActiveBranch, refreshWorkspace, signIn, requestPasswordReset, updatePassword, signOut]);

  return <WorkspaceContext.Provider value={value}>{children}</WorkspaceContext.Provider>;
}

export function useWorkspace(): WorkspaceState {

  const context = useContext(WorkspaceContext);
  if (!context) throw new Error('useWorkspace must be used inside AuthProvider');
  return context;
}
