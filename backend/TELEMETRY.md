# Backend telemetry & menu-photo retention

Phase 1 of the analytics work. Everything here is **off by default** and behind
env flags — the pipeline runs identically when unconfigured.

## Analytics (PostHog, server-side)

One event, `scan_processed`, is emitted per scan from the background pipeline
(`app/api/menus.py`). Properties:

| Property | Meaning |
|---|---|
| `outcome` | `success` \| `failed` |
| `failure_reason` | `zero_dishes` (also = "not a menu") \| `timeout` \| `invalid_output` \| `extraction_error` \| `error` \| null |
| `dishes_count` | dishes extracted |
| `primary_extraction_ms` | first pass (OCR + translation) duration |
| `enrichment_ms` | about + nutrition pass duration (null if it failed) |
| `time_to_last_image_ms` | scan start → last image persisted |
| `images_ready` / `images_failed` | per-dish image outcomes |
| `cuisine_type` | detected cuisine |
| `image_stored` | whether the upload was saved (see below) |
| `platform` | always `backend` (added automatically; web=`web`, mobile=`mobile`) |

`distinct_id` = the client's `X-Device-Id` header (mobile/web send their PostHog
distinct id) so scans attribute to a user; falls back to a per-scan id.

### Enable
Set on Railway (values are the same PostHog project as the web app):

```
POSTHOG_API_KEY=phc_...            # from PostHog project settings
POSTHOG_HOST=https://eu.i.posthog.com   # default; already correct for the EU project
```

Without `POSTHOG_API_KEY`, `capture()` is a silent no-op.

## Menu-photo retention (debugging failed scans)

When enabled, the uploaded (preprocessed) menu photo is written to S3 under the
`_uploads/<menu_id>.jpg` prefix — separate from the generated dish-image cache
under `_cache/`, so retention can be scoped to uploads only.

### ⚠️ Enable order (do NOT skip)
Storing user photos changes what we promise users. Before setting the flag:

1. **Add a 30-day lifecycle-expiry rule** on the `_uploads/` prefix (otherwise
   photos are kept forever). AWS CLI:
   ```bash
   aws s3api put-bucket-lifecycle-configuration --bucket <BUCKET> \
     --lifecycle-configuration '{
       "Rules": [{
         "ID": "expire-menu-uploads-30d",
         "Filter": {"Prefix": "_uploads/"},
         "Status": "Enabled",
         "Expiration": {"Days": 30}
       }]
     }'
   ```
2. **Update the Privacy Policy + Data safety** to state that menu photos are
   stored for 30 days (currently both say "not stored"). Until this is done the
   policy is accurate only while the flag is OFF.
3. Then set:
   ```
   STORE_MENU_UPLOADS=true
   ```

Requires S3 to be configured (`S3_BUCKET`); it's a no-op on local filesystem.
