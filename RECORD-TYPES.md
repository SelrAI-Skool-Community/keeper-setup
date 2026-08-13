# Keeper record types — use the RIGHT type, never "Login" for everything⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

> **The mistake this prevents:** dumping every record in as `login`. Keeper filters and groups by record **TYPE** and by **TAGS**. A vault of 1,000 `login` records is one undifferentiated blob — you can't pull "all payment cards", "all tax docs", or "everything for Example Pty Ltd". Pick the type that matches the data, and tag it.

## Built-in record types (Keeper Business/Enterprise, AU + global)

`Login` · `Payment Card` · `Bank Account` · `Contact` · `Address` · `Driver's License` · `Passport` · `Identity Card` · `Birth Certificate` · `Health Insurance` · `Membership` · `Secure Note` · `Software License` · `SSH Key` · `Database` · `Server` · `Photo` · `File Attachment` · `Blank Type`

Plus **Custom Record Types**: Vault → record-type dropdown → *New Custom Record Type* → name it, pick a base type, add your own fields (text, hidden/secret, date, etc.).

## What goes where — the mapping (use this every time)

| The data | Record type |
|---|---|
| Website / app login | `Login` |
| Credit / debit card | `Payment Card` (number, expiry, CVV, cardholder, PIN) |
| Bank account (BSB / account no.) | `Bank Account` |
| API key / token / webhook secret | `Secure Note` (or custom `API Key`) — **not** Login |
| SSH private key | `SSH Key` |
| Server / VPS host creds | `Server` |
| Database connection | `Database` |
| Software / license key | `Software License` |
| Driver licence / passport / Medicare / ID | `Driver's License` / `Passport` / `Identity Card` / `Health Insurance` |
| A standalone document (PDF, scan) | `File Attachment` (attach the file) |
| Free-form secret / note | `Secure Note` |

## Custom record types for the AU businesses (create these)

**1. `AU Company`** — one per legal entity. Base: Blank. Fields:
- Legal Name (text) · Trading Name (text)
- ABN (text) · ACN (text)
- **TFN (hidden/secret)** · ASIC Corporate Key (hidden)
- GST Registered (date) · Entity Type (text) · Registered Address (address)
- Directors / Trustee (text) · Notes (multiline)
- File attachment (registration certificate / trust deed)

**2. `AU Tax Doc`** — base: File Attachment. Fields:
- Entity (text) · Doc Type (BAS / Return / PAYG / ATO Notice) · Period (text) · Date (date) · Amount (text) · File

(Keep it to these two custom types; everything else maps to a built-in above.)

## Tagging convention (this is what makes filtering work)

Tag **every** record with:
- the **entity** it belongs to — `example-pty-ltd`, `example-trust`, `example-holdings`, `personal`
- a **category** — `tax`, `banking`, `identifier`, `insurance`, `licence`, `card`, `api-key`, `login`

Then you filter by type ("all Payment Cards") AND tag ("everything example-pty-ltd") in two clicks.

## Naming convention

`Entity - Thing`  ->  `Example Pty Ltd - ABN`, `Example Trust - TFN`, `Example Holdings - Business Account 1234`.
So one entity's records sort together alphabetically.

## CLI surface (Commander)

- `keeper record-type-info`  (alias `rti`) — list all record types + their fields. **Run this first to see exact field names before adding records.**
- `keeper record-type-info --lr <name>` — show one type's layout.
- `keeper record-add --record-type "<type>" --title "<title>" "field=value" ...` — add a record OF A SPECIFIC TYPE.
- `keeper record-type-add` / `record-type-update` — create/update custom record types from JSON (verify exact flags with `keeper record-type-add --help`; the Vault UI is the reliable fallback for creating custom types).
- Tags: set on a record via `keeper record-update <uid> --tag <tag>` (verify flag) or in the UI.

> When unsure about field names or whether the CLI can create a custom type, the **Vault UI is authoritative** — create the custom type there from this spec, then file records into it.

## Hard rules (unchanged)

- **TFN, card numbers, PINs NEVER enter chat or email.** Agent creates the labelled empty record of the right type; the user types the secret value into Keeper.
- One record = one fact. ABN, TFN, GST each their own record, tagged + typed.
- PDFs go IN Keeper as `File Attachment` records (encrypted + searchable), not left loose on disk.

## Full custom-type catalogue

Built-ins cover: Login, Payment Card (bankCard), Bank Account, Secure Note (encryptedNotes), File (file), Driver's License, Passport, Identity Card, Health Insurance, Membership, SSH Key, Server, Database, Software License, Contact, Address, SSN (ssnCard), WiFi.

Suggested custom types, so data filters by type instead of one login blob:
1. `auCompany` - Legal Name, Trading Name, ABN, ACN, TFN(secret), ASIC Key(secret), GST date, Entity Type, address, file
2. `auTaxDoc` - Entity, Doc Type, Period, Date, Amount, file
3. `apiKey` - login, password(secret), url, file
4. `tfnPersonal` — Person, TFN(secret)
5. `medicareCard` — Medicare Number, IRN, Valid To(date), Name
6. `superannuation` — Fund Name, Member Number, USI, Fund ABN, url, login, password
7. `insurancePolicy` — Insurer, Policy Number, Cover Type, Premium, Renewal(date), url, file
8. `vehicle` — Make/Model, Registration, VIN, State, Rego Expiry(date), Insurer
9. `cryptoWallet` — Wallet/Exchange, Address, Seed Phrase(secret), Private Key(secret), url, 2FA
10. `domainName` — Domain, Registrar, Expiry(date), url, login, password
11. `subscription` — Service, Plan, Cost, Billing Cycle, Renewal(date), url, login, password
12. `loanFinance` — Lender, Account Number, Balance, Interest Rate, Term, url
13. `investmentAccount` — Platform, Account Number, Holdings, url, login, password

Create via `keeper record-type -a add --data '{"$id":"...","description":"...","fields":[{"$ref":"text|secret|date|url|login|password|fileRef|oneTimeCode","label":"...","required":bool}]}'`.

## Extended catalogue — full business + personal coverage (2026-06-23)
Use Keeper BUILT-INS for: cards (bankCard), bank accounts, birth certificates, passports, driver licenses, health insurance, membership, servers (serverCredentials), databases, SSH keys, software licenses, wifi, contacts, addresses, photos, secure notes, files, SSN/national-ID (ssnCard). Don't recreate those.
Custom types 14-20 (gaps built-ins don't cover):
14. `employeeRecord` — Name, Role, Email, Phone, TFN(secret), Super, Bank, Start Date, Emergency Contact, file
15. `supplierVendor` — Supplier Name, ABN, Email, Phone, Account Number, Payment Terms, url
16. `contractAgreement` — Title, Parties, Start, End, Value, file
17. `utilityAccount` — Provider, Account Number, Service Type, Supply Address, url, login, password, phone
18. `propertyAsset` — address, Title Reference, Purchase Date, Price, Mortgage/Lender, Council Ref, file
19. `warrantyItem` — Item, Brand/Model, Purchase Date, Warranty Expiry, Retailer, file
20. `equipmentAsset` — Item, Serial, Purchase Date, Assigned To/Location, Warranty Expiry, file
Full set = 20 custom types covering: entities, tax, API keys, IDs (TFN/Medicare), money (super/loans/crypto/investments), recurring (subscriptions/utilities/domains/insurance), people (employees/suppliers), assets (vehicles/property/equipment/warranties), contracts. Everything else uses a built-in.
(see RATE-LIMITS.md for Commander rate-limit discipline)

Router key `sk-9s9ef6` — resolved by the skills index on load.
