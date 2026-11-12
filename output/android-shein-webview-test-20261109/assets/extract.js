(function () {
  const visible = el => !!el && el.getBoundingClientRect().width>0 && el.getBoundingClientRect().height>0 && getComputedStyle(el).visibility!=='hidden' && getComputedStyle(el).display!=='none';
  const text = el => el ? (el.innerText||el.textContent||'').replace(/\s+/g,' ').trim() : '';
  const safeUrl = raw => {try{const u=new URL(raw,location.href);return /^https?:$/.test(u.protocol)?u.origin+u.pathname:'';}catch(e){return '';}};
  const ancestry = el => {const a=[];for(let p=el.parentElement;p&&a.length<6;p=p.parentElement)a.push({tag:p.tagName.toLowerCase(),class:typeof p.className==='string'?p.className:null});return a;};
  const bodyText=document.body?document.body.innerText.slice(0,12000):'';
  const headings=Array.from(document.querySelectorAll('h1')).filter(visible).map(text).slice(0,5);
  const auth=/\/login|\/signin|\/sign-in|\/user\/auth|account-verification/i.test(location.pathname);
  const challenge=/\/captcha|\/challenge|\/risk\/|\/risk-control|\/verify/i.test(location.pathname)||/verify you are human|verifica que eres humano|verificaci[oó]n de seguridad|robot check|slide to verify|desliza para verificar|complete the security check|confirma que no eres un robot|access denied/i.test(bodyText);
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
  const largeImageCandidates=Array.from(document.querySelectorAll('img')).filter(el=>visible(el)&&el.complete&&el.naturalWidth>=200&&el.naturalHeight>=150&&/^https?:/.test(el.currentSrc||el.src)).slice(0,18).map(el=>({alt:el.alt,src:el.currentSrc||el.src,naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,class:el.className||null,ancestors:ancestry(el)}));
  return {pageUrl:safeUrl(location.href),pageTitle:document.title,readyState:document.readyState,headings:headings,accountVerification:auth,challenge:challenge,metadata:meta,structuredProducts:structuredProducts,invalidJsonLd:invalidJsonLd,priceCandidates:priceCandidates,largeImageCandidates:largeImageCandidates,bodyTextExcerpt:bodyText,extractionConfirmed:false,interpretation:'Candidate evidence only. No primary product price or image is automatically asserted.'};
})();
