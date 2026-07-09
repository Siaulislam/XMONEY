# XMONEY Enterprise UI/UX Standards

Mandatory for **every new module** across web, admin, and mobile.

## 1. Responsive design

| Breakpoint | Min width | Target |
|------------|-----------|--------|
| xs | 320px | Small phones |
| sm | 375px | Standard phones |
| md | 768px | Tablets |
| lg | 1024px | Laptops |
| xl | 1280px | Desktop |
| 2xl | 1440px | Large desktop |
| 3xl | 1920px | Ultra-wide |

- Use CSS Grid / Flexbox (web) and `LayoutBuilder` / `XmBreakpoints` (Flutter).
- No horizontal page scroll; tables scroll inside `.xm-table-wrap` only.
- Touch targets ≥ 44×44px.
- Fluid typography via `clamp()` / `MediaQuery.textScaler`.

## 2. Theme system

**Web / Admin:** `XMTheme` (`xm-theme.js`) — `light` | `dark` | `system`, stored in `localStorage`.

**Mobile:** `ThemeController` — persisted via `shared_preferences`.

## 3. Internationalization

| Code | Language | Direction |
|------|----------|-----------|
| `en` | English | LTR |
| `ar` | Arabic | RTL |
| `ur` | Urdu | RTL |

**Web:** `XMI18n` + JSON in `src/assets/i18n/`. Mark strings with `data-i18n="key"`.

**Mobile:** `XmStrings` + `assets/i18n/*.json`.

Add new languages by adding a JSON file — no structural changes.

## 4. Accessibility (WCAG)

- Skip link to `#xmMainContent`
- `:focus-visible` rings on interactive elements
- `aria-label` / `aria-expanded` on menus
- `prefers-reduced-motion` respected
- Semantic HTML / Flutter semantics

## 5. Shared UI package

Source of truth: `shared/ui/`  
Sync to apps:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-enterprise-ui.ps1
powershell -ExecutionPolicy Bypass -File scripts/inject-enterprise-ui.ps1
```

## 6. File checklist for new pages

- [ ] Uses design tokens (`var(--xm-*)`)
- [ ] `data-i18n` on user-visible strings
- [ ] Works at 320px and 1920px
- [ ] Dark mode verified
- [ ] RTL verified (Arabic/Urdu)
- [ ] Keyboard navigable
- [ ] No layout overflow
