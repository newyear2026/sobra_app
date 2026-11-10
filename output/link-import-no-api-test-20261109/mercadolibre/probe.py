#!/usr/bin/env python3
"""Small, API-free public-page probe. No login, cookies, API keys or proxies."""
import concurrent.futures
import datetime
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import subprocess
import tempfile

SAMPLES = [
    ("adidas_sneaker", "https://articulo.mercadolibre.com.mx/MLM-3990889244-tenis-adidas-correr-hombre-negro-jq8645-_JM?searchVariation=190036940257"),
    ("iphone_catalog", "https://www.mercadolibre.com.mx/apple-iphone-15-128-gb-azul-distribuidor-autorizado/p/MLM1027172667"),
]

class Metadata(HTMLParser):
    def __init__(self):
        super().__init__()
        self.meta, self.images, self.jsonld, self.visible = [], [], [], []
        self.title, self.in_title, self.script, self.style = "", False, None, False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "meta":
            name = a.get("property") or a.get("name") or a.get("itemprop") or ""
            if name.startswith(("og:", "product:")) or name in ("price", "priceCurrency", "image"):
                self.meta.append({"field": name, "value": a.get("content")})
        if tag == "img" and a.get("src"):
            self.images.append({"src": a["src"], "alt": a.get("alt", "")})
        if tag == "title": self.in_title = True
        if tag == "style": self.style = True
        if tag == "script": self.script = {"type": a.get("type"), "text": ""}

    def handle_data(self, data):
        if self.in_title: self.title += data
        if self.script is not None: self.script["text"] += data
        elif not self.style and data.strip(): self.visible.append(data.strip())

    def handle_endtag(self, tag):
        if tag == "title": self.in_title = False
        if tag == "style": self.style = False
        if tag == "script" and self.script is not None:
            if self.script["type"] == "application/ld+json":
                try: self.jsonld.append(json.loads(self.script["text"]))
                except ValueError: pass
            self.script = None

def products(obj):
    if isinstance(obj, dict):
        t = obj.get("@type", [])
        if t == "Product" or isinstance(t, list) and "Product" in t:
            yield {k: obj[k] for k in ("@type", "name", "image", "offers") if k in obj}
        for value in obj.values(): yield from products(value)
    elif isinstance(obj, list):
        for value in obj: yield from products(value)

def has_offer_price(obj):
    if isinstance(obj, dict):
        return any(obj.get(k) is not None for k in ("price", "lowPrice", "highPrice")) or any(has_offer_price(v) for v in obj.values())
    if isinstance(obj, list):
        return any(has_offer_price(v) for v in obj)
    return False

def probe(sample):
    name, url = sample
    result = {"sample": name, "url": url, "tested_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat()}
    with tempfile.TemporaryDirectory(prefix="sobrita-public-page-") as tmp:
        body = Path(tmp) / "body.html"
        proc = subprocess.run([
            "curl", "--disable", "--noproxy", "*", "--location", "--compressed", "--max-time", "25", "--silent", "--show-error",
            "--user-agent", "Sobrita-LinkPreview-Test/1.0", "--output", str(body),
            "--write-out", "%{http_code}\n%{url_effective}\n%{content_type}", url,
        ], capture_output=True, text=True)
        parts = proc.stdout.splitlines()
        result.update({"curl_exit": proc.returncode, "http_status": int(parts[0]) if parts and parts[0].isdigit() else None,
                       "final_url": parts[1] if len(parts) > 1 else None, "content_type": parts[2] if len(parts) > 2 else None,
                       "network_error": proc.stderr.strip() or None})
        raw = body.read_bytes() if body.exists() else b""
        parser = Metadata(); parser.feed(raw.decode("utf-8", errors="replace"))
        result.update({"body_bytes": len(raw), "body_sha256": hashlib.sha256(raw).hexdigest(),
                       "page_title": parser.title.strip(), "metadata": parser.meta,
                       "product_jsonld": list(products(parser.jsonld)),
                       "visible_excerpt": " ".join(parser.visible)[:1200],
                       "image_elements": parser.images[:5]})
        result["product_image_extracted"] = any(m["field"] == "og:image" and m["value"] for m in parser.meta) or any(p.get("image") for p in result["product_jsonld"])
        result["product_price_extracted"] = any(m["field"] in ("price", "product:price:amount") and m["value"] for m in parser.meta) or any(has_offer_price(p.get("offers")) for p in result["product_jsonld"])
        if result["http_status"] != 200:
            result["product_image_extracted"] = False
            result["product_price_extracted"] = False
    return result

if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(probe, SAMPLES))
    report = {"method": "Direct public HTTPS GET; transparent test User-Agent; no API, credentials, cookies, proxies or JavaScript execution.",
              "samples": results, "limits": "Two samples, one network location, one run. Search snippets are not extraction results. Error-page images do not count as product images."}
    out = Path(__file__).with_name("results.json")
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
