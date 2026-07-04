# Dienstkleidung

FiveM-Ressource für ein Multi-Job Outfit-Menü mit Admin-Panel (ESX, ox_lib, ox_target, oxmysql).

## Installation

1. Ordner `dienstkleidung` in deinen `resources`-Ordner legen.
2. SQL aus `dienstkleidung/install.sql` in der Datenbank ausführen.
3. In der `server.cfg` eintragen:

```
ensure oxmysql
ensure es_extended
ensure ox_lib
ensure ox_target
ensure dienstkleidung
```

> **Hinweis:** Früher hieß der Ordner `multijob_outfit`. Nach dem Umbenennen `ensure dienstkleidung` verwenden.

## Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `/outfitadmin` | Admin-Panel öffnen |
| `/outfitunstuck` | NUI-Fokus zurücksetzen (Notfall) |

## Admin-Berechtigung

ACE-Permission in der `server.cfg`:

```
add_ace group.admin job_outfit.admin allow
```

## Konfiguration

- `dienstkleidung/config.lua` – Grundeinstellungen
- `/outfitadmin` – Jobs, Outfits, Peds und Notify live bearbeiten
