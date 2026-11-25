import { useEffect, useRef, useState } from 'react';
import { Bell, ChevronDown, FlaskConical, LogOut, RotateCcw, Search, Settings } from 'lucide-react';
import type { WorkspaceBranch } from '../../infrastructure/supabase/AuthContext';

export function Topbar({
  title,
  companyName,
  branch,
  branches,
  userName,
  unreadCount = 0,
  isDemoMode,
  onResetDemo,
  onBranchChange,
  onSignOut,
  onNotifications,
  onSettings,
  onSearch,
}: {
  title: string;
  companyName?: string;
  branch: WorkspaceBranch;
  branches: WorkspaceBranch[];
  userName: string;
  unreadCount?: number;
  isDemoMode?: boolean;
  onResetDemo?: () => void;
  onBranchChange: (id: string) => void;
  onSignOut: () => Promise<void>;
  onNotifications: () => void;
  onSettings?: () => void;
  onSearch?: () => void;
}) {
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!menuOpen) return;
    const onOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) setMenuOpen(false);
    };
    document.addEventListener('mousedown', onOutside);
    return () => document.removeEventListener('mousedown', onOutside);
  }, [menuOpen]);

  return (
    <header className="topbar">
      <div className="topbar-title">
        <span className="desktop-crumb">{companyName || 'Agi Ayam & Bebek'} <b>/</b> </span>
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
                className="secondary-button topbar-reset-btn"
                onClick={onResetDemo}
                title="Kembalikan data simulasi ke awal"
              >
                <RotateCcw size={12} /> <span>Reset Data</span>
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

        <button type="button" className="topbar-icon" aria-label="Cari modul" title="Cari cepat modul (Ctrl+K)" onClick={onSearch}>
          <Search size={17} />
        </button>
        <button type="button" className="topbar-icon notification-button" aria-label="Buka notifikasi" onClick={onNotifications}>
          <Bell size={17} />
          {unreadCount > 0 && <i />}
        </button>
        <div className="user-menu-wrap" ref={menuRef}>
          <button type="button" className="user-chip" aria-expanded={menuOpen} aria-haspopup="menu" onClick={() => setMenuOpen((open) => !open)}>
            <span>{userName.slice(0, 2).toUpperCase()}</span>
            <span className="user-name">{userName}</span>
            <ChevronDown size={14} />
          </button>
          {menuOpen && (
            <div className="user-dropdown" role="menu">
              <div className="user-dropdown-info">
                <strong>{userName}</strong>
                <small>{branch.name}</small>
              </div>
              {onSettings && (
                <button type="button" role="menuitem" onClick={() => { setMenuOpen(false); onSettings(); }}>
                  <Settings size={14} /> Pengaturan
                </button>
              )}
              <button type="button" role="menuitem" className="danger-item" onClick={() => { setMenuOpen(false); void onSignOut(); }}>
                <LogOut size={14} /> Keluar
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}

