# Aurora Examples

This repository contains example code for working with the **Aurora API** and related services.  
It includes scripts and applications in multiple languages to help developers get started quickly.  

## 📂 Repository Structure

```bat
aurora-examples/
├── [powershell/](powershell)     # PowerShell examples
├── [bash/](bash)                 # Bash shell examples
├── [csharp/](csharp)             # .NET / C# examples
├── [python/](python)             # Python examples
├── [java/](java)                 # Java examples
├── [javascript/](javascript)     # JavaScript (Node.js) examples
├── [golang/](golang)             # Go examples
└── README.md
```

## 🚀 Getting Started

1. Clone this repository:

   ```bash
   git clone https://github.com/TFL-LLC/aurora-examples.git
   cd aurora-examples
   ```

2. Navigate into a language folder and run a sample:

   ```bash
   cd python
   python aurora_examples.py query-events "Chiefs"
   ```

   > Each language folder has its own README with setup instructions and dependencies.

---

## 🖥️ Language Guides (with Quick Start)

### [PowerShell](powershell)

![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell)

#### Examples

```powershell
# Query events
.\Aurora.Examples.ps1 -Token "<TOKEN>" -QueryEvents -SearchText "Chiefs"

# Tickets
.\Aurora.Examples.ps1 -Token "<TOKEN>" -QueryTickets -EventId "1972578"

# Autocomplete
.\Aurora.Examples.ps1 -Token "<TOKEN>" -QueryAutocomplete -SearchText "Taylor Swift"

# Managed checkout
.\Aurora.Examples.ps1 -Token "<TOKEN>" -ManagedCheckout `
  -ListingId "<LISTING_ID>" -Quantity 2 -Price 26.00 -Currency USD `
  -Email "dev@example.com" -FirstName "Jane" -LastName "Doe" `
  -PhoneNumber "555-555-1234" `
  -Address1 "1313 Mockingbird Lane" -City "Kansas City" -Region "MO" -PostalCode "64106" -Country "US"

# Unmanaged checkout
.\Aurora.Examples.ps1 -Token "<TOKEN>" -UnmanagedCheckout `
  -ListingId "<LISTING_ID>" -Quantity 2 -Price 26.00 -Currency USD `
  -Email "dev@example.com" -FirstName "Jane" -LastName "Doe"
```

---

### [Bash](bash)

![Bash](https://img.shields.io/badge/Bash-5%2B-black?logo=gnu-bash) ![curl](https://img.shields.io/badge/curl-7.68%2B-lightgrey?logo=curl)

#### Setup

```bash
export TOKEN=<TOKEN>
export ENV=sandbox   # or prod
```

#### Examples

```bash
./aurora_examples.sh query-events "Chiefs"
./aurora_examples.sh query-autocomplete "Taylor Swift"
./aurora_examples.sh query-tickets <EVENT_ID>

./aurora_examples.sh managed-checkout <LISTING_ID> 2 26.00 USD
./aurora_examples.sh unmanaged-checkout <LISTING_ID> 2 26.00 USD
```

---

### [C# / .NET](csharp)

![.NET](https://img.shields.io/badge/.NET-8.0-blueviolet?logo=dotnet)

#### Setup

```bash
export TOKEN=<TOKEN>
export ENV=sandbox
dotnet run --project csharp/AuroraExamples.csproj -- query-events "Chiefs"
```

---

### [Python](python)

![Python](https://img.shields.io/badge/Python-3.9%2B-blue?logo=python)

#### Setup

```bash
pip install requests
export TOKEN=<TOKEN>
export ENV=sandbox
```

---

### [Java](java)

![Java](https://img.shields.io/badge/Java-11%2B-red?logo=openjdk)

---

### [JavaScript / Node.js](javascript)

![Node.js](https://img.shields.io/badge/Node.js-18%2B-green?logo=node.js)

---

### ⭐ [Go / Golang](golang)

![Go](https://img.shields.io/badge/Go-1.21%2B-blue?logo=go)

#### Setup

```bash
go version        # ensure Go 1.21+
export TOKEN=<TOKEN>
export ENV=sandbox
```

> The Go example uses the standard library only (`net/http`, `encoding/json`) and Go modules.

#### Examples

```bash
cd golang

# Query events
go run . query-events "Chiefs"

# Autocomplete
go run . query-autocomplete "Taylor Swift"

# Tickets
go run . query-tickets <EVENT_ID>

# Managed checkout
go run . managed-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first Jane --last Doe \
  --phone "555-555-1234" \
  --address1 "1313 Mockingbird Lane" --city "Kansas City" \
  --region "MO" --postal "64106" --country "US"

# Unmanaged checkout
go run . unmanaged-checkout <LISTING_ID> 2 26.00 USD \
  --email dev@example.com --first Jane --last Doe
```

---

## 📖 Documentation

Full API documentation is available at:
👉 [https://developers.tflgroup.com](https://developers.tflgroup.com)

## 🤝 Contributing

We welcome contributions! If you'd like to add more examples or improve existing ones:

1. Fork this repo
2. Create a branch
3. Submit a pull request

## 📜 License

This repository is licensed under the [MIT License](LICENSE).
You are free to use these examples in your own projects.
