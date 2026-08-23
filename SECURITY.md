# Security notes

- Treat all local environment files as sensitive even when they contain public-client credentials.
- Use development-only Supabase projects when reviewing this portfolio clone.
- Never place a service-role key in either Vite application; browser bundles cannot protect server credentials.
- Keep authorization in database policies and trusted server/edge components, not in UI route guards alone.
- Rotate any credential immediately if it is accidentally committed, then remove it from Git history before publishing.

This repository is a portfolio snapshot, not a security disclosure channel for a deployed service.
