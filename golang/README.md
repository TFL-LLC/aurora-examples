# Aurora API Examples — Go

## Setup

```bash
cd golang
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
go run . --help
```

## Examples

```bash
go run . query-events "Chiefs"
go run . query-autocomplete "Taylor Swift"
go run . query-tickets <EVENT_ID>

# Managed Checkout (creates cart, adds item, then checks out)
go run . managed-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first-name Jane --last-name Doe \
  --phone "555-555-1234" \
  --address1 "1313 Mockingbird Lane" --city "Kansas City" --region "MO" --postal "64106" --country "US"

# Unmanaged Checkout (one-shot checkout)
go run . unmanaged-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first-name Jane --last-name Doe --phone "555-555-1234"
```

### Notes

- If **any** address field is provided, the following are required (address2 optional): `address1`, `city`, `region`, `postal`, `country`.
- Optional: `--client-order-id <value>` will set `clientOrderIdentifier` on checkout.
