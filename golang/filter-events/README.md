# Aurora Event Search – Category Filter (Go)

This script queries the **Aurora Catalog Events API**, automatically pages through **all matching results**, and filters events locally by **category type** (e.g. `sport`, `concert`, `theatre`, `other`).

It is intended for clients who want:

- Full search coverage (not just the first page)
- Client-side filtering without additional API calls
- A simple, auditable JSON output

---

## ✨ What the Script Does

- Calls `/Catalog/Events` using a search query
- Automatically pages through all results (e.g. 3,000+ events)
- Filters events where **any category has the specified `type`**
- Streams matching events to **stdout as valid JSON**
- Writes a summary to **stderr** (so output can be redirected cleanly)

---

## 📋 Requirements

- **Go 1.21+**
- A valid **Aurora API Bearer Token**

---

## 🔐 Authentication

The script uses environment variables for authentication and environment selection.

```bash
export TOKEN=<YOUR_AURORA_API_TOKEN>
export ENV=sandbox   # or prod
````

- `TOKEN` **(required)** – Bearer token for the Aurora API
- `ENV` *(optional)* – API environment (default: `sandbox`)

---

## 🚀 Usage

### Basic command

```bash
go run . -search "nba" -category-type sport > filtered-events.json
```

### Parameters

| Flag             | Required | Description                                    |
| ---------------- | -------- | ---------------------------------------------- |
| `-search`        | ✅        | Search text passed to `/Catalog/Events?Query=` |
| `-category-type` | ✅        | Category type to filter by (case-insensitive)  |
| `-per-page`      | ❌        | Results per page (default: 100)                |
| `-timeout`       | ❌        | HTTP timeout in seconds (default: 30)          |
| `-env`           | ❌        | API environment (overrides `ENV`)              |

---

## 🧪 Examples

### Sports events

```bash
go run . -search "king" -category-type sport > sport-events.json
```

### Concerts

```bash
go run . -search "king" -category-type concert > concerts.json
```

### Theatre

```bash
go run . -search "king" -category-type theatre > theatre-events.json
```

### Other

```bash
go run . -search "king" -category-type other > other-events.json
```

---

## 📄 Output

### `stdout`

- A single JSON array containing **only matching events**
- Safe to redirect to a file

### `stderr`

- A processing summary, for example:

```text
Done. Total=3140 Seen=3140 Matched=264 CategoryType="sport" Search="king"
```

---

## 🧠 Filtering Logic

An event is included **if any category** attached to the event has:

```json
{
  "type": "<category-type>"
}
```

Matching is:

- Case-insensitive
- Exact match on the `type` field

---

## 🌐 API Endpoint Used

```http
GET https://{ENV}.tflapis.com/Catalog/Events?Query=<search>&Page=<n>&PerPage=<m>
```

Headers:

```http
Authorization: Bearer <TOKEN>
Accept: text/plain
```

---

## ⚠️ Notes

- The script filters **while paging** to avoid holding large datasets in memory.
- Unknown event fields are preserved exactly as returned by the API.
- The script intentionally avoids SDKs or external dependencies for clarity.

---

## 📜 License

This script is provided as an example and may be freely adapted for client use.
