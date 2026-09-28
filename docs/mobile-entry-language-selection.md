# Mobile — Entry splash & language selection (`01 · Entry`)

The first-run entry sequence (**v2 Figma**, Phase B — 2026-09-24):

```
splash (AuthSplashPage)  →  language sheet over the splash (LanguageSelectionPage)
                         →  onboarding (EntryWelcomePage)  →  discover …
```

This follows the v2 prototype links in `Design/hotel_guest_app.fig`:
`ENTRY_Splash` opens the language `sheet` as a **centred modal overlay**
(AFTER_TIMEOUT 1.6s, default Center position, black @25% background); both language
buttons navigate to `ENTRY_Onboarding`; its CTA goes to `HOME_Default`. The v1
standalone `ENTRY_Language` screen no longer exists in the Figma.

> **Deferred auth** (`mobile-deferred-auth.md`): onboarding's CTA opens
> `/discover`, not sign-in. Browsing is public; the phone/OTP/profile surface is
> reached on demand from the "confirm" step of a booking (or the discover
> app-bar sign-in action).

## Screens

| Route | Widget | v2 frame | Notes |
|---|---|---|---|
| `/` | `AuthSplashPage` | `ENTRY_Splash` (board 14) | White field; 120px two-tone brand mark, 5px gap, `Hotel System` wordmark (`title-lg` 24/36 Bold) — centred. No tagline, no spinner. Held for `splashMinDurationProvider` (**1.6s** — the Figma `ENTRY_Splash` AFTER_TIMEOUT) while the stored session restores (`AuthState.unknown`). |
| `/welcome/language` | `LanguageSelectionPage` | language `sheet` (board 14) | The **same splash composition** under a black @25% scrim with the sheet centred on it as a modal (see below). |
| `/welcome` | `EntryWelcomePage` | `ENTRY_Onboarding` (board 01) | Full-bleed photo + one glass card (see below). |

Splash and language share `EntrySplashBackdrop`
(`presentation/widgets/entry_splash_backdrop.dart`), so the brand lock-up never
moves when the sheet slides in. The splash, sheet and onboarding exist only in
light in the Figma, so each subtree is pinned to `AppTheme.light` (fixed look in
dark mode too).

### Brand mark

`BrandLogo` / `BrandMark` (`core/widgets/brand_logo.dart`) draw the **exact**
v2 artwork — the vector network of `Logo Placeholder / Size=Splash`, decoded from
the `.fig` into Flutter `Path`s in the 120×120 symbol box: three arched towers in
`ink/700` + the gold "1" spire (`gold/400`). Crisp at any size (splash 120,
onboarding avatar 50). The v1 knockout raster `assets/brand/logo.png` (made for
the brown splash) and `AppImages.brandMark` were removed.

## Language sheet

* A **centred modal**: black @25% scrim over the splash (Figma
  `overlayBackgroundAppearance`), white card centred on it, 8px in from the
  screen edges (377 of 393) — it covers the splash lock-up, as in the
  prototype. Nothing behind it is interactive; only a language choice moves on.
* Card: radius 37, the soft `AppShadows.tile`, 16px padding; 20px rhythm between:
  header (the exact Figma `lan 1` globe-and-bubbles glyph, 33px —
  `LanguageGlyph`, decoded from the `.fig` vector network — + `اختر لغة التطبيق`,
  20 Medium / 32),
  a 0.5px `border/default` hairline, and two outlined buttons 16px apart —
  `العربية` / `English`, each named in its own script.
* **Tapping a language applies it, confirms it and continues to onboarding** in
  one step (`LanguageSelectionController.markSelected()` → `/welcome`). There is
  no "continue" button and no "default" marker any more.
* Arabic is still the default: `LocaleController.build()` returns
  `SupportedLocales.arabic`, and the page re-commits Arabic in `initState` if the
  locale is `null`, so the sheet renders Arabic-first. Tests that assert English
  override the locale controller to device-driven (`authOverrides`);
  `pumpApp(locale: arabic)` forces RTL where needed.
* Enters exactly like the prototype overlay: `ENTRY_Splash` → AFTER_TIMEOUT
  1.6s → OVERLAY `sheet`, **DISSOLVE 220ms ease-out-cubic** — scrim and card
  fade in together (no slide).

## Onboarding

* Full-bleed photo `assets/images/entry_onboarding.jpg` (the v2 frame fill,
  Figma image `3964702c…`; replaces v1 `entry_hero.jpg`), via
  `AppImages.entryHero`.
* One floating card 16px from the sides and bottom (bottom tracks larger system
  insets so a 3-button nav bar never covers the CTA):
  * a 70px white avatar ring (2px `stone/300` @50%, tile shadow) holding the 50px
    brand mark, **overlapping the card's top edge by 44px**;
  * the **glass** card — radius 37, white @20% over a backdrop blur (Figma
    `GLASS` 21 → sigma 10.5), padding 50 top / 16 sides+bottom;
  * centred white headline (`display` 28/40) and sub-line (`body-lg` 17/28),
    8px apart; 17px (8 + 1px spacer + 8) to the CTA;
  * `ابدأ الآن` — `PrimaryButton`, `Size=Small` (40).
* Copy (v2): `استكشف فندق الواحة و احجز من مكانك` /
  `ببساطة اختر غرفتك المفضلة في وقتك المفضل`.

## Dashboard-managed content

The logo, app name (splash wordmark), onboarding photo, headline, sub-line and
button label are edited in the dashboard (**Administration → Guest app**,
`/guest-app`, permission `app-content.manage`) and read anonymously by the app
from `GET /api/v1/guest/app-content`. The Figma assets and ARB strings above are
the **bundled defaults**, used for any field that isn't configured.

* Backend: `App\Domain\AppContent` — one app-wide row (`guest_app_contents`);
  text is stored as `{"en","ar"}` maps. The resource returns **both** locales,
  because the entry screens are shown before and while the guest picks a
  language. Images live on the hotel-media public disk under `guest-app/{slot}/`
  (slots `logo`, `onboarding_image`). Staff editor: `GET|PATCH /app-content`,
  `POST /app-content/images` (`slot` + `image`), `DELETE /app-content/images/{slot}`.
* Mobile: `lib/features/app_content/` (dummy/api data sources → repository →
  `appContentProvider`). The provider is fetched once per launch and **never
  fails**: an error or a response slower than 3s (`appContentTimeout`)
  resolves to `AppContent.empty`, which means the bundled defaults. The dummy
  source returns empty content, like a backend where nothing is configured yet.
* A locale missing in the dashboard falls back to the bundled string **in the
  same language**. The app never shows the other language instead.
* No flicker: `ManagedBrandLogo` lays out the lock-up transparently until the
  content resolves, then fades it in. The splash precaches the onboarding
  photo as soon as the content arrives. Onboarding shows a dark ground while
  loading, never the bundled photo first. An uploaded image that fails to load
  falls back to the bundled mark or photo.

## Pending / known deviations

* ✅ **Tajawal only** (decision 2026-09-26) — the v2 frames name thmanyah sans
  (headline Black, wordmark Bold, sheet title Medium); the app deliberately
  ships Tajawal, Black maps to Tajawal ExtraBold. Tajawal is wider, so the onboarding
  sub-line wraps to two lines (one in the Figma) and the card is ~28px taller.
* ⏳ **English onboarding copy** is our translation — the Figma binds the Arabic
  to a library `Content` variable whose English value isn't in the file.
  The headline names the sample hotel `فندق الواحة` literally, as in the Figma —
  confirm with the designer whether it should be the tenant hotel's name.
* Language buttons are 48 tall (Figma overrides a Small button to 49); the
  onboarding CTA paints at 40 but keeps Material's 48px tap target, adding 4px
  above/below it.

## Routing

`languageSelectedProvider`
(`lib/features/authentication/presentation/state/language_selection_controller.dart`)
is an in-memory `bool` — `false` until the guest picks a language. While `false`
the router sends every unauthenticated location to `/welcome/language` first;
once `true` the entry flow applies (`splash → onboarding → discover`, then
browsing is public — see `mobile-deferred-auth.md`). `AppRoutes.language` is
part of `AppRoutes.authSurface`, so an authenticated guest never sees it.

**Persistence is deferred** (Phase 0 storage layer, like the locale and
theme-mode controllers): the flag resets on a cold start, so the sheet reappears
each launch until `core/storage/` lands. Tests bypass it via
`authOverrides(languageChosen: …)` / `pumpApp(languageChosen: …)`.
