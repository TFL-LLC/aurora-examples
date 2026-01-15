package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

func main() {
	env := getenv("ENV", "sandbox")
	baseURL := fmt.Sprintf("https://%s.tflapis.com", env)
	token := getenv("TOKEN", "<TOKEN>")

	if token == "<TOKEN>" {
		fmt.Fprintln(os.Stderr, "Set TOKEN env var (export TOKEN=<TOKEN>)")
		os.Exit(1)
	}

	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}

	client := &APIClient{
		BaseURL: baseURL,
		Token:   token,
		HTTP: &http.Client{
			Timeout: 60 * time.Second,
		},
	}

	cmd := os.Args[1]
	args := os.Args[2:]

	switch cmd {
	case "query-events":
		if len(args) < 1 {
			dieUsage("query-events <search text>")
		}
		search := args[0]
		path := fmt.Sprintf("/Catalog/Events?query=%s&perPage=10&page=1", url.QueryEscape(search))
		obj := must(client.GetJSON(path))
		printPretty(obj)

	case "query-tickets":
		if len(args) < 1 {
			dieUsage("query-tickets <event_id>")
		}
		eventID := args[0]
		obj := must(client.GetJSON(fmt.Sprintf("/Catalog/Events/%s/Tickets", eventID)))
		printPretty(obj)

	case "query-autocomplete":
		if len(args) < 1 {
			dieUsage("query-autocomplete <search text>")
		}
		search := args[0]
		path := fmt.Sprintf("/Catalog/Autocomplete?searchText=%s&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category",
			url.QueryEscape(search))
		obj := must(client.GetJSON(path))
		printPretty(obj)

	case "managed-checkout":
		managedCheckout(client, args)

	case "unmanaged-checkout":
		unmanagedCheckout(client, args)

	default:
		fmt.Fprintln(os.Stderr, "Unknown command:", cmd)
		usage()
		os.Exit(1)
	}
}

func usage() {
	fmt.Println(`Usage:
  query-events <search>
  query-tickets <event_id>
  query-autocomplete <search>

  managed-checkout   <listing_id> <quantity> <price> <currency> [--email ...] [--first-name ...] [--last-name ...] [--phone ...] [--address1 ... --city ... --region ... --postal ... --country ...] [--address2 ...] [--client-order-id ...]
  unmanaged-checkout <listing_id> <quantity> <price> <currency> [--email ...] [--first-name ...] [--last-name ...] [--phone ...] [--address1 ... --city ... --region ... --postal ... --country ...] [--address2 ...] [--client-order-id ...]

Environment:
  ENV   (default: sandbox) -> base URL https://{ENV}.tflapis.com
  TOKEN (required)         -> Bearer token`)
}

func dieUsage(msg string) {
	fmt.Fprintln(os.Stderr, "Usage error:", msg)
	fmt.Fprintln(os.Stderr)
	usage()
	os.Exit(2)
}

func getenv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

// ---------- API client ----------

type APIClient struct {
	BaseURL string
	Token   string
	HTTP    *http.Client
}

func (c *APIClient) newRequest(method, path string, body io.Reader) (*http.Request, error) {
	req, err := http.NewRequest(method, c.BaseURL+path, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.Token)
	req.Header.Set("Accept", "text/plain, application/json")
	return req, nil
}

func (c *APIClient) GetJSON(path string) (any, error) {
	req, err := c.newRequest(http.MethodGet, path, nil)
	if err != nil {
		return nil, err
	}
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ERROR %d: %s", resp.StatusCode, strings.TrimSpace(string(b)))
	}
	return decodeJSON(resp.Body)
}

func (c *APIClient) PostJSON(path string, payload any) (any, error) {
	b, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	req, err := c.newRequest(http.MethodPost, path, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("ERROR %d: %s", resp.StatusCode, strings.TrimSpace(string(bodyBytes)))
	}
	return decodeJSON(bytes.NewReader(bodyBytes))
}

func decodeJSON(r io.Reader) (any, error) {
	var v any
	dec := json.NewDecoder(r)
	dec.UseNumber()
	if err := dec.Decode(&v); err != nil {
		return nil, err
	}
	return v, nil
}

func must(v any, err error) any {
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	return v
}

func printPretty(v any) {
	out, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		fmt.Fprintln(os.Stderr, "Failed to format JSON:", err)
		os.Exit(1)
	}
	fmt.Println(string(out))
}

// ---------- Customer + checkout ----------

type CheckoutFlags struct {
	Email         string
	FirstName     string
	LastName      string
	Phone         string
	Address1      string
	Address2      string
	City          string
	Region        string
	Postal        string
	Country       string
	ClientOrderID string
}

func (f *CheckoutFlags) BuildCustomer() (map[string]any, error) {
	customer := map[string]any{
		"firstName": pick(f.FirstName, "First"),
		"lastName":  pick(f.LastName, "Last"),
		"email":     pick(f.Email, "dev@example.com"),
	}
	if strings.TrimSpace(f.Phone) != "" {
		customer["phoneNumber"] = f.Phone
	}

	anyAddr := strings.TrimSpace(f.Address1) != "" ||
		strings.TrimSpace(f.City) != "" ||
		strings.TrimSpace(f.Region) != "" ||
		strings.TrimSpace(f.Postal) != "" ||
		strings.TrimSpace(f.Country) != ""

	if anyAddr {
		missing := []string{}
		if strings.TrimSpace(f.Address1) == "" {
			missing = append(missing, "address1")
		}
		if strings.TrimSpace(f.City) == "" {
			missing = append(missing, "city")
		}
		if strings.TrimSpace(f.Region) == "" {
			missing = append(missing, "region")
		}
		if strings.TrimSpace(f.Postal) == "" {
			missing = append(missing, "postalCode")
		}
		if strings.TrimSpace(f.Country) == "" {
			missing = append(missing, "country")
		}
		if len(missing) > 0 {
			return nil, fmt.Errorf("if any address field is set, the following are required (address2 optional): %s", strings.Join(missing, ", "))
		}
		customer["address"] = map[string]any{
			"address1":    f.Address1,
			"address2":    emptyToNil(f.Address2),
			"city":        f.City,
			"region":      f.Region,
			"postalCode":  f.Postal,
			"country":     f.Country,
		}
	}

	return customer, nil
}

func emptyToNil(s string) any {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	return s
}

func pick(v, def string) string {
	if strings.TrimSpace(v) == "" {
		return def
	}
	return v
}

func parseCheckoutFlags(name string, args []string) (CheckoutFlags, []string, error) {
	fs := flag.NewFlagSet(name, flag.ContinueOnError)
	// Silence default output; we’ll return errors ourselves.
	fs.SetOutput(io.Discard)

	var f CheckoutFlags
	fs.StringVar(&f.Email, "email", os.Getenv("EMAIL"), "Customer email (or env EMAIL)")
	fs.StringVar(&f.FirstName, "first-name", os.Getenv("FIRST_NAME"), "Customer first name (or env FIRST_NAME)")
	fs.StringVar(&f.LastName, "last-name", os.Getenv("LAST_NAME"), "Customer last name (or env LAST_NAME)")
	fs.StringVar(&f.Phone, "phone", os.Getenv("PHONE"), "Customer phone (or env PHONE)")

	fs.StringVar(&f.Address1, "address1", os.Getenv("ADDRESS1"), "Address line 1 (or env ADDRESS1)")
	fs.StringVar(&f.Address2, "address2", os.Getenv("ADDRESS2"), "Address line 2 (or env ADDRESS2)")
	fs.StringVar(&f.City, "city", os.Getenv("CITY"), "City (or env CITY)")
	fs.StringVar(&f.Region, "region", os.Getenv("REGION"), "Region/state (or env REGION)")
	fs.StringVar(&f.Postal, "postal", os.Getenv("POSTAL"), "Postal/zip (or env POSTAL)")
	fs.StringVar(&f.Country, "country", os.Getenv("COUNTRY"), "Country code (or env COUNTRY)")

	fs.StringVar(&f.ClientOrderID, "client-order-id", "", "Optional client order identifier")

	if err := fs.Parse(args); err != nil {
		return CheckoutFlags{}, nil, err
	}
	return f, fs.Args(), nil
}

func managedCheckout(client *APIClient, args []string) {
	// Go's standard flag package stops parsing flags once it encounters the first
	// non-flag argument. Our CLI expects the 4 required positional args first and
	// then optional flags afterwards, so we split them explicitly.
	if len(args) < 4 {
		dieUsage("managed-checkout <listing_id> <quantity> <price> <currency> [flags...]")
	}
	listingID := args[0]
	qty := args[1]
	price := args[2]
	currency := args[3]

	flags, _, err := parseCheckoutFlags("managed-checkout", args[4:])
	if err != nil {
		dieUsage("managed-checkout <listing_id> <quantity> <price> <currency> [flags...]")
	}

	// 1) Create cart
	cartObj := must(client.PostJSON("/Cart", map[string]any{"items": []any{}})).(map[string]any)
	cartIDVal, ok := cartObj["id"]
	if !ok || fmt.Sprint(cartIDVal) == "" {
		fmt.Fprintln(os.Stderr, "No cart id returned")
		os.Exit(1)
	}
	cartID := fmt.Sprint(cartIDVal)

	// 2) Add item
	_ = must(client.PostJSON(fmt.Sprintf("/Cart/%s/Items", cartID), map[string]any{
		"listingId":     listingID,
		"quantity":      mustInt(qty),
		"currencyType":  currency,
		"price":         mustFloat(price),
	}))

	// 3) Checkout
	customer, err := flags.BuildCustomer()
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(2)
	}

	body := map[string]any{
		"customer": customer,
	}
	if strings.TrimSpace(flags.ClientOrderID) != "" {
		body["clientOrderIdentifier"] = flags.ClientOrderID
	}

	out := must(client.PostJSON(fmt.Sprintf("/Cart/%s/Checkout", cartID), body))
	printPretty(out)
}

func unmanagedCheckout(client *APIClient, args []string) {
	// Same positional-then-flags convention as managed-checkout.
	if len(args) < 4 {
		dieUsage("unmanaged-checkout <listing_id> <quantity> <price> <currency> [flags...]")
	}
	listingID := args[0]
	qty := mustInt(args[1])
	price := mustFloat(args[2])
	currency := args[3]

	flags, _, err := parseCheckoutFlags("unmanaged-checkout", args[4:])
	if err != nil {
		dieUsage("unmanaged-checkout <listing_id> <quantity> <price> <currency> [flags...]")
	}

	customer, err := flags.BuildCustomer()
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(2)
	}

	body := map[string]any{
		"customer": customer,
		"shoppingCart": map[string]any{
			"items": []any{
				map[string]any{
					"listingId":     listingID,
					"quantity":      qty,
					"currencyType":  currency,
					"price":         price,
				},
			},
		},
	}
	if strings.TrimSpace(flags.ClientOrderID) != "" {
		body["clientOrderIdentifier"] = flags.ClientOrderID
	}

	out := must(client.PostJSON("/Cart/Checkout", body))
	printPretty(out)
}

func mustInt(s string) int {
	i, err := parseInt(s)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Invalid integer:", s)
		os.Exit(2)
	}
	return i
}

func mustFloat(s string) float64 {
	f, err := parseFloat(s)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Invalid number:", s)
		os.Exit(2)
	}
	return f
}

func parseInt(s string) (int, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, errors.New("empty")
	}
	var i int
	_, err := fmt.Sscanf(s, "%d", &i)
	return i, err
}

func parseFloat(s string) (float64, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, errors.New("empty")
	}
	var f float64
	_, err := fmt.Sscanf(s, "%f", &f)
	return f, err
}
