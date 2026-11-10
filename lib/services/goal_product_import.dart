import 'dart:convert';

import '../models/savings_goal.dart';

/// A candidate from the page the user is viewing, never a saved goal or quote.
/// The goal editor confirms every value, including the currency and amount.
class GoalProductImport {
  const GoalProductImport({
    required this.sourceUrl,
    this.title,
    this.imageUrl,
    this.priceCentavos,
    this.currencyCode,
    this.merchantName,
  });

  final String sourceUrl;
  final String? title;
  final String? imageUrl;
  final int? priceCentavos;
  final String? currencyCode;
  final String? merchantName;
}

/// A product page is not inspected while a visible security or sign-in step
/// is present. Only the user can complete that step in the actual WebView.
class GoalProductVerificationRequired implements Exception {
  const GoalProductVerificationRequired();
}

Uri? safeGoalUrl(String? raw) {
  if (raw == null || !SavingsGoal.isSupportedUrl(raw.trim())) return null;
  return Uri.parse(raw.trim()).removeFragment();
}

String? _shortText(Object? raw, int limit) {
  if (raw is! String) return null;
  final value = raw
      .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (value.isEmpty) return null;
  return String.fromCharCodes(value.runes.take(limit));
}

int? _priceCentavos(Object? raw) {
  // The JS sends a canonical decimal string. No currency stripping, rounding,
  // floating point multiplication, ranges, or installment heuristics here.
  if (raw is! String || !RegExp(r'^\d{1,12}(?:\.\d{1,2})?$').hasMatch(raw)) {
    return null;
  }
  final parts = raw.split('.');
  final amount =
      int.parse(parts.first) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts.last.padRight(2, '0')));
  return amount > 0 ? amount : null;
}

/// Android may JSON-quote the string result while WKWebView returns the
/// string itself. Decode either representation, then distrust every field.
GoalProductImport? parseGoalProductPayload(Object? raw) {
  Object? value = raw;
  for (var depth = 0; depth < 2 && value is String; depth++) {
    if (value.length > 65536) return null;
    try {
      value = jsonDecode(value);
    } on FormatException {
      return null;
    }
  }
  if (value is! Map<String, dynamic>) return null;
  if (value['verificationRequired'] == true) {
    throw const GoalProductVerificationRequired();
  }
  if (value['isProduct'] != true) return null;
  final source = safeGoalUrl(
    value['sourceUrl'] is String ? value['sourceUrl'] as String : null,
  );
  if (source == null) return null;
  final title = _shortText(value['title'], 60);
  final image = safeGoalUrl(
    value['imageUrl'] is String ? value['imageUrl'] as String : null,
  );
  if (title == null && image == null) return null;
  final currency = value['currencyCode'];
  return GoalProductImport(
    sourceUrl: source.toString(),
    title: title,
    imageUrl: image?.toString(),
    priceCentavos: _priceCentavos(value['price']),
    currencyCode: currency is String && RegExp(r'^[A-Z]{3}$').hasMatch(currency)
        ? currency
        : null,
    merchantName: _merchantName(source.host),
  );
}

String _merchantName(String host) {
  bool at(String domain) => host == domain || host.endsWith('.$domain');
  if (at('amazon.com.mx')) return 'Amazon México';
  if (at('mercadolibre.com.mx')) return 'Mercado Libre';
  if (at('walmart.com.mx')) return 'Walmart México';
  if (at('shein.com.mx') || at('shein.com')) return 'SHEIN';
  return _shortText(host.replaceFirst(RegExp(r'^www\.'), ''), 80)!;
}

/// Pure public DOM reads. No cookie access, private app state, network calls,
/// cross-frame inspection, click events, or CAPTCHA interaction. If multiple
/// current prices disagree, the amount stays empty for manual confirmation.
const goalProductExtractionScript = r'''
(function () {
  'use strict';
  const text = el => el ? (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim() : '';
  const visible = el => {
    if (!el) return false;
    const r = el.getBoundingClientRect(), s = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && s.display !== 'none' && s.visibility !== 'hidden';
  };
  const url = raw => {
    if (!raw || typeof raw !== 'string') return null;
    try { const u = new URL(raw, location.href); u.hash = '';
      return u.protocol === 'https:' && !u.username && !u.password ? u.href : null;
    } catch (_) { return null; }
  };
  const sourceUrl = url(location.href);
  const challengePath = /\/(?:blocked|captcha|challenge|risk|account-verification)(?:\/|$)/i.test(location.pathname);
  const challengeTitle = /verifica tu identidad|verify your identity|robot check|security verification|access denied|captcha/i.test(document.title);
  const challengeNode = Array.from(document.querySelectorAll('#px-captcha,#captcha,[id*=captcha],[id*=challenge],[class*=captcha],[class*=challenge],iframe')).some(el => {
    if (!visible(el)) return false;
    const r = el.getBoundingClientRect();
    const marker = [el.id, el.className, el.getAttribute('title'), el.getAttribute('src')].join(' ');
    return /captcha|challenge|turnstile|perimeterx|verification/i.test(marker) && r.width > 120 && r.height > 70;
  });
  const signIn = /\/(?:signin|sign-in|login|auth)(?:\/|$)/i.test(location.pathname) ||
    Array.from(document.querySelectorAll('input[type="password"]')).some(visible);
  if (challengePath || challengeTitle || challengeNode || signIn) {
    return JSON.stringify({sourceUrl, verificationRequired: true});
  }
  const at = domain => location.hostname === domain || location.hostname.endsWith('.' + domain);
  const amazon = at('amazon.com.mx'), mercado = at('mercadolibre.com.mx'), walmart = at('walmart.com.mx');
  const knownProductPath = (amazon && /\/(?:dp|gp\/product)\/[A-Z0-9]{10}(?:\/|$)/i.test(location.pathname)) ||
    (mercado && /(?:MLM-\d+|\/p\/MLM\d+)/i.test(location.pathname)) ||
    (walmart && /^\/ip\/[^/]+\/\d+\/?$/.test(location.pathname)) ||
    ((at('shein.com.mx') || at('shein.com')) && /-p-\d+\.html$/i.test(location.pathname));
  const meta = key => {
    for (const el of document.querySelectorAll('meta[property],meta[name],meta[itemprop]')) {
      if ((el.getAttribute('property') || el.getAttribute('name') || el.getAttribute('itemprop')) === key)
        return (el.getAttribute('content') || '').slice(0, 4096);
    }
    return null;
  };
  const heading = ['#productTitle','h1.ui-pdp-title','h1#main-title','h1'].map(s => document.querySelector(s)).find(visible);
  let title = text(heading) || meta('og:title');
  if (!title && amazon && knownProductPath) title = document.title.replace(/\s*:\s*Amazon\.com\.mx(?:\s*:.*)?$/i, '').trim();
  const normalized = value => String(value || '').replace(/\s+/g, ' ').trim().toLowerCase();
  const pathKey = raw => { const u = url(raw); return u ? new URL(u).origin + new URL(u).pathname.replace(/\/$/, '') : null; };
  const pageKey = pathKey(sourceUrl), canonicalKey = pathKey(document.querySelector('link[rel="canonical"]')?.href || '');
  const products = [];
  let visited = 0;
  function walk(o, depth) {
    if (!o || typeof o !== 'object' || depth > 8 || visited++ > 3000 || products.length >= 24) return;
    if (Array.isArray(o)) { o.slice(0, 50).forEach(v => walk(v, depth + 1)); return; }
    const type = o['@type'];
    if (type === 'Product' || Array.isArray(type) && type.includes('Product')) products.push(o);
    Object.values(o).forEach(v => { if (v && typeof v === 'object') walk(v, depth + 1); });
  }
  for (const script of Array.from(document.querySelectorAll('script[type="application/ld+json"]')).slice(0, 20)) {
    try { if (script.textContent.length < 500000) walk(JSON.parse(script.textContent), 0); } catch (_) {}
  }
  const sameProducts = products.filter(p => {
    const key = pathKey(typeof p.url === 'string' ? p.url : '');
    const named = !!title && normalized(p.name) === normalized(title);
    const sameUrl = !!key && (key === pageKey || key === canonicalKey);
    return (named || sameUrl) && (!key || sameUrl);
  });
  const isProduct = knownProductPath || sameProducts.length > 0 ||
    /^(?:product|product\.item)$/i.test(meta('og:type') || '') && !!heading;
  if (!isProduct) return JSON.stringify({sourceUrl, isProduct: false});
  if (!title && sameProducts.length === 1) title = sameProducts[0].name;
  const decimal = raw => {
    const t = String(raw == null ? '' : raw).trim();
    return /^\d{1,12}(?:\.\d{1,2})?$/.test(t) && Number(t) > 0 ? Number(t).toFixed(2) : null;
  };
  const mexicanPrice = raw => {
    const t = String(raw || '').replace(/(?:MXN|MX|\$|\s)/gi, '');
    return /^\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?$|^\d+(?:\.\d{1,2})?$/.test(t) ? decimal(t.replace(/,/g, '')) : null;
  };
  const forbidden = el => !!el.closest('s,del,.a-text-price,.apex-basisprice-value,.andes-money-amount--previous,.ui-pdp-price__original-value,.ui-pdp-price__payments,[id*="installment"],[id*="Installment"],[id*="swatch"],[id*="Swatch"],[id^="twister"],.ui-pdp-variations');
  const primary = [];
  const push = value => { if (value) primary.push(value); };
  if (amazon) {
    for (const el of document.querySelectorAll('#corePriceDisplay_mobile_feature_div .apex-pricetopay-value,#corePrice_mobile_feature_div .apex-pricetopay-value,#corePrice_feature_div .apex-pricetopay-value,#corePriceDisplay_desktop_feature_div .apex-pricetopay-value')) {
      if (!visible(el) || forbidden(el)) continue;
      const whole = text(el.querySelector('.a-price-whole')).replace(/[\s,.]/g, '');
      const cents = text(el.querySelector('.a-price-fraction'));
      const value = /^\d+$/.test(whole) && /^\d{2}$/.test(cents) ? decimal(whole + '.' + cents) : null;
      const accessible = text(el.querySelector('.a-offscreen'));
      if (!accessible || mexicanPrice(accessible) === value) push(value);
    }
  } else if (mercado) {
    for (const el of document.querySelectorAll('.ui-pdp-price__second-line .andes-money-amount')) {
      if (!visible(el) || forbidden(el)) continue;
      const whole = text(el.querySelector('.andes-money-amount__fraction')).replace(/[,.\s]/g, '');
      const cents = text(el.querySelector('.andes-money-amount__cents')) || '00';
      if (/^\d+$/.test(whole) && /^\d{1,2}$/.test(cents)) push(decimal(whole + '.' + cents.padStart(2, '0')));
    }
  } else if (walmart) {
    for (const el of document.querySelectorAll('[data-testid="price-wrap"] [data-seo-id="hero-price"][itemprop="price"]')) {
      if (visible(el) && !forbidden(el)) push(mexicanPrice(el.getAttribute('content') || text(el)));
    }
  }
  const unique = values => Array.from(new Set(values.filter(Boolean)));
  const structuredPrices = [], currencies = [];
  for (const p of sameProducts) {
    for (const offer of (Array.isArray(p.offers) ? p.offers : [p.offers])) {
      if (!offer || typeof offer !== 'object') continue;
      // Do not turn an AggregateOffer lowPrice or an installment into a price.
      const value = decimal(offer.price);
      if (value) structuredPrices.push(value);
      if (value && /^[A-Z]{3}$/.test(offer.priceCurrency || '')) currencies.push(offer.priceCurrency);
    }
  }
  const main = unique(primary), structured = unique(structuredPrices);
  const metaPrice = decimal(meta('product:price:amount'));
  let price = main.length === 1 ? main[0] : main.length > 1 ? null :
    structured.length === 1 ? structured[0] : structured.length > 1 ? null : metaPrice;
  // Conflicting structured prices may describe unselected variants. Let the
  // user enter the final amount instead of choosing a minimum or first offer.
  if (main.length === 1 && structured.length && (structured.length !== 1 || structured[0] !== main[0])) price = null;
  const mc = meta('product:price:currency');
  if (mc && /^[A-Z]{3}$/.test(mc)) currencies.push(mc);
  const uniqueCurrencies = unique(currencies);
  const currencyCode = uniqueCurrencies.length === 1 ? uniqueCurrencies[0] :
    uniqueCurrencies.length === 0 && (amazon || mercado || walmart || at('shein.com.mx')) ? 'MXN' : null;
  const loaded = el => el && el.complete && el.naturalWidth > 0 && el.naturalHeight > 0;
  let imageUrl = null;
  const gallerySelectors = amazon ? ['img#main-image','img#landingImage','#image-block-product-image-0 img'] :
    mercado ? ['.ui-pdp-gallery img.ui-pdp-image','img.ui-pdp-image','.ui-pdp-gallery img'] :
    walmart ? ['img#hero-image-default-0','img[data-testid="hero-image"]'] : [];
  for (const selector of gallerySelectors) {
    const el = Array.from(document.querySelectorAll(selector)).find(loaded);
    if (el && (imageUrl = url(el.currentSrc || el.src))) break;
  }
  if (!imageUrl) {
    const structuredImages = [];
    for (const p of sameProducts) {
      for (const v of (Array.isArray(p.image) ? p.image : [p.image])) structuredImages.push(url(typeof v === 'string' ? v : v && v.url));
    }
    const images = unique(structuredImages), og = url(meta('og:image'));
    imageUrl = og && (knownProductPath || images.includes(og)) ? og : images[0] || null;
  }
  return JSON.stringify({isProduct: true, sourceUrl, title: typeof title === 'string' ? title.slice(0, 500) : '', imageUrl, price, currencyCode});
})();
''';
