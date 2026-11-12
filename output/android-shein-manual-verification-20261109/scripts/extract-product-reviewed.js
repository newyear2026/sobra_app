(function () {
  const visible = el => !!el && el.getBoundingClientRect().width>0 && el.getBoundingClientRect().height>0 && getComputedStyle(el).visibility!=='hidden' && getComputedStyle(el).display!=='none';
  const text = el => el ? (el.innerText||el.textContent||'').replace(/\s+/g,' ').trim() : '';
  const safeUrl = raw => {try{const u=new URL(raw,location.href);return /^https?:$/.test(u.protocol)?u.origin+u.pathname:'';}catch(e){return '';}};
  const ancestry = el => {const a=[];for(let p=el.parentElement;p&&a.length<6;p=p.parentElement)a.push({tag:p.tagName.toLowerCase(),class:typeof p.className==='string'?p.className:null});return a;};
  const path=location.pathname;
  // Iframe attributes only: do not enter frame documents or inspect security questions.
  const iframeMetadata=Array.from(document.querySelectorAll('iframe')).map(el=>({
    title:el.getAttribute('title')||null,id:el.id||null,class:typeof el.className==='string'?el.className:null,
    src:safeUrl(el.getAttribute('src')||''),visible:visible(el),
    securityMarker:/captcha|challenge|verify|verification|risk|turnstile|hcaptcha|recaptcha/i.test([el.id,el.className,el.getAttribute('title'),el.getAttribute('src')].join(' '))
  })).slice(0,30);
  const visibleSecurityWidget=Array.from(document.querySelectorAll('#px-captcha,#captcha,[id*=captcha],[class*=captcha],[id*=Captcha],[class*=Captcha],[id*=challenge],[class*=challenge],iframe')).some(el=>visible(el)&&/captcha|challenge|verify|verification|risk|turnstile|hcaptcha|recaptcha/i.test([el.id,el.className,el.getAttribute('title'),el.getAttribute('src')].join(' ')));
  const auth=/\/login|\/signin|\/sign-in|\/user\/auth|account-verification/i.test(path)||Array.from(document.querySelectorAll('input[type="password"]')).some(visible);
  const challenge=/\/captcha|\/challenge|\/risk\/|\/risk-control|\/verify|\/blocked/i.test(path)||/captcha|security verification|verificaci[oó]n|verify|robot|access denied/i.test(document.title)||visibleSecurityWidget;
  if(auth||challenge)return {pageUrl:safeUrl(location.href),pageTitle:document.title,accountVerification:auth,challenge:challenge,status:auth?'authentication_screen_not_inspected':'security_confirmation_screen_not_inspected',iframeMetadata:iframeMetadata,bodyInspected:false,fieldsReadable:false,extractionConfirmed:false,manualVerificationCompleted:null};
  const productPath=/-p-[0-9]+\.html$/.test(path);
  if(!productPath)return {pageUrl:safeUrl(location.href),pageTitle:document.title,accountVerification:false,challenge:false,status:'not_public_product_path',iframeMetadata:iframeMetadata,bodyInspected:false,fieldsReadable:false,extractionConfirmed:false,manualVerificationCompleted:null};
  const bodyText=document.body?document.body.innerText.slice(0,10000):'';
  const headings=Array.from(document.querySelectorAll('h1')).filter(visible).map(el=>({text:text(el),id:el.id||null,class:el.className||null,ancestors:ancestry(el)})).slice(0,5);
  const meta={};
  for(const el of document.querySelectorAll('meta[property],meta[name],meta[itemprop]')){
    const k=el.getAttribute('property')||el.getAttribute('name')||el.getAttribute('itemprop');
    if(['og:title','og:image','og:url','og:description','product:price:amount','product:price:currency','price','priceCurrency'].includes(k))meta[k]=(el.getAttribute('content')||'').slice(0,800);
  }
  const structuredProducts=[];
  const summarizeOffer=o=>{if(Array.isArray(o))return o.slice(0,5).map(summarizeOffer);if(!o||typeof o!=='object')return null;const v={};for(const k of ['@type','price','lowPrice','highPrice','priceCurrency','availability','url'])if(o[k]!==undefined)v[k]=o[k];return v;};
  function walk(o,d=0){if(d>8||!o||typeof o!=='object'||structuredProducts.length>=5)return;if(Array.isArray(o)){o.forEach(x=>walk(x,d+1));return;}const t=o['@type'];if(t==='Product'||Array.isArray(t)&&t.includes('Product'))structuredProducts.push({name:o.name||null,image:o.image||null,sku:o.sku||null,url:o.url||null,offers:summarizeOffer(o.offers)});for(const v of Object.values(o))if(v&&typeof v==='object')walk(v,d+1);}
  let invalidJsonLd=0;
  for(const script of document.querySelectorAll('script[type="application/ld+json"]')){try{if(script.textContent.length<500000)walk(JSON.parse(script.textContent));}catch(e){invalidJsonLd++;}}
  const priceCandidates=[];
  for(const el of document.querySelectorAll('[class*="price"],[class*="Price"],[data-price],[itemprop="price"]')){
    if(priceCandidates.length>=60)break;
    if(!visible(el))continue;
    const t=text(el);if(!/\d/.test(t)||t.length>350)continue;
    priceCandidates.push({tag:el.tagName.toLowerCase(),class:el.className||null,text:t,itemprop:el.getAttribute('itemprop'),dataPrice:el.getAttribute('data-price'),ariaLabel:el.getAttribute('aria-label'),parentText:text(el.parentElement).slice(0,450),ancestors:ancestry(el)});
  }
  const largeImageCandidates=Array.from(document.querySelectorAll('img')).filter(el=>visible(el)&&el.complete&&el.naturalWidth>0&&el.naturalHeight>0&&/^https?:/.test(el.currentSrc||el.src)).slice(0,18).map(el=>({alt:el.alt,src:el.currentSrc||el.src,naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,class:el.className||null,ancestors:ancestry(el)}));
  // Only the current product's displayed main-price selector can be selected.
  const productId=(path.match(/-p-([0-9]+)\.html$/)||[])[1];
  const productUrlMatches=raw=>{try{return new URL(raw,location.href).pathname.match(/-p-([0-9]+)\.html$/)?.[1]===productId;}catch(e){return false;}};
  const positiveMoney=raw=>{const t=String(raw==null?'':raw).trim().replace(/(?:MXN|MX|USD|US|\$|\s)/gi,'');if(!/^[0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?$/.test(t))return null;const n=Number(t.replace(/,/g,''));return Number.isFinite(n)&&n>0?n:null;};
  const titleEl=Array.from(document.querySelectorAll('h1.detail-title-h1')).find(visible);
  const productTitle=titleEl?{value:text(titleEl),source:'h1.detail-title-h1',id:titleEl.id||null,class:titleEl.className||null,ancestors:ancestry(titleEl)}:null;
  const primaryPriceCandidates=Array.from(document.querySelectorAll('.productPriceContainer .bsc-main-price')).filter(visible).map(el=>({
    value:positiveMoney(text(el)),text:text(el),source:'.productPriceContainer .bsc-main-price',
    currencyEvidence:/MXN/i.test(text(el))?'explicit MXN in displayed main price':null,
    class:el.className||null,ancestors:ancestry(el),
    rejected:!!el.closest('.bsc-strikethrough-price,[class*="installment"],[class*="Installment"],s,del'),
    rejectedReason:el.closest('.bsc-strikethrough-price,[class*="installment"],[class*="Installment"],s,del')?'reference_or_installment_ancestor':null
  }));
  const sameProductStructured=structuredProducts.filter(p=>{
    const offers=Array.isArray(p.offers)?p.offers:[p.offers];
    return productUrlMatches(p.url)||offers.some(o=>o&&productUrlMatches(o.url));
  });
  const structuredPriceEvidence=[];
  for(const product of sameProductStructured)for(const offer of Array.isArray(product.offers)?product.offers:[product.offers]){
    if(offer)structuredPriceEvidence.push({name:product.name,sku:product.sku,value:positiveMoney(offer.price),currency:offer.priceCurrency||null,url:safeUrl(offer.url||product.url||'')});
  }
  const primaryValues=Array.from(new Set(primaryPriceCandidates.filter(p=>!p.rejected&&p.value!==null).map(p=>p.value)));
  const candidateValue=primaryValues.length===1?primaryValues[0]:null;
  const metaPrice=positiveMoney(meta['product:price:amount']);
  const metaCurrency=meta['product:price:currency']||null;
  const allStructuredAgree=structuredPriceEvidence.length>0&&structuredPriceEvidence.every(p=>p.value===candidateValue&&p.currency==='MXN');
  const priceEvidenceConsistent=candidateValue!==null&&metaPrice===candidateValue&&metaCurrency==='MXN'&&allStructuredAgree;
  const primaryPrice=priceEvidenceConsistent?{
    value:candidateValue,currency:'MXN',source:'.productPriceContainer .bsc-main-price',
    displayed:primaryPriceCandidates.find(p=>!p.rejected&&p.value===candidateValue).text,
    agreement:{displayedMainPrice:true,productMeta:true,sameProductStructuredOffers:structuredPriceEvidence.length},
    excluded:'Reference, strikethrough, discounts, installment and variant selectors are never primary price sources.'
  }:null;

  // Match image identity from current-product metadata/JSON-LD, then require an actually loaded primary-gallery img.
  // SHEIN converts format and repeats thumbnail dimensions; these are rendition suffixes, not image identities.
  const canonicalImage=raw=>{try{const u=new URL(raw,location.href);if(!/^https?:$/.test(u.protocol))return null;return u.origin+u.pathname.replace(/(?:_thumbnail_[0-9]*x[0-9]*)+/gi,'').replace(/\.(?:jpe?g|png|webp|avif)$/i,'');}catch(e){return null;}};
  const imageReferences=[];
  if(meta['og:image'])imageReferences.push({source:'og:image',src:meta['og:image'],canonical:canonicalImage(meta['og:image'])});
  for(const p of sameProductStructured)for(const value of Array.isArray(p.image)?p.image:[p.image]){
    const src=typeof value==='string'?value:value&&value.url;
    if(src)imageReferences.push({source:'same-product JSON-LD Product.image',src:src,canonical:canonicalImage(src)});
  }
  const referenceKeys=new Set(imageReferences.map(r=>r.canonical).filter(Boolean));
  const allImages=Array.from(document.querySelectorAll('img'));
  const mainImageCandidates=allImages.map(el=>{
    const src=el.currentSrc||el.src,canonical=canonicalImage(src),gallery=el.closest('.main-picture');
    if(!gallery||!canonical||!referenceKeys.has(canonical))return null;
    return {src:src,canonical:canonical,alt:el.alt||null,naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,
      complete:el.complete,loaded:el.complete&&el.naturalWidth>0&&el.naturalHeight>0,visible:visible(el),
      source:'.main-picture img matching current-product metadata image identity',class:el.className||null,
      ancestors:ancestry(el),matchingReferences:imageReferences.filter(r=>r.canonical===canonical)};
  }).filter(Boolean);
  const loadedImageCandidates=mainImageCandidates.filter(i=>i.loaded);
  const loadedIdentities=Array.from(new Set(loadedImageCandidates.map(i=>i.canonical)));
  // Repeated carousel copies of the same photograph are allowed; conflicting identities remain ambiguous.
  const mainImage=loadedIdentities.length===1?(loadedImageCandidates.find(i=>i.visible)||loadedImageCandidates[0]):null;
  const fieldsReadable=!!(productTitle&&productTitle.value&&primaryPrice&&mainImage);
  return {pageUrl:safeUrl(location.href),pageTitle:document.title,readyState:document.readyState,
    extractorVersion:'0.3-reviewed-public-product-dom',headings:headings,accountVerification:auth,challenge:challenge,
    iframeMetadata:iframeMetadata,metadata:meta,structuredProducts:structuredProducts,invalidJsonLd:invalidJsonLd,
    priceCandidates:priceCandidates,largeImageCandidates:largeImageCandidates,bodyTextExcerpt:bodyText,bodyInspected:true,
    productTitle:productTitle,primaryPrice:primaryPrice,primaryPriceCandidates:primaryPriceCandidates,
    priceAgreement:{uniquePrimaryValues:primaryValues,metaPrice:metaPrice,metaCurrency:metaCurrency,structuredOffers:structuredPriceEvidence,consistent:priceEvidenceConsistent},
    mainImage:mainImage,mainImageCandidates:mainImageCandidates,imagesScanned:allImages.length,
    currencyEvidence:{productMeta:metaCurrency,structuredOffers:structuredPriceEvidence.map(o=>o.currency)},
    fieldsReadable:fieldsReadable,extractionConfirmed:false,manualVerificationCompleted:null,
    interpretation:'Fields describe public product DOM readability only, not completed security verification. Absence of detected challenge is not proof of human verification; iframe contents are never inspected. Compare both snapshots and user confirmation before reporting the outcome. Loaded image dimensions are evidence, not a quality guarantee.'};
})();
