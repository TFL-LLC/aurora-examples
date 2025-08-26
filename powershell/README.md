# Aurora API Examples — PowerShell

This folder contains working PowerShell examples for interacting with the Aurora API.  

## Files

- **Aurora.Examples.ps1**  
  Core functions for querying events, tickets, autocomplete, and performing managed/unmanaged checkout.

- **Aurora.Examples.Driver.ps1**  
  A sample driver script that demonstrates how to call the core functions end-to-end.

## Usage

1. **Set your API token**  
   Edit the driver script and replace:

   ```powershell
   $TOKEN = "<<TOKEN>>"
   ```

with a valid token from the Aurora Sandbox or Production environment.

2. **Run queries**

   ```powershell
   # Search events
   .\Aurora.Examples.ps1 -Token "<<TOKEN>>" -QueryEvents -SearchText "Chiefs"

   # Get tickets for an event
   .\Aurora.Examples.ps1 -Token "<<TOKEN>>" -QueryTickets -EventId "1972578"

   # Autocomplete
   .\Aurora.Examples.ps1 -Token "<<TOKEN>>" -QueryAutocomplete -SearchText "Taylor Swift"
   ```

3. **Managed checkout**

   The managed flow creates a cart, adds tickets, sets customer info, and performs checkout:

   ```powershell
   .\Aurora.Examples.ps1 -Token "<<TOKEN>>" -ManagedCheckout `
     -ListingId "<listing-guid>" -Quantity 2 -Price 100 -Currency USD `
     -Email "dev@example.com" -FirstName "Jane" -LastName "Doe" `
     -PhoneNumber "555-555-1234" `
     -Address1 "1313 Mockingbird Lane" -City "Kansas City" -Region "MO" -PostalCode "64106" -Country "US"
   ```

4. **Unmanaged checkout**

   The unmanaged flow checks out in one call with customer and tickets:

   ```powershell
   .\Aurora.Examples.ps1 -Token "<<TOKEN>>" -UnmanagedCheckout `
     -ListingId "<listing-guid>" -Quantity 2 -Price 100 -Currency USD `
     -Email "dev@example.com" -FirstName "Jane" -LastName "Doe" `
     -PhoneNumber "555-555-1234" `
     -Address1 "1313 Mockingbird Lane" -City "Kansas City" -Region "MO" -PostalCode "64106" -Country "US"
   ```

5. **Driver script**

   To run all queries + managed and unmanaged flows in sequence:

   ```powershell
   .\Aurora.Examples.Driver.ps1
   ```

## Notes

* Default environment is **sandbox**; use `-Env prod` for production.
* `Price` is **required** for both managed and unmanaged checkouts.
* If you supply an address, all fields except `Address2` must be provided.
