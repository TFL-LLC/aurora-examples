# Aurora API Examples — C# (.NET 8)

## Setup
```bash
dotnet new console -n AuroraExamples
# Replace Program.cs with the one in this folder
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
dotnet run -- query-events "Chiefs"
```

## Examples

```bash
dotnet run -- query-autocomplete "Taylor Swift"
dotnet run -- query-tickets <EVENT_ID>

# Managed
dotnet run -- managed-checkout <LISTING_ID> 2 26.00 USD dev@example.com Jane Doe "555-555-1234" "1313 Mockingbird Lane" "" "Kansas City" "MO" "64106" "US"

# Unmanaged
dotnet run -- unmanaged-checkout <LISTING_ID> 2 26.00 USD dev@example.com Jane Doe
```