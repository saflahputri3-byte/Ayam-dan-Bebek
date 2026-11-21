import { CircleAlert, ShieldCheck } from 'lucide-react';

export function SetupPage() {
  return <main className="auth-screen"><section className="auth-card setup-card"><span className="setup-mark"><ShieldCheck size={25}/></span><p className="eyebrow">KONFIGURASI BACKEND</p><h1>Hubungkan proyek Supabase</h1><p className="setup-copy">UI aplikasi sudah siap. Untuk login dan data operasional, isi URL proyek dan publishable key Supabase di file <code>.env.local</code>, lalu jalankan migrasi database.</p><div className="setup-code"><code>VITE_SUPABASE_URL=https://&lt;project-ref&gt;.supabase.co<br/>VITE_SUPABASE_PUBLISHABLE_KEY=&lt;publishable-key&gt;</code></div><div className="setup-warning"><CircleAlert size={17}/><span>Jangan pernah menaruh secret/service-role key di variabel <code>VITE_</code> atau kode browser.</span></div><small>Setelah migrasi, administrator perlu membuat perusahaan, cabang, gudang, serta mengundang pengguna dan menetapkan aksesnya.</small></section></main>;
}
