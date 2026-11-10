(function () {
  const visible = el => {if(!el)return false;const r=el.getBoundingClientRect();if(r.width<=0||r.height<=0)return false;for(let p=el;p;p=p.parentElement){const s=getComputedStyle(p);if(s.display==='none'||s.visibility==='hidden'||s.visibility==='collapse'||p.hidden)return false;}return true;};
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
  return {pageUrl:safeUrl(location.href),pageTitle:document.title,readyState:document.readyState,headings:headings,accountVerification:auth,challenge:challenge,metadata:meta,structuredProducts:structuredProducts,invalidJsonLd:invalidJsonLd,priceCandidates:priceCandidates,largeImageCandidates:largeImageCandidates,bodyTextExcerpt:bodyText,extractionConfirmed:false,interpretation:'Candidate evidence only. No primary product price or image is automatically asserted; review rendered price/image and screenshot.'};
})();
