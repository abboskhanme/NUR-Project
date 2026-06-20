"""Products catalog + inventory."""
import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, Response, UploadFile
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.order import OrderItem
from app.models.product import Inventory, Product, ProductImage
from app.schemas.common import Page
from app.schemas.product import (
    InventoryCreate, InventoryOut,
    ProductCreate, ProductOut, ProductUpdate,
)

router = APIRouter(dependencies=[Depends(module_guard("products"))])

ALLOWED_IMAGE_TYPES = {"image/png", "image/jpeg", "image/jpg", "image/webp", "image/gif"}
MAX_IMAGE_BYTES = 5 * 1024 * 1024


# ---- Products ----
def _validate_product(product_type: str, model, name):
    """Tur bo'yicha majburiy maydonlarni tekshirish."""
    if product_type in ("main", "warehouse") and not model:
        raise HTTPException(422, "Asosiy mahsulot uchun model majburiy")
    if product_type == "additional" and not name:
        raise HTTPException(422, "Qo'shimcha mahsulot uchun nom majburiy")


async def _image_ids(db: AsyncSession, product_ids: list[uuid.UUID]) -> set[uuid.UUID]:
    """Rasmi bor mahsulot ID'lari — og'ir BYTEA data yuklamasdan (faqat kalit)."""
    if not product_ids:
        return set()
    rows = await db.execute(
        select(ProductImage.product_id).where(ProductImage.product_id.in_(product_ids))
    )
    return set(rows.scalars().all())


def _out_with_image(p: Product, has_image: bool) -> ProductOut:
    po = ProductOut.model_validate(p)
    po.has_image = has_image
    return po


@router.get("", response_model=Page[ProductOut])
async def list_products(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                        page: int = Query(1, ge=1), page_size: int = Query(50, ge=1, le=200),
                        product_type: Optional[str] = None,
                        model: Optional[str] = None, search: Optional[str] = None,
                        status: Optional[str] = "active"):
    q = select(Product)
    if product_type:
        q = q.where(Product.product_type == product_type)
    if model:
        q = q.where(Product.model == model)
    if search:
        like = f"%{search}%"
        q = q.where((Product.model.ilike(like)) | (Product.name.ilike(like)))
    if status:
        q = q.where(Product.status == status)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    res = await db.execute(
        q.order_by(Product.product_type, Product.model, Product.name, Product.kvm)
        .offset((page - 1) * page_size).limit(page_size)
    )
    items = res.scalars().all()
    have = await _image_ids(db, [p.id for p in items])
    return Page[ProductOut](
        items=[_out_with_image(p, p.id in have) for p in items],
        total=total, page=page, page_size=page_size)


@router.post("", response_model=ProductOut, status_code=201)
async def create_product(payload: ProductCreate, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    _validate_product(payload.product_type, payload.model, payload.name)
    p = Product(**payload.model_dump())
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return p


@router.patch("/{product_id}", response_model=ProductOut)
async def update_product(product_id: uuid.UUID, payload: ProductUpdate, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Product).where(Product.id == product_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    data = payload.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(p, k, v)
    _validate_product(p.product_type, p.model, p.name)
    await db.commit()
    await db.refresh(p)
    return _out_with_image(p, bool(await _image_ids(db, [p.id])))


@router.delete("/{product_id}", status_code=204)
async def delete_product(product_id: uuid.UUID, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    """Buyurtmada ishlatilmagan bo'lsa o'chiradi, aks holda arxivlaydi."""
    res = await db.execute(select(Product).where(Product.id == product_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    used = (await db.execute(
        select(func.count()).select_from(OrderItem).where(OrderItem.product_id == product_id)
    )).scalar() or 0
    if used:
        p.status = "archived"
    else:
        await db.delete(p)
    await db.commit()


# ---- Mahsulot rasmi (BYTEA, 1 mahsulot — 1 rasm) ----
@router.post("/{product_id}/image", response_model=ProductOut)
async def upload_product_image(
    product_id: uuid.UUID,
    file: Annotated[UploadFile, File(description="Mahsulot rasmi (PNG/JPEG/WEBP, <5MB)")],
    _: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = (await db.execute(select(Product).where(Product.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(400, f"Rasm formati qo'llab-quvvatlanmaydi: {file.content_type}")
    data = await file.read()
    if len(data) == 0:
        raise HTTPException(400, "Fayl bo'sh")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(400, "Rasm 5 MB dan kichik bo'lishi kerak")

    img = (await db.execute(
        select(ProductImage).where(ProductImage.product_id == product_id))).scalar_one_or_none()
    if img is None:
        img = ProductImage(product_id=product_id, content_type=file.content_type,
                           size_bytes=len(data), data=data)
        db.add(img)
    else:
        img.content_type = file.content_type
        img.size_bytes = len(data)
        img.data = data
    await db.commit()
    return _out_with_image(p, True)


@router.get("/{product_id}/image")
async def get_product_image(product_id: uuid.UUID, _: CurrentUser,
                            db: Annotated[AsyncSession, Depends(get_db)]):
    img = (await db.execute(
        select(ProductImage).where(ProductImage.product_id == product_id))).scalar_one_or_none()
    if not img:
        raise HTTPException(404, "Rasm mavjud emas")
    return Response(content=img.data, media_type=img.content_type,
                    headers={"Cache-Control": "private, max-age=300"})


@router.delete("/{product_id}/image", status_code=204)
async def delete_product_image(product_id: uuid.UUID, _: CurrentUser,
                               db: Annotated[AsyncSession, Depends(get_db)]):
    img = (await db.execute(
        select(ProductImage).where(ProductImage.product_id == product_id))).scalar_one_or_none()
    if img:
        await db.delete(img)
    await db.commit()


# ---- Inventory (SKLAD KATYOL) ----
@router.get("/inventory/list", response_model=list[InventoryOut])
async def list_inventory(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                         status: Optional[str] = "available"):
    q = select(Inventory)
    if status:
        q = q.where(Inventory.status == status)
    res = await db.execute(q.order_by(Inventory.added_date.desc()))
    return [InventoryOut.model_validate(i) for i in res.scalars().all()]


@router.post("/inventory", response_model=InventoryOut, status_code=201)
async def add_inventory(payload: InventoryCreate, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    inv = Inventory(**payload.model_dump())
    db.add(inv)
    await db.commit()
    await db.refresh(inv)
    return inv
