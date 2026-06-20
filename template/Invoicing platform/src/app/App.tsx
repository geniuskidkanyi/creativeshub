import { useState, useMemo } from "react";
import {
  LayoutDashboard,
  FileText,
  Users,
  Plus,
  ChevronRight,
  TrendingUp,
  Clock,
  CheckCircle,
  AlertCircle,
  ArrowUpRight,
  ArrowDownRight,
  Send,
  Download,
  MoreHorizontal,
  X,
  CreditCard,
  Building2,
  Mail,
  Phone,
  Globe,
  Search,
  Filter,
  Edit3,
  Trash2,
  Eye,
  ChevronDown,
  DollarSign,
  Calendar,
} from "lucide-react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
} from "recharts";

// ─── Types ────────────────────────────────────────────────────────────────────

type View = "dashboard" | "invoices" | "clients" | "create-invoice" | "invoice-detail" | "client-detail";

interface Client {
  id: string;
  name: string;
  company: string;
  email: string;
  phone: string;
  website: string;
  address: string;
  totalBilled: number;
  invoiceCount: number;
  since: string;
}

interface InvoiceItem {
  description: string;
  qty: number;
  rate: number;
}

interface Invoice {
  id: string;
  number: string;
  clientId: string;
  status: "draft" | "sent" | "paid" | "overdue";
  issueDate: string;
  dueDate: string;
  items: InvoiceItem[];
  notes: string;
  tax: number;
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

const CLIENTS: Client[] = [
  { id: "c1", name: "Margot Ellison", company: "Ellison & Rao Partners", email: "margot@ellisonrao.com", phone: "+1 (415) 221-8844", website: "ellisonrao.com", address: "340 Pine St, San Francisco, CA 94104", totalBilled: 48500, invoiceCount: 7, since: "2023-03-12" },
  { id: "c2", name: "Theo Vandermeer", company: "Vandermeer Collective", email: "theo@vandermeer.co", phone: "+1 (212) 554-9012", website: "vandermeer.co", address: "120 W 20th St, New York, NY 10011", totalBilled: 31200, invoiceCount: 5, since: "2023-07-04" },
  { id: "c3", name: "Priya Nair", company: "Nair Studio", email: "priya@nairstudio.in", phone: "+91 98765 43210", website: "nairstudio.in", address: "12 MG Road, Bangalore 560001, India", totalBilled: 19750, invoiceCount: 3, since: "2024-01-18" },
  { id: "c4", name: "Felix Okafor", company: "Okafor Digital", email: "felix@okafordigital.ng", phone: "+234 812 345 6789", website: "okafordigital.ng", address: "15 Admiralty Way, Lagos, Nigeria", totalBilled: 12300, invoiceCount: 4, since: "2023-11-02" },
  { id: "c5", name: "Camille Renaud", company: "Studio Renaud", email: "camille@studiorenaud.fr", phone: "+33 6 12 34 56 78", website: "studiorenaud.fr", address: "45 Rue du Faubourg, Paris 75008, France", totalBilled: 27900, invoiceCount: 6, since: "2023-05-29" },
];

const INVOICES: Invoice[] = [
  { id: "i1", number: "INV-0041", clientId: "c1", status: "paid", issueDate: "2024-11-01", dueDate: "2024-11-30", items: [{ description: "Brand Identity System", qty: 1, rate: 8500 }, { description: "Style Guide Documentation", qty: 1, rate: 2000 }], notes: "Thank you for your continued partnership.", tax: 8 },
  { id: "i2", number: "INV-0042", clientId: "c2", status: "sent", issueDate: "2024-11-15", dueDate: "2024-12-15", items: [{ description: "UI/UX Design — Phase 1", qty: 1, rate: 6200 }, { description: "Prototype & Testing", qty: 1, rate: 1800 }], notes: "Net 30 payment terms apply.", tax: 0 },
  { id: "i3", number: "INV-0043", clientId: "c5", status: "overdue", issueDate: "2024-10-10", dueDate: "2024-11-10", items: [{ description: "Web Development", qty: 80, rate: 120 }, { description: "CMS Integration", qty: 1, rate: 2400 }], notes: "Please process at your earliest convenience.", tax: 0 },
  { id: "i4", number: "INV-0044", clientId: "c3", status: "draft", issueDate: "2024-11-22", dueDate: "2024-12-22", items: [{ description: "Motion Graphics Package", qty: 3, rate: 2200 }], notes: "", tax: 18 },
  { id: "i5", number: "INV-0045", clientId: "c4", status: "paid", issueDate: "2024-11-05", dueDate: "2024-12-05", items: [{ description: "SEO Audit & Strategy", qty: 1, rate: 3400 }, { description: "Content Roadmap", qty: 1, rate: 900 }], notes: "", tax: 0 },
  { id: "i6", number: "INV-0046", clientId: "c1", status: "sent", issueDate: "2024-11-28", dueDate: "2024-12-28", items: [{ description: "Annual Retainer — Q1 2025", qty: 1, rate: 12000 }], notes: "Retainer covers 40 hours/month.", tax: 8 },
];

const REVENUE_DATA = [
  { month: "Jun", revenue: 14200, invoices: 4 },
  { month: "Jul", revenue: 18900, invoices: 6 },
  { month: "Aug", revenue: 12400, invoices: 3 },
  { month: "Sep", revenue: 22100, invoices: 7 },
  { month: "Oct", revenue: 17800, invoices: 5 },
  { month: "Nov", revenue: 31500, invoices: 9 },
];

// ─── Utilities ────────────────────────────────────────────────────────────────

const fmt = (n: number) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n);

const invoiceTotal = (inv: Invoice) => {
  const sub = inv.items.reduce((s, it) => s + it.qty * it.rate, 0);
  return sub + (sub * inv.tax) / 100;
};

const statusColors: Record<Invoice["status"], string> = {
  draft: "text-muted-foreground bg-muted",
  sent: "text-blue-300 bg-blue-950/60",
  paid: "text-emerald-300 bg-emerald-950/60",
  overdue: "text-red-300 bg-red-950/60",
};

const statusDot: Record<Invoice["status"], string> = {
  draft: "bg-muted-foreground",
  sent: "bg-blue-400",
  paid: "bg-emerald-400",
  overdue: "bg-red-400",
};

// ─── Components ───────────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: Invoice["status"] }) {
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-mono uppercase tracking-wider ${statusColors[status]}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${statusDot[status]}`} />
      {status}
    </span>
  );
}

function StatCard({ label, value, sub, icon: Icon, trend }: { label: string; value: string; sub?: string; icon: React.ElementType; trend?: "up" | "down" }) {
  return (
    <div className="bg-card border border-border rounded-lg p-5 flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <span className="text-xs font-mono text-muted-foreground uppercase tracking-widest">{label}</span>
        <div className="w-8 h-8 rounded-md bg-muted flex items-center justify-center">
          <Icon size={14} className="text-primary" />
        </div>
      </div>
      <div>
        <p className="text-2xl font-display font-light text-foreground">{value}</p>
        {sub && (
          <p className={`text-xs mt-1 flex items-center gap-1 ${trend === "up" ? "text-emerald-400" : trend === "down" ? "text-red-400" : "text-muted-foreground"}`}>
            {trend === "up" && <ArrowUpRight size={12} />}
            {trend === "down" && <ArrowDownRight size={12} />}
            {sub}
          </p>
        )}
      </div>
    </div>
  );
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

function Sidebar({ view, setView }: { view: View; setView: (v: View) => void }) {
  const nav = [
    { id: "dashboard" as View, label: "Dashboard", icon: LayoutDashboard },
    { id: "invoices" as View, label: "Invoices", icon: FileText },
    { id: "clients" as View, label: "Clients", icon: Users },
  ];

  return (
    <aside className="w-56 shrink-0 flex flex-col bg-sidebar border-r border-sidebar-border h-screen sticky top-0">
      <div className="px-5 pt-6 pb-4 border-b border-sidebar-border">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-md bg-primary flex items-center justify-center">
            <FileText size={13} className="text-primary-foreground" />
          </div>
          <span className="font-display text-foreground font-light tracking-wide">Ledger</span>
        </div>
        <p className="text-[10px] font-mono text-muted-foreground mt-1 tracking-widest uppercase">Invoicing Platform</p>
      </div>

      <nav className="flex-1 px-3 py-4 flex flex-col gap-0.5">
        {nav.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setView(id)}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-md text-sm transition-colors ${
              view === id || (view === "invoice-detail" && id === "invoices") || (view === "client-detail" && id === "clients")
                ? "bg-sidebar-accent text-foreground"
                : "text-muted-foreground hover:text-foreground hover:bg-sidebar-accent/60"
            }`}
          >
            <Icon size={15} />
            {label}
          </button>
        ))}
      </nav>

      <div className="px-3 pb-4">
        <button
          onClick={() => setView("create-invoice")}
          className="w-full flex items-center justify-center gap-2 bg-primary text-primary-foreground px-3 py-2.5 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          <Plus size={14} />
          New Invoice
        </button>
      </div>

      <div className="px-4 py-3 border-t border-sidebar-border">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-full bg-secondary flex items-center justify-center text-xs font-mono text-muted-foreground">AK</div>
          <div>
            <p className="text-xs text-foreground font-medium">Alex Kim</p>
            <p className="text-[10px] text-muted-foreground">alex@studiokim.co</p>
          </div>
        </div>
      </div>
    </aside>
  );
}

// ─── Dashboard View ───────────────────────────────────────────────────────────

function Dashboard({ setView, setSelectedInvoice }: { setView: (v: View) => void; setSelectedInvoice: (id: string) => void }) {
  const paid = INVOICES.filter(i => i.status === "paid").reduce((s, i) => s + invoiceTotal(i), 0);
  const outstanding = INVOICES.filter(i => i.status === "sent").reduce((s, i) => s + invoiceTotal(i), 0);
  const overdue = INVOICES.filter(i => i.status === "overdue").reduce((s, i) => s + invoiceTotal(i), 0);
  const recent = [...INVOICES].sort((a, b) => b.issueDate.localeCompare(a.issueDate)).slice(0, 5);

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload?.length) {
      return (
        <div className="bg-popover border border-border rounded-md px-3 py-2 text-xs font-mono">
          <p className="text-muted-foreground mb-1">{label}</p>
          <p className="text-primary">{fmt(payload[0]?.value)}</p>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="flex flex-col gap-6 p-7 max-w-5xl">
      <div>
        <h1 className="font-display font-light text-2xl text-foreground">Overview</h1>
        <p className="text-sm text-muted-foreground mt-0.5 font-mono">November 2024</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Collected" value={fmt(paid)} sub="+12% vs last month" icon={CheckCircle} trend="up" />
        <StatCard label="Outstanding" value={fmt(outstanding)} sub={`${INVOICES.filter(i => i.status === "sent").length} invoices`} icon={Clock} />
        <StatCard label="Overdue" value={fmt(overdue)} sub="Requires attention" icon={AlertCircle} trend="down" />
        <StatCard label="Avg. Invoice" value={fmt(paid / Math.max(INVOICES.filter(i => i.status === "paid").length, 1))} sub="This month" icon={TrendingUp} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 bg-card border border-border rounded-lg p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest">Revenue</p>
              <p className="font-display font-light text-xl text-foreground mt-0.5">6-Month Trend</p>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={180}>
            <AreaChart data={REVENUE_DATA} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#c9a84c" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#c9a84c" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(232,228,220,0.06)" />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: "#7a7870", fontFamily: "Geist Mono" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#7a7870", fontFamily: "Geist Mono" }} axisLine={false} tickLine={false} tickFormatter={v => `$${(v / 1000).toFixed(0)}k`} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="revenue" stroke="#c9a84c" strokeWidth={1.5} fill="url(#revGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-card border border-border rounded-lg p-5">
          <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-4">By Status</p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={[
              { name: "Paid", value: INVOICES.filter(i => i.status === "paid").length },
              { name: "Sent", value: INVOICES.filter(i => i.status === "sent").length },
              { name: "Draft", value: INVOICES.filter(i => i.status === "draft").length },
              { name: "Overdue", value: INVOICES.filter(i => i.status === "overdue").length },
            ]} margin={{ top: 0, right: 0, left: -25, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(232,228,220,0.06)" />
              <XAxis dataKey="name" tick={{ fontSize: 10, fill: "#7a7870", fontFamily: "Geist Mono" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 10, fill: "#7a7870", fontFamily: "Geist Mono" }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="value" fill="#c9a84c" radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="bg-card border border-border rounded-lg">
        <div className="px-5 py-4 border-b border-border flex items-center justify-between">
          <p className="text-sm font-medium text-foreground">Recent Invoices</p>
          <button onClick={() => setView("invoices")} className="text-xs text-muted-foreground hover:text-primary transition-colors flex items-center gap-1">
            View all <ChevronRight size={12} />
          </button>
        </div>
        <div className="divide-y divide-border">
          {recent.map(inv => {
            const client = CLIENTS.find(c => c.id === inv.clientId)!;
            return (
              <button
                key={inv.id}
                onClick={() => { setSelectedInvoice(inv.id); setView("invoice-detail"); }}
                className="w-full flex items-center justify-between px-5 py-3.5 hover:bg-muted/40 transition-colors text-left"
              >
                <div className="flex items-center gap-4">
                  <span className="font-mono text-xs text-muted-foreground w-20">{inv.number}</span>
                  <span className="text-sm text-foreground">{client.company}</span>
                </div>
                <div className="flex items-center gap-5">
                  <StatusBadge status={inv.status} />
                  <span className="font-mono text-sm text-foreground w-20 text-right">{fmt(invoiceTotal(inv))}</span>
                  <span className="text-xs text-muted-foreground w-20 text-right">{inv.dueDate}</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ─── Invoices View ────────────────────────────────────────────────────────────

function InvoicesView({ setView, setSelectedInvoice }: { setView: (v: View) => void; setSelectedInvoice: (id: string) => void }) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<Invoice["status"] | "all">("all");

  const filtered = useMemo(() =>
    INVOICES.filter(inv => {
      const client = CLIENTS.find(c => c.id === inv.clientId)!;
      const matchSearch = inv.number.toLowerCase().includes(search.toLowerCase()) || client.company.toLowerCase().includes(search.toLowerCase());
      const matchStatus = statusFilter === "all" || inv.status === statusFilter;
      return matchSearch && matchStatus;
    }).sort((a, b) => b.issueDate.localeCompare(a.issueDate)),
    [search, statusFilter]
  );

  return (
    <div className="flex flex-col gap-6 p-7 max-w-5xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display font-light text-2xl text-foreground">Invoices</h1>
          <p className="text-sm text-muted-foreground mt-0.5 font-mono">{INVOICES.length} total</p>
        </div>
        <button onClick={() => setView("create-invoice")} className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors">
          <Plus size={14} /> New Invoice
        </button>
      </div>

      <div className="flex gap-3">
        <div className="relative flex-1">
          <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search invoices or clients…"
            className="w-full bg-input-background border border-border rounded-md pl-9 pr-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
          />
        </div>
        <div className="flex gap-1.5">
          {(["all", "draft", "sent", "paid", "overdue"] as const).map(s => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 py-2 rounded-md text-xs font-mono uppercase tracking-wide transition-colors ${statusFilter === s ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:text-foreground"}`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-card border border-border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border">
              <th className="text-left px-5 py-3 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Number</th>
              <th className="text-left px-5 py-3 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Client</th>
              <th className="text-left px-5 py-3 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Status</th>
              <th className="text-left px-5 py-3 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Issued</th>
              <th className="text-left px-5 py-3 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Due</th>
              <th className="text-right px-5 py-3 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Amount</th>
              <th className="px-5 py-3 w-10" />
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.map(inv => {
              const client = CLIENTS.find(c => c.id === inv.clientId)!;
              return (
                <tr
                  key={inv.id}
                  onClick={() => { setSelectedInvoice(inv.id); setView("invoice-detail"); }}
                  className="hover:bg-muted/40 cursor-pointer transition-colors"
                >
                  <td className="px-5 py-3.5 font-mono text-xs text-muted-foreground">{inv.number}</td>
                  <td className="px-5 py-3.5">
                    <div>
                      <p className="text-foreground">{client.company}</p>
                      <p className="text-xs text-muted-foreground">{client.name}</p>
                    </div>
                  </td>
                  <td className="px-5 py-3.5"><StatusBadge status={inv.status} /></td>
                  <td className="px-5 py-3.5 font-mono text-xs text-muted-foreground">{inv.issueDate}</td>
                  <td className="px-5 py-3.5 font-mono text-xs text-muted-foreground">{inv.dueDate}</td>
                  <td className="px-5 py-3.5 font-mono text-sm text-foreground text-right">{fmt(invoiceTotal(inv))}</td>
                  <td className="px-5 py-3.5 text-center">
                    <button className="text-muted-foreground hover:text-foreground transition-colors" onClick={e => e.stopPropagation()}>
                      <MoreHorizontal size={14} />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="py-12 text-center text-muted-foreground text-sm font-mono">No invoices match your filters</div>
        )}
      </div>
    </div>
  );
}

// ─── Invoice Detail View ──────────────────────────────────────────────────────

function InvoiceDetail({ invoiceId, setView }: { invoiceId: string; setView: (v: View) => void }) {
  const [paymentModal, setPaymentModal] = useState(false);
  const [paid, setPaid] = useState(false);
  const inv = INVOICES.find(i => i.id === invoiceId)!;
  const client = CLIENTS.find(c => c.id === inv.clientId)!;
  const subtotal = inv.items.reduce((s, it) => s + it.qty * it.rate, 0);
  const taxAmt = (subtotal * inv.tax) / 100;
  const total = subtotal + taxAmt;
  const currentStatus = paid ? "paid" : inv.status;

  return (
    <div className="flex flex-col gap-6 p-7 max-w-4xl">
      <div className="flex items-center gap-3 text-sm text-muted-foreground">
        <button onClick={() => setView("invoices")} className="hover:text-foreground transition-colors">Invoices</button>
        <ChevronRight size={12} />
        <span className="text-foreground font-mono">{inv.number}</span>
      </div>

      <div className="flex items-start justify-between">
        <div>
          <h1 className="font-display font-light text-2xl text-foreground">{inv.number}</h1>
          <div className="flex items-center gap-3 mt-2">
            <StatusBadge status={currentStatus as Invoice["status"]} />
            <span className="text-sm text-muted-foreground font-mono">Due {inv.dueDate}</span>
          </div>
        </div>
        <div className="flex gap-2">
          <button className="flex items-center gap-2 bg-muted text-foreground px-3 py-2 rounded-md text-sm hover:bg-secondary transition-colors">
            <Download size={13} /> Export PDF
          </button>
          <button className="flex items-center gap-2 bg-muted text-foreground px-3 py-2 rounded-md text-sm hover:bg-secondary transition-colors">
            <Send size={13} /> Send
          </button>
          {currentStatus !== "paid" && (
            <button
              onClick={() => setPaymentModal(true)}
              className="flex items-center gap-2 bg-primary text-primary-foreground px-3 py-2 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors"
            >
              <CreditCard size={13} /> Mark as Paid
            </button>
          )}
        </div>
      </div>

      <div className="bg-card border border-border rounded-lg overflow-hidden">
        <div className="p-7">
          <div className="flex items-start justify-between mb-8">
            <div>
              <div className="flex items-center gap-2 mb-3">
                <div className="w-6 h-6 rounded-sm bg-primary flex items-center justify-center">
                  <FileText size={11} className="text-primary-foreground" />
                </div>
                <span className="font-display text-foreground">Ledger</span>
              </div>
              <p className="text-xs font-mono text-muted-foreground">Alex Kim</p>
              <p className="text-xs font-mono text-muted-foreground">alex@studiokim.co</p>
              <p className="text-xs font-mono text-muted-foreground">San Francisco, CA</p>
            </div>
            <div className="text-right">
              <p className="font-display font-light text-3xl text-foreground">{fmt(total)}</p>
              <p className="text-xs font-mono text-muted-foreground mt-1">{inv.number}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-6 mb-8">
            <div>
              <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-2">Bill To</p>
              <p className="text-sm font-medium text-foreground">{client.company}</p>
              <p className="text-sm text-muted-foreground">{client.name}</p>
              <p className="text-sm text-muted-foreground">{client.email}</p>
            </div>
            <div className="text-right">
              <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-2">Dates</p>
              <p className="text-sm text-muted-foreground">Issued: <span className="text-foreground font-mono">{inv.issueDate}</span></p>
              <p className="text-sm text-muted-foreground">Due: <span className="text-foreground font-mono">{inv.dueDate}</span></p>
            </div>
          </div>

          <table className="w-full mb-6">
            <thead>
              <tr className="border-b border-border">
                <th className="text-left pb-2 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal">Description</th>
                <th className="text-right pb-2 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal w-16">Qty</th>
                <th className="text-right pb-2 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal w-24">Rate</th>
                <th className="text-right pb-2 text-xs font-mono text-muted-foreground uppercase tracking-widest font-normal w-24">Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {inv.items.map((item, i) => (
                <tr key={i}>
                  <td className="py-3 text-sm text-foreground">{item.description}</td>
                  <td className="py-3 text-sm font-mono text-muted-foreground text-right">{item.qty}</td>
                  <td className="py-3 text-sm font-mono text-muted-foreground text-right">{fmt(item.rate)}</td>
                  <td className="py-3 text-sm font-mono text-foreground text-right">{fmt(item.qty * item.rate)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="flex justify-end">
            <div className="w-56 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Subtotal</span>
                <span className="font-mono text-foreground">{fmt(subtotal)}</span>
              </div>
              {inv.tax > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Tax ({inv.tax}%)</span>
                  <span className="font-mono text-foreground">{fmt(taxAmt)}</span>
                </div>
              )}
              <div className="flex justify-between pt-2 border-t border-border">
                <span className="font-medium text-foreground">Total</span>
                <span className="font-mono font-medium text-primary">{fmt(total)}</span>
              </div>
            </div>
          </div>

          {inv.notes && (
            <div className="mt-6 pt-5 border-t border-border">
              <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5">Notes</p>
              <p className="text-sm text-muted-foreground">{inv.notes}</p>
            </div>
          )}
        </div>
      </div>

      {paymentModal && (
        <PaymentModal
          total={total}
          invoiceNumber={inv.number}
          onClose={() => setPaymentModal(false)}
          onConfirm={() => { setPaid(true); setPaymentModal(false); }}
        />
      )}
    </div>
  );
}

// ─── Payment Modal ────────────────────────────────────────────────────────────

function PaymentModal({ total, invoiceNumber, onClose, onConfirm }: { total: number; invoiceNumber: string; onClose: () => void; onConfirm: () => void }) {
  const [step, setStep] = useState<"form" | "success">("form");
  const [cardNum, setCardNum] = useState("");
  const [expiry, setExpiry] = useState("");
  const [cvc, setCvc] = useState("");

  const handlePay = () => {
    setStep("success");
    setTimeout(() => { onConfirm(); }, 1500);
  };

  const formatCard = (v: string) => v.replace(/\D/g, "").slice(0, 16).replace(/(.{4})/g, "$1 ").trim();
  const formatExpiry = (v: string) => {
    const d = v.replace(/\D/g, "").slice(0, 4);
    return d.length >= 2 ? `${d.slice(0, 2)}/${d.slice(2)}` : d;
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-popover border border-border rounded-xl w-full max-w-md shadow-2xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <div>
            <p className="text-sm font-medium text-foreground">Process Payment</p>
            <p className="text-xs font-mono text-muted-foreground">{invoiceNumber}</p>
          </div>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground transition-colors">
            <X size={16} />
          </button>
        </div>

        {step === "form" ? (
          <div className="p-6 space-y-4">
            <div className="bg-muted rounded-lg p-4 flex items-center justify-between">
              <span className="text-xs font-mono text-muted-foreground uppercase tracking-widest">Total Due</span>
              <span className="font-display font-light text-xl text-primary">{fmt(total)}</span>
            </div>

            <div className="bg-secondary/50 border border-border rounded-md px-3 py-2 text-xs text-muted-foreground font-mono flex items-center gap-2">
              <AlertCircle size={11} />
              Demo mode — no real charges processed
            </div>

            <div>
              <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">Card Number</label>
              <input
                value={cardNum}
                onChange={e => setCardNum(formatCard(e.target.value))}
                placeholder="4242 4242 4242 4242"
                className="w-full bg-input-background border border-border rounded-md px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring font-mono"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">Expiry</label>
                <input
                  value={expiry}
                  onChange={e => setExpiry(formatExpiry(e.target.value))}
                  placeholder="MM/YY"
                  className="w-full bg-input-background border border-border rounded-md px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring font-mono"
                />
              </div>
              <div>
                <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">CVC</label>
                <input
                  value={cvc}
                  onChange={e => setCvc(e.target.value.replace(/\D/g, "").slice(0, 4))}
                  placeholder="123"
                  className="w-full bg-input-background border border-border rounded-md px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring font-mono"
                />
              </div>
            </div>

            <button
              onClick={handlePay}
              className="w-full bg-primary text-primary-foreground py-2.5 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors flex items-center justify-center gap-2 mt-2"
            >
              <CreditCard size={14} />
              Pay {fmt(total)}
            </button>
          </div>
        ) : (
          <div className="p-8 text-center">
            <div className="w-12 h-12 rounded-full bg-emerald-950/60 border border-emerald-800/40 flex items-center justify-center mx-auto mb-3">
              <CheckCircle size={20} className="text-emerald-400" />
            </div>
            <p className="font-display font-light text-lg text-foreground">Payment Processed</p>
            <p className="text-sm text-muted-foreground mt-1 font-mono">{fmt(total)} received</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Create Invoice View ──────────────────────────────────────────────────────

function CreateInvoice({ setView }: { setView: (v: View) => void }) {
  const [clientId, setClientId] = useState("");
  const [items, setItems] = useState<InvoiceItem[]>([{ description: "", qty: 1, rate: 0 }]);
  const [dueDate, setDueDate] = useState("");
  const [notes, setNotes] = useState("");
  const [tax, setTax] = useState(0);
  const [saved, setSaved] = useState(false);

  const subtotal = items.reduce((s, it) => s + it.qty * it.rate, 0);
  const taxAmt = (subtotal * tax) / 100;
  const total = subtotal + taxAmt;

  const addItem = () => setItems(prev => [...prev, { description: "", qty: 1, rate: 0 }]);
  const removeItem = (i: number) => setItems(prev => prev.filter((_, idx) => idx !== i));
  const updateItem = (i: number, field: keyof InvoiceItem, val: string | number) =>
    setItems(prev => prev.map((it, idx) => idx === i ? { ...it, [field]: val } : it));

  const handleSave = () => { setSaved(true); setTimeout(() => setView("invoices"), 1000); };

  return (
    <div className="flex flex-col gap-6 p-7 max-w-3xl">
      <div className="flex items-center gap-3 text-sm text-muted-foreground">
        <button onClick={() => setView("invoices")} className="hover:text-foreground transition-colors">Invoices</button>
        <ChevronRight size={12} />
        <span className="text-foreground">New Invoice</span>
      </div>

      <h1 className="font-display font-light text-2xl text-foreground">Create Invoice</h1>

      <div className="bg-card border border-border rounded-lg p-6 space-y-5">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">Client</label>
            <select
              value={clientId}
              onChange={e => setClientId(e.target.value)}
              className="w-full bg-input-background border border-border rounded-md px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring appearance-none"
            >
              <option value="">Select a client…</option>
              {CLIENTS.map(c => <option key={c.id} value={c.id}>{c.company}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">Due Date</label>
            <input
              type="date"
              value={dueDate}
              onChange={e => setDueDate(e.target.value)}
              className="w-full bg-input-background border border-border rounded-md px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring"
            />
          </div>
        </div>

        <div>
          <div className="flex items-center justify-between mb-3">
            <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest">Line Items</label>
          </div>
          <div className="space-y-2">
            <div className="grid grid-cols-12 gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest px-1">
              <span className="col-span-6">Description</span>
              <span className="col-span-2 text-right">Qty</span>
              <span className="col-span-3 text-right">Rate</span>
              <span className="col-span-1" />
            </div>
            {items.map((item, i) => (
              <div key={i} className="grid grid-cols-12 gap-2">
                <input
                  value={item.description}
                  onChange={e => updateItem(i, "description", e.target.value)}
                  placeholder="Service or product…"
                  className="col-span-6 bg-input-background border border-border rounded-md px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
                />
                <input
                  type="number"
                  value={item.qty}
                  onChange={e => updateItem(i, "qty", Number(e.target.value))}
                  className="col-span-2 bg-input-background border border-border rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring font-mono text-right"
                />
                <input
                  type="number"
                  value={item.rate}
                  onChange={e => updateItem(i, "rate", Number(e.target.value))}
                  className="col-span-3 bg-input-background border border-border rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring font-mono text-right"
                />
                <button onClick={() => removeItem(i)} className="col-span-1 flex items-center justify-center text-muted-foreground hover:text-destructive transition-colors">
                  <X size={13} />
                </button>
              </div>
            ))}
            <button onClick={addItem} className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors mt-1">
              <Plus size={13} /> Add line item
            </button>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 pt-2 border-t border-border">
          <div>
            <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">Notes</label>
            <textarea
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="Payment terms, thank you note…"
              rows={3}
              className="w-full bg-input-background border border-border rounded-md px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring resize-none"
            />
          </div>
          <div className="space-y-3">
            <div>
              <label className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-1.5 block">Tax (%)</label>
              <input
                type="number"
                value={tax}
                onChange={e => setTax(Number(e.target.value))}
                className="w-full bg-input-background border border-border rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring font-mono"
              />
            </div>
            <div className="bg-muted rounded-md p-3 space-y-1.5">
              <div className="flex justify-between text-xs">
                <span className="text-muted-foreground font-mono">Subtotal</span>
                <span className="font-mono text-foreground">{fmt(subtotal)}</span>
              </div>
              {tax > 0 && (
                <div className="flex justify-between text-xs">
                  <span className="text-muted-foreground font-mono">Tax ({tax}%)</span>
                  <span className="font-mono text-foreground">{fmt(taxAmt)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm pt-1.5 border-t border-border">
                <span className="font-medium text-foreground">Total</span>
                <span className="font-mono font-medium text-primary">{fmt(total)}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-end gap-3">
        <button onClick={() => setView("invoices")} className="px-4 py-2 rounded-md text-sm text-muted-foreground hover:text-foreground transition-colors">
          Cancel
        </button>
        <button className="flex items-center gap-2 bg-muted text-foreground px-4 py-2 rounded-md text-sm hover:bg-secondary transition-colors">
          Save as Draft
        </button>
        <button
          onClick={handleSave}
          className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          {saved ? <CheckCircle size={13} /> : <Send size={13} />}
          {saved ? "Saved!" : "Create & Send"}
        </button>
      </div>
    </div>
  );
}

// ─── Clients View ─────────────────────────────────────────────────────────────

function ClientsView({ setView, setSelectedClient }: { setView: (v: View) => void; setSelectedClient: (id: string) => void }) {
  const [search, setSearch] = useState("");
  const filtered = CLIENTS.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.company.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-6 p-7 max-w-5xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display font-light text-2xl text-foreground">Clients</h1>
          <p className="text-sm text-muted-foreground mt-0.5 font-mono">{CLIENTS.length} clients</p>
        </div>
        <button className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors">
          <Plus size={14} /> New Client
        </button>
      </div>

      <div className="relative max-w-sm">
        <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search clients…"
          className="w-full bg-input-background border border-border rounded-md pl-9 pr-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.map(client => {
          const clientInvoices = INVOICES.filter(i => i.clientId === client.id);
          const outstanding = clientInvoices.filter(i => i.status === "sent").reduce((s, i) => s + invoiceTotal(i), 0);
          return (
            <button
              key={client.id}
              onClick={() => { setSelectedClient(client.id); setView("client-detail"); }}
              className="bg-card border border-border rounded-lg p-5 text-left hover:border-primary/30 hover:bg-muted/30 transition-all group"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center mb-2 text-xs font-mono font-medium text-muted-foreground group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                    {client.company.slice(0, 2).toUpperCase()}
                  </div>
                  <p className="font-medium text-foreground">{client.company}</p>
                  <p className="text-sm text-muted-foreground">{client.name}</p>
                </div>
                <ChevronRight size={14} className="text-muted-foreground group-hover:text-primary transition-colors mt-1" />
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-3">
                <Mail size={11} />
                <span className="font-mono">{client.email}</span>
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-border">
                <div>
                  <p className="text-xs font-mono text-muted-foreground">Total Billed</p>
                  <p className="font-mono text-sm text-foreground">{fmt(client.totalBilled)}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs font-mono text-muted-foreground">Outstanding</p>
                  <p className={`font-mono text-sm ${outstanding > 0 ? "text-primary" : "text-muted-foreground"}`}>{fmt(outstanding)}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs font-mono text-muted-foreground">Invoices</p>
                  <p className="font-mono text-sm text-foreground">{client.invoiceCount}</p>
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─── Client Detail View ───────────────────────────────────────────────────────

function ClientDetail({ clientId, setView, setSelectedInvoice }: { clientId: string; setView: (v: View) => void; setSelectedInvoice: (id: string) => void }) {
  const client = CLIENTS.find(c => c.id === clientId)!;
  const clientInvoices = INVOICES.filter(i => i.clientId === clientId);
  const totalPaid = clientInvoices.filter(i => i.status === "paid").reduce((s, i) => s + invoiceTotal(i), 0);

  return (
    <div className="flex flex-col gap-6 p-7 max-w-4xl">
      <div className="flex items-center gap-3 text-sm text-muted-foreground">
        <button onClick={() => setView("clients")} className="hover:text-foreground transition-colors">Clients</button>
        <ChevronRight size={12} />
        <span className="text-foreground">{client.company}</span>
      </div>

      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center text-sm font-mono font-medium text-muted-foreground">
            {client.company.slice(0, 2).toUpperCase()}
          </div>
          <div>
            <h1 className="font-display font-light text-2xl text-foreground">{client.company}</h1>
            <p className="text-sm text-muted-foreground mt-0.5">{client.name}</p>
          </div>
        </div>
        <button
          onClick={() => setView("create-invoice")}
          className="flex items-center gap-2 bg-primary text-primary-foreground px-3 py-2 rounded-md text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          <Plus size={13} /> New Invoice
        </button>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Total Billed" value={fmt(client.totalBilled)} icon={DollarSign} />
        <StatCard label="Collected" value={fmt(totalPaid)} icon={CheckCircle} />
        <StatCard label="Client Since" value={client.since} icon={Calendar} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-card border border-border rounded-lg p-5">
          <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-4">Contact</p>
          <div className="space-y-3">
            {[
              { icon: Mail, value: client.email },
              { icon: Phone, value: client.phone },
              { icon: Globe, value: client.website },
              { icon: Building2, value: client.address },
            ].map(({ icon: Icon, value }) => (
              <div key={value} className="flex items-center gap-3">
                <Icon size={13} className="text-muted-foreground shrink-0" />
                <span className="text-sm text-muted-foreground font-mono">{value}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-card border border-border rounded-lg p-5">
          <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-4">Invoices</p>
          <div className="space-y-2">
            {clientInvoices.map(inv => (
              <button
                key={inv.id}
                onClick={() => { setSelectedInvoice(inv.id); setView("invoice-detail"); }}
                className="w-full flex items-center justify-between py-2 border-b border-border/50 last:border-0 hover:text-primary transition-colors text-left"
              >
                <div className="flex items-center gap-3">
                  <span className="font-mono text-xs text-muted-foreground">{inv.number}</span>
                  <StatusBadge status={inv.status} />
                </div>
                <span className="font-mono text-sm text-foreground">{fmt(invoiceTotal(inv))}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── App ───────────────────────────────────────────────────────────────────────

export default function App() {
  const [view, setView] = useState<View>("dashboard");
  const [selectedInvoice, setSelectedInvoice] = useState("");
  const [selectedClient, setSelectedClient] = useState("");

  return (
    <div className="flex h-screen bg-background overflow-hidden" style={{ fontFamily: "var(--font-body)" }}>
      <Sidebar view={view} setView={setView} />
      <main className="flex-1 overflow-y-auto scrollbar-hide">
        {view === "dashboard" && <Dashboard setView={setView} setSelectedInvoice={setSelectedInvoice} />}
        {view === "invoices" && <InvoicesView setView={setView} setSelectedInvoice={setSelectedInvoice} />}
        {view === "invoice-detail" && <InvoiceDetail invoiceId={selectedInvoice} setView={setView} />}
        {view === "create-invoice" && <CreateInvoice setView={setView} />}
        {view === "clients" && <ClientsView setView={setView} setSelectedClient={setSelectedClient} />}
        {view === "client-detail" && <ClientDetail clientId={selectedClient} setView={setView} setSelectedInvoice={setSelectedInvoice} />}
      </main>
    </div>
  );
}
