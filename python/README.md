# Aurora API Examples — Python

![Python](https://img.shields.io/badge/Python-3.9%2B-blue?logo=python) ![Requests](https://img.shields.io/badge/requests-2.28%2B-yellow)

## Prereqs
- Python 3.9+
- `pip install requests`

## Setup
```bash
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
```

## Examples

```bash
python aurora_examples.py query-events "Chiefs"
python aurora_examples.py query-autocomplete "Taylor Swift"
python aurora_examples.py query-tickets <EVENT_ID>

# Managed
python aurora_examples.py managed-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first-name Jane --last-name Doe \
  --phone "555-555-1234" \
  --address1 "1313 Mockingbird Lane" --city "Kansas City" --region "MO" --postal "64106" --country "US"

# Unmanaged
python aurora_examples.py unmanaged-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first-name Jane --last-name Doe \
  --phone "555-555-1234"
```