import { RefObject, useCallback, useEffect, useRef, useState } from 'react';

import { cn } from '@/lib/cn';

/**
 * Keng jadvallar uchun DOIM ko'rinib turadigan gorizontal scrollbar.
 *
 * Nativ scrollbar macOS'da (va Chrome 121+ da standart `scrollbar-*`
 * xossalari bilan) faqat aylantirganda ko'rinadi — sichqoncha bilan
 * ishlaydiganlar uchun noqulay. Shuning uchun bu yerda scrollbar o'zimiz
 * chiziladi: kenglik/holat kuzatilgan konteynerdan olinadi, tutgichni
 * sudrash yoki yo'lakka bosish konteynerni suradi.
 *
 * Odatda `sticky top-16` bilan jadval tepasiga qo'yiladi va sahifa
 * aylantirilganda ham ko'rinib turadi.
 */
export default function StickyScrollbar({
  targetRef, className, thickness = 14,
}: {
  /** Gorizontal aylanadigan konteyner (overflow-x-auto/scroll) */
  targetRef: RefObject<HTMLElement>;
  className?: string;
  thickness?: number;
}) {
  const trackRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ startX: number; startScroll: number } | null>(null);
  const [m, setM] = useState({ scrollLeft: 0, clientWidth: 0, scrollWidth: 0 });

  const measure = useCallback(() => {
    const el = targetRef.current;
    if (!el) return;
    setM({ scrollLeft: el.scrollLeft, clientWidth: el.clientWidth, scrollWidth: el.scrollWidth });
  }, [targetRef]);

  useEffect(() => {
    const el = targetRef.current;
    if (!el) return;
    measure();
    el.addEventListener('scroll', measure, { passive: true });
    // Konteyner va uning ichidagi jadval o'lchami o'zgarsa qayta o'lchaymiz
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    if (el.firstElementChild) ro.observe(el.firstElementChild);
    return () => { el.removeEventListener('scroll', measure); ro.disconnect(); };
  }, [targetRef, measure]);

  const maxScroll = Math.max(0, m.scrollWidth - m.clientWidth);
  const overflows = maxScroll > 1;
  const trackW = trackRef.current?.clientWidth ?? m.clientWidth;
  const thumbW = overflows
    ? Math.max(44, Math.round(trackW * (m.clientWidth / m.scrollWidth)))
    : 0;
  const thumbLeft = maxScroll > 0
    ? Math.round((m.scrollLeft / maxScroll) * (trackW - thumbW))
    : 0;

  /** Tutgich markazini bosilgan nuqtaga olib boradi. */
  function scrollToPointer(clientX: number) {
    const track = trackRef.current;
    const el = targetRef.current;
    if (!track || !el) return;
    const x = clientX - track.getBoundingClientRect().left - thumbW / 2;
    const ratio = trackW - thumbW > 0 ? x / (trackW - thumbW) : 0;
    el.scrollLeft = Math.min(maxScroll, Math.max(0, ratio * maxScroll));
  }

  function onThumbDown(e: React.PointerEvent<HTMLDivElement>) {
    e.preventDefault();
    e.stopPropagation();
    const el = targetRef.current;
    if (!el) return;
    dragRef.current = { startX: e.clientX, startScroll: el.scrollLeft };
    e.currentTarget.setPointerCapture(e.pointerId);
  }

  function onThumbMove(e: React.PointerEvent<HTMLDivElement>) {
    const drag = dragRef.current;
    const el = targetRef.current;
    if (!drag || !el) return;
    const span = trackW - thumbW;
    if (span <= 0) return;
    const delta = ((e.clientX - drag.startX) / span) * maxScroll;
    el.scrollLeft = Math.min(maxScroll, Math.max(0, drag.startScroll + delta));
  }

  function onThumbUp(e: React.PointerEvent<HTMLDivElement>) {
    dragRef.current = null;
    e.currentTarget.releasePointerCapture(e.pointerId);
  }

  if (!overflows) return null;

  return (
    <div className={cn('select-none', className)}>
      <div
        ref={trackRef}
        onPointerDown={(e) => scrollToPointer(e.clientX)}
        className="relative w-full rounded-full bg-black/[0.07] cursor-pointer"
        style={{ height: thickness }}
        role="scrollbar"
        aria-orientation="horizontal"
        aria-label="Jadvalni gorizontal aylantirish"
        aria-valuemin={0}
        aria-valuemax={maxScroll}
        aria-valuenow={Math.round(m.scrollLeft)}>
        <div
          onPointerDown={onThumbDown}
          onPointerMove={onThumbMove}
          onPointerUp={onThumbUp}
          onPointerCancel={onThumbUp}
          className="absolute top-0 rounded-full bg-ink/35 hover:bg-ink/50 active:bg-ink/60 transition-colors cursor-grab active:cursor-grabbing"
          style={{ height: thickness, width: thumbW, left: thumbLeft }}
        />
      </div>
    </div>
  );
}
