import { useState } from 'react';
import { ChartNoAxesCombined, Home, Menu, MoreHorizontal, ShoppingCart } from 'lucide-react';
import type { AppModule, ModuleId } from '../../domain/navigation/Module';

const operationIds: ModuleId[] = ['production','receiving','purchases','inventory','transfers','opname'];

export function BottomNavigation({ active, modules, onSelect }: { active: ModuleId; modules: AppModule[]; onSelect: (id: ModuleId) => void }) {
  const [moreOpen, setMoreOpen] = useState(false);
  const allowed = new Set(modules.map((module) => module.id));
  const operation = operationIds.find((id) => allowed.has(id));
  const primary: Array<{ label: string; icon: typeof Home; id: ModuleId }> = [
    { label: 'Beranda', icon: Home, id: 'dashboard' },
    ...(operation ? [{ label: 'Operasional', icon: Menu, id: operation! as ModuleId }] : []),
    ...(allowed.has('sales') ? [{ label: 'Penjualan', icon: ShoppingCart, id: 'sales' as ModuleId }] : []),
    ...(allowed.has('reports') ? [{ label: 'Laporan', icon: ChartNoAxesCombined, id: 'reports' as ModuleId }] : []),
  ];
  const primaryIds = new Set(primary.map((item) => item.id));
  const moreModules = modules.filter((module) => !primaryIds.has(module.id));
  const isInMore = moreModules.some((module) => module.id === active);
  const select = (id: ModuleId) => { setMoreOpen(false); onSelect(id); };

  return <>
    {moreOpen && <><button className="mobile-more-backdrop" aria-label="Tutup menu lainnya" onClick={() => setMoreOpen(false)}/><section className="mobile-more-panel" aria-label="Modul lainnya"><strong>Semua modul</strong><div>{moreModules.map((module) => <button key={module.id} onClick={() => select(module.id)}>{module.label}</button>)}</div></section></>}
    <nav className="bottom-navigation" aria-label="Navigasi mobile">
      {primary.map(({ label, icon: Icon, id }) => <button key={id} className={active === id || (id === operation && operationIds.includes(active)) ? 'active' : ''} aria-current={active === id ? 'page' : undefined} onClick={() => select(id)}><Icon size={19} strokeWidth={1.8}/><span>{label}</span></button>)}
      {moreModules.length > 0 && <button className={isInMore || moreOpen ? 'active' : ''} aria-expanded={moreOpen} aria-haspopup="true" onClick={() => setMoreOpen((open) => !open)}><MoreHorizontal size={19} strokeWidth={1.8}/><span>Lainnya</span></button>}
    </nav>
  </>;
}
