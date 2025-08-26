
# Aurora API Examples — Bash

## Prereqs
- bash, curl, Python (for safe URL encoding in one-liners)

## Setup
```bash
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
````

## Customer (env variables)

```bash
export EMAIL="dev@example.com"
export FIRST_NAME="Jane"
export LAST_NAME="Doe"
export PHONE="555-555-1234"

# If ADDRESS1 is set, then CITY, REGION, POSTAL, COUNTRY are required (ADDRESS2 optional)
export ADDRESS1="1313 Mockingbird Lane"
export CITY="Kansas City"
export REGION="MO"
export POSTAL="64106"
export COUNTRY="US"
```

## Usage

```bash
./aurora_examples.sh query-events "Chiefs"
./aurora_examples.sh query-autocomplete "Taylor Swift"
./aurora_examples.sh query-tickets <EVENT_ID> USD

# Managed
./aurora_examples.sh managed-checkout <LISTING_ID> 2 26.00 USD

# Unmanaged
./aurora_examples.sh unmanaged-checkout <LISTING_ID> 2 26.00 USD
```