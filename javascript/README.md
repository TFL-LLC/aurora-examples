# Aurora API Examples — JavaScript (Node 18+)

## Prereqs
- Node.js 18+ (uses native `fetch`)

## Setup
```bash
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
```

## Commands

```bash
# Queries
node aurora_examples.js query-events "Chiefs"
node aurora_examples.js query-autocomplete "Taylor Swift"
node aurora_examples.js query-tickets <EVENT_ID>

# Managed checkout (cart -> add item -> checkout)
node aurora_examples.js managed-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first Jane --last Doe \
  --phone "555-555-1234" \
  --address1 "1313 Mockingbird Lane" --city "Kansas City" --region "MO" --postal "64106" --country "US"

# Unmanaged checkout (single call)
node aurora_examples.js unmanaged-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first Jane --last Doe
```

## Notes

* Default environment is **sandbox**; set `ENV=prod` for production.
* `price` is **required**.
* If any address field is provided, then **address1, city, region, postal, country** are all required (address2 optional).
