"""Summarize saved anonymous HTTP evidence; does not make network requests."""
from pathlib import Path
from html.parser import HTMLParser
import json

ROOT = Path(__file__).resolve().parent


class ProductMetadata(HTMLParser):
    def __init__(self):
        super().__init__()
        self.current = None
        self.products = []

    def handle_starttag(self, tag, attrs):
        if tag == 'script' and dict(attrs).get('type') == 'application/ld+json':
            self.current = ''

    def handle_data(self, data):
        if self.current is not None:
            self.current += data

    def handle_endtag(self, tag):
        if tag == 'script' and self.current is not None:
            obj = json.loads(self.current)
            if isinstance(obj, dict) and obj.get('@type') == 'Product':
                self.products.append(obj)
            self.current = None


data = json.loads((ROOT / 'http_results.json').read_text())
parser = ProductMetadata()
parser.feed((ROOT / 'walmart.html').read_text())
product = parser.products[0]
next_product = json.loads((ROOT / 'walmart_nextdata.json').read_text())['props']['pageProps']['initialData']['data']['product']
assert product['offers'][0]['price'] == next_product['priceInfo']['currentPrice']['price'] == 1499
assert product['image'] == next_product['imageInfo']['thumbnailUrl']
image_check = json.loads((ROOT / 'walmart_image_check.json').read_text())
for item in data:
    if item['site'] == 'walmart':
        item['extraction'] = {
            'success': True,
            'name': product['name'],
            'image_url': product['image'],
            'price': product['offers'][0]['price'],
            'currency': product['offers'][0]['priceCurrency'],
            'source': 'HTML-embedded JSON-LD Product and __NEXT_DATA__ product.priceInfo.currentPrice',
            'image_check': image_check,
            'excluded_reference_price': next_product['priceInfo']['wasPrice']['price'],
        }
    else:
        item['extraction'] = {'success': False, 'reason': 'HTTP 403 Access Denied; did not attempt bypass'}
(ROOT / 'results.json').write_text(json.dumps(data, ensure_ascii=False, indent=2))
print(json.dumps([{'site':x['site'],'status':x['status'],'extraction':x['extraction']} for x in data], ensure_ascii=False))
