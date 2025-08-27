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

# Require jq (used for URL-encoding and JSON parsing)
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: 'jq' is required. Install it, e.g.: sudo apt-get install -y jq" >&2
    exit 1
  fi
}

# URL-encode using jq
urlencode() { jq -rn --arg x "$1" '$x|@uri'; }

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
  require_jq
  local q_enc
  q_enc="$(urlencode "$1")"
  curl_get "/Catalog/Events?query=${q_enc}&perPage=10&page=1"
}

query_tickets() {
  local event_id="$1"
  curl_get "/Catalog/Events/${event_id}/Tickets"
}

query_autocomplete() {
  require_jq
  local q_enc
  q_enc="$(urlencode "$1")"
  curl_get "/Catalog/Autocomplete?searchText=${q_enc}&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category"
}

managed_checkout() {
  local listing_id="$1"; local qty="$2"; local price="$3"; local currency="$4"
  # 1) Create cart
  cart_json='{"items":[]}'
  require_jq
  cart="$(curl_post_json "/Cart" "$cart_json")"
  cart_id="$(jq -r '.id // empty' <<<"$cart")"
  if [[ -z "$cart_id" ]]; then
    echo "ERROR: No cart id returned" >&2
    echo "$cart" >&2
    exit 1
  fi

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
