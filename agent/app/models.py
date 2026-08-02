"""Agent modellari.

  • AgentOutput  — AI qaytaradigan strukturali JSON (Claude va Gemini bir xil sxema)
  • LeadInfo     — AgentOutput ichidagi lead ma'lumotlari
  • LeadPayload  — ERP `POST /leads/ingest` ga yuboriladigan JSON (ERP LeadIngest bilan mos)

Diqqat: strukturali chiqish sxemasida `minLength`/`ge`/`le` kabi cheklovlar
ISHLATILMAYDI — Claude structured outputs ularni qo'llab-quvvatlamaydi. Diapazonni
(masalan lead_score 0..100) Python tomonda klamplaymiz.
"""
from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class LeadInfo(BaseModel):
    """AI aniqlagan mijoz ma'lumotlari (barchasi ixtiyoriy)."""

    name: Optional[str] = Field(default=None, description="Mijoz ismi, aniqlansa")
    contact: Optional[str] = Field(
        default=None, description="Telefon raqami yoki username, mijoz bergan bo'lsa"
    )
    product_interest: Optional[str] = Field(
        default=None, description="Qiziqqan mahsulot/xizmat nomi"
    )
    summary: Optional[str] = Field(
        default=None, description="Suhbat qisqacha xulosasi (o'zbekcha)"
    )


class AgentOutput(BaseModel):
    """AI (sotuv agenti) qaytaradigan strukturali natija."""

    reply: str = Field(description="Mijozga yuboriladigan javob matni")
    language: str = Field(
        description="Mijoz tili/yozuvi: uz-Cyrl | uz-Latn | ru | en"
    )
    intent: str = Field(
        description=(
            "Mijoz niyati: greeting | price_question | product_question | "
            "buying_intent | complaint | spam | other"
        )
    )
    lead_score: int = Field(description="Lead qiymati 0..100 (100 = juda qaynoq)")
    is_hot_lead: bool = Field(
        description="Jiddiy xaridor belgilari bormi (narx so'radi, raqam qoldirdi va h.k.)"
    )
    move_to_dm: bool = Field(
        description="Ochiq kommentdan DM'ga o'tkazish kerakmi (shaxsiy ma'lumot uchun)"
    )
    escalate_to_human: bool = Field(
        description="Operatorga o'tkazish kerakmi (narxni bilmasa, murakkab holat, shikoyat)"
    )
    lead: LeadInfo = Field(default_factory=LeadInfo)

    def clamp(self) -> "AgentOutput":
        """Diapazon tashqarisidagi qiymatlarni to'g'rilaymiz."""
        self.lead_score = max(0, min(100, self.lead_score))
        return self


class LeadPayload(BaseModel):
    """ERP ingest JSON — `backend/app/schemas/lead.py::LeadIngest` bilan bir xil."""

    source: str = "instagram"
    ig_user_id: Optional[str] = None
    ig_username: Optional[str] = None
    media_id: Optional[str] = None
    comment_id: Optional[str] = None

    name: Optional[str] = None
    contact: Optional[str] = None
    product_interest: Optional[str] = None
    language: Optional[str] = None
    intent: Optional[str] = None
    lead_score: int = 0
    summary: Optional[str] = None

    message_text: Optional[str] = None
    agent_reply: Optional[str] = None
    extra: dict = Field(default_factory=dict)
