#!/usr/bin/env python3
import argparse, json, os, sys, urllib.parse
import requests

ENV = os.getenv("ENV", "sandbox")
BASE = f"https://{ENV}.tflapis.com"
TOKEN = os.getenv("TOKEN", "<TOKEN>")
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "text/plain, application/json",
}

def _post(path: str, body: dict):
    resp = requests.post(BASE + path, headers={**HEADERS, "Content-Type": "application/json"}, json=body)
    if not resp.ok:
        print(f"ERROR {resp.status_code}: {resp.text}", file=sys.stderr)
        resp.raise_for_status()
    return resp.json()

def _get(path: str):
    resp = requests.get(BASE + path, headers=HEADERS)
    if not resp.ok:
        print(f"ERROR {resp.status_code}: {resp.text}", file=sys.stderr)
        resp.raise_for_status()
    return resp.json()

def build_customer(args):
    customer = {
        "firstName": args.first_name or "First",
        "lastName": args.last_name or "Last",
        "email": args.email or "dev@example.com",
    }
    if args.phone: customer["phoneNumber"] = args.phone
    a1 = args.address1
    if any([a1, args.city, args.region, args.postal, args.country]):
        missing = [n for n,v in [("address1",a1),("city",args.city),("region",args.region),("postalCode",args.postal),("country",args.country)] if not v]
        if missing:
            raise SystemExit(f"If any address field is set, the following are required (address2 optional): {', '.join(missing)}")
        customer["address"] = {
            "address1": a1,
            "address2": args.address2,
            "city": args.city,
            "region": args.region,
            "postalCode": args.postal,
            "country": args.country,
        }
    return customer

def query_events(args):
    q = urllib.parse.quote(args.search)
    print(json.dumps(_get(f"/Catalog/Events?query={q}&perPage=10&page=1"), indent=2))

def query_tickets(args):
    print(json.dumps(_get(f"/Catalog/Events/{args.event_id}/Tickets"), indent=2))

def query_autocomplete(args):
    q = urllib.parse.quote(args.search)
    print(json.dumps(_get(f"/Catalog/Autocomplete?searchText={q}&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category"), indent=2))

def managed_checkout(args):
    cart = _post("/Cart", {"items": []})
    cart_id = cart.get("id")
    if not cart_id: raise SystemExit("No cart id returned")

    _post(f"/Cart/{cart_id}/Items", {
        "listingId": args.listing_id,
        "quantity": args.quantity,
        "currencyType": args.currency,
        "price": float(args.price),
    })

    body = {"customer": build_customer(args)}
    if args.client_order_id:
        body["clientOrderIdentifier"] = args.client_order_id

    print(json.dumps(_post(f"/Cart/{cart_id}/Checkout", body), indent=2))

def unmanaged_checkout(args):
    body = {
        "customer": build_customer(args),
        "shoppingCart": {
            "items": [{
                "listingId": args.listing_id,
                "quantity": args.quantity,
                "currencyType": args.currency,
                "price": float(args.price),
            }]
        }
    }
    if args.client_order_id:
        body["clientOrderIdentifier"] = args.client_order_id
    print(json.dumps(_post("/Cart/Checkout", body), indent=2))

def common_checkout_args(sp):
    sp.add_argument("--email", default=os.getenv("EMAIL"))
    sp.add_argument("--first-name", default=os.getenv("FIRST_NAME"))
    sp.add_argument("--last-name", default=os.getenv("LAST_NAME"))
    sp.add_argument("--phone", default=os.getenv("PHONE"))
    sp.add_argument("--address1", default=os.getenv("ADDRESS1"))
    sp.add_argument("--address2", default=os.getenv("ADDRESS2"))
    sp.add_argument("--city", default=os.getenv("CITY"))
    sp.add_argument("--region", default=os.getenv("REGION"))
    sp.add_argument("--postal", default=os.getenv("POSTAL"))
    sp.add_argument("--country", default=os.getenv("COUNTRY"))
    sp.add_argument("--client-order-id")

parser = argparse.ArgumentParser(description="Aurora API Examples — Python")
sub = parser.add_subparsers(dest="cmd", required=True)

sp = sub.add_parser("query-events")
sp.add_argument("search")
sp.set_defaults(func=query_events)

sp = sub.add_parser("query-tickets")
sp.add_argument("event_id")
sp.set_defaults(func=query_tickets)

sp = sub.add_parser("query-autocomplete")
sp.add_argument("search")
sp.set_defaults(func=query_autocomplete)

sp = sub.add_parser("managed-checkout")
sp.add_argument("listing_id")
sp.add_argument("quantity", type=int)
sp.add_argument("price", type=float)
sp.add_argument("currency")
common_checkout_args(sp)
sp.set_defaults(func=managed_checkout)

sp = sub.add_parser("unmanaged-checkout")
sp.add_argument("listing_id")
sp.add_argument("quantity", type=int)
sp.add_argument("price", type=float)
sp.add_argument("currency")
common_checkout_args(sp)
sp.set_defaults(func=unmanaged_checkout)

if __name__ == "__main__":
  if TOKEN == "<TOKEN>":
    sys.exit("Set TOKEN env var (export TOKEN=<TOKEN>)")
  args = parser.parse_args()
  args.func(args)