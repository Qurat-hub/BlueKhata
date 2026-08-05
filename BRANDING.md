# Branding Requirements — Do Not Remove

This project must always display **Zenvyro Labs** branding. This is a hard
requirement, enforced in code (not just docs), at three points:

1. **Splash Screen** — `lib/features/authentication/presentation/screens/splash_screen.dart`
   renders the app name and, via `BrandingFooter`, "Powered by Zenvyro Labs".
2. **Dashboard Footer** — `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
   renders `BrandingFooter` at the bottom of the dashboard home tab.
3. **Logo asset** — `assets/images/zenvyro_labs_logo.png`, registered in
   `pubspec.yaml`, referenced from `AppConfig.logoAsset`.

The reusable widget is `lib/core/shared/widgets/branding_footer.dart`
(`BrandingFooter`). If you add new screens that warrant branding (e.g. an
About screen, invoice PDF footer, business card), reuse this widget or the
`AppConfig.poweredByLabel` / `AppConfig.companyName` constants rather than
hardcoding new copies of the string.

Do not delete `BrandingFooter`, `AppConfig.poweredByLabel`, or the logo
asset reference without replacing them with an equivalent, clearly visible
"Powered by Zenvyro Labs" credit.
