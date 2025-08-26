#!/usr/bin/env bash
set -euo pipefail

# Aurora API Examples — bash
# Usage:
#   export TOKEN=<TOKEN>
#   ./aurora_examples.sh query-events "Chiefs"
#   ./aurora_examples.sh query-tickets <EVENT_ID>
#   ./aurora_examples.sh query-autocomplete "Taylor Swift"
#   ./aurora_examples.sh managed-checkout <LISTING_ID> <QTY:int> <PRICE:number> <CURRENCY>
#   ./aurora_examples.sh unmanaged-checkout <LISTING_ID> <QTY:int> <PRICE:number> <CURRENCY>
#
# Customer via env (recommended):
#   EMAIL, FIRST_NAME, LAST_NAME, PHONE (optional)
#   ADDRESS1, ADDRESS2 (opt), CITY, REGION, POSTAL, COUNTRY
#
# Env:
#   TOKEN (required), ENV=sandbox|prod (default: sandbox)

ENVIRONMENT="${ENV:-sandbox}"
BASE="https://${ENVIRONMENT}.tflapis.com"

require_token() {
  if [[ -z "${TOKEN:-}" ]]; then
    echo "ERROR: TOKEN env var is required (export TOKEN=<TOKEN>)" >&2
    exit 1
  fi
}

curl_get() {
  require_token
  local path="$1"
  curl -sS "${BASE}${path}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: text/plain, application/json"
}

curl_post_json() {
  require_token
  local path="$1"
  local json="$2"
  curl -sS -X POST "${BASE}${path}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: text/plain, application/json" \
    -H "Content-Type: application/json" \
    --data "${json}"
}

# Build customer JSON. Enforces address all-or-none except address2.
build_customer_json() {
  local first="${FIRST_NAME:-First}"
  local last="${LAST_NAME:-Last}"
  local email="${EMAIL:-dev@example.com}"
  local phone="${PHONE:-}"

  local addr1="${ADDRESS1:-}"
  local addr2="${ADDRESS2:-}"
  local city="${CITY:-}"
  local region="${REGION:-}"
  local postal="${POSTAL:-}"
  local country="${COUNTRY:-}"

  local any_addr=""
  [[ -n "$addr1" || -n "$city" || -n "$region" || -n "$postal" || -n "$country" ]] && any_addr="yes"
  if [[ -n "$any_addr" ]]; then
    for f in addr1 city region postal country; do
      eval "v=\${$f}"
      if [[ -z "$v" ]]; then
        echo "ERROR: If specifying any address field, require ADDRESS1, CITY, REGION, POSTAL, COUNTRY." >&2
        exit 1
      fi
    done
    cat <<JSON
{"firstName":"$first","lastName":"$last","email":"$email"$( [[ -n "$phone" ]] && printf ',"phoneNumber":"%s"' "$phone"),"address":{"address1":"$addr1","address2":"$addr2","city":"$city","region":"$region","postalCode":"$postal","country":"$country"}}
JSON
  else
    cat <<JSON
{"firstName":"$first","lastName":"$last","email":"$email"$( [[ -n "$phone" ]] && printf ',"phoneNumber":"%s"' "$phone")}
JSON
  fi
}

query_events() {
  local q="$1"
  curl_get "/Catalog/Events?query=$(python - <<PY
import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))
PY
"$q")&perPage=10&page=1"
}

query_tickets() {
  local event_id="$1"
  local currency="${2:-USD}"
  curl_get "/Catalog/Events/${event_id}/Tickets?currency=${currency}"
}

query_autocomplete() {
  local q="$1"
  # repeated catalogs
  curl_get "/Catalog/Autocomplete?searchText=$(python - <<PY
import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))
PY
"$q")&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category"
}

managed_checkout() {
  local listing_id="$1"; local qty="$2"; local price="$3"; local currency="$4"
  # 1) Create cart
  cart_json='{"items":[]}'
  cart=$(curl_post_json "/Cart" "$cart_json")
  cart_id=$(python - <<PY
import json,sys; d=json.load(sys.stdin); print(d.get("id",""))
PY
<<<"$cart")
  [[ -z "$cart_id" ]] && (echo "ERROR: No cart id returned"; echo "$cart" >&2; exit 1)

  # 2) Add item (single object body)
  add_body=$(cat <<JSON
{"listingId":"$listing_id","quantity":$qty,"currencyType":"$currency","price":$price}
JSON
)
  curl_post_json "/Cart/${cart_id}/Items" "$add_body" >/dev/null

  # 3) Checkout with customer
  customer=$(build_customer_json)
  chk_body=$(cat <<JSON
{"customer":$customer}
JSON
)
  curl_post_json "/Cart/${cart_id}/Checkout" "$chk_body"
}

unmanaged_checkout() {
  local listing_id="$1"; local qty="$2"; local price="$3"; local currency="$4"
  customer=$(build_customer_json)
  body=$(cat <<JSON
{"customer":$customer,"shoppingCart":{"items":[{"listingId":"$listing_id","quantity":$qty,"currencyType":"$currency","price":$price}]}}
JSON
)
  curl_post_json "/Cart/Checkout" "$body"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  query-events)         query_events "$@";;
  query-tickets)        query_tickets "$@";;
  query-autocomplete)   query_autocomplete "$@";;
  managed-checkout)     managed_checkout "$@";;
  unmanaged-checkout)   unmanaged_checkout "$@";;
  ""|help|--help|-h)    sed -n '1,80p' "$0";;
  *) echo "Unknown command: $cmd" >&2; exit 1;;
esac
