import { useState, type FormEvent } from 'react';
import { Bird, KeyRound, LoaderCircle, Mail, Sparkles, ShieldCheck, ShoppingCart, Cog, Boxes, Wallet } from 'lucide-react';
import { useWorkspace } from '../../infrastructure/supabase/AuthContext';

export function LoginPage() {
  const { signIn, requestPasswordReset, enterDemoMode } = useWorkspace();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [resetNotice, setResetNotice] = useState('');
  const [resetBusy, setResetBusy] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    try {
      await signIn(email.trim(), password);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Login tidak berhasil.');
    } finally {
      setBusy(false);
    }
  }

  async function resetPassword() {
    if (!email.trim()) {
      setError('Masukkan email kerja terlebih dahulu.');
      return;
    }
    setResetBusy(true);
    setError('');
    setResetNotice('');
    try {
      await requestPasswordReset(email.trim());
      setResetNotice('Jika email terdaftar, tautan pemulihan akan dikirim. Periksa inbox dan folder spam.');
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Permintaan pemulihan gagal.');
    } finally {
      setResetBusy(false);
    }
  }

  return (
    <main className="auth-screen">
      <section className="auth-card">
        <div className="auth-brand">
          <span><Bird size={23} /></span>
          <div>
            <strong>AGI AYAM & BEBEK</strong>
            <small>BUSINESS CONTROL ERP</small>
          </div>
        </div>

        <div className="auth-intro">
          <p className="eyebrow">PORTAL OPERASIONAL & PRESENTASI</p>
          <h1>Selamat Datang</h1>
          <p>Sistem ERP terintegrasi perdagangan, RPA, rantai dingin, dan akuntansi unggas.</p>
        </div>

        {/* PRESENTATION / DEMO MODE SECTION */}
        <div className="demo-login-box">
          <div className="demo-login-header">
            <span className="demo-icon-badge"><Sparkles size={16} /></span>
            <div>
              <strong>Mode Presentasi / Demo</strong>
              <small>Masuk langsung dengan data lengkap siap uji</small>
            </div>
          </div>

          <button
            type="button"
            className="demo-main-button"
            onClick={() => enterDemoMode('owner')}
          >
            <ShieldCheck size={16} />
            <span>Masuk sebagai Direktur / Owner (Akses Penuh)</span>
          </button>

          <p className="demo-sub-label">Atau uji berdasarkan divisi / peran kerja:</p>
          <div className="demo-role-grid">
            <button type="button" className="demo-role-btn" onClick={() => enterDemoMode('cashier')}>
              <ShoppingCart size={13} /> Kasir & POS
            </button>
            <button type="button" className="demo-role-btn" onClick={() => enterDemoMode('production')}>
              <Cog size={13} /> Produksi / RPA
            </button>
            <button type="button" className="demo-role-btn" onClick={() => enterDemoMode('warehouse')}>
              <Boxes size={13} /> Gudang & Stok
            </button>
            <button type="button" className="demo-role-btn" onClick={() => enterDemoMode('finance')}>
              <Wallet size={13} /> Keuangan (Finance)
            </button>
          </div>
        </div>

        <div className="auth-divider">
          <span>ATAU LOGIN SUPABASE DATABASE</span>
        </div>

        {resetNotice && <p className="success-notice" role="status">{resetNotice}</p>}

        <form onSubmit={(event) => void submit(event)} className="auth-form">
          <label>
            Email kerja
            <span className="input-wrap">
              <Mail size={16} />
              <input
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                autoComplete="username"
                required
                placeholder="nama@perusahaan.id"
              />
            </span>
          </label>
          <label>
            Kata sandi
            <span className="input-wrap">
              <KeyRound size={16} />
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                autoComplete="current-password"
                required
                placeholder="Masukkan kata sandi"
              />
            </span>
          </label>
          {error && <p className="form-error" role="alert">{error}</p>}
          <button className="auth-submit" type="submit" disabled={busy}>
            {busy ? <><LoaderCircle size={16} className="spin" /> Memeriksa akun…</> : 'Masuk dengan Akun Database'}
          </button>
          <button
            type="button"
            className="auth-link-button"
            onClick={() => void resetPassword()}
            disabled={resetBusy}
          >
            {resetBusy ? <LoaderCircle size={14} className="spin" /> : 'Lupa kata sandi?'}
          </button>
        </form>

        <p className="auth-footnote">Multi-tenant RLS · Batch traceability · Double-entry ledger</p>
      </section>
    </main>
  );
}

