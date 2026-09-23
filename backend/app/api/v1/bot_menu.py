"""Telegram AI botining menyusi — bo'limlar (buyruq + matn + rasmlar).

Ikki xil kirish:
  • Xodim (`telegram` modul ruxsati) — bo'limlarni yaratish, tahrirlash,
    rasmlarni yuklash, tartibini o'zgartirish.
  • Tashqi agent (`X-Agent-Key`) — faol bo'limlarni va rasm baytlarini oladi.

Har o'zgarishdan keyin agentga «menyuni yangila» deb xabar beriladi (fon
rejimida, xato bo'lsa jim o'tadi) — agent baribir har 5 daqiqada o'zi ham
tortib oladi, shuning uchun agent o'chiq bo'lsa ham hech narsa buzilmaydi.
"""
from __future__ import annotations

import hashlib
import uuid
from typing import Annotated

from fastapi import (
    APIRouter, BackgroundTasks, Depends, File, HTTPException, Response, UploadFile,
)
from loguru import logger
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import undefer

from app.api.v1.leads import require_agent_key
from app.core.agent_client import agent_request
from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.bot_menu import (
    ALLOWED_IMAGE_TYPES, GREETING_KEY, MAX_IMAGE_BYTES, MAX_IMAGES_PER_ITEM,
    BotMenuImage, BotMenuItem,
)
from app.models.system import SystemSetting
from app.schemas.bot_menu import (
    AgentMenuImage, AgentMenuItem, AgentMenuOut, BotMenuItemCreate, BotMenuItemOut,
    BotMenuItemUpdate, BotMenuOut, GreetingIn, ReorderIn,
)

# Bot menyusi Telegram botining bir qismi — o'sha modul ruxsatidan foydalanamiz
router = APIRouter(dependencies=[Depends(module_guard("telegram"))])
agent_router = APIRouter()

DB = Annotated[AsyncSession, Depends(get_db)]


# ===========================================================================
# Yordamchilar
# ===========================================================================
async def _greeting(db: AsyncSession) -> str:
    row = await db.get(SystemSetting, GREETING_KEY)
    return (row.value or "") if row else ""


async def _get_item(db: AsyncSession, item_id: uuid.UUID) -> BotMenuItem:
    item = await db.get(BotMenuItem, item_id)
    if not item:
        raise HTTPException(404, "Bo'lim topilmadi")
    return item


async def _ensure_unique_command(
    db: AsyncSession, command: str, exclude_id: uuid.UUID | None = None
) -> None:
    q = select(BotMenuItem.id).where(BotMenuItem.command == command)
    if exclude_id:
        q = q.where(BotMenuItem.id != exclude_id)
    if (await db.execute(q)).first():
        raise HTTPException(409, f"/{command} buyrug'i allaqachon mavjud")


async def _ensure_unique_title(
    db: AsyncSession, title: str, exclude_id: uuid.UUID | None = None
) -> None:
    """Pastki klaviatura tugmasi nomi bo'yicha topiladi — ikkita bir xil nom bo'lmasin."""
    q = select(BotMenuItem.id).where(func.lower(BotMenuItem.title) == title.lower())
    if exclude_id:
        q = q.where(BotMenuItem.id != exclude_id)
    if (await db.execute(q)).first():
        raise HTTPException(409, f"«{title}» nomli tugma allaqachon mavjud")


async def _item_out(db: AsyncSession, item: BotMenuItem) -> BotMenuItemOut:
    # Server qiymatlari (vaqt) va rasmlar ro'yxati yuklash/o'chirishdan keyin yangilansin
    await db.refresh(item)
    return BotMenuItemOut.model_validate(item)


async def _notify_agent() -> None:
    """Agentga menyu o'zgarganini bildiradi. Xato bo'lsa — jim (5 daqiqada o'zi oladi)."""
    try:
        await agent_request("POST", "/admin/menu/refresh", timeout=5.0)
    except Exception as exc:  # noqa: BLE001
        logger.info("Agent menyuni darhol yangilamadi (5 daqiqada o'zi oladi): {}", exc)


# ===========================================================================
# Xodim: ko'rish va boshqarish
# ===========================================================================
@router.get("", response_model=BotMenuOut)
async def get_menu(db: DB, _: CurrentUser):
    items = (await db.execute(
        select(BotMenuItem).order_by(BotMenuItem.sort_order, BotMenuItem.created_at)
    )).scalars().all()
    return BotMenuOut(
        greeting=await _greeting(db),
        items=[BotMenuItemOut.model_validate(i) for i in items],
    )


@router.put("/greeting", response_model=BotMenuOut)
async def set_greeting(payload: GreetingIn, db: DB, user: CurrentUser,
                       background: BackgroundTasks):
    text = (payload.greeting or "").strip()
    if text:
        row = await db.get(SystemSetting, GREETING_KEY)
        if row:
            row.value = text
        else:
            db.add(SystemSetting(key=GREETING_KEY, value=text))
    else:
        await db.execute(delete(SystemSetting).where(SystemSetting.key == GREETING_KEY))
    await db.commit()
    background.add_task(_notify_agent)
    return await get_menu(db, user)


@router.post("/items", response_model=BotMenuItemOut, status_code=201)
async def create_item(payload: BotMenuItemCreate, db: DB, _: CurrentUser,
                      background: BackgroundTasks):
    await _ensure_unique_command(db, payload.command)
    await _ensure_unique_title(db, payload.title)
    last = (await db.execute(select(func.max(BotMenuItem.sort_order)))).scalar()
    item = BotMenuItem(
        command=payload.command,
        title=payload.title,
        text=(payload.text or "").strip() or None,
        is_active=payload.is_active,
        sort_order=(last or 0) + 1,
    )
    db.add(item)
    await db.commit()
    background.add_task(_notify_agent)
    return await _item_out(db, item)


@router.patch("/items/{item_id}", response_model=BotMenuItemOut)
async def update_item(item_id: uuid.UUID, payload: BotMenuItemUpdate, db: DB,
                      _: CurrentUser, background: BackgroundTasks):
    item = await _get_item(db, item_id)
    data = payload.model_dump(exclude_unset=True)
    if data.get("command") and data["command"] != item.command:
        await _ensure_unique_command(db, data["command"], exclude_id=item.id)
    if data.get("title") and data["title"].lower() != item.title.lower():
        await _ensure_unique_title(db, data["title"], exclude_id=item.id)
    for key in ("command", "title", "is_active"):
        if data.get(key) is not None:
            setattr(item, key, data[key])
    if "text" in data:
        item.text = (data["text"] or "").strip() or None
    await db.commit()
    background.add_task(_notify_agent)
    return await _item_out(db, item)


@router.delete("/items/{item_id}", status_code=204)
async def delete_item(item_id: uuid.UUID, db: DB, _: CurrentUser,
                      background: BackgroundTasks):
    item = await _get_item(db, item_id)
    await db.delete(item)
    await db.commit()
    background.add_task(_notify_agent)


@router.post("/reorder", response_model=BotMenuOut)
async def reorder_items(payload: ReorderIn, db: DB, user: CurrentUser,
                        background: BackgroundTasks):
    """Tugmalar tartibi — `ids` ro'yxatidagi ketma-ketlikda."""
    items = {
        i.id: i for i in (await db.execute(select(BotMenuItem))).scalars().all()
    }
    if set(payload.ids) != set(items) or len(payload.ids) != len(items):
        raise HTTPException(400, "Ro'yxat eskirgan — sahifani yangilang")
    for index, item_id in enumerate(payload.ids, start=1):
        items[item_id].sort_order = index
    await db.commit()
    background.add_task(_notify_agent)
    return await get_menu(db, user)


# ---- Rasmlar ----
@router.post("/items/{item_id}/images", response_model=BotMenuItemOut, status_code=201)
async def upload_image(
    item_id: uuid.UUID,
    file: Annotated[UploadFile, File(description="Rasm (JPEG/PNG/WEBP, <5MB)")],
    db: DB,
    _: CurrentUser,
    background: BackgroundTasks,
):
    # Qatorni qulflaymiz: bir vaqtda bir nechta rasm yuklansa ham 10 tadan oshmasin
    item = (await db.execute(
        select(BotMenuItem).where(BotMenuItem.id == item_id).with_for_update()
    )).scalar_one_or_none()
    if not item:
        raise HTTPException(404, "Bo'lim topilmadi")
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(400, f"Rasm formati qo'llab-quvvatlanmaydi: {file.content_type}")
    data = await file.read()
    if not data:
        raise HTTPException(400, "Fayl bo'sh")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(400, "Rasm 5 MB dan kichik bo'lishi kerak")
    count, last = (await db.execute(
        select(func.count(BotMenuImage.id), func.max(BotMenuImage.sort_order))
        .where(BotMenuImage.item_id == item.id)
    )).one()
    if count >= MAX_IMAGES_PER_ITEM:
        raise HTTPException(
            400, f"Bitta bo'limga ko'pi bilan {MAX_IMAGES_PER_ITEM} ta rasm (Telegram albomi chegarasi)"
        )

    db.add(BotMenuImage(
        item_id=item.id,
        content_type=file.content_type,
        size_bytes=len(data),
        sha256=hashlib.sha256(data).hexdigest(),
        sort_order=(last or 0) + 1,
        data=data,
    ))
    await db.commit()
    background.add_task(_notify_agent)
    return await _item_out(db, item)


@router.get("/images/{image_id}")
async def get_image(image_id: uuid.UUID, db: DB, _: CurrentUser):
    img = (await db.execute(
        select(BotMenuImage).where(BotMenuImage.id == image_id).options(undefer(BotMenuImage.data))
    )).scalar_one_or_none()
    if not img:
        raise HTTPException(404, "Rasm topilmadi")
    return Response(content=img.data, media_type=img.content_type,
                    headers={"Cache-Control": "private, max-age=300"})


@router.delete("/images/{image_id}", status_code=204)
async def delete_image(image_id: uuid.UUID, db: DB, _: CurrentUser,
                       background: BackgroundTasks):
    img = await db.get(BotMenuImage, image_id)
    if img:
        await db.delete(img)
        await db.commit()
        background.add_task(_notify_agent)


# ===========================================================================
# Tashqi agent (X-Agent-Key)
# ===========================================================================
@agent_router.get("/agent", response_model=AgentMenuOut,
                  dependencies=[Depends(require_agent_key)])
async def agent_menu(db: DB):
    """Faqat faol bo'limlar — botda ko'rinadigan tartibda."""
    items = (await db.execute(
        select(BotMenuItem)
        .where(BotMenuItem.is_active.is_(True))
        .order_by(BotMenuItem.sort_order, BotMenuItem.created_at)
    )).scalars().all()
    return AgentMenuOut(
        greeting=await _greeting(db),
        items=[
            AgentMenuItem(
                id=i.id, command=i.command, title=i.title, text=i.text or "",
                images=[AgentMenuImage(id=img.id, sha256=img.sha256,
                                       content_type=img.content_type)
                        for img in i.images],
            )
            for i in items
        ],
    )


@agent_router.get("/agent/images/{image_id}", dependencies=[Depends(require_agent_key)])
async def agent_image(image_id: uuid.UUID, db: DB):
    img = (await db.execute(
        select(BotMenuImage).where(BotMenuImage.id == image_id).options(undefer(BotMenuImage.data))
    )).scalar_one_or_none()
    if not img:
        raise HTTPException(404, "Rasm topilmadi")
    return Response(content=img.data, media_type=img.content_type)
