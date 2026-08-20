# Play Store Assets

Ready-to-upload graphics for Google Play Console.

## Screenshots (upload these)

Play Console needs **JPEG or 24-bit PNG (no alpha)**. These files are RGB PNG.

| Folder | Size | Aspect | Play Console slot |
|--------|------|--------|-------------------|
| `screenshots/phone/` | 1080×1920 | 9:16 | Phone screenshots (upload all 4) |
| `screenshots/tablet-7/` | 1920×1080 | 16:9 | 7-inch tablet (upload all 4) |
| `screenshots/tablet-10/` | 2560×1440 | 16:9 | 10-inch tablet (upload all 4) |

Upload in this order:

1. `01_your_month.png` — Your month, clearly
2. `02_progress.png` — Progress you can see
3. `03_dark_mode.png` — A calm dark mode
4. `04_on_device.png` — Just you and your calendar

Raw captures are kept in `screenshots/_source/` (720×1600, too tall for Play — longest side was over 2× the shortest).

To rebuild after replacing the source JPEGs:

```powershell
py -3 tool/generate_store_screenshots.py
```

## Other listing graphics

| File | Size | Use in Play Console |
|------|------|---------------------|
| `play-store-icon.png` | 512×512 | App icon |
| `feature-graphic.png` | 1024×500 | Feature graphic |

## Native debug symbols

**File:** `store-assets/native-debug-symbols.zip`

Play Console expects **`.so.sym`** files (not raw `.so` files).

**Upload:** App bundle explorer → version → **Downloads** → **Native debug symbols**

**Regenerate after each release build:**

```powershell
flutter build appbundle --release
powershell -ExecutionPolicy Bypass -File tool/generate_native_debug_symbols.ps1
```

## Upload order (recommended)

1. App icon → `play-store-icon.png`
2. Feature graphic → `feature-graphic.png`
3. Phone screenshots → all 4 files in `screenshots/phone/`
4. 7-inch tablet → all 4 files in `screenshots/tablet-7/`
5. 10-inch tablet → all 4 files in `screenshots/tablet-10/`
