import { useEffect } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { api } from '@/api/client';
import { useAuthStore } from '@/stores/auth';
import { usePermissions } from '@/lib/permissions';

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
import ServicePage from '@/pages/ServicePage';
import FinancePage from '@/pages/FinancePage';
import DebtsPage from '@/pages/DebtsPage';
import HRPage from '@/pages/HRPage';
import EmployeeDetailPage from '@/pages/EmployeeDetailPage';
import SupplyPage from '@/pages/SupplyPage';
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
        <Route index element={<DashboardPage />} />
        <Route path="orders" element={<RequireModule module="orders"><OrdersPage /></RequireModule>} />
        <Route path="orders/:orderId" element={<RequireModule module="orders"><OrderDetailPage /></RequireModule>} />
        <Route path="queue" element={<RequireModule module="orders"><QueuePage /></RequireModule>} />
        <Route path="customers" element={<RequireModule module="customers"><CustomersPage /></RequireModule>} />
        <Route path="customers/:customerId" element={<RequireModule module="customers"><CustomerDetailPage /></RequireModule>} />
        <Route path="products" element={<RequireModule module="products"><ProductsPage /></RequireModule>} />
        <Route path="warehouse" element={<RequireModule module="inventory"><WarehousePage /></RequireModule>} />
        <Route path="service" element={<RequireModule module="service"><ServicePage /></RequireModule>} />
        <Route path="finance" element={<RequireModule module="finance"><FinancePage /></RequireModule>} />
        <Route path="debts" element={<RequireModule module="debts"><DebtsPage /></RequireModule>} />
        <Route path="hr" element={<RequireModule module="hr"><HRPage /></RequireModule>} />
        <Route path="hr/:employeeId" element={<RequireModule module="hr"><EmployeeDetailPage /></RequireModule>} />
        <Route path="supply" element={<RequireModule module="supply"><SupplyPage /></RequireModule>} />
        <Route path="reports" element={<RequireModule module="reports"><ReportsPage /></RequireModule>} />
        <Route path="settings" element={<SettingsPage />} />
        <Route path="users" element={<RequireModule module="users"><UsersPage /></RequireModule>} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
