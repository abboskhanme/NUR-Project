"""Gemini provayder — google-genai, response_schema bilan strukturali JSON.

Arzon/tez (gemini-2.5-flash) — dastlabki test uchun qulay. Bilim tizim
ko'rsatmasida (system_instruction) uzatiladi.
"""
from __future__ import annotations

from google import genai
from google.genai import types

from app.ai.base import AIProvider, T
from app.config import settings


class GeminiProvider(AIProvider):
    def __init__(self) -> None:
        if not settings.GEMINI_API_KEY:
            raise RuntimeError("GEMINI_API_KEY o'rnatilmagan (AI_PROVIDER=gemini)")
        self._client = genai.Client(api_key=settings.GEMINI_API_KEY)

    async def generate(
        self, system: str, messages: list[dict], output_model: type[T]
    ) -> T:
        contents = [
            types.Content(
                # Gemini rollari: "user" | "model" (assistant -> model)
                role="model" if m["role"] == "assistant" else "user",
                parts=[types.Part(text=m["content"])],
            )
            for m in messages
        ]
        response = await self._client.aio.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system,
                max_output_tokens=settings.AI_MAX_TOKENS,
                response_mime_type="application/json",
                response_schema=output_model,
            ),
        )
        parsed = getattr(response, "parsed", None)
        if isinstance(parsed, output_model):
            return parsed
        # Fallback: xom JSON matnini validatsiya qilamiz
        return output_model.model_validate_json(response.text)
