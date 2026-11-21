import { ArrowUpRight, Boxes, ChartNoAxesCombined, Cog, ContactRound, Database, Files, HandCoins, LayoutDashboard, PackageCheck, Receipt, ScanLine, Settings, ShoppingBasket, ShoppingCart, Truck, Users, Wallet, ArrowLeftRight } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import type { AppModule } from '../../domain/navigation/Module';

const iconMap: Record<string, LucideIcon> = { LayoutDashboard, ShoppingBasket, PackageCheck, Cog, Boxes, ArrowLeftRight, ShoppingCart, Users, Truck, Files, ScanLine, Wallet, Receipt, HandCoins, ChartNoAxesCombined, Database, ContactRound, Settings };
const colors: Record<string, string> = { home: 'mint', operations: 'blue', sales: 'orange', finance: 'violet', control: 'slate' };

export function MenuCard({ module, onSelect, featured = false }: { module: AppModule; onSelect: (id: AppModule['id']) => void; featured?: boolean }) {
  const Icon = iconMap[module.icon] ?? Boxes;
  return <button className={`menu-card ${featured ? 'menu-card-featured' : ''}`} onClick={() => onSelect(module.id)}>
    <span className={`menu-icon ${colors[module.group]}`}><Icon size={20} strokeWidth={1.8} /></span>
    <span className="menu-text"><strong>{module.label}</strong><small>{module.description}</small></span>
    <ArrowUpRight className="menu-arrow" size={15} />
    {module.status === 'planned' && <span className="planned-dot" title="Belum dibangun" />}{module.status === 'live' && <span className="live-dot" title="Terhubung ke data Supabase" />}
  </button>;
}
