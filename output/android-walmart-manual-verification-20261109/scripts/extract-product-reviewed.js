(function () {
  // Read only the current page's public product DOM. Never access frame content, cookies or private state.
  const visible=el=>!!el&&el.getBoundingClientRect().width>0&&el.getBoundingClientRect().height>0&&getComputedStyle(el).display!=='none'&&getComputedStyle(el).visibility!=='hidden';
  const text=el=>el?(el.innerText||el.textContent||'').replace(/\s+/g,' ').trim():'';
  const safeUrl=raw=>{try{const u=new URL(raw,location.href);return /^https?:$/.test(u.protocol)?u.origin+u.pathname:'';}catch(e){return '';}};
  const ancestry=el=>{const out=[];for(let p=el.parentElement;p&&out.length<7;p=p.parentElement)out.push({tag:p.tagName.toLowerCase(),id:p.id||null,class:typeof p.className==='string'?p.className:null});return out;};
  const iframeMetadata=Array.from(document.querySelectorAll('iframe')).map(el=>({id:el.id||null,class:typeof el.className==='string'?el.className:null,title:el.getAttribute('title'),src:safeUrl(el.getAttribute('src')||''),visible:visible(el)})).slice(0,30);
  const securityMarker=el=>/captcha|challenge|verify|verification|risk|turnstile|hcaptcha|recaptcha|perimeterx/i.test([el.id,el.className,el.getAttribute('title'),el.getAttribute('src')].join(' '));
  const challenge=/\/(?:blocked|captcha|challenge|risk|verify)(?:\/|$)/i.test(location.pathname)||/verifica tu identidad|verify your identity|captcha|security verification|robot|human|access denied/i.test(document.title)||Array.from(document.querySelectorAll('#px-captcha,#captcha,[id*=captcha],[class*=captcha],[id*=challenge],[class*=challenge],iframe')).some(el=>visible(el)&&securityMarker(el));
  const auth=/\/(?:login|signin|sign-in|auth|account-verification)(?:\/|$)/i.test(location.pathname)||Array.from(document.querySelectorAll('input[type="password"]')).some(visible);
  const base={pageUrl:safeUrl(location.href),pageTitle:document.title,challenge:challenge,accountVerification:auth,iframeMetadata:iframeMetadata,manualVerificationCompleted:null,extractionConfirmed:false};
  // Do not read body text, questions, images, inputs or JSON-LD on security/authentication screens.
  if(challenge||auth)return Object.assign(base,{status:auth?'authentication_screen_not_inspected':'security_confirmation_screen_not_inspected',bodyInspected:false});
  if(!/^\/ip\/[^/]+\/[0-9]+\/?$/.test(location.pathname))return Object.assign(base,{status:'not_public_product_path',bodyInspected:false});
  const headings=Array.from(document.querySelectorAll('h1')).filter(visible).slice(0,5).map(el=>({text:text(el),id:el.id||null,class:el.className||null,ancestors:ancestry(el)}));
  const metadata={};
  for(const el of document.querySelectorAll('meta[property],meta[name],meta[itemprop]')){
    const key=el.getAttribute('property')||el.getAttribute('name')||el.getAttribute('itemprop');
    if(['og:title','og:image','og:url','og:description','product:price:amount','product:price:currency','price','priceCurrency'].includes(key))metadata[key]=(el.getAttribute('content')||'').slice(0,800);
  }
  const structuredProducts=[];
  const offers=o=>{if(Array.isArray(o))return o.slice(0,8).map(offers);if(!o||typeof o!=='object')return null;const out={};for(const k of ['@type','price','lowPrice','highPrice','priceCurrency','availability','url'])if(o[k]!==undefined)out[k]=o[k];return out;};
  function walk(o,depth=0){if(depth>8||!o||typeof o!=='object'||structuredProducts.length>=8)return;if(Array.isArray(o)){o.forEach(v=>walk(v,depth+1));return;}const t=o['@type'];if(t==='Product'||Array.isArray(t)&&t.includes('Product'))structuredProducts.push({name:o.name||null,image:o.image||null,sku:o.sku||null,url:o.url||null,offers:offers(o.offers)});for(const value of Object.values(o))if(value&&typeof value==='object')walk(value,depth+1);}
  let invalidJsonLd=0;
  for(const script of document.querySelectorAll('script[type="application/ld+json"]'))try{if(script.textContent.length<500000)walk(JSON.parse(script.textContent));}catch(e){invalidJsonLd++;}
  const mainPriceSelector='[data-testid="price-wrap"] [data-seo-id="hero-price"][itemprop="price"]';
  const rejectedAncestor=el=>el.closest('s,del,[class*="installment"],[class*="Installment"],[data-testid*="installment"],[data-testid*="strikethrough"],[class*="strike"],[class*="old-price"],[data-testid*="was-price"]');
  const money=raw=>{const t=String(raw||'').replace(/(?:MXN|MX|\$|\s)/gi,'');if(!/^[0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?$/.test(t))return null;const n=Number(t.replace(/,/g,''));return Number.isFinite(n)&&n>0?n:null;};
  const priceCandidates=[];
  const priceElements=Array.from(document.querySelectorAll(mainPriceSelector+', [data-seo-id="hero-price"], [itemprop="price"], [data-testid*="price"], [class*="price"]'));
  for(const el of priceElements){
    if(priceCandidates.length>=60)break;
    if(!visible(el))continue;const t=text(el);if(!/\d/.test(t)||t.length>250)continue;
    const primaryScope=el.matches(mainPriceSelector),badAncestor=!!rejectedAncestor(el);
    priceCandidates.push({text:t,value:money(el.getAttribute('content')||t),source:primaryScope?mainPriceSelector:'diagnostic_price_candidate',primaryScope:primaryScope,excludedFromPrimary:!primaryScope||badAncestor,rejectedReason:badAncestor?'old_reference_or_installment_ancestor':primaryScope?null:'outside_exact_primary_hero_selector',tag:el.tagName.toLowerCase(),id:el.id||null,class:el.className||null,itemprop:el.getAttribute('itemprop'),content:el.getAttribute('content'),dataTestid:el.getAttribute('data-testid'),dataSeoId:el.getAttribute('data-seo-id'),parentText:text(el.parentElement).slice(0,400),ancestors:ancestry(el)});
  }
  const mainPriceCandidates=priceCandidates.filter(p=>!p.excludedFromPrimary);
  const imageReferences=[];
  if(metadata['og:image'])imageReferences.push({source:'og:image',src:metadata['og:image']});
  for(const product of structuredProducts)for(const value of Array.isArray(product.image)?product.image:[product.image]){const src=typeof value==='string'?value:value&&value.url;if(src)imageReferences.push({source:'JSON-LD Product.image',src:src});}
  const imageKey=raw=>{try{const u=new URL(raw,location.href);return /^https?:$/.test(u.protocol)?u.origin+u.pathname:null;}catch(e){return null;}};
  const mainImageCandidates=Array.from(document.querySelectorAll('#hero-image-default-0,#hero-image-zoom-0,img[data-testid="hero-image"]')).map(el=>{
    const src=el.currentSrc||el.src,key=imageKey(src),style=getComputedStyle(el);
    return {src:src,alt:el.alt||null,id:el.id||null,class:el.className||null,dataTestid:el.getAttribute('data-testid'),source:el.id==='hero-image-default-0'?'#hero-image-default-0':'hero-gallery diagnostic',primaryGallery:el.id==='hero-image-default-0',complete:el.complete,loaded:el.complete&&el.naturalWidth>0&&el.naturalHeight>0,naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,visible:visible(el),computedDisplay:style.display,computedVisibility:style.visibility,ancestors:ancestry(el),metadataMatches:imageReferences.filter(r=>imageKey(r.src)===key)};
  });
  // Strictly associate structured data with the current product, not recommendations or other variants.
  const titleElement=document.querySelector('h1#main-title');
  const productTitle=visible(titleElement)?{value:text(titleElement),source:'h1#main-title',id:titleElement.id,class:titleElement.className||null,ancestors:ancestry(titleElement)}:null;
  const normalizeName=value=>String(value||'').replace(/\s+/g,' ').trim();
  const currentSku=location.pathname.replace(/\/$/,'').split('/').pop();
  const currentPath=location.pathname.replace(/\/$/,'');
  const sameProductUrl=raw=>{try{const u=new URL(raw,location.href);return u.hostname===location.hostname&&u.pathname.replace(/\/$/,'')===currentPath;}catch(e){return false;}};
  const sameProductStructured=structuredProducts.filter(product=>
    String(product.sku)===currentSku&&productTitle&&normalizeName(product.name)===normalizeName(productTitle.value)&&
    (Array.isArray(product.offers)?product.offers:[product.offers]).some(offer=>offer&&sameProductUrl(offer.url)));
  const structuredPriceEvidence=[];
  for(const product of sameProductStructured)for(const offer of Array.isArray(product.offers)?product.offers:[product.offers]){
    if(offer&&sameProductUrl(offer.url))structuredPriceEvidence.push({sku:product.sku,name:product.name,value:money(offer.price),currency:offer.priceCurrency||null,availability:offer.availability||null,url:safeUrl(offer.url)});
  }
  const uniquePrimaryValues=Array.from(new Set(mainPriceCandidates.filter(p=>p.value!==null).map(p=>p.value)));
  const candidateValue=uniquePrimaryValues.length===1?uniquePrimaryValues[0]:null;
  const priceAgreement=candidateValue!==null&&structuredPriceEvidence.length>0&&structuredPriceEvidence.every(offer=>offer.value===candidateValue&&offer.currency==='MXN');
  const primaryPrice=priceAgreement?{value:candidateValue,currency:'MXN',source:mainPriceSelector,
    displayed:mainPriceCandidates.find(p=>p.value===candidateValue).text,
    agreement:{uniqueMainDisplayedPrice:true,sameProductStructuredOffers:structuredPriceEvidence.length},
    excluded:'Reference, strikethrough, installments and unrelated variant prices are excluded from the exact main price selector.'}:null;

  // Match the current product's known image URL path; query resize/format parameters are rendition details.
  // Do not invent image URLs or fetch files. Every chosen URL comes from an already loaded DOM img.
  const currentProductImageReferences=[];
  if(metadata['og:image'])currentProductImageReferences.push({source:'og:image',src:metadata['og:image'],key:imageKey(metadata['og:image'])});
  for(const product of sameProductStructured)for(const value of Array.isArray(product.image)?product.image:[product.image]){
    const src=typeof value==='string'?value:value&&value.url;
    if(src)currentProductImageReferences.push({source:'same-product JSON-LD Product.image',src:src,key:imageKey(src)});
  }
  const ogImageKey=metadata['og:image']?imageKey(metadata['og:image']):null;
  const productImageKeys=new Set(currentProductImageReferences.filter(r=>r.source==='same-product JSON-LD Product.image').map(r=>r.key).filter(Boolean));
  const corroboratedKeys=new Set(Array.from(productImageKeys).filter(key=>!ogImageKey||key===ogImageKey));
  const allImages=Array.from(document.querySelectorAll('img'));
  const matchedProductImages=allImages.map(el=>{
    const src=el.currentSrc||el.src,key=imageKey(src);
    if(!key||!corroboratedKeys.has(key))return null;
    const style=getComputedStyle(el),rect=el.getBoundingClientRect();
    return {src:src,key:key,alt:el.alt||null,id:el.id||null,class:el.className||null,
      dataTestid:el.getAttribute('data-testid'),ariaLabel:el.getAttribute('aria-label'),
      complete:el.complete,loaded:el.complete&&el.naturalWidth>0&&el.naturalHeight>0,
      naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,visible:visible(el),
      layoutWidth:rect.width,layoutHeight:rect.height,computedDisplay:style.display,computedVisibility:style.visibility,
      ancestors:ancestry(el),source:'loaded DOM img matched by origin/path against current-product image metadata',
      matchingReferences:currentProductImageReferences.filter(reference=>reference.key===key)};
  }).filter(Boolean);
  const loadedProductImages=matchedProductImages.filter(el=>el.loaded);
  const loadedImageKeys=Array.from(new Set(loadedProductImages.map(el=>el.key)));
  const mainImage=loadedImageKeys.length===1?(loadedProductImages.find(el=>el.visible)||loadedProductImages[0]):null;
  const availabilityValues=Array.from(new Set(structuredPriceEvidence.map(offer=>offer.availability).filter(Boolean)));
  const availability={source:'same-product JSON-LD Offer.availability',values:availabilityValues,
    outOfStock:availabilityValues.length>0&&availabilityValues.every(value=>/\/OutOfStock$/.test(value))};
  const fieldsReadable=!!(productTitle&&primaryPrice&&mainImage);
  return Object.assign(base,{status:'public_product_reviewed_diagnostic',extractorVersion:'0.2-walmart-reviewed-product-dom',bodyInspected:true,
    readyState:document.readyState,headings:headings,metadata:metadata,structuredProducts:structuredProducts,invalidJsonLd:invalidJsonLd,
    priceCandidates:priceCandidates,mainPriceCandidates:mainPriceCandidates,mainImageCandidates:mainImageCandidates,imageReferences:imageReferences,
    productTitle:productTitle,primaryPrice:primaryPrice,mainImage:mainImage,matchedProductImages:matchedProductImages,imagesScanned:allImages.length,
    currentProductSku:currentSku,sameProductStructuredCount:sameProductStructured.length,availability:availability,
    priceAgreement:{uniquePrimaryValues:uniquePrimaryValues,sameProductStructuredOffers:structuredPriceEvidence,consistent:priceAgreement},
    currencyEvidence:structuredPriceEvidence.map(offer=>({source:'same-product JSON-LD Offer.priceCurrency',currency:offer.currency})),
    bodyTextExcerpt:document.body?document.body.innerText.slice(0,10000):'',fieldsReadable:fieldsReadable,
    interpretation:'Fields describe public product DOM readability only. Security verification and human confirmation are never inferred. Compare both snapshots and user confirmation separately. Loaded image dimensions are evidence, not a quality guarantee. Availability is separate from readable price/image.'});
})();
