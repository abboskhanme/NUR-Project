# Assumptions

Decisions made without asking the user (question budget).

- [2026-09-05] Service list row colors: which statuses count as "unfinished"? -> new + scheduled = pink/red, completed = green, cancelled = neutral -> matches the existing "Servis muammolari" KPI card, which already counts new+scheduled as open
- [2026-09-14] Telegram bot menu: who may manage it? -> `telegram` module permission (read/write/delete), not super-admin -> same as the "WhatsApp navbati" page; content is marketing, not infrastructure
- [2026-09-14] Telegram bot menu in Business-connection chats: how does the customer see buttons? -> inline buttons under the greeting (shown on /start, /menu or the word "menyu"); typed /command also works -> Bot API forbids ReplyKeyboardMarkup for messages sent on behalf of a business account
- [2026-09-14] Should a menu tap be answered while the AI is paused for that chat (operator took over)? -> yes, menu replies ignore the pause -> it is an explicit customer request with fixed content, not an AI reply
- [2026-09-14] Where are menu images stored? -> BYTEA in `bot_menu_images`, agent caches Telegram file_id by sha256 -> same pattern as ProductImage/ChannelPost, no extra volume; file_id cache avoids re-uploading on every tap
- [2026-09-14] Greeting text storage -> `system_settings` key TG_MENU_GREETING (hidden, local), edited from the Bot menyusi page -> reuses the key-value table instead of a one-row table
