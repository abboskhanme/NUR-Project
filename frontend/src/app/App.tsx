import { useEffect } from 'react';
import { Navigate, Route, Routes, useParams } from 'react-router-dom';
import { api } from '@/api/client';
import { useAuthStore } from '@/stores/auth';
import { usePermissions } from '@/lib/permissions';
import { useNavItems } from '@/components/layout/navItems';

import LoginPage from '@/pages/LoginPage';
import AppLayout from '@/components/layout/AppLayout';
import DashboardPage from '@/pages/DashboardPage';
import OrdersPage from '@/pages/OrdersPage';
import OrderDetailPage from '@/pages/OrderDetailPage';
import QueuePage from '@/pages/QueuePage';
import CustomersPage from '@/pages/CustomersPage';
import CustomerDetailPage from '@/pages/CustomerDetailPage';
import ProductsPage from '@/pages/ProductsPage';
import WarehousePage from '@/pages/WarehousePage';
import ProductionPage from '@/pages/ProductionPage';
import ServicePage from '@/pages/ServicePage';
import FinancePage from '@/pages/FinancePage';
import DebtsPage from '@/pages/DebtsPage';
import TargetsPage from '@/pages/TargetsPage';
import ShippingPage from '@/pages/ShippingPage';
import HRPage from '@/pages/HRPage';
import EmployeeDetailPage from '@/pages/EmployeeDetailPage';
import TaminotPage from '@/pages/TaminotPage';
import ReportsPage from '@/pages/ReportsPage';
import SettingsPage from '@/pages/SettingsPage';
import UsersPage from '@/pages/UsersPage';

function RequireAuth({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.accessToken);
  if (!token) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

/** Modulga ruxsati yo'q foydalanuvchini bosh sahifaga qaytaradi. */
function RequireModule({ module, children }: { module: string; children: React.ReactNode }) {
  const { canModule } = usePermissions();
  if (!canModule(module)) return <Navigate to="/" replace />;
  return <>{children}</>;
}

/**
 * Ta'minot: ichki/tashqi alohida ruxsat. URL scope'iga qarab `supply_<scope>`
 * modulini tekshiradi. Noto'g'ri scope yoki ruxsat yo'q bo'lsa — bosh sahifaga.
 */
function RequireTaminot({ children }: { children: React.ReactNode }) {
  const { scope } = useParams();
  const { canModule } = usePermissions();
  if (scope !== 'ichki' && scope !== 'tashqi') return <Navigate to="/" replace />;
  if (!canModule(`supply_${scope}`)) return <Navigate to="/" replace />;
  return <>{children}</>;
}

/** /supply — foydalanuvchi kira oladigan birinchi ta'minot turiga yo'naltiradi. */
function SupplyIndexRedirect() {
  const { canModule } = usePermissions();
  if (canModule('supply_ichki')) return <Navigate to="/supply/ichki" replace />;
  if (canModule('supply_tashqi')) return <Navigate to="/supply/tashqi" replace />;
  return <Navigate to="/" replace />;
}

/**
 * Bosh sahifa "hisobotlar" (reports) moduliga bog'langan. Ruxsat bo'lsa — dashboard;
 * bo'lmasa — foydalanuvchining birinchi mavjud bo'limiga yo'naltiramiz (sikldan saqlanish
 * uchun "/" ga qaytarmaymiz).
 */
function HomeRoute() {
  const { canModule } = usePermissions();
  const navItems = useNavItems();
  if (canModule('reports')) return <DashboardPage />;
  const first = navItems.find((it) => it.to !== '/');
  return <Navigate to={first?.to ?? '/settings'} replace />;
}

/**
 * Token bo'lsa, har bir sahifa yuklanganda /auth/me ni chaqirib
 * persisted user ma'lumotini eng so'nggi versiyaga yangilaymiz.
 * Bu avatar_url va boshqa eski cache'lar bilan bog'liq muammolarni hal qiladi.
 */
function useRefreshUserOnBoot() {
  const token = useAuthStore((s) => s.accessToken);
  const setUser = useAuthStore((s) => s.setUser);
  useEffect(() => {
    if (!token) return;
    api.get('/auth/me')
      .then((r) => setUser(r.data))
      .catch(() => {/* 401 bo'lsa interceptor refresh qiladi */});
  }, [token]);
}

export default function App() {
  useRefreshUserOnBoot();
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <RequireAuth>
            <AppLayout />
          </RequireAuth>
        }
      >
        <Route index element={<HomeRoute />} />
        <Route path="orders" element={<RequireModule module="orders"><OrdersPage /></RequireModule>} />
        <Route path="orders/:orderId" element={<RequireModule module="orders"><OrderDetailPage /></RequireModule>} />
        <Route path="queue" element={<RequireModule module="orders"><QueuePage /></RequireModule>} />
        <Route path="customers" element={<RequireModule module="customers"><CustomersPage /></RequireModule>} />
        <Route path="customers/:customerId" element={<RequireModule module="customers"><CustomerDetailPage /></RequireModule>} />
        <Route path="products" element={<RequireModule module="products"><ProductsPage /></RequireModule>} />
        <Route path="warehouse" element={<RequireModule module="inventory"><WarehousePage /></RequireModule>} />
        <Route path="production" element={<RequireModule module="production"><ProductionPage /></RequireModule>} />
        <Route path="service" element={<RequireModule module="service"><ServicePage /></RequireModule>} />
        <Route path="finance" element={<RequireModule module="finance"><FinancePage /></RequireModule>} />
        <Route path="debts" element={<RequireModule module="debts"><DebtsPage /></RequireModule>} />
        <Route path="targets" element={<RequireModule module="targets"><TargetsPage /></RequireModule>} />
        <Route path="shipping" element={<RequireModule module="shipping"><ShippingPage /></RequireModule>} />
        <Route path="hr" element={<RequireModule module="hr"><HRPage /></RequireModule>} />
        <Route path="hr/:employeeId" element={<RequireModule module="hr"><EmployeeDetailPage /></RequireModule>} />
        <Route path="supply" element={<SupplyIndexRedirect />} />
        <Route path="supply/:scope" element={<RequireTaminot><TaminotPage /></RequireTaminot>} />
        <Route path="reports" element={<RequireModule module="reports"><ReportsPage /></RequireModule>} />
        <Route path="settings" element={<SettingsPage />} />
        <Route path="users" element={<RequireModule module="users"><UsersPage /></RequireModule>} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
