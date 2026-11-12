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
  return Object.assign(base,{status:'public_product_diagnostic',bodyInspected:true,readyState:document.readyState,headings:headings,metadata:metadata,structuredProducts:structuredProducts,invalidJsonLd:invalidJsonLd,priceCandidates:priceCandidates,mainPriceCandidates:mainPriceCandidates,mainImageCandidates:mainImageCandidates,imageReferences:imageReferences,bodyTextExcerpt:document.body?document.body.innerText.slice(0,10000):'',interpretation:'Public product DOM candidates only. This diagnostic does not confirm a primary price/photo or successful human verification. Compare both samples and actual user confirmation. Loaded natural dimensions are recorded without arbitrary size thresholds.'});
})();
