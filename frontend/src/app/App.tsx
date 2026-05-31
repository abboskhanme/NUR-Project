import { useEffect } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { api } from '@/api/client';
import { useAuthStore } from '@/stores/auth';

import LoginPage from '@/pages/LoginPage';
import AppLayout from '@/components/layout/AppLayout';
import DashboardPage from '@/pages/DashboardPage';
import OrdersPage from '@/pages/OrdersPage';
import OrderDetailPage from '@/pages/OrderDetailPage';
import QueuePage from '@/pages/QueuePage';
import CustomersPage from '@/pages/CustomersPage';
import CustomerDetailPage from '@/pages/CustomerDetailPage';
import ProductsPage from '@/pages/ProductsPage';
import ServicePage from '@/pages/ServicePage';
import FinancePage from '@/pages/FinancePage';
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
        <Route path="orders" element={<OrdersPage />} />
        <Route path="orders/:orderId" element={<OrderDetailPage />} />
        <Route path="queue" element={<QueuePage />} />
        <Route path="customers" element={<CustomersPage />} />
        <Route path="customers/:customerId" element={<CustomerDetailPage />} />
        <Route path="products" element={<ProductsPage />} />
        <Route path="service" element={<ServicePage />} />
        <Route path="finance" element={<FinancePage />} />
        <Route path="hr" element={<HRPage />} />
        <Route path="hr/:employeeId" element={<EmployeeDetailPage />} />
        <Route path="supply" element={<SupplyPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="settings" element={<SettingsPage />} />
        <Route path="users" element={<UsersPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
