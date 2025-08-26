using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

// dotnet build; TOKEN=<TOKEN> ENV=sandbox dotnet run -- query-events "Chiefs"

static string Env => Environment.GetEnvironmentVariable("ENV") ?? "sandbox";
static string BaseUrl => $"https://{Env}.tflapis.com";
static string Token => Environment.GetEnvironmentVariable("TOKEN") ?? "<TOKEN>";
static readonly HttpClient Http = new HttpClient {
    DefaultRequestHeaders = {
        Authorization = new AuthenticationHeaderValue("Bearer", Token),
        Accept = { new MediaTypeWithQualityHeaderValue("application/json"), new MediaTypeWithQualityHeaderValue("text/plain") }
    }
};
static readonly JsonSerializerOptions JsonOpts = new JsonSerializerOptions { WriteIndented = true };

static async Task<HttpResponseMessage> PostAsync(string path, object body)
{
    var json = JsonSerializer.Serialize(body);
    var req = new HttpRequestMessage(HttpMethod.Post, BaseUrl + path) {
        Content = new StringContent(json, Encoding.UTF8, "application/json")
    };
    return await Http.SendAsync(req);
}
static async Task<string> GetAsync(string path) => await Http.GetStringAsync(BaseUrl + path);

static object BuildCustomer(string? email, string? first, string? last, string? phone,
    string? address1, string? address2, string? city, string? region, string? postal, string? country)
{
    var cust = new Dictionary<string, object?>
    {
        ["firstName"] = first ?? "First",
        ["lastName"] = last ?? "Last",
        ["email"] = email ?? "dev@example.com"
    };
    if (!string.IsNullOrWhiteSpace(phone)) cust["phoneNumber"] = phone;

    bool anyAddr = !string.IsNullOrWhiteSpace(address1) || !string.IsNullOrWhiteSpace(city) || !string.IsNullOrWhiteSpace(region) || !string.IsNullOrWhiteSpace(postal) || !string.IsNullOrWhiteSpace(country);
    if (anyAddr)
    {
        if (string.IsNullOrWhiteSpace(address1) || string.IsNullOrWhiteSpace(city) || string.IsNullOrWhiteSpace(region) || string.IsNullOrWhiteSpace(postal) || string.IsNullOrWhiteSpace(country))
            throw new ArgumentException("If any address field is specified, Address1, City, Region, Postal, Country are all required (Address2 optional).");

        cust["address"] = new Dictionary<string, object?> {
            ["address1"] = address1, ["address2"] = address2, ["city"] = city, ["region"] = region, ["postalCode"] = postal, ["country"] = country
        };
    }
    return cust;
}

if (Token == "<TOKEN>")
{
    Console.Error.WriteLine("Set TOKEN env var (e.g., TOKEN=<TOKEN>)");
    return;
}

if (args.Length == 0) { Console.WriteLine("Usage: query-events|query-tickets|query-autocomplete|managed-checkout|unmanaged-checkout ..."); return; }

switch (args[0])
{
    case "query-events":
    {
        var search = Uri.EscapeDataString(args[1]);
        var json = await GetAsync($"/Catalog/Events?query={search}&perPage=10&page=1");
        Console.WriteLine(json);
        break;
    }
    case "query-tickets":
    {
        var eventId = args[1];
        var json = await GetAsync($"/Catalog/Events/{eventId}/Tickets");
        Console.WriteLine(json);
        break;
    }
    case "query-autocomplete":
    {
        var search = Uri.EscapeDataString(args[1]);
        var json = await GetAsync($"/Catalog/Autocomplete?searchText={search}&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category");
        Console.WriteLine(json);
        break;
    }
    case "managed-checkout":
    {
        // args: listingId qty price currency email first last [phone] [address1] [address2] [city] [region] [postal] [country]
        var listingId = args[1];
        var qty = int.Parse(args[2]);
        var price = double.Parse(args[3]);
        var currency = args[4];
        string? email = args.Length > 5 ? args[5] : null;
        string? first = args.Length > 6 ? args[6] : null;
        string? last  = args.Length > 7 ? args[7] : null;
        string? phone = args.Length > 8 ? args[8] : null;
        string? a1 = args.Length > 9 ? args[9] : null;
        string? a2 = args.Length > 10 ? args[10] : null;
        string? city = args.Length > 11 ? args[11] : null;
        string? region = args.Length > 12 ? args[12] : null;
        string? postal = args.Length > 13 ? args[13] : null;
        string? country = args.Length > 14 ? args[14] : null;

        // 1) Create cart
        var cartResp = await PostAsync("/Cart", new { items = Array.Empty<object>() });
        var cartJson = await cartResp.Content.ReadAsStringAsync();
        cartResp.EnsureSuccessStatusCode();
        var cart = JsonSerializer.Deserialize<Dictionary<string, object>>(cartJson)!;
        var cartId = cart["id"]!.ToString();

        // 2) Add item (single object)
        var addResp = await PostAsync($"/Cart/{cartId}/Items", new { listingId, quantity = qty, currencyType = currency, price });
        addResp.EnsureSuccessStatusCode();

        // 3) Checkout
        var customer = BuildCustomer(email, first, last, phone, a1, a2, city, region, postal, country);
        var coResp = await PostAsync($"/Cart/{cartId}/Checkout", new { customer });
        Console.WriteLine(await coResp.Content.ReadAsStringAsync());
        break;
    }
    case "unmanaged-checkout":
    {
        // args: listingId qty price currency email first last [phone] [address1] [address2] [city] [region] [postal] [country]
        var listingId = args[1];
        var qty = int.Parse(args[2]);
        var price = double.Parse(args[3]);
        var currency = args[4];
        string? email = args.Length > 5 ? args[5] : null;
        string? first = args.Length > 6 ? args[6] : null;
        string? last  = args.Length > 7 ? args[7] : null;
        string? phone = args.Length > 8 ? args[8] : null;
        string? a1 = args.Length > 9 ? args[9] : null;
        string? a2 = args.Length > 10 ? args[10] : null;
        string? city = args.Length > 11 ? args[11] : null;
        string? region = args.Length > 12 ? args[12] : null;
        string? postal = args.Length > 13 ? args[13] : null;
        string? country = args.Length > 14 ? args[14] : null;

        var customer = BuildCustomer(email, first, last, phone, a1, a2, city, region, postal, country);
        var body = new {
            customer,
            shoppingCart = new {
                items = new [] { new { listingId, quantity = qty, currencyType = currency, price } }
            }
        };
        var resp = await PostAsync("/Cart/Checkout", body);
        Console.WriteLine(await resp.Content.ReadAsStringAsync());
        break;
    }
    default:
        Console.Error.WriteLine("Unknown command");
        break;
}