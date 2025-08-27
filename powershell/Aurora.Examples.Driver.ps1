# --- One-time vars ---
$TOKEN   = "<TOKEN>"   # paste your sandbox token
$ENV     = "sandbox"   # default is sandbox; set "prod" to test prod
$SEARCH  = "Chiefs"    # change to a term that exists in your catalog

# Customer for checkout samples
$EMAIL      = "test@example.com"
$FIRSTNAME  = "Jane"
$LASTNAME   = "Doe"
$PHONENUM   = "555-555-1234"

# Optional address (all-or-none except Address2)
$ADDR1      = "1313 Mockingbird Lane"
$ADDR2      = ""
$CITY       = "Kansas City"
$REGION     = "MO"
$POSTAL     = "64106"
$COUNTRY    = "US"

# ------------------------
# Query events
.\Aurora.Examples.ps1 -Token $TOKEN -Env $ENV -QueryEvents -SearchText $SEARCH

# ------------------------
# Query tickets (auto-pick first matching event, then tickets)
$base    = "https://$ENV.tflapis.com"
$hdrs    = @{ Authorization = "Bearer $TOKEN" }
$events  = Invoke-RestMethod -Headers $hdrs -Uri "$base/Catalog/Events?query=$([uri]::EscapeDataString($SEARCH))&perPage=1&page=1"
$eventRecord   = $events.records[0]
$eventId = $eventRecord.id
Write-Host "Using EventId: $eventId" -ForegroundColor Cyan
.\Aurora.Examples.ps1 -Token $TOKEN -Env $ENV -QueryTickets -EventId $eventId

# ------------------------
# Query autocomplete
.\Aurora.Examples.ps1 -Token $TOKEN -Env $ENV -QueryAutocomplete -SearchText $SEARCH

# ------------------------
# Discover a listing for the first matched event
$tix          = Invoke-RestMethod -Headers $hdrs -Uri "$base/Catalog/Events/$eventId/Tickets"
$listing      = $tix.ticketListings[0]
$listingId    = $listing.id
$quantity     = $listing.availableQuantities[0]
$price        = $listing.price
$currencyType = $listing.currencyType
Write-Host "Using ListingId: $listingId with Price $price" -ForegroundColor Cyan

# Managed checkout via your script
.\Aurora.Examples.ps1 -Token $TOKEN -Env $ENV -ManagedCheckout `
  -ListingId $listingId -Quantity $quantity -Price $price -Currency $currencyType `
  -Email $EMAIL -FirstName $FIRSTNAME -LastName $LASTNAME -PhoneNumber $PHONENUM `
  -Address1 $ADDR1 -Address2 $ADDR2 -City $CITY -Region $REGION -PostalCode $POSTAL -Country $COUNTRY

# ------------------------
# Discover another listing for unmanaged checkout (reuse the same event)
$tix          = Invoke-RestMethod -Headers $hdrs -Uri "$base/Catalog/Events/$eventId/Tickets"
$listing      = $tix.ticketListings[0]
$listingId    = $listing.id
$quantity     = $listing.availableQuantities[0]
$price        = $listing.price
$currencyType = $listing.currencyType
Write-Host "Using ListingId: $listingId with Price $price" -ForegroundColor Cyan

# Unmanaged checkout via your script
.\Aurora.Examples.ps1 -Token $TOKEN -Env $ENV -UnmanagedCheckout `
  -ListingId $listingId -Quantity $quantity -Price $price -Currency $currencyType `
  -Email $EMAIL -FirstName $FIRSTNAME -LastName $LASTNAME -PhoneNumber $PHONENUM `
  -Address1 $ADDR1 -Address2 $ADDR2 -City $CITY -Region $REGION -PostalCode $POSTAL -Country $COUNTRY
