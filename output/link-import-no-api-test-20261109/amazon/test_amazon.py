#!/usr/bin/env python3
"""Small anonymous direct-HTML feasibility test. No API, login, or cookie jar.

Run: python3 test_amazon.py
Writes sanitized extraction evidence only, not raw HTML/session data.
"""
import datetime
import hashlib
import json
from html.parser import HTMLParser
from pathlib import Path
import urllib.error
import urllib.request

PRODUCTS = [
    "https://www.amazon.com.mx/adidas-Tenis-Hombre-Casual-Negro/dp/B0DHZVB27Q",
    "https://www.amazon.com.mx/dp/B0F1X7M849",
]
HEADERS = {
    "User-Agent": "Sobrita-LinkPreview-Test/1.0",
    "Accept": "text/html",
    "Accept-Language": "es-MX,es;q=0.9",
}
VOID = set("area base br col embed hr img input link meta param source track wbr".split())


class PageParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.captures = []
        self.meta = {}
        self.images = []

    def handle_starttag(self, tag, pairs):
        attrs = dict(pairs)
        node = {"tag": tag, "attrs": attrs}
        if tag == "meta":
            key = attrs.get("property") or attrs.get("name") or attrs.get("itemprop")
            if key and (key.startswith("og:") or key in ["price", "priceCurrency", "product:price:amount", "product:price:currency"]):
                self.meta[key] = attrs.get("content")
        if tag == "img" and attrs.get("id") in ["landingImage", "imgBlkFront", "main-image"]:
            self.images.append({k: v for k, v in attrs.items() if k in ["id", "src", "alt", "data-old-hires", "data-a-dynamic-image"]})
        classes = (attrs.get("class") or "").split()
        kind = None
        if tag == "title":
            kind = "page_title"
        elif attrs.get("id") == "productTitle":
            kind = "product_title"
        elif attrs.get("id") == "availability":
            kind = "availability"
        elif tag == "script" and attrs.get("type") == "application/ld+json":
            kind = "json_ld"
        elif "a-offscreen" in classes or attrs.get("itemprop") == "price" or attrs.get("id") in ["priceblock_ourprice", "priceblock_dealprice", "priceblock_saleprice"]:
            kind = "price_candidate"
        if kind:
            capture = {"kind": kind, "text": "", "tag": tag,
                       "attrs": {k: v for k, v in attrs.items() if k in ["id", "class", "itemprop", "content"]},
                       "ancestors": [{"tag": x["tag"], "id": x["attrs"].get("id"), "class": x["attrs"].get("class")} for x in self.stack[-12:]]}
            node["capture"] = capture
            self.captures.append(capture)
        if tag not in VOID:
            self.stack.append(node)

    def handle_startendtag(self, tag, pairs):
        self.handle_starttag(tag, pairs)
        if tag not in VOID:
            self.handle_endtag(tag)

    def handle_endtag(self, tag):
        for index in range(len(self.stack)-1, -1, -1):
            if self.stack[index]["tag"] == tag:
                self.stack = self.stack[:index]
                return

    def handle_data(self, text):
        for node in self.stack:
            if "capture" in node:
                node["capture"]["text"] += text


def short_text(value):
    return " ".join(value.split())


def classify_prices(candidates):
    selected, excluded = [], []
    for candidate in candidates:
        ids = [a.get("id") for a in candidate["ancestors"]]
        classes = [c for a in candidate["ancestors"] for c in (a.get("class") or "").split()]
        if "corePrice_feature_div" in ids and "apex-pricetopay-value" in classes:
            selected.append({"display": candidate["text"], "source_css": "#corePrice_feature_div .apex-pricetopay-value .a-offscreen"})
        else:
            reason = "installment amount" if "installmentCalculatorCentral_feature_div" in ids else "reference/list price" if "apex-basisprice-value" in classes else "not confirmed as primary payable price"
            excluded.append({"display": candidate["text"], "reason": reason})
    return {"primary_offer_price": selected[0] if len(selected) == 1 else None,
            "excluded_price_candidates": excluded,
            "price_currency": "MXN (inferred from amazon.com.mx marketplace, not from a structured currency field)"}


def fetch(url, image=False):
    # Explicitly disable proxy use; no cookie handler is installed.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    headers = dict(HEADERS)
    if image:
        headers["Accept"] = "image/*"
        headers["Range"] = "bytes=0-127"
    request = urllib.request.Request(url, headers=headers)
    try:
        response = opener.open(request, timeout=35)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        body = response.read(128 if image else 5_000_000)
        return {"status": response.code, "final_url": response.url,
                "content_type": response.headers.get("Content-Type"),
                "bytes_read": len(body)}, body


def test(url):
    result = {"url": url, "tested_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "request_headers": HEADERS, "api_used": False, "login_used": False, "cookies_sent": False,
              "javascript_executed": False, "proxy_used": False}
    try:
        response, body = fetch(url)
        result.update(response)
        result["html_sha256"] = hashlib.sha256(body).hexdigest()
        text = body.decode("utf-8", "replace")
        parser = PageParser()
        parser.feed(text)
        result["page_title"] = next((short_text(c["text"]) for c in parser.captures if c["kind"] == "page_title"), None)
        result["product_title"] = next((short_text(c["text"]) for c in parser.captures if c["kind"] == "product_title"), None)
        result["availability"] = [short_text(c["text"]) for c in parser.captures if c["kind"] == "availability"]
        result["metadata"] = parser.meta
        result["main_images"] = parser.images
        result["structured_data"] = []
        for capture in parser.captures:
            if capture["kind"] == "json_ld":
                try:
                    result["structured_data"].append(json.loads(capture["text"]))
                except json.JSONDecodeError:
                    result.setdefault("invalid_json_ld_blocks", 0)
                    result["invalid_json_ld_blocks"] += 1
        primary = []
        for capture in parser.captures:
            if capture["kind"] != "price_candidate":
                continue
            ancestry = " ".join((a.get("id") or "")+" "+(a.get("class") or "") for a in capture["ancestors"])
            if any(marker in ancestry for marker in ["corePrice", "priceToPay", "apex_desktop"]) or (capture["attrs"].get("id") or "").startswith("priceblock_"):
                capture["text"] = short_text(capture["text"])
                if capture["text"]:
                    primary.append(capture)
        result["primary_price_candidates"] = primary
        result.update(classify_prices(primary))
        result["challenge_indicators"] = [marker for marker in ["Robot Check", "Enter the characters you see below", "api-services-support@amazon.com", "/errors/validateCaptcha"] if marker.lower() in text.lower()]
        image_url = None
        if parser.images:
            image_url = parser.images[0].get("data-old-hires") or parser.images[0].get("src")
        if not image_url:
            image_url = parser.meta.get("og:image")
        if image_url:
            try:
                info, sample = fetch(image_url, image=True)
                result["image_check"] = dict(info, magic_hex=sample[:16].hex(), source="main image HTML attribute")
            except Exception as error:
                result["image_check"] = {"error_type": type(error).__name__, "error": str(error)}
    except Exception as error:
        result["error_type"] = type(error).__name__
        result["error"] = str(error)
    return result


if __name__ == "__main__":
    results = [test(url) for url in PRODUCTS]
    destination = Path(__file__).with_name("results.json")
    destination.write_text(json.dumps(results, indent=2, ensure_ascii=False)+"\n")
    for row in results:
        print(json.dumps({"url": row["url"], "status": row.get("status"), "title": row.get("product_title"),
                          "images": len(row.get("main_images", [])), "price_candidates": [p["text"] for p in row.get("primary_price_candidates", [])],
                          "image_check": row.get("image_check"), "challenge_indicators": row.get("challenge_indicators"),
                          "error": row.get("error")}, ensure_ascii=False))
    print("Saved:", destination)
