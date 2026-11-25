import { ArrowLeftRight, Bell, Boxes, ChartNoAxesCombined, ChevronDown, ClipboardCheck, Cog, ContactRound, Database, Files, HandCoins, LayoutDashboard, PackageCheck, Receipt, ScanLine, Settings, ShoppingBasket, ShoppingCart, Truck, Undo2, Users, Wallet } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import type { AppModule, ModuleId } from '../../domain/navigation/Module';
import { Brand } from './Brand';

const icons: Record<string, LucideIcon> = { LayoutDashboard, ShoppingBasket, PackageCheck, Cog, Boxes, ArrowLeftRight, ClipboardCheck, ShoppingCart, Undo2, Users, Truck, Files, ScanLine, Wallet, Receipt, HandCoins, ChartNoAxesCombined, Database, ContactRound, Settings, Bell };
const sections: Array<[string, AppModule['group']]> = [['BERANDA', 'home'], ['OPERASIONAL', 'operations'], ['PENJUALAN', 'sales'], ['KEUANGAN', 'finance'], ['PENGENDALIAN', 'control']];

export function Sidebar({ modules, active, branchName, branchId, branches, companyName, onBranchChange, onSelect }: { modules: AppModule[]; active: ModuleId; branchName: string; branchId?: string; branches?: Array<{ id: string; name: string }>; companyName?: string; onBranchChange?: (id: string) => void; onSelect: (id: ModuleId) => void }) {
  const canSwitch = (branches?.length ?? 0) > 1 && onBranchChange;
  return <aside className="sidebar"><Brand companyName={companyName} /><div className="branch-switch"><span className="branch-dot" /><span><small>LOKASI AKTIF</small>{canSwitch ? <select className="sidebar-branch-select" aria-label="Pilih cabang aktif" value={branchId} onChange={(e) => onBranchChange(e.target.value)}>{branches!.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}</select> : <strong>{branchName}</strong>}</span>{canSwitch && <ChevronDown size={16} />}</div>
    <nav className="side-navigation" aria-label="Navigasi utama">{sections.map(([label, group]) => {
      const items = modules.filter((module) => module.group === group);
      return <div className="nav-section" key={group}><p className="nav-label">{label}</p>{items.map((module) => { const Icon = icons[module.icon]; return <button key={module.id} className={`nav-link ${active === module.id ? 'active' : ''}`} onClick={() => onSelect(module.id)}><Icon size={17} strokeWidth={1.8} /><span>{module.label}</span>{module.status === 'planned' && <i />}</button>; })}</div>;
    })}</nav>
    <div className="sidebar-footer"><span className="online-dot" />Workspace terhubung <span className="footer-version">ERP</span><small>Akses sesuai peran dan cabang</small></div>
  </aside>;
}
