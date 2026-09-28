# Identity documents — regional OCR routes & custom models

Status: **code implemented, custom models NOT trained.** Last updated 2026-09-27.

This extends the passport OCR check described in
[`mobile-phase-6-identity-verification.md`](mobile-phase-6-identity-verification.md)
("Real OCR document check") to Egyptian and Saudi identity documents. Read that
section first — matching, storage, encryption and retention are unchanged.

---

## 1. What reads what

The guest **selects** the document type. The backend never guesses it from the
photo.

```
IdentityVerificationService ── IdentityDocumentCheckService
                                        │
                     IdentityDocumentProviderInterface
                                        │
                         DocumentProviderRouter  (production)
                                        │  by IdentityDocumentType
     ┌──────────────────┬───────────────┼────────────────┬─────────────────────┐
  PASSPORT     EGYPTIAN_NATIONAL_ID  SAUDI_NATIONAL_ID  SAUDI_IQAMA     other_id (legacy)
     │                  │                   │                │                  │
 prebuilt-idDocument  custom model      custom model     custom model    prebuilt-idDocument
 AZURE_DI_PASSPORT_   AZURE_DI_EGYPT_   AZURE_DI_SAUDI_  AZURE_DI_SAUDI_
 MODEL                ID_MODEL          ID_MODEL         IQAMA_MODEL
     │                  │                   │                │
 PrebuiltIdDocument   EgyptianNational   SaudiIdentityCard SaudiIdentityCard
 Mapper + MRZ         IdMapper           Mapper(national)  Mapper(iqama)
```

- **One HTTP adapter** (`AzureDocumentIntelligenceProvider::analyze(model, …)`)
  serves every model. **Field mappers** turn each model's output into the
  neutral `ExtractedIdentityDocument`. The mapper for a custom model defines
  its labeling contract (§4).
- **Front and back** are two separate analyze operations. Each one is deleted
  from Azure right after extraction (`{model}/{resultId}` references). Any that
  can't be deleted are retried hourly by `identity:purge-ocr-artifacts`.
- **The router has no path to the dummy provider.** The dummy is bound only
  when `IDENTITY_DOCUMENT_PROVIDER=dummy`, and it is refused when
  `APP_ENV=production`.
- **Missing or disabled model.** The route returns `not_configured`. The check
  becomes **NEEDS_REVIEW** (`provider_not_configured`), every such upload logs
  an **error**, and nothing is ever verified automatically.
  `php artisan identity:document-providers` lists every route and exits with
  code 1 when an enabled route has no model.
- **Adding a country or document** takes four things, all without changing the
  workflow:
  1. a new `IdentityDocumentType` case;
  2. a `document_types.<type>` config block;
  3. a mapper;
  4. optionally, national-number rules.

## 2. Support status per document type

| Type | Route | Code | Real model trained | Real document processed | Auto-verify |
|---|---|---|---|---|---|
| Passport | Azure `prebuilt-idDocument` (Microsoft-documented, worldwide passports) + our MRZ check digits | **IMPLEMENTED** | n/a (prebuilt) | **NOT TESTED** live (no credentials) | on (MRZ required) |
| Egyptian National ID | custom model `AZURE_DI_EGYPT_ID_MODEL` | **IMPLEMENTED** (router, mapper, rules, API, app) | **NO** | **NO** | **off** → manual review |
| Saudi National ID | custom model `AZURE_DI_SAUDI_ID_MODEL` | **IMPLEMENTED** | **NO** | **NO** | **off** → manual review |
| Saudi Iqama | custom model `AZURE_DI_SAUDI_IQAMA_MODEL` | **IMPLEMENTED** | **NO** | **NO** | **off** → manual review |

Microsoft does **not** document Egyptian or Saudi identity cards as supported
by the prebuilt ID model. Their only listed "worldwide" coverage is passports.
Printed Arabic **is** documented for both custom template and custom neural
models (v4.0), which is why these types use custom models.

Until each custom model is trained and evaluated (§6–7), every Egyptian or
Saudi upload ends in **manual review** at best, even when every field matches.
That is the intended safe behaviour.

## 3. Deterministic rules (supplementary only)

A valid number structure is **not** proof that a document is genuine.

- **Egyptian national number** — 14 digits:
  - `C YYMMDD GG SSSS K`;
  - century `2` = 1900s, `3` = 2000s;
  - the birth date must be a real date and not in the future;
  - governorate `01–35` or `88`;
  - gender = parity of the 13th digit.
  - The card prints **no separate date of birth**: it is derived from the
    number, never invented.
  - The printed gender and any printed date are cross-checked against the
    number.
  - The check digit is **not** validated: its algorithm isn't officially
    published.
- **Saudi numbers** — 10 digits:
  - prefix `1` = National ID, `2` = Iqama;
  - a wrong prefix for the selected type → review.
  - A Luhn-style checksum is described only by third parties, so it is **not
    enforced**.
- **Dates** — Arabic-Indic, Persian and Western digits are all accepted.
  - Layouts: `YYYY/MM/DD` or `DD/MM/YYYY`.
  - Hijri (a year from 1300 to 1500, or a `هـ` marker) is converted with ICU
    **Umm al-Qura**.
- **Names** — Arabic normalization folds only spelling variants: hamza forms
  of alef, ة/ه, ى/ي, tashkeel, tatweel, `ال` spacing, `بن`.
  - An Arabic token counts as a strong match **only if it is identical** after
    that normalization. محمد ≠ محمود and احمد ≠ حامد (these become weak →
    review).
  - Arabic is **never transliterated**. An Arabic claim against Latin-only OCR
    (or the reverse) → NEEDS_REVIEW.
  - Saudi cards that print both scripts are compared in the guest's script.
- **Decision order:** OCR_FAILED → DOCUMENT_UNSUPPORTED (incl. a different
  document than selected) → DOCUMENT_EXPIRED (against check-in) → MISMATCH →
  NEEDS_REVIEW → VERIFIED. A route with `auto_verify=false` cannot reach
  VERIFIED.

## 4. Labeling contract (field names the models must be trained with)

Label **only** these fields. Leave everything else unlabeled: religion, marital
status, profession and employer are deliberately never extracted.

**Egyptian National ID** (front + back labeled in the same project)

| Side | Field label | Content |
|---|---|---|
| front | `FirstName` | first name line |
| front | `FamilyNames` | second name line (father / grandfather / family) |
| front | `FullName` | *(alternative)* the whole name as one field |
| front | `Address` | address lines (read, never stored) |
| front | `NationalIdNumber` | 14-digit number (Arabic-Indic digits as printed) |
| back | `NationalIdNumber` | the repeated number (front/back cross-check) |
| back | `Gender` | النوع |
| back | `ExpiryDate` | البطاقة سارية حتى |
| back | `IssuingAuthority` | *(optional)* issuing office |

**Saudi National ID** — `FullNameArabic`, `FullNameLatin` (if printed),
`IdNumber`, `DateOfBirth`, `ExpiryDate`, and `Nationality` only if that card
version prints it.

**Saudi Iqama** — `FullNameArabic`, `FullNameLatin` (if printed),
`IqamaNumber`, `Nationality`, `DateOfBirth` (if printed), `ExpiryDate`.

Keep dates exactly as printed (Hijri or Gregorian). The backend converts them.

The Saudi National ID and the Iqama are **separate models**. Their layouts and
schemas differ; do not train one model for both.

## 5. Dataset requirements

**Never commit, upload to public storage, screenshot, log or put in test
fixtures any real person's identity document.** Use only data you are legally
authorized to process. Prefer:

- specimen cards;
- consented, anonymized, redacted samples (faces, names and numbers replaced
  with synthetic values);
- synthetic renders.

Keep a written authorization record per dataset.

| | Egyptian ID | Saudi National ID | Saudi Iqama |
|---|---|---|---|
| Minimum to train (Azure) | 5 labeled per side | 5 labeled | 5 labeled |
| Recommended before enabling auto-verify | **≥ 50 per side** | **≥ 50** | **≥ 50** |
| Card versions | every version in circulation | old and new (2021+) designs | old and new "resident identity" designs |

Each dataset should cover:

- **Diversity:**
  - lighting: daylight, indoor warm, low light, flash glare;
  - rotation: ±5–15°, plus upside-down images to confirm rejection;
  - blur: light motion blur and focus blur;
  - backgrounds: table, hand-held, patterned surfaces;
  - phone cameras: several models at different resolutions;
  - crops: partial and tight.
- **Content:**
  - short and long Arabic names, compound names (عبد …, ال …), names with
    hamza, ة and ى;
  - Arabic-Indic and Western digits;
  - Hijri and Gregorian dates;
  - many different number patterns: all Egyptian governorate codes you
    expect, both centuries, both genders.
- **Negative samples** (for evaluation only, not labeled as the positive type):
  passports, driver licences, the other Saudi card, screenshots and
  photos-of-screens.

**Staging layout.** This is a local, git-ignored curation area. The real
training set lives in a private Azure Blob container, not on the app server:

```
backend/storage/app/private/identity-training/   (git-ignored by storage/app/.gitignore)
    egypt/{front,back}/
    saudi-national-id/{front,back}/
    saudi-iqama/{front,back}/
    AUTHORIZATION.md      ← who authorized which data, when, for what
```

## 6. Azure setup (production)

1. **Resource.** Create an Azure AI Document Intelligence (Foundry) resource on
   the **S0** tier (F0 caps files at 4 MB and pages at 2) in the region closest
   to your data-residency requirement.
   - UAE North is the nearest generally available region to KSA/Egypt.
   - Confirm current regional availability and custom-model support there
     before committing.
2. **Network and keys.**
   - Restrict the resource to your backend's egress IPs (or use a private
     endpoint).
   - Prefer Managed Identity / Entra ID auth later. For now the key lives only
     in the backend env and is rotated regularly.
3. **Storage.**
   - Create a private Blob container per dataset: no public access,
     encryption at rest, lifecycle deletion after training.
   - Upload the authorized training images there. Grant the Document
     Intelligence resource read access (SAS or managed identity).
4. **Project.** In Document Intelligence Studio → Custom extraction model,
   create one project per document type: `egypt-id`, `saudi-national-id`,
   `saudi-iqama`.
5. **Build mode.**
   - **Template** suits fixed layouts like these cards and trains fast.
   - Use **neural** if the dataset shows significant layout variation between
     card versions.
   - Both support printed Arabic.
6. **Label** exactly the §4 field names (case-sensitive). Label front and back
   pages in the same project.
7. **Train** with an explicit model id, e.g. `egypt-id-2026-10-01`. Ids must
   match `^[A-Za-z0-9][A-Za-z0-9._~-]{1,63}$`.
8. **Evaluate** on a held-out set that was **not** used for training:
   - field-level accuracy for every labeled field;
   - confidence distribution;
   - the negative samples;
   - the end-to-end test in §7.
   - Set the acceptance bar before looking at results (e.g. ≥ 98% exact
     number, ≥ 97% name, ≥ 98% expiry).
9. **Configure Laravel** (backend env only, never in the app):
   ```
   IDENTITY_DOCUMENT_PROVIDER=azure_document_intelligence
   AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://<resource>.cognitiveservices.azure.com
   AZURE_DOCUMENT_INTELLIGENCE_KEY=<key>
   AZURE_DI_PASSPORT_MODEL=prebuilt-idDocument
   AZURE_DI_EGYPT_ID_MODEL=egypt-id-2026-10-01
   AZURE_DI_SAUDI_ID_MODEL=saudi-id-2026-10-01
   AZURE_DI_SAUDI_IQAMA_MODEL=saudi-iqama-2026-10-01
   # keep these false until §7 passes for that type:
   IDENTITY_DOC_EGYPT_ID_AUTO_VERIFY=false
   IDENTITY_DOC_SAUDI_ID_AUTO_VERIFY=false
   IDENTITY_DOC_SAUDI_IQAMA_AUTO_VERIFY=false
   ```
   Then run `php artisan config:cache && php artisan identity:document-providers`.
   The command must exit 0.
10. **Deploy.**
    - Make sure the scheduler runs `identity:purge-ocr-artifacts` (hourly) and
      `identity:purge-expired-images` (daily).
    - Watch the `identity.document_check` logs: `provider_status`, `status`,
      reason codes and durations. Values are never logged.
11. **Monitor.** Alert on:
    - any `identity.document_check` **error** (`auth_error`, `provider_error`,
      `not_configured`, `model_not_found`);
    - a rising `ocr_failed` or `needs_review` rate per `document_type`;
    - p95 duration;
    - pending artifacts reported by the hourly job.
12. **Retention.**
    - Azure keeps analysis input and output for 24 h unless deleted. The app
      calls *Delete Analyze Result* immediately after each analysis and
      retries hourly.
    - App-side images stay encrypted and are purged 30 days after the stay at
      most.
    - Delete the training Blob container once the model is trained, unless your
      authorization covers keeping it.

**Replace or retrain a model without a code change.** Train a new model id,
evaluate it (§8), then change the `AZURE_DI_*_MODEL` env var and re-cache
config. Roll back by restoring the previous id. Delete the old model on Azure
after the new one is confirmed.

## 7. Before enabling `auto_verify` for a type

Run the live test with the new model and a **synthetic or authorized** sample:

```
AZURE_DI_LIVE_TEST=1 AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=… AZURE_DOCUMENT_INTELLIGENCE_KEY=… \
AZURE_DI_SAMPLE_PASSPORT=/abs/path/specimen.jpg php artisan test --filter AzureDocumentIntelligenceLiveTest
```

Then run the mobile live journey (`test/_e2e/live_journey_test.dart`) against
a staging backend configured with the real models. Record the results,
including false accepts and false rejects on the held-out set. Only then
flip `IDENTITY_DOC_<TYPE>_AUTO_VERIFY=true`.

A per-type live test for the custom models needs an authorized sample and is
**not yet written or run**. There is no trained model to run it against.

## 8. What this does NOT do

- **Authenticity.** OCR and custom extraction read a document. They do **not**
  prove that it is genuine, unedited, or that it belongs to the person holding
  it. No authenticity or tamper check exists. Check-digit and structure rules
  only catch typos and naive edits.
- **Face match** is still the **dummy** provider.
- **Liveness** is **not implemented**.

These remain separate pipeline stages: document OCR → document matching →
*document authenticity* → *face match* → *liveness*. Until the last three are
real, manual review and the in-person check at reception remain the actual
identity control.
