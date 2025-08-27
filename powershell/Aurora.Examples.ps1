<#
.SYNOPSIS
  Aurora API Examples — query & checkout flows.

.DESCRIPTION
  Switch-driven PowerShell samples for Aurora API with sandbox default.
  Supports:
    - Query events, autocomplete, and tickets
    - Managed checkout: create cart -> add ticket -> set customer -> checkout
    - Unmanaged checkout: single-call checkout with ticket + customer

.EXAMPLES
  # Query events (sandbox default)
  .\Aurora.Examples.ps1 -Token "<TOKEN>" -QueryEvents -SearchText "Chiefs"

  # Tickets for an event
  .\Aurora.Examples.ps1 -Token "<TOKEN>" -QueryTickets -EventId "1972578"

  # Autocomplete across catalogs
  .\Aurora.Examples.ps1 -Token "<TOKEN>" -QueryAutocomplete -SearchText "Taylor Swift"

  # Managed checkout flow
  .\Aurora.Examples.ps1 -Token "<TOKEN>" -ManagedCheckout `
    -ListingId "ABC123" -Quantity 2 -Currency USD `
    -Email "test@example.com" -FirstName "Jane" -LastName "Doe"

  # Unmanaged checkout flow
  .\Aurora.Examples.ps1 -Token "<TOKEN>" -UnmanagedCheckout `
    -ListingId "ABC123" -Quantity 2 -Currency USD `
    -Email "test@example.com" -FirstName "Jane" -LastName "Doe"
#>

[CmdletBinding(DefaultParameterSetName = 'Queries')]
param(
  # --- Common ---
  [ValidateSet('sandbox','prod')]
  [string]$Env = 'sandbox',

  [Parameter(Mandatory)]
  [string]$Token,

  # --- Query inputs ---
  [Parameter(ParameterSetName='Queries')]
  [switch]$QueryEvents,

  [Parameter(ParameterSetName='Queries')]
  [switch]$QueryAutocomplete,

  [Parameter(ParameterSetName='Queries')]
  [switch]$QueryTickets,

  [Parameter(ParameterSetName='Queries')]
  [string]$SearchText,

  [Parameter(ParameterSetName='Queries')]
  [string]$EventId,

  # --- Managed checkout path ---
  [Parameter(ParameterSetName='Managed')]
  [switch]$ManagedCheckout,

  # --- Unmanaged checkout path ---
  [Parameter(ParameterSetName='Unmanaged')]
  [switch]$UnmanagedCheckout,

  # --- Shared checkout inputs ---
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [Parameter(ParameterSetName='Queries')]
  [string]$ListingId,

  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [ValidateRange(1, 10)]
  [int]$Quantity = 1,
  
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [ValidateRange(1, 100000)]
  [double]$Price,

  # Customer (minimal)
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$FirstName = "First",

  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$LastName = "Last",
    
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$Email = "dev@example.com",
  
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$PhoneNumber,
  
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$Address1,
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$Address2,
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$City,
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$Region,
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$PostalCode,
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$Country,
  
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$Currency,
  
  # Optional client order identifier
  [Parameter(ParameterSetName='Managed')]
  [Parameter(ParameterSetName='Unmanaged')]
  [string]$ClientOrderId    
)

# ---- Setup ----
$Base    = "https://$Env.tflapis.com"
$Headers = @{ Authorization = "Bearer $Token" }

function Write-Title([string]$text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }

function New-QueryString {
  param([hashtable]$Query)
  if (-not $Query -or $Query.Count -eq 0) { return "" }
  $pairs = New-Object System.Collections.Generic.List[string]
  foreach ($key in $Query.Keys) {
    $val = $Query[$key]
    if ($null -eq $val) { continue }
    $isEnumerable = ($val -is [System.Collections.IEnumerable]) -and -not ($val -is [string])
    if ($isEnumerable) {
      foreach ($v in $val) {
        $pairs.Add( [System.Uri]::EscapeDataString([string]$key) + "=" + [System.Uri]::EscapeDataString([string]$v) )
      }
    } else {
      $pairs.Add( [System.Uri]::EscapeDataString([string]$key) + "=" + [System.Uri]::EscapeDataString([string]$val) )
    }
  }
  return ($pairs -join "&")
}

function Invoke-Aurora {
  param(
    [Parameter(Mandatory)] [ValidateSet('GET','POST')]
    [string]$Method,
    [Parameter(Mandatory)]
    [string]$Path,
    [hashtable]$Query,
    $Body
  )

  $reqHeaders = @{
    Authorization = "Bearer $Token"
    Accept        = "text/plain, application/json"
  }

  $qs = New-QueryString -Query $Query
  $url = if ([string]::IsNullOrEmpty($qs)) { "$Base$Path" } else { "$Base$Path`?$qs" }

  try {
    if ($Method -eq 'POST') {
      if (-not $PSBoundParameters.ContainsKey('Body') -or $null -eq $Body) { $Body = @{} }
      $json = ($Body | ConvertTo-Json -Depth 10)
      $resp = Invoke-RestMethod -Headers $reqHeaders -ContentType "application/json" -Method $Method -Body $json -Uri $url
    } else {
      $resp = Invoke-RestMethod -Headers $reqHeaders -Method $Method -Uri $url
    }
    return $resp
  }
  catch {
    $status = $null
    if ($_.Exception -and $_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $status = [int]$_.Exception.Response.StatusCode
      # Try to surface raw response
      try {
        $rs = $_.Exception.Response.GetResponseStream()
        if ($rs) { $raw = (New-Object IO.StreamReader($rs)).ReadToEnd(); if ($raw) { Write-Host "Server said: $raw" -ForegroundColor Yellow } }
      } catch {}
    }
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { Write-Error $_.ErrorDetails.Message } else { Write-Error $_.Exception.Message }
    if ($status -eq 404) { Write-Warning "Not Found - verify IDs and environment ($Env)." }
    throw
  }
}

# ---- Query helpers ----

function Get-AuroraEvents {
  param([Parameter(Mandatory)][string]$SearchText)
  Write-Title "Search Events: '$SearchText'"
  Invoke-Aurora -Method GET -Path "/Catalog/Events" -Query @{ query = $SearchText; perPage = 10; page = 1 }
}

function Get-AuroraTickets {
  param(
    [Parameter(Mandatory)][string]$EventId
  )
  Write-Title "Tickets for Event $EventId"
  Invoke-Aurora -Method GET -Path "/Catalog/Events/$EventId/Tickets"
}

function Get-AuroraAutocomplete {
  param([Parameter(Mandatory)][string]$SearchText)
  Write-Title "Autocomplete: '$SearchText'"
  # Use repeated keys via array values
  $q = @{
    searchText = $SearchText
    catalogs   = @('event','performer','venue','category')
  }
  Invoke-Aurora -Method GET -Path "/Catalog/Autocomplete" -Query $q
}

# ---- Managed checkout flow ----

function New-AuroraCart {
  Write-Title "Create Cart"
  Invoke-Aurora -Method POST -Path "/Cart" -Body @{ items = @() }
}

function Add-AuroraCartItem {
  param(
    [Parameter(Mandatory)][string]$CartId,
    [Parameter(Mandatory)][string]$ListingId,
    [Parameter(Mandatory)][int]$Quantity,
    [Parameter(Mandatory)][double]$Price,
    [string]$Currency
  )
  Write-Title "Add Ticket to Cart $CartId"

  $body = @{
    listingId    = $ListingId
    quantity     = $Quantity
    currencyType = $Currency
    price        = [double]$Price
  }

  Invoke-Aurora -Method POST -Path "/Cart/$CartId/Items" -Body $body
}

function BuildCustomer {
  param(
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$LastName,
    [Parameter(Mandatory)][string]$Email,
    [string]$PhoneNumber,
    [string]$Address1,
    [string]$Address2,
    [string]$City,
    [string]$Region,
    [string]$PostalCode,
    [string]$Country
  )

  $customer = @{
    firstName = $FirstName
    lastName  = $LastName
    email     = $Email
  }
  if ($PhoneNumber) { $customer.phoneNumber = $PhoneNumber }

  $anyAddress = $Address1 -or $City -or $Region -or $PostalCode -or $Country
  if ($anyAddress) {
    $missing = @()
    if (-not $Address1)   { $missing += 'Address1' }
    if (-not $City)       { $missing += 'City' }
    if (-not $Region)     { $missing += 'Region' }
    if (-not $PostalCode) { $missing += 'PostalCode' }
    if (-not $Country)    { $missing += 'Country' }
    if ($missing.Count -gt 0) {
      throw "If any address field is specified, the following are required (Address2 is optional): $($missing -join ', ')"
    }

    $customer.address = @{
      address1   = $Address1
      address2   = $Address2
      city       = $City
      region     = $Region
      postalCode = $PostalCode
      country    = $Country
    }
  }

  return $customer
}

function Set-AuroraCartCustomer {
  param(
    [Parameter(Mandatory)][string]$CartId,    
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$LastName,
	[Parameter(Mandatory)][string]$Email,
	[Parameter(Mandatory)][string]$PhoneNumber,
	[Parameter][string]$Address1,
    [Parameter][string]$Address2,
    [Parameter][string]$City,
    [Parameter][string]$Region,
    [Parameter][string]$PostalCode,
    [Parameter][string]$Country
  )
  Write-Title "Set Customer on Cart $CartId"
  
  $customer = BuildCustomer -FirstName $FirstName -LastName $LastName -Email $Email -PhoneNumber $PhoneNumber -Address1 $Address1 `
                -Address2 $Address2 -City $City -Region $Region -PostalCode $PostalCode -Country $Country
  
  Invoke-Aurora -Method POST -Path "/Cart/$CartId/Customer" -Body $customer
}

function Checkout-AuroraManaged {
  param(
    [Parameter(Mandatory)][string]$CartId
  )
  Write-Title "Managed Checkout (Cart $CartId)"

  $customer = BuildCustomer -FirstName $FirstName -LastName $LastName -Email $Email `
                            -PhoneNumber $PhoneNumber -Address1 $Address1 -Address2 $Address2 `
                            -City $City -Region $Region -PostalCode $PostalCode -Country $Country

  $body = @{ customer = $customer }
  if ($ClientOrderId) { $body.clientOrderIdentifier = $ClientOrderId }

  Invoke-Aurora -Method POST -Path "/Cart/$CartId/Checkout" -Body $body
}

# ---- Unmanaged checkout flow (single call) ----

function Checkout-AuroraUnmanaged {
  param(
    [Parameter(Mandatory)][string]$ListingId,
    [Parameter(Mandatory)][int]$Quantity,
    [Parameter(Mandatory)][double]$Price,
    [Parameter(Mandatory)][string]$Currency
  )
  Write-Title "Unmanaged Checkout"

  $customer = BuildCustomer -FirstName $FirstName -LastName $LastName -Email $Email `
                            -PhoneNumber $PhoneNumber -Address1 $Address1 -Address2 $Address2 `
                            -City $City -Region $Region -PostalCode $PostalCode -Country $Country

  $item = @{
    listingId    = $ListingId
    quantity     = $Quantity
	currencyType = $Currency
    price        = $Price    
  }

  $body = @{
    customer     = $customer
    shoppingCart = @{ items = @($item) }
  }
  if ($ClientOrderId) { $body.clientOrderIdentifier = $ClientOrderId }

  Invoke-Aurora -Method POST -Path "/Cart/Checkout" -Body $body
}

# ---- Dispatcher ----

switch ($PSCmdlet.ParameterSetName) {
  'Queries' {
    if ($QueryEvents) {
      if (-not $SearchText) { throw "Specify -SearchText for -QueryEvents." }
      $res = Get-AuroraEvents -SearchText $SearchText
      $res | ConvertTo-Json -Depth 10
      break
    }
    if ($QueryTickets) {
      if (-not $EventId) { throw "Specify -EventId for -QueryTickets." }
      $res = Get-AuroraTickets -EventId $EventId
      $res | ConvertTo-Json -Depth 10
      break
    }
    if ($QueryAutocomplete) {
      if (-not $SearchText) { throw "Specify -SearchText for -QueryAutocomplete." }
      $res = Get-AuroraAutocomplete -SearchText $SearchText
      $res | ConvertTo-Json -Depth 10
      break
    }
    throw "No query switch specified. Use -QueryEvents, -QueryTickets, or -QueryAutocomplete; or use -ManagedCheckout / -UnmanagedCheckout."
  }

  'Managed' {
    if (-not $ListingId) { throw "Managed checkout requires -ListingId." }
    if (-not $PSBoundParameters.ContainsKey('Price')) { throw "Managed checkout requires -Price." }
  
    $cart = New-AuroraCart
    $cartId = $cart.id
    if (-not $cartId) { throw "Cart creation did not return an 'id'." }
  
    Add-AuroraCartItem -CartId $cartId -ListingId $ListingId -Quantity $Quantity -Price $Price -Currency $Currency | Out-Null
    
    $order = Checkout-AuroraManaged -CartId $cartId
    $order | ConvertTo-Json -Depth 10
    break
  }

  'Unmanaged' {
    if (-not $ListingId) { throw "Unmanaged checkout requires -ListingId." }
    if (-not $PSBoundParameters.ContainsKey('Price')) { throw "Unmanaged checkout requires -Price." }
  
    $order = Checkout-AuroraUnmanaged `
                -ListingId $ListingId `
                -Quantity  $Quantity `
                -Price     $Price `
                -Currency  $Currency
  
    $order | ConvertTo-Json -Depth 10
    break
  }

  default {
    throw "Unknown mode."
  }
}
