(function () {
  const visible = el => {if(!el)return false;const r=el.getBoundingClientRect();if(r.width<=0||r.height<=0)return false;const own=getComputedStyle(el);if(own.visibility==='hidden'||own.visibility==='collapse')return false;for(let p=el;p;p=p.parentElement){const s=getComputedStyle(p);if(s.display==='none'||p.hidden)return false;}return true;};
  const text=el=>el?(el.innerText||el.textContent||'').replace(/\s+/g,' ').trim():'';
  const safeUrl=raw=>{try{const u=new URL(raw,location.href);return /^https?:$/.test(u.protocol)?u.origin+u.pathname:'';}catch(e){return '';}};
  const ancestry=el=>{const a=[];for(let p=el.parentElement;p&&a.length<8;p=p.parentElement)a.push({tag:p.tagName.toLowerCase(),id:p.id||null,class:typeof p.className==='string'?p.className:null});return a;};
  const bodyText=document.body?document.body.innerText.slice(0,14000):'';
  const headings=Array.from(document.querySelectorAll('h1,#productTitle')).filter(visible).map(text).slice(0,6);
  const auth=/\/ap\/signin|\/login|\/signin|\/sign-in|account-verification/i.test(location.pathname);
  const challengeUi=Array.from(document.querySelectorAll('#captchacharacters,form[action*="validateCaptcha"],#px-captcha,[data-testid="robot-check"]')).some(visible);
  const challenge=/\/captcha|\/challenge|validateCaptcha|\/blocked/i.test(location.pathname)||/robot check|robot or human|access denied|captcha|human verification/i.test(document.title)||challengeUi||(!headings.length&&bodyText.length<6000&&/verify you are human|verifica que eres humano|verificaci[oó]n de seguridad|slide to verify|complete the security check|confirma que no eres un robot|enter the characters you see below|introduce los caracteres que ves/i.test(bodyText));
  const meta={};
  for(const el of document.querySelectorAll('meta[property],meta[name],meta[itemprop]')){const k=el.getAttribute('property')||el.getAttribute('name')||el.getAttribute('itemprop');if(['og:title','og:image','og:url','og:description','product:price:amount','product:price:currency','price','priceCurrency'].includes(k))meta[k]=(el.getAttribute('content')||'').slice(0,800);}
  const structuredProducts=[];
  const summarizeOffer=o=>{if(Array.isArray(o))return o.slice(0,6).map(summarizeOffer);if(!o||typeof o!=='object')return null;const v={};for(const k of ['@type','price','lowPrice','highPrice','priceCurrency','availability','url'])if(o[k]!==undefined)v[k]=o[k];return v;};
  function walk(o,d=0){if(d>8||!o||typeof o!=='object'||structuredProducts.length>=6)return;if(Array.isArray(o)){o.forEach(x=>walk(x,d+1));return;}const t=o['@type'];if(t==='Product'||Array.isArray(t)&&t.includes('Product'))structuredProducts.push({name:o.name||null,image:o.image||null,sku:o.sku||null,url:o.url||null,offers:summarizeOffer(o.offers)});for(const v of Object.values(o))if(v&&typeof v==='object')walk(v,d+1);}
  let invalidJsonLd=0;
  for(const script of document.querySelectorAll('script[type="application/ld+json"]')){try{if(script.textContent.length<1000000)walk(JSON.parse(script.textContent));}catch(e){invalidJsonLd++;}}
  const priceCandidates=[],seen=new Set();
  const selectors=['#corePrice_feature_div .a-offscreen','#corePriceDisplay_desktop_feature_div .a-offscreen','#apex_desktop .a-offscreen','#apex_mobile .a-offscreen','#corePrice_mobile_feature_div .a-offscreen','[data-testid="price-wrap"] [data-seo-id="hero-price"][itemprop="price"]','[data-testid="price-wrap"]','[itemprop="price"]','[data-automation-id*="price"]','[data-testid*="price"]','[class*="price"]','[class*="Price"]'];
  for(const selector of selectors)for(const el of document.querySelectorAll(selector)){
    if(priceCandidates.length>=80)break;if(seen.has(el)||!visible(el))continue;seen.add(el);
    const t=text(el);if(!/\d/.test(t)||t.length>350)continue;
    priceCandidates.push({selector:selector,tag:el.tagName.toLowerCase(),id:el.id||null,class:el.className||null,text:t,itemprop:el.getAttribute('itemprop'),dataSeoId:el.getAttribute('data-seo-id'),ariaLabel:el.getAttribute('aria-label'),parentText:text(el.parentElement).slice(0,500),ancestors:ancestry(el)});
  }
  const largeImageCandidates=[],imageSeen=new Set();
  const imageSelectors=['img#landingImage','img#main-image','img#imgBlkFront','img#hero-image-default-0','img[data-testid="hero-image"]','img'];
  for(const selector of imageSelectors)for(const el of document.querySelectorAll(selector)){
    if(largeImageCandidates.length>=25)break;if(imageSeen.has(el)||!visible(el)||!el.complete||el.naturalWidth<200||el.naturalHeight<150||!/^https?:/.test(el.currentSrc||el.src))continue;imageSeen.add(el);
    largeImageCandidates.push({selector:selector,id:el.id||null,alt:el.alt,src:el.currentSrc||el.src,highResolutionSrc:el.getAttribute('data-old-hires'),naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,class:el.className||null,ancestors:ancestry(el)});
  }
  const amazon=/^(?:[^.]+\.)*amazon\.com\.mx$/i.test(location.hostname);
  const productTitleElement=amazon?document.querySelector('#productTitle'):null;
  const visibleHeadings=Array.from(document.querySelectorAll('h1')).filter(visible).slice(0,10).map(el=>({tag:'h1',id:el.id||null,class:el.className||null,text:text(el),ancestors:ancestry(el)}));
  const documentProductTitle=amazon?document.title.replace(/\s*:\s*Amazon\.com\.mx(?:\s*:.*)?$/i,'').trim():null;
  const ownProductTitle=visible(productTitleElement)?text(productTitleElement):null;
  const productTitle=ownProductTitle||(documentProductTitle&&documentProductTitle!==document.title.trim()?documentProductTitle:null);
  const productTitleSource=ownProductTitle?'#productTitle':productTitle?'document.title (Amazon marketplace suffix removed)':null;
  const currencyEvidence={currency:amazon?'MXN':null,inferred:amazon,source:amazon?'amazon.com.mx marketplace; not an extracted structured currency field':null};
  const primaryPriceCandidates=[],primarySeen=new Set();
  const primaryRoots=['#corePriceDisplay_mobile_feature_div','#corePrice_mobile_feature_div','#corePrice_feature_div','#corePriceDisplay_desktop_feature_div'];
  const parseAccessible=t=>{const normalized=t.replace(/\s/g,'').replace(/^\$/,'');return /^\d{1,3}(?:,\d{3})*(?:\.\d{2})?$|^\d+(?:\.\d{2})?$/.test(normalized)?Number(normalized.replace(/,/g,'')):null;};
  if(amazon)for(const rootSelector of primaryRoots)for(const root of document.querySelectorAll(rootSelector))for(const el of root.querySelectorAll('.apex-pricetopay-value')){
    if(primarySeen.has(el)||!visible(el))continue;primarySeen.add(el);
    const whole=text(el.querySelector('.a-price-whole')),fraction=text(el.querySelector('.a-price-fraction'));
    const wholeDigits=whole.replace(/[\s,.]/g,'');
    const amount=/^\d+$/.test(wholeDigits)&&/^\d{2}$/.test(fraction)?Number(wholeDigits)+Number(fraction)/100:null;
    const accessible=el.querySelector('.a-offscreen');
    const accessibleText=accessible?text(accessible):null;
    const accessibleAmount=accessibleText?parseAccessible(accessibleText):null;
    const forbidden=!!el.closest('s,del,.a-text-price,.apex-basisprice-value,[id*="installment"],[id*="Installment"],[id*="swatch"],[id*="Swatch"],[id^="twister"]');
    const reason=forbidden?'reference_installment_or_option_price':amount===null||!Number.isFinite(amount)||amount<=0?'invalid_positive_amount':accessibleText&&(accessibleAmount===null||Math.abs(accessibleAmount-amount)>0.001)?'accessible_price_mismatch':null;
    primaryPriceCandidates.push({selector:rootSelector+' .apex-pricetopay-value',whole:whole,fraction:fraction,amount:amount===null?null:amount.toFixed(2),display:text(el),accessibleText:accessibleText,accessibleAmount:accessibleAmount,rejected:reason!==null,rejectedReason:reason,ancestors:ancestry(el)});
  }
  const validPrimary=primaryPriceCandidates.filter(x=>!x.rejected);
  const uniqueAmounts=Array.from(new Set(validPrimary.map(x=>x.amount)));
  const primaryPrice=uniqueAmounts.length===1?{amount:uniqueAmounts[0],display:'$'+Number(uniqueAmounts[0]).toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2}),currency:'MXN',currencyInferred:true,sources:validPrimary.map(x=>x.selector)}:null;
  const mainImageCandidates=[],mainImageDiagnostics=[],mainImageSeen=new Set();
  const mainSelectors=['img#main-image','img#landingImage','#image-block-product-image-0 img','#landing-image-wrapper img','#imgTagWrapperId img','.variant-MAIN img'];
  if(amazon)for(const selector of mainSelectors)for(const el of document.querySelectorAll(selector)){
    if(mainImageSeen.has(el))continue;mainImageSeen.add(el);
    const gallery=el.closest('#image-block-product-image-0,#landing-image-wrapper,#imageBlock,#imgTagWrapperId,.variant-MAIN');
    const style=getComputedStyle(el),rect=el.getBoundingClientRect(),ancestorStyles=[];
    for(let parent=el.parentElement;parent&&ancestorStyles.length<8;parent=parent.parentElement){const ps=getComputedStyle(parent);ancestorStyles.push({tag:parent.tagName.toLowerCase(),id:parent.id||null,class:parent.className||null,display:ps.display,visibility:ps.visibility,hidden:parent.hidden});}
    const candidate={selector:selector,id:el.id||null,alt:el.alt,src:el.currentSrc||el.src,naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,complete:el.complete,gallerySource:gallery?(gallery.id||gallery.className):null,renderedVisible:visible(el),elementStyle:{display:style.display,visibility:style.visibility,opacity:style.opacity},layout:{width:rect.width,height:rect.height},ancestors:ancestry(el),ancestorStyles:ancestorStyles};
    const loaded=!!(gallery&&el.complete&&el.naturalWidth>0&&el.naturalHeight>0&&/^https:/.test(el.currentSrc||el.src));
    candidate.loadedPrimaryGalleryImage=loaded;mainImageDiagnostics.push(candidate);
    if(loaded)mainImageCandidates.push(candidate);
  }
  const mobileMain=mainImageCandidates.filter(x=>x.id==='main-image');
  const desktopMain=mainImageCandidates.filter(x=>x.id==='landingImage');
  const preferredMain=mobileMain.length?mobileMain:desktopMain.length?desktopMain:mainImageCandidates;
  const uniqueImages=Array.from(new Set(preferredMain.map(x=>x.src)));
  const mainImage=uniqueImages.length===1?preferredMain[0]:null;
  const photoAndPriceReadable=!!(amazon&&productTitle&&primaryPrice&&mainImage&&!auth&&!challenge);
  return {pageUrl:safeUrl(location.href),pageTitle:document.title,readyState:document.readyState,headings:headings,accountVerification:auth,challenge:challenge,metadata:meta,structuredProducts:structuredProducts,invalidJsonLd:invalidJsonLd,priceCandidates:priceCandidates,largeImageCandidates:largeImageCandidates,bodyTextExcerpt:bodyText,productTitle:productTitle,productTitleSource:productTitleSource,visibleHeadings:visibleHeadings,primaryPriceCandidates:primaryPriceCandidates,primaryPrice:primaryPrice,currencyEvidence:currencyEvidence,mainImageCandidates:mainImageCandidates,mainImageDiagnostics:mainImageDiagnostics,imageEvidenceMode:'loaded_primary_gallery_dom',mainImage:mainImage,photoAndPriceReadable:photoAndPriceReadable,interpretation:amazon?'Amazon primary price and loaded primary-gallery DOM image; CSS visibility is recorded separately. Native app requires two matching observations.':'Diagnostic only; no Walmart extraction success is asserted.'};
})();
