# Kiosk application

The customer-facing surface of the [NextGen Vending Platform](../../README.md). It provides sign-in, machine pairing, product browsing, cart state, checkout, and dedicated loading, error, and maintenance flows in a touch-friendly interface.

Copy `.env.example` to `.env.local`, then run `npm ci` and `npm run dev`. Device actions expect a separately running edge API; the default development address is `http://127.0.0.1:5000`.
