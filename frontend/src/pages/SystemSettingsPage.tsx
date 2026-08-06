import { useMemo, useState, useEffect } from 'react';
import { cn } from '@/lib/cn';
import toast from 'react-hot-toast';
import {
  ServerCog, ShieldCheck, RefreshCw, Save, Bot, Instagram, Send,
  SlidersHorizontal, Check, RotateCcw, BookOpen, ChevronDown, Sparkles,
  type LucideIcon,
} from 'lucide-react';

import {
  systemSettingsApi, type SysSettingGroup, type SysSettingItem,
} from '@/features/system/systemSettingsApi';

// Guruh id → ikonka + qisqa izoh (backend katalogidagi guruhlarга mos)
const GROUP_META: Record<string, { icon: LucideIcon; desc: string }> = {
  ai: { icon: Bot, desc: "Afzal ko'rilgan model va API kalitlar." },
  knowledge: { icon: BookOpen, desc: "Agent leadlarga shu ma'lumot asosida javob beradi." },
  instagram: { icon: Instagram, desc: 'Webhook va Graph API ulanishi (Meta).' },
  telegram: { icon: Send, desc: 'Xodimlarga qaynoq lead va kunlik hisobot boti.' },
  general: { icon: SlidersHorizontal, desc: 'Umumiy agent sozlamalari.' },
};

const AI_KEYS = {
  claude: ['ANTHROPIC_API_KEY', 'CLAUDE_MODEL'],
  gemini: ['GEMINI_API_KEY', 'GEMINI_MODEL'],
};

/** Maydon (draft'ni hisobga olib) to'ldirilganmi. */
function itemSet(item: SysSettingItem, draftVal: string | undefined): boolean {
  if (draftVal === undefined) return item.is_set;
  return draftVal.trim() !== '';
}

export default function SystemSettingsPage() {
  const [groups, setGroups] = useState<SysSettingGroup[]>([]);
  const [igConnected, setIgConnected] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeId, setActiveId] = useState('');
  // O'zgartirilgan kalitlar ("" = tozalash)
  const [draft, setDraft] = useState<Record<string, string>>({});

  async function load() {
    setLoading(true);
    try {
      const data = await systemSettingsApi.get();
      setGroups(data.groups);
      setIgConnected(data.instagram_connected);
      setDraft({});
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Yuklashda xatolik');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);
  useEffect(() => {
    if (groups.length && !groups.some((g) => g.id === activeId)) setActiveId(groups[0].id);
  }, [groups, activeId]);

  const dirty = Object.keys(draft).length;
  const active = groups.find((g) => g.id === activeId) ?? groups[0];

  const provider = useMemo(() => {
    const it = groups.flatMap((g) => g.items).find((i) => i.key === 'AI_PROVIDER');
    return draft['AI_PROVIDER'] ?? it?.value ?? '';
  }, [groups, draft]);

  function groupProgress(g: SysSettingGroup) {
    const set = g.items.filter((it) => itemSet(it, draft[it.key])).length;
    return { set, total: g.items.length };
  }

  function setField(key: string, value: string) {
    setDraft((d) => ({ ...d, [key]: value }));
  }
  function clearField(key: string) {
    setDraft((d) => ({ ...d, [key]: '' }));
  }
  function undoField(key: string) {
    setDraft((d) => { const n = { ...d }; delete n[key]; return n; });
  }

  async function save() {
    if (!dirty) return;
    setSaving(true);
    try {
      const data = await systemSettingsApi.update(draft);
      setGroups(data.groups);
      setIgConnected(data.instagram_connected);
      setDraft({});
      toast.success('Saqlandi — agent 5 daqiqada avtomatik yangilaydi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Saqlashda xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      {/* Sarlavha */}
      <div className="flex items-start justify-between gap-3 flex-wrap mb-4">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <ServerCog size={22} className="text-primary" /> Tizim sozlamalari
          </h1>
          <p className="text-sm text-ink-soft mt-0.5">
            Instagram AI marketing agenti konfiguratsiyasi. O'zgartirilganda agent
            <b> restartsiz</b> avtomatik yangilanadi.
          </p>
        </div>
        <div className="flex items-center gap-2">
          {provider && (
            <span className="inline-flex items-center gap-1.5 text-xs font-medium rounded-full px-2.5 py-1 bg-primary/10 text-primary">
              <Bot size={13} /> {provider === 'gemini' ? 'Gemini' : 'Claude'}
            </span>
          )}
          <button onClick={load} disabled={loading}
                  className="btn-ghost inline-flex items-center gap-1.5 text-sm">
            <RefreshCw size={15} className={loading ? 'animate-spin' : ''} /> Yangilash
          </button>
        </div>
      </div>

      {/* Xavfsizlik eslatmasi */}
      <div className="rounded-card border border-emerald-300/40 bg-emerald-50 text-emerald-800 p-3 flex items-start gap-2 text-sm mb-4">
        <ShieldCheck size={18} className="shrink-0 mt-0.5" />
        <div>
          Maxfiy kalitlar bazada <b>shifrlangan</b> holda saqlanadi va faqat
          super-adminga ko'rinadi. Saqlangan sirlar to'liq ko'rsatilmaydi —
          yangisini kiritsangiz, ustiga yoziladi.
        </div>
      </div>

      {loading ? (
        <div className="grid lg:grid-cols-[16rem_1fr] gap-4">
          <div className="h-64 rounded-card bg-black/5 animate-pulse" />
          <div className="h-96 rounded-card bg-black/5 animate-pulse" />
        </div>
      ) : (
        <div className="grid lg:grid-cols-[16rem_1fr] gap-4 items-start">
          {/* Chap: guruh navigatsiyasi */}
          <nav className="card p-2 lg:sticky lg:top-4 flex lg:flex-col gap-1 overflow-x-auto">
            {groups.map((g) => {
              const meta = GROUP_META[g.id] ?? { icon: ServerCog, desc: '' };
              const Icon = meta.icon;
              const { set, total } = groupProgress(g);
              const isActive = g.id === active?.id;
              return (
                <button
                  key={g.id}
                  onClick={() => setActiveId(g.id)}
                  className={`flex items-center gap-2.5 rounded-button px-3 py-2 text-left whitespace-nowrap transition ${
                    isActive ? 'bg-primary/10 text-primary' : 'hover:bg-black/[0.04] text-ink'
                  }`}
                >
                  <Icon size={17} className="shrink-0" />
                  <span className="flex-1 text-sm font-medium">{g.title}</span>
                  <span className={`text-xs tabular-nums ${
                    set === total ? 'text-success' : 'text-ink-soft'
                  }`}>
                    {set}/{total}
                  </span>
                </button>
              );
            })}
          </nav>

          {/* O'ng: tanlangan guruh */}
          {active && (
            <section className="card">
              <GroupHeader group={active} />
              {active.id === 'ai' ? (
                <AiPanel
                  items={active.items}
                  draft={draft}
                  provider={provider}
                  onProvider={(p) => setField('AI_PROVIDER', p)}
                  onChange={setField}
                  onClear={clearField}
                  onUndo={undoField}
                />
              ) : (
                <div className="mt-1">
                  {active.id === 'instagram' && (
                    <InstagramConnect
                      items={active.items}
                      dirty={dirty}
                      connected={igConnected}
                    />
                  )}
                  {active.items.map((item) => (
                    <FieldRow
                      key={item.key}
                      item={item}
                      draftValue={draft[item.key]}
                      onChange={(v) => setField(item.key, v)}
                      onClear={() => clearField(item.key)}
                      onUndo={() => undoField(item.key)}
                    />
                  ))}
                </div>
              )}
            </section>
          )}
        </div>
      )}

      {/* Yopishqoq saqlash paneli — kontent oqimida, sidebar'ni avtomatik hisobga oladi */}
      {!loading && (
        <div className="sticky bottom-0 mt-4 -mb-4 sm:-mb-6 py-3 border-t border-black/10 bg-card/90 backdrop-blur z-20 flex items-center justify-between gap-3">
          <span className="text-sm text-ink-soft">
            {dirty
              ? <><b className="text-ink">{dirty}</b> ta saqlanmagan o'zgarish</>
              : "Barcha o'zgarishlar saqlangan"}
          </span>
          <div className="flex items-center gap-2">
            {dirty > 0 && (
              <button onClick={() => setDraft({})}
                      className="btn-ghost inline-flex items-center gap-1.5 text-sm">
                <RotateCcw size={15} /> Bekor qilish
              </button>
            )}
            <button onClick={save} disabled={!dirty || saving}
                    className="btn-primary inline-flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed">
              <Save size={16} /> {saving ? 'Saqlanmoqda...' : 'Saqlash'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
/**
 * Instagram'ni ULASH paneli — token qo'lda kiritilmaydi.
 * Tugma agentning `/connect` sahifasini ochadi: u Instagram login oynasiga
 * olib boradi, so'ng tokenni o'zi olib shu sozlamalarga yozib qo'yadi.
 */
function InstagramConnect(
  { items, dirty, connected }:
  { items: SysSettingItem[]; dirty: number; connected: boolean },
) {
  const byKey = Object.fromEntries(
    items.map((i) => [i.key, i]),
  ) as Record<string, SysSettingItem>;
  const publicUrl = (byKey.AGENT_PUBLIC_URL?.value || '').replace(/\/+$/, '');
  const ready = Boolean(publicUrl && byKey.IG_APP_ID?.is_set && byKey.IG_APP_SECRET?.is_set);

  return (
    <div className="mb-4 rounded-lg border border-black/10 bg-black/[0.02] p-4">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div>
          <div className="font-medium">
            {connected ? 'Instagram ulangan ✅' : 'Instagram hali ulanmagan'}
          </div>
          <p className="text-sm text-ink-soft mt-0.5">
            {ready
              ? 'Tugmani bosing — Instagram login oynasi ochiladi. Token avtomatik olinadi.'
              : 'Avval App ID, App Secret va tashqi manzilni to‘ldirib saqlang.'}
          </p>
        </div>
        <a
          href={ready ? `${publicUrl}/connect` : undefined}
          target="_blank"
          rel="noreferrer"
          aria-disabled={!ready || dirty > 0}
          className={`btn-primary text-sm ${!ready || dirty > 0 ? 'pointer-events-none opacity-50' : ''}`}
        >
          {connected ? 'Qayta ulash' : 'Instagram’ni ulash'}
        </a>
      </div>
      {dirty > 0 && ready && (
        <p className="text-xs text-amber-600 mt-2">
          Avval o‘zgarishlarni saqlang, keyin ulang.
        </p>
      )}
    </div>
  );
}

function GroupHeader({ group }: { group: SysSettingGroup }) {
  const meta = GROUP_META[group.id] ?? { icon: ServerCog, desc: '' };
  const Icon = meta.icon;
  return (
    <div className="flex items-center gap-3 pb-4 border-b border-black/5">
      <div className="w-10 h-10 rounded-button bg-primary/10 text-primary flex items-center justify-center shrink-0">
        <Icon size={20} />
      </div>
      <div>
        <h2 className="font-semibold">{group.title}</h2>
        {meta.desc && <p className="text-xs text-ink-soft">{meta.desc}</p>}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
function FieldMeta({ item, touched, cleared, onUndo }: {
  item: SysSettingItem; touched: boolean; cleared: boolean; onUndo: () => void;
}) {
  return (
    <div className="flex items-start justify-between gap-2">
      <div>
        <div className="flex items-center gap-2 flex-wrap">
          <label className="text-sm font-medium text-ink">{item.label}</label>
          {item.secret && item.is_set && !cleared && (
            <span className="inline-flex items-center gap-0.5 text-xs text-success">
              <Check size={12} /> saqlangan
            </span>
          )}
          {item.from_env && (
            <span className="text-xs text-ink-soft bg-black/5 rounded px-1.5">.env</span>
          )}
          {cleared && <span className="text-xs text-red-500">tozalanadi</span>}
          {touched && !cleared && <span className="text-xs text-amber-600">o'zgardi</span>}
        </div>
        {item.help && <p className="text-xs text-ink-soft mt-0.5">{item.help}</p>}
      </div>
      {touched && (
        <button onClick={onUndo} title="O'zgarishni bekor qilish"
                className="text-ink-soft hover:text-ink shrink-0 mt-0.5">
          <RotateCcw size={15} />
        </button>
      )}
    </div>
  );
}

function FieldRow({
  item, draftValue, onChange, onClear, onUndo,
}: {
  item: SysSettingItem;
  draftValue: string | undefined;
  onChange: (v: string) => void;
  onClear: () => void;
  onUndo: () => void;
}) {
  const touched = draftValue !== undefined;
  const cleared = touched && draftValue === '';
  const controlled = item.secret ? (draftValue ?? '') : (draftValue ?? item.value);

  // Boshqaruv kengligi maydon turiga qarab (ustma-ust ko'rinishда)
  const widthCls =
    item.type === 'textarea' ? 'w-full'
      : item.type === 'number' ? 'max-w-[12rem]'
        : item.type === 'select' ? 'max-w-md'
          : 'max-w-2xl';

  return (
    <div className="py-4 border-b border-black/5 last:border-0">
      <FieldMeta item={item} touched={touched} cleared={cleared} onUndo={onUndo} />
      <div className={cn('mt-2', widthCls)}>
        {item.type === 'textarea' ? (
          <textarea
            className="input w-full min-h-[150px] resize-y leading-relaxed text-[13px]"
            value={controlled}
            placeholder={item.placeholder}
            onChange={(e) => onChange(e.target.value)}
          />
        ) : item.type === 'select' ? (
          <select className="input" value={controlled} onChange={(e) => onChange(e.target.value)}>
            {item.options.map((o) => <option key={o} value={o}>{o}</option>)}
          </select>
        ) : (
          <input
            className="input"
            type={item.secret ? 'password' : item.type === 'number' ? 'number' : 'text'}
            value={controlled}
            placeholder={item.secret
              ? (item.is_set ? (item.masked || 'saqlangan — yangisini kiriting') : 'kiritilmagan')
              : item.placeholder}
            onChange={(e) => onChange(e.target.value)}
            autoComplete={item.secret ? 'new-password' : 'off'}
          />
        )}
      </div>
      {item.secret && item.is_set && !cleared && (
        <button onClick={onClear} className="text-xs text-red-500 hover:text-red-600 mt-1.5">
          Tozalash
        </button>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// AI paneli — afzal ko'rilgan provayder toggle + faqat o'shaning maydonlari
function AiPanel({ items, draft, provider, onProvider, onChange, onClear, onUndo }: {
  items: SysSettingItem[];
  draft: Record<string, string>;
  provider: string;
  onProvider: (p: string) => void;
  onChange: (key: string, v: string) => void;
  onClear: (key: string) => void;
  onUndo: (key: string) => void;
}) {
  const [showBackup, setShowBackup] = useState(false);
  const byKey = useMemo(
    () => Object.fromEntries(items.map((i) => [i.key, i])) as Record<string, SysSettingItem>,
    [items],
  );
  const sel: 'claude' | 'gemini' = provider === 'gemini' ? 'gemini' : 'claude';
  const backup = sel === 'gemini' ? 'claude' : 'gemini';
  const backupLabel = backup === 'gemini' ? 'Gemini' : 'Claude';

  const field = (key: string) =>
    byKey[key] ? (
      <FieldRow key={key} item={byKey[key]} draftValue={draft[key]}
                onChange={(v) => onChange(key, v)} onClear={() => onClear(key)}
                onUndo={() => onUndo(key)} />
    ) : null;

  return (
    <div>
      {/* Afzal ko'rilgan AI */}
      <div className="py-4 border-b border-black/5">
        <label className="text-sm font-medium text-ink flex items-center gap-1.5">
          <Sparkles size={14} className="text-primary" /> Afzal ko'rilgan AI
        </label>
        <p className="text-xs text-ink-soft mt-0.5 mb-2.5">
          Belgilangani ishlaydi. Ikkalasining kaliti saqlansa ham, faqat tanlangani javob beradi.
        </p>
        <div className="inline-flex rounded-button border border-black/10 p-1 bg-black/[0.03] gap-1">
          {(['claude', 'gemini'] as const).map((p) => (
            <button key={p} type="button" onClick={() => onProvider(p)}
                    className={cn(
                      'px-5 py-1.5 rounded-[0.5rem] text-sm font-medium inline-flex items-center gap-1.5 transition',
                      sel === p ? 'bg-primary text-white shadow-sm' : 'text-ink-soft hover:text-ink',
                    )}>
              <Bot size={14} /> {p === 'claude' ? 'Claude' : 'Gemini'}
              {sel === p && <Check size={13} />}
            </button>
          ))}
        </div>
        <p className="text-xs text-ink-soft mt-2">
          {sel === 'claude'
            ? 'Claude — sifatli javoblar, jonli sotuvга tavsiya etiladi.'
            : 'Gemini — tez va arzon, dastlabki test uchun qulay.'}
        </p>
      </div>

      {/* Tanlangan provayder maydonlari + umumiy */}
      {AI_KEYS[sel].map(field)}
      {field('AI_MAX_TOKENS')}

      {/* Zaxira provayder (ixtiyoriy) */}
      <div className="pt-4">
        <button type="button" onClick={() => setShowBackup((s) => !s)}
                className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline">
          <ChevronDown size={14} className={cn('transition', showBackup && 'rotate-180')} />
          {backupLabel} kalitlari (zaxira — ixtiyoriy)
        </button>
        {showBackup && (
          <div className="mt-2 rounded-card bg-black/[0.02] border border-black/5 px-3.5">
            {AI_KEYS[backup].map(field)}
          </div>
        )}
      </div>
    </div>
  );
}
