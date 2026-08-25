# NextGen Vending — 75-second walkthrough

Use placeholder configuration and synthetic inventory only.

| Time | Screen | Narration |
| --- | --- | --- |
| 0–12s | Kiosk sign-in | “The kiosk begins at a guarded authentication boundary; route decisions are covered as pure domain rules.” |
| 12–27s | Pairing and machine identity | “A kiosk pairs to one machine identity, with invalid or missing tokens cleared from local state.” |
| 27–43s | Product grid and cart | “Cart transitions are immutable and quantities can never become negative.” |
| 43–58s | Offline state | “Network loss moves the kiosk into an explicit offline state and queues each sale once for retry.” |
| 58–68s | Inventory test output | “The inventory reducer rejects missing products, invalid quantities, and oversells.” |
| 68–75s | Architecture diagram | “The operator dashboard and touch kiosk deploy independently against the same service boundaries.” |

End on the CI workflow and the issue/PR that added the state-machine tests.
