# Aurora API Examples — C# (.NET 8)

[![.NET 8.0](https://img.shields.io/badge/.NET-8.0-purple.svg)](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)

## Setup
```bash
dotnet new console -n AuroraExamples
# Replace Program.cs with the one in this folder
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
dotnet run --project csharp/AuroraExamples.csproj -- query-events "Chiefs"
```

## Examples

```bash
dotnet run --project csharp/AuroraExamples.csproj -- query-autocomplete "Taylor Swift"
dotnet run --project csharp/AuroraExamples.csproj -- query-tickets <EVENT_ID>

# Managed
dotnet run --project csharp/AuroraExamples.csproj -- managed-checkout <LISTING_ID> 2 26.00 USD dev@example.com Jane Doe "555-555-1234" "1313 Mockingbird Lane" "" "Kansas City" "MO" "64106" "US"

# Unmanaged
dotnet run --project csharp/AuroraExamples.csproj -- unmanaged-checkout <LISTING_ID> 2 26.00 USD dev@example.com Jane Doe
```