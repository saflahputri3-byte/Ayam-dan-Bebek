import { Bell, ChevronDown, FlaskConical, RotateCcw, Search } from 'lucide-react';
import type { WorkspaceBranch } from '../../infrastructure/supabase/AuthContext';

export function Topbar({
  title,
  branch,
  branches,
  userName,
  isDemoMode,
  onResetDemo,
  onBranchChange,
  onSignOut,
  onNotifications,
}: {
  title: string;
  branch: WorkspaceBranch;
  branches: WorkspaceBranch[];
  userName: string;
  isDemoMode?: boolean;
  onResetDemo?: () => void;
  onBranchChange: (id: string) => void;
  onSignOut: () => Promise<void>;
  onNotifications: () => void;
}) {
  return (
    <header className="topbar">
      <div className="topbar-title">
        <span className="desktop-crumb">Agi Ayam & Bebek <b>/</b> </span>
        <strong>{title}</strong>
      </div>
      <div className="topbar-actions">
        {isDemoMode ? (
          <>
            <span className="demo-badge">
              <FlaskConical size={13} /> MODE DEMO
            </span>
            {onResetDemo && (
              <button
                type="button"
                className="secondary-button"
                style={{ height: '28px', padding: '0 8px', fontSize: '9px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                onClick={onResetDemo}
                title="Kembalikan data simulasi ke awal"
              >
                <RotateCcw size={12} /> Reset Data
              </button>
            )}
          </>
        ) : (
          <span className="live-badge"><i /> TERSAMBUNG</span>
        )}

        {branches.length > 1 ? (
          <label className="branch-control">
            <span className="sr-only">Cabang aktif</span>
            <select value={branch.id} onChange={(event) => onBranchChange(event.target.value)}>
              {branches.map((item) => (
                <option key={item.id} value={item.id}>{item.name}</option>
              ))}
            </select>
            <ChevronDown size={13} />
          </label>
        ) : (
          <span className="branch-label">⌖ {branch.name}</span>
        )}

        <button className="topbar-icon" aria-label="Cari"><Search size={17} /></button>
        <button className="topbar-icon notification-button" aria-label="Buka notifikasi" onClick={onNotifications}>
          <Bell size={17} />
          <i />
        </button>
        <button className="user-chip" title="Keluar dari aplikasi" onClick={() => void onSignOut()}>
          <span>{userName.slice(0, 2).toUpperCase()}</span>
          <span className="user-name">{userName}</span>
          <ChevronDown size={14} />
        </button>
      </div>
    </header>
  );
}

