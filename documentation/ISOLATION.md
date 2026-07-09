# XMONEY — Isolation Policy (Mandatory)

XMONEY is a **completely independent application** on the same cPanel account as any existing site.

## Hard rules

1. **Folder isolation**  
   Deploy only under `public_html/xmoney/` (or a dedicated subdomain document root that points only to XMONEY).  
   Never write into, overwrite, rename, or delete sibling folders under `public_html/`.

2. **Database isolation**  
   Use the dedicated XMONEY MySQL database: `smartdms_XMONEY`.  
   Never connect to, migrate, or alter any non-XMONEY database.

3. **User isolation**  
   Use the dedicated XMONEY MySQL user: `smartdms_xmoney` with grants **only** on `smartdms_XMONEY`.

4. **Config isolation**  
   All secrets live in `backend-api/.env` (production: `public_html/xmoney/api/.env`).  
   Never hard-code DB name, user, password, domain, or API URLs in source code.

5. **Migration isolation**  
   Every future SQL migration, API change, and feature ships only inside `C:\XMONEY` and deploys only to the XMONEY folder/database.

6. **No shared tables**  
   XMONEY tables are created only inside the XMONEY database. No foreign keys or joins to other databases.

## Target layout on hosting

```
public_html/
├── .github/                   ← leave untouched
├── admin-panel/               ← leave untouched
├── backend-api/               ← leave untouched
├── frontend-web/              ← leave untouched
├── (other existing folders)   ← leave untouched
└── xmoney/                    ← XMONEY ONLY
    ├── .htaccess
    ├── index.html             (customer web)
    ├── admin/                 (admin panel)
    ├── api/                   (backend API)
    ├── storage/               (uploads, logs, backups)
    └── config/                (public runtime URLs only)
```

## Optional subdomain (recommended)

Point `xmoney.yourdomain.com` (or `api.xmoney…` / `admin.xmoney…`) at `public_html/xmoney` without changing the main site document root.
