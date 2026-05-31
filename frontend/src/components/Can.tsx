import { ReactNode } from 'react';
import { usePermissions } from '@/lib/permissions';

/**
 * Permission-guarded wrapper. Berilgan ruxsat bo'lmasa, hech narsa render qilmaydi.
 *
 * Misol:
 *   <Can perm="finance:write">
 *     <button>Yangi to'lov</button>
 *   </Can>
 *
 *   <Can anyOf={["users:write", "users:delete"]}>...</Can>
 *
 *   <Can perm="reports:export" fallback={<span>Ruxsat yo'q</span>}>
 *     <button>Eksport</button>
 *   </Can>
 */
export default function Can({
  perm,
  anyOf,
  allOf,
  fallback = null,
  children,
}: {
  perm?: string;
  anyOf?: string[];
  allOf?: string[];
  fallback?: ReactNode;
  children: ReactNode;
}) {
  const { can, canAny, canAll } = usePermissions();
  let allowed = true;
  if (perm) allowed = allowed && can(perm);
  if (anyOf && anyOf.length > 0) allowed = allowed && canAny(...anyOf);
  if (allOf && allOf.length > 0) allowed = allowed && canAll(...allOf);
  if (!allowed) return <>{fallback}</>;
  return <>{children}</>;
}
