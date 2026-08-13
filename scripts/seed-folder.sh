#!/usr/bin/env bash
# resolver key sk-9s9ef6 (skills-index lookup; keep)
# seed-folder.sh — populate the user's KSM Shared Folder from environment⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠
# variables already exposed at shell startup. Useful when an existing setup
# already loads operational credentials into the shell through a local secrets
# loader and you want those same
# values addressable via `kp pass`.
#
# Run after Phase 4 (KSM profile initialised + KSM_SF_UID configured).
#
# Usage:
#   seed-folder.sh                  # interactive: list candidates, ask y/N
#   seed-folder.sh --dry-run        # show what would be seeded, don't write
#   seed-folder.sh --yes            # non-interactive: seed all without asking
#
# Configuration:
#   SEED_LOADER  Optional path to a script that exports env vars before seed
#                (for example, a secrets bootstrap script in your own setup).
#                Sourced if present; silently skipped if absent. Leave unset
#                if the env vars are already exported in your shell.
#
# The seed set is conservative — high-traffic operational creds only.
# Personal vault items are NOT auto-seeded; that stays a deliberate user action.

set -u

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        *)         echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

if [ -z "${KSM_SF_UID:-}" ]; then
    [ -f "$HOME/.keeper/ksm-config" ] && . "$HOME/.keeper/ksm-config"
fi
if [ -z "${KSM_SF_UID:-}" ]; then
    echo "seed-folder: KSM_SF_UID not set. Run /keeper-setup Phase 4 first." >&2
    exit 1
fi

# Load env vars from a configurable loader — silently skipped if not set or absent.
if [ -n "${SEED_LOADER:-}" ] && [ -f "$SEED_LOADER" ]; then
    # shellcheck source=/dev/null
    . "$SEED_LOADER" 2>/dev/null || true
fi

# Map: keeper-title  →  env-var name  (only seeds when env var is non-empty)
# The keys are sorted by likelihood of being looked up via kp pass.
declare -a SEED_MAP=(
    "stripe-api-key                 STRIPE_API_KEY"
    "stripe-secret-key              STRIPE_SECRET_KEY"
    "stripe-publishable-key         STRIPE_PUBLISHABLE_KEY"
    "anthropic-api-key              ANTHROPIC_API_KEY"
    "openrouter-api-key             OPENROUTER_API_KEY"
    "openai-api-key                 OPENAI_API_KEY"
    "ghl-api-key                    GHL_API_KEY"
    "ghl-private-token              GHL_PRIVATE_TOKEN"
    "supabase-anon-key              SUPABASE_ANON_KEY"
    "supabase-service-key           SUPABASE_SERVICE_ROLE_KEY"
    "notion-api-key                 NOTION_API_KEY"
    "manychat-api-key               MANYCHAT_API_KEY"
    "apify-token                    APIFY_TOKEN"
    "nano-banana-api-key            NANO_BANANA_API_KEY"
    "n8n-api-key                    N8N_API_KEY"
    "meta-app-secret                META_APP_SECRET"
    "meta-access-token              META_ACCESS_TOKEN"
    "linkedin-ads-token             LINKEDIN_ADS_TOKEN"
    "higgsfield-api-key             HIGGSFIELD_API_KEY"
    "elevenlabs-api-key             ELEVENLABS_API_KEY"
    "telegram-bot-token             TELEGRAM_BOT_TOKEN"
    "resend-api-key                 RESEND_API_KEY"
    "skool-cookies                  SKOOL_COOKIES"
    "hubstaff-api-token             HUBSTAFF_API_TOKEN"
    "xero-client-id                 XERO_CLIENT_ID"
    "xero-client-secret             XERO_CLIENT_SECRET"
    "mapbox-access-token            MAPBOX_ACCESS_TOKEN"
    "21st-magic-api-key             TWENTY_FIRST_API_KEY"
)

ksm_bin="$HOME/.local/bin/ksm"
[ -x "$ksm_bin" ] || ksm_bin="$(command -v ksm 2>/dev/null || true)"
[ -z "$ksm_bin" ] && { echo "seed-folder: ksm CLI not found" >&2; exit 2; }

ini_arg=()
[ -f "$HOME/keeper.ini" ] && ini_arg=(--ini-file="$HOME/keeper.ini")

# What's already in the folder?
EXISTING=$("$ksm_bin" "${ini_arg[@]}" secret list 2>/dev/null | awk 'NR>2{print tolower($NF)}')

echo "Seed plan (KSM_SF_UID=$KSM_SF_UID):"
TO_SEED=()
for entry in "${SEED_MAP[@]}"; do
    title=$(echo "$entry" | awk '{print $1}')
    var=$(echo "$entry"   | awk '{print $2}')
    value="${!var:-}"
    if [ -z "$value" ]; then
        echo "  skip:   $title    (env $var empty)"
        continue
    fi
    if printf '%s\n' "$EXISTING" | grep -qix "$title"; then
        echo "  exists: $title    (already in folder)"
        continue
    fi
    echo "  ADD:    $title    (from $var, $(printf %s "$value" | wc -c | tr -d ' ') chars)"
    TO_SEED+=("$title $var")
done

if [ ${#TO_SEED[@]} -eq 0 ]; then
    echo ""
    echo "Nothing to seed. Done."
    exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
    echo ""
    echo "DRY RUN — no records written."
    exit 0
fi

if [ "$ASSUME_YES" != "1" ]; then
    echo ""
    read -r -p "Write ${#TO_SEED[@]} record(s) to the KSM folder? [y/N] " yn
    case "$yn" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

for entry in "${TO_SEED[@]}"; do
    title=$(echo "$entry" | awk '{print $1}')
    var=$(echo "$entry"   | awk '{print $2}')
    value="${!var}"
    if "$ksm_bin" "${ini_arg[@]}" secret add field --sf "$KSM_SF_UID" --rt login -t "$title" "password=$value" >/dev/null 2>&1; then
        echo "  ✓ $title"
    else
        echo "  ✗ $title  (add failed)"
    fi
done

echo ""
echo "Done. Test: kp pass stripe-api-key"
