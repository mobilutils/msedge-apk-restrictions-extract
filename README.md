# msedge-apk-restrictions-extract

![tags](./lalinea-bouh-edge_600x454.png)
<left><u><bold>Figure1</bold></u>: this persona is "Mr. Linea" created by Italian cartoonist Osvaldo Cavandoli ~1970. (this image has been misappropriated).</left>

Extract and track Microsoft Edge MDM restrictions from APK files. Downloads the latest Edge APK, decompiles it, and produces a consolidated CSV/JSON of all available MDM policies.

## Install dependencies

### Nux

```bash
pip install google-play-scraper packaging gplaydl
```

### MacOSx

```bash
python3 -m venv mvenv
source mvenv/bin/activate
pip3 install google-play-scraper packaging gplaydl
```

## Usage

### Automated (recommended)

`main.sh` handles the full workflow: download the latest APK, extract it, and generate the restriction reports.

```bash
source mvenv/bin/activate
./main.sh
```

### Manual extraction

```bash
bash extract_restrictions_from_last_apk.sh
```

### Output

After running, the latest APK directory contains:

- `app_restrictions.xml` — raw restriction definitions from the APK
- `strings.xml` — resolved string resources
- `app_restrictions.json` — structured JSON of all restrictions
- `app_restrictions_consolidated.csv` — tabular CSV with columns: key, title, default_value, type, description

### Cron

```bash
# Run every 2 days at 21:42
42 21 */2 * * /usr/bin/bash /path/to/main.sh
```

### Monitor logs

```bash
tail -f ~/logs/edge-monitor.log
```
