package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type SearchResponse struct {
	Page    int     `json:"page"`
	PerPage int     `json:"perPage"`
	Records []Event `json:"records"`
	Total   int     `json:"total"`
}

type Event struct {
	ID         string     `json:"id"`
	Name       string     `json:"name"`
	Date       string     `json:"date"`
	Time       string     `json:"time"`
	Categories []Category `json:"categories"`
	Venue      *Venue     `json:"venue"`
	// Keep everything else if present (future-proof)
	Raw map[string]any `json:"-"`
}

// Custom unmarshal to preserve unknown fields without needing a huge model.
func (e *Event) UnmarshalJSON(data []byte) error {
	var m map[string]any
	if err := json.Unmarshal(data, &m); err != nil {
		return err
	}
	e.Raw = m

	// Pull strongly-typed fields we care about
	if v, ok := m["id"].(string); ok {
		e.ID = v
	}
	if v, ok := m["name"].(string); ok {
		e.Name = v
	}
	if v, ok := m["date"].(string); ok {
		e.Date = v
	}
	if v, ok := m["time"].(string); ok {
		e.Time = v
	}

	// categories
	if cats, ok := m["categories"].([]any); ok {
		e.Categories = make([]Category, 0, len(cats))
		for _, c := range cats {
			cm, ok := c.(map[string]any)
			if !ok {
				continue
			}
			var cat Category
			if v, ok := cm["id"].(string); ok {
				cat.ID = v
			}
			if v, ok := cm["name"].(string); ok {
				cat.Name = v
			}
			if v, ok := cm["type"].(string); ok {
				cat.Type = v
			}
			e.Categories = append(e.Categories, cat)
		}
	}

	// venue (optional)
	if v, ok := m["venue"].(map[string]any); ok {
		venue := &Venue{}
		if s, ok := v["id"].(string); ok {
			venue.ID = s
		}
		if s, ok := v["name"].(string); ok {
			venue.Name = s
		}
		if s, ok := v["city"].(string); ok {
			venue.City = s
		}
		if s, ok := v["region"].(string); ok {
			venue.Region = s
		}
		if s, ok := v["postalCode"].(string); ok {
			venue.PostalCode = s
		}
		if s, ok := v["country"].(string); ok {
			venue.Country = s
		}
		e.Venue = venue
	}

	return nil
}

// Marshal back out using the original raw JSON map so we preserve full event payload.
func (e Event) MarshalJSON() ([]byte, error) {
	if e.Raw != nil {
		return json.Marshal(e.Raw)
	}
	// fallback minimal shape
	type Alias Event
	return json.Marshal(Alias(e))
}

type Category struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Type string `json:"type"`
}

type Venue struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	City       string `json:"city"`
	Region     string `json:"region"`
	PostalCode string `json:"postalCode"`
	Country    string `json:"country"`
}

func main() {
	// Inputs
	var (
		search       = flag.String("search", "", "Search text (required). Example: \"nba\"")
		categoryType = flag.String("category-type", "", "Category type to include (required). Example: sport, concert, theater")
		env          = flag.String("env", getenvDefault("ENV", "sandbox"), "Environment subdomain (sandbox, prod, etc). Defaults to ENV or sandbox.")
		perPage      = flag.Int("per-page", 100, "Results per page (1-500 recommended).")
		maxPages     = flag.Int("max-pages", 0, "Optional safety limit. 0 = no limit.")
		timeoutSec   = flag.Int("timeout", 30, "HTTP timeout in seconds.")
	)
	flag.Parse()

	token := strings.TrimSpace(os.Getenv("TOKEN"))
	if token == "" {
		fatalUsage(errors.New("TOKEN env var is required"))
	}
	if strings.TrimSpace(*search) == "" {
		fatalUsage(errors.New("--search is required"))
	}
	if strings.TrimSpace(*categoryType) == "" {
		fatalUsage(errors.New("--category-type is required"))
	}
	if *perPage <= 0 {
		fatalUsage(errors.New("--per-page must be > 0"))
	}

	baseURL := fmt.Sprintf("https://%s.tflapis.com", strings.TrimSpace(*env))

	searchPath := "/Catalog/Events"

	client := &http.Client{Timeout: time.Duration(*timeoutSec) * time.Second}

	want := strings.ToLower(strings.TrimSpace(*categoryType))

	ctx := context.Background()
	page := 1

	// Stream output JSON array
	enc := json.NewEncoder(os.Stdout)
	_, _ = os.Stdout.Write([]byte("["))
	firstOut := true

	total := -1
	seen := 0
	matched := 0

	for {
		if *maxPages > 0 && page > *maxPages {
			break
		}

		resp, err := fetchPage(ctx, client, baseURL, searchPath, token, *search, page, *perPage)
		if err != nil {
			exitErr(err)
		}

		if total < 0 {
			total = resp.Total
		}

		for _, ev := range resp.Records {
			seen++
			if hasCategoryType(ev, want) {
				matched++
				if !firstOut {
					_, _ = os.Stdout.Write([]byte(","))
				}
				firstOut = false
				if err := enc.Encode(ev); err != nil {
					exitErr(fmt.Errorf("failed writing output JSON: %w", err))
				}
			}
		}

		// Stop condition:
		// - If we’ve seen all events based on total
		// - Or if this page returned no records
		if len(resp.Records) == 0 || (resp.Total > 0 && seen >= resp.Total) {
			break
		}

		page++
	}

	_, _ = os.Stdout.Write([]byte("]"))

	// Summary to stderr so stdout remains pure JSON
	fmt.Fprintf(os.Stderr, "\nDone. Total=%d Seen=%d Matched=%d CategoryType=%q Search=%q\n",
		total, seen, matched, want, *search)
}

func fetchPage(ctx context.Context, client *http.Client, baseURL, path, token, search string, page, perPage int) (*SearchResponse, error) {
	u, err := url.Parse(baseURL + path)
	if err != nil {
		return nil, err
	}

	q := u.Query()
	// These parameter names must match your API’s paging/search contract.
	// If your existing samples use different names, change them here.
	q.Set("query", search)
	q.Set("page", strconv.Itoa(page))
	q.Set("perPage", strconv.Itoa(perPage))
	u.RawQuery = q.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Accept", "application/json")

	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	body, _ := io.ReadAll(res.Body)
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		return nil, fmt.Errorf("HTTP %d: %s", res.StatusCode, strings.TrimSpace(string(body)))
	}

	var parsed SearchResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("invalid JSON response: %w\n%s", err, strings.TrimSpace(string(body)))
	}

	return &parsed, nil
}

func hasCategoryType(ev Event, wantLower string) bool {
	for _, c := range ev.Categories {
		if strings.ToLower(strings.TrimSpace(c.Type)) == wantLower {
			return true
		}
	}
	return false
}

func getenvDefault(key, def string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	return v
}

func fatalUsage(err error) {
	fmt.Fprintf(os.Stderr, "Usage:\n  TOKEN=<TOKEN> ENV=sandbox go run . -search \"nba\" -category-type sport > filtered.json\n\nError: %v\n", err)
	os.Exit(2)
}

func exitErr(err error) {
	fmt.Fprintln(os.Stderr, "ERROR:", err)
	os.Exit(1)
}
