"""`python -m app.integrations.telegram` uchun kirish nuqtasi."""
import asyncio

from .bot import main

if __name__ == "__main__":
    asyncio.run(main())
