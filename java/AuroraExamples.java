import java.net.URI;
import java.net.URLEncoder;
import java.net.http.*;
import java.nio.charset.StandardCharsets;

public class AuroraExamples {
  static String ENV = System.getenv().getOrDefault("ENV", "sandbox");
  static String BASE = "https://" + ENV + ".tflapis.com";
  static String TOKEN = System.getenv().getOrDefault("TOKEN", "<TOKEN>");
  static HttpClient http = HttpClient.newHttpClient();

  static HttpRequest.Builder baseReq(String path) {
    return HttpRequest.newBuilder(URI.create(BASE + path))
      .header("Authorization", "Bearer " + TOKEN)
      .header("Accept", "text/plain, application/json");
  }
  static String get(String path) throws Exception {
    var res = http.send(baseReq(path).GET().build(), HttpResponse.BodyHandlers.ofString());
    if (res.statusCode() >= 400) throw new RuntimeException(res.statusCode() + " " + res.body());
    return res.body();
  }
  static String post(String path, String json) throws Exception {
    var res = http.send(baseReq(path).header("Content-Type","application/json")
      .POST(HttpRequest.BodyPublishers.ofString(json)).build(), HttpResponse.BodyHandlers.ofString());
    if (res.statusCode() >= 400) throw new RuntimeException(res.statusCode() + " " + res.body());
    return res.body();
  }

  static String enc(String s){ return URLEncoder.encode(s, StandardCharsets.UTF_8); }

  public static void main(String[] args) throws Exception {
    if (TOKEN.equals("<TOKEN>")) { System.err.println("Set TOKEN env var"); return; }
    if (args.length == 0) { System.out.println("usage: query-events|query-tickets|query-autocomplete|managed-checkout|unmanaged-checkout ..."); return; }

    switch (args[0]) {
      case "query-events": {
        var q = enc(args[1]);
        System.out.println(get("/Catalog/Events?query=" + q + "&perPage=10&page=1"));
        break;
      }
      case "query-tickets": {
        String eventId = args[1];
        System.out.println(get("/Catalog/Events/" + eventId + "/Tickets"));
        break;
      }
      case "query-autocomplete": {
        var q = enc(args[1]);
        System.out.println(get("/Catalog/Autocomplete?searchText=" + q + "&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category"));
        break;
      }
      case "managed-checkout": {
        // listingId qty price currency email first last [phone] [addr1] [addr2] [city] [region] [postal] [country]
        String listingId = args[1];
        int qty = Integer.parseInt(args[2]);
        double price = Double.parseDouble(args[3]);
        String currency = args[4];
        String email = args.length>5?args[5]:null, first=args.length>6?args[6]:null, last=args.length>7?args[7]:null;
        String phone = args.length>8?args[8]:null, a1=args.length>9?args[9]:null, a2=args.length>10?args[10]:null;
        String city=args.length>11?args[11]:null, region=args.length>12?args[12]:null, postal=args.length>13?args[13]:null, country=args.length>14?args[14]:null;

        String cart = post("/Cart", "{\"items\":[]}");
        String cartId = cart.replaceAll(".*\"id\"\\s*:\\s*\"([^\"]+)\".*", "$1");
        post("/Cart/" + cartId + "/Items", String.format("{\"listingId\":\"%s\",\"quantity\":%d,\"currencyType\":\"%s\",\"price\":%s}", listingId, qty, currency, Double.toString(price)));

        String customer = "{\"firstName\":\"" + (first==null?"First":first) + "\",\"lastName\":\"" + (last==null?"Last":last) + "\",\"email\":\"" + (email==null?"dev@example.com":email) + "\""
          + (phone!=null? ",\"phoneNumber\":\"" + phone + "\"" : "")
          + (a1!=null && !a1.isBlank() ? ",\"address\":{\"address1\":\"" + a1 + "\",\"address2\":\"" + (a2==null?"":a2) + "\",\"city\":\"" + city + "\",\"region\":\"" + region + "\",\"postalCode\":\"" + postal + "\",\"country\":\"" + country + "\"}" : "")
          + "}";

        String body = "{\"customer\":" + customer + "}";
        System.out.println(post("/Cart/" + cartId + "/Checkout", body));
        break;
      }
      case "unmanaged-checkout": {
        String listingId = args[1];
        int qty = Integer.parseInt(args[2]);
        double price = Double.parseDouble(args[3]);
        String currency = args[4];
        String email = args.length>5?args[5]:null, first=args.length>6?args[6]:null, last=args.length>7?args[7]:null;
        String phone = args.length>8?args[8]:null, a1=args.length>9?args[9]:null, a2=args.length>10?args[10]:null;
        String city=args.length>11?args[11]:null, region=args.length>12?args[12]:null, postal=args.length>13?args[13]:null, country=args.length>14?args[14]:null;

        String customer = "{\"firstName\":\"" + (first==null?"First":first) + "\",\"lastName\":\"" + (last==null?"Last":last) + "\",\"email\":\"" + (email==null?"dev@example.com":email) + "\""
          + (phone!=null? ",\"phoneNumber\":\"" + phone + "\"" : "")
          + (a1!=null && !a1.isBlank() ? ",\"address\":{\"address1\":\"" + a1 + "\",\"address2\":\"" + (a2==null?"":a2) + "\",\"city\":\"" + city + "\",\"region\":\"" + region + "\",\"postalCode\":\"" + postal + "\",\"country\":\"" + country + "\"}" : "")
          + "}";

        String body = "{\"customer\":" + customer + ",\"shoppingCart\":{\"items\":[{\"listingId\":\"" + listingId + "\",\"quantity\":" + qty + ",\"currencyType\":\"" + currency + "\",\"price\":" + Double.toString(price) + "}]}}";
        System.out.println(post("/Cart/Checkout", body));
        break;
      }
      default: System.err.println("Unknown command"); break;
    }
  }
}