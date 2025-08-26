# Aurora API Examples — Java (single-file)

![Java](https://img.shields.io/badge/Java-11%2B-red?logo=openjdk)

## Run
```bash
javac AuroraExamples.java
TOKEN=<TOKEN> ENV=sandbox java AuroraExamples query-events "Chiefs"
```

## Examples

```bash
java AuroraExamples query-autocomplete "Taylor Swift"
java AuroraExamples query-tickets <EVENT_ID>

# Managed
java AuroraExamples managed-checkout <LISTING_ID> 2 26.00 USD dev@example.com Jane Doe "555-555-1234" "1313 Mockingbird Lane" "" "Kansas City" "MO" "64106" "US"

# Unmanaged
java AuroraExamples unmanaged-checkout <LISTING_ID> 2 26.00 USD dev@example.com Jane Doe
```