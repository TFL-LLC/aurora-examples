#!/usr/bin/env node
/**
 * Aurora API Examples — JavaScript (Node 18+)
 *
 * Usage:
 *   TOKEN=<TOKEN> ENV=sandbox node aurora_examples.js query-events "Chiefs"
 *   TOKEN=<TOKEN> ENV=sandbox node aurora_examples.js query-tickets <EVENT_ID>
 *   TOKEN=<TOKEN> ENV=sandbox node aurora_examples.js query-autocomplete "Taylor Swift"
 *
 *   TOKEN=<TOKEN> ENV=sandbox node aurora_examples.js managed-checkout <LISTING_ID> <QTY> <PRICE> <CURRENCY> [--email ... --first ... --last ... --phone ... --address1 ... --address2 ... --city ... --region ... --postal ... --country ... --client-order-id ...]
 *
 *   TOKEN=<TOKEN> ENV=sandbox node aurora_examples.js unmanaged-checkout <LISTING_ID> <QTY> <PRICE> <CURRENCY> [same customer flags]
 */

const TOKEN = process.env.TOKEN || "<TOKEN>";
const ENV = process.env.ENV || "sandbox";
const BASE = `https://${ENV}.tflapis.com`;

if (TOKEN === "<TOKEN>") {
  console.error("Set TOKEN env var (e.g., TOKEN=<TOKEN>)");
  process.exit(1);
}

// ---------- tiny arg parser ----------
const args = process.argv.slice(2);
const cmd = args[0];
const positional = [];
const flags = {};
for (let i = 1; i < args.length; i++) {
  const a = args[i];
  if (a.startsWith("--")) {
    const key = a.replace(/^--/, "");
    const val = args[i + 1] && !args[i + 1].startsWith("--") ? args[++i] : "true";
    flags[key] = val;
  } else {
    positional.push(a);
  }
}

async function get(path) {
  const res = await fetch(`${BASE}${path}`, {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: "text/plain, application/json",
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`GET ${path} -> ${res.status}: ${text}`);
  }
  return res.json();
}

async function post(path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: "text/plain, application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body ?? {}),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`POST ${path} -> ${res.status}: ${text}`);
  }
  return res.json();
}

// ---------- customer builder with address rule ----------
function buildCustomer(f) {
  const customer = {
    firstName: f.first ?? process.env.FIRST_NAME ?? "First",
    lastName: f.last ?? process.env.LAST_NAME ?? "Last",
    email: f.email ?? process.env.EMAIL ?? "dev@example.com",
  };
  if (f.phone ?? process.env.PHONE) customer.phoneNumber = f.phone ?? process.env.PHONE;

  const address1 = f.address1 ?? process.env.ADDRESS1;
  const address2 = f.address2 ?? process.env.ADDRESS2 ?? "";
  const city = f.city ?? process.env.CITY;
  const region = f.region ?? process.env.REGION;
  const postal = f.postal ?? process.env.POSTAL;
  const country = f.country ?? process.env.COUNTRY;

  const any = [address1, city, region, postal, country].some(Boolean);
  if (any) {
    const missing = [];
    if (!address1) missing.push("address1");
    if (!city) missing.push("city");
    if (!region) missing.push("region");
    if (!postal) missing.push("postal");
    if (!country) missing.push("country");
    if (missing.length) {
      throw new Error(
        `If any address field is set, the following are required (address2 optional): ${missing.join(", ")}`
      );
    }
    customer.address = { address1, address2, city, region, postalCode: postal, country };
  }
  return customer;
}

// ---------- commands ----------
async function queryEvents(search) {
  const q = encodeURIComponent(search);
  const data = await get(`/Catalog/Events?query=${q}&perPage=10&page=1`);
  console.log(JSON.stringify(data, null, 2));
}

async function queryTickets(eventId) {
  const data = await get(`/Catalog/Events/${eventId}/Tickets`);
  console.log(JSON.stringify(data, null, 2));
}

async function queryAutocomplete(search) {
  const q = encodeURIComponent(search);
  const data = await get(
    `/Catalog/Autocomplete?searchText=${q}&catalogs=event&catalogs=performer&catalogs=venue&catalogs=category`
  );
  console.log(JSON.stringify(data, null, 2));
}

async function managedCheckout(listingId, qty, price, currency) {
  // 1) Create cart
  const cart = await post("/Cart", { items: [] });
  const cartId = cart.id;
  if (!cartId) throw new Error("No cart id returned from /Cart");

  // 2) Add item (single-object body)
  await post(`/Cart/${cartId}/Items`, {
    listingId,
    quantity: Number(qty),
    currencyType: currency,
    price: Number(price),
  });

  // 3) Checkout w/ customer (clientOrderIdentifier optional)
  const customer = buildCustomer({
    email: flags.email,
    first: flags.first,
    last: flags.last,
    phone: flags.phone,
    address1: flags.address1,
    address2: flags.address2,
    city: flags.city,
    region: flags.region,
    postal: flags.postal,
    country: flags.country,
  });

  const body = { customer };
  if (flags["client-order-id"]) body.clientOrderIdentifier = flags["client-order-id"];

  const out = await post(`/Cart/${cartId}/Checkout`, body);
  console.log(JSON.stringify(out, null, 2));
}

async function unmanagedCheckout(listingId, qty, price, currency) {
  const customer = buildCustomer({
    email: flags.email,
    first: flags.first,
    last: flags.last,
    phone: flags.phone,
    address1: flags.address1,
    address2: flags.address2,
    city: flags.city,
    region: flags.region,
    postal: flags.postal,
    country: flags.country,
  });

  const body = {
    customer,
    shoppingCart: {
      items: [
        {
          listingId,
          quantity: Number(qty),
          currencyType: currency,
          price: Number(price),
        },
      ],
    },
  };
  if (flags["client-order-id"]) body.clientOrderIdentifier = flags["client-order-id"];

  const out = await post("/Cart/Checkout", body);
  console.log(JSON.stringify(out, null, 2));
}

// ---------- main ----------
(async () => {
  try {
    switch (cmd) {
      case "query-events":
        if (!positional[0]) throw new Error("Usage: query-events <SEARCH>");
        await queryEvents(positional[0]);
        break;
      case "query-tickets":
        if (!positional[0]) throw new Error("Usage: query-tickets <EVENT_ID>");
        await queryTickets(positional[0]);
        break;
      case "query-autocomplete":
        if (!positional[0]) throw new Error("Usage: query-autocomplete <SEARCH>");
        await queryAutocomplete(positional[0]);
        break;
      case "managed-checkout":
        if (positional.length < 4) throw new Error("Usage: managed-checkout <LISTING_ID> <QTY> <PRICE> <CURRENCY> [--email ... --first ... --last ... --phone ... --address1 ... --address2 ... --city ... --region ... --postal ... --country ... --client-order-id ...]");
        await managedCheckout(positional[0], positional[1], positional[2], positional[3]);
        break;
      case "unmanaged-checkout":
        if (positional.length < 4) throw new Error("Usage: unmanaged-checkout <LISTING_ID> <QTY> <PRICE> <CURRENCY> [--email ... --first ... --last ... ...]");
        await unmanagedCheckout(positional[0], positional[1], positional[2], positional[3]);
        break;
      case undefined:
      case "help":
      case "--help":
      case "-h":
        console.log(`Aurora API Examples — JavaScript

Env:
  TOKEN=<TOKEN> (required)
  ENV=sandbox|prod (default: sandbox)

Commands:
  query-events <SEARCH>
  query-tickets <EVENT_ID>
  query-autocomplete <SEARCH>
  managed-checkout <LISTING_ID> <QTY> <PRICE> <CURRENCY> [--email ... --first ... --last ... --phone ... --address1 ... --address2 ... --city ... --region ... --postal ... --country ... --client-order-id ...]
  unmanaged-checkout <LISTING_ID> <QTY> <PRICE> <CURRENCY> [same flags]

Examples:
  TOKEN=<TOKEN> node aurora_examples.js query-events "Chiefs"
  TOKEN=<TOKEN> node aurora_examples.js query-tickets 1972578
  TOKEN=<TOKEN> node aurora_examples.js query-autocomplete "Taylor Swift"

  TOKEN=<TOKEN> node aurora_examples.js managed-checkout <LISTING_ID> 2 26.00 USD --email dev@example.com --first Jane --last Doe --phone "555-555-1234" --address1 "1313 Mockingbird Lane" --city "Kansas City" --region "MO" --postal "64106" --country "US"

  TOKEN=<TOKEN> node aurora_examples.js unmanaged-checkout <LISTING_ID> 2 26.00 USD --email dev@example.com --first Jane --last Doe
`);
        break;
      default:
        throw new Error(`Unknown command: ${cmd}`);
    }
  } catch (err) {
    console.error(String(err?.message || err));
    process.exit(1);
  }
})();