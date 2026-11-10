(function () {
  const visible = el => !!el && el.getBoundingClientRect().width > 0 && el.getBoundingClientRect().height > 0 && getComputedStyle(el).visibility !== 'hidden' && getComputedStyle(el).display !== 'none';
  const text = el => el ? (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim() : '';
  const safeUrl = raw => { try { const u=new URL(raw,location.href); return u.protocol === 'https:' ? u.origin+u.pathname : ''; } catch(e) { return ''; } };
  const heading = document.querySelector('h1.ui-pdp-title') || document.querySelector('h1');
  const productTitle = visible(heading) ? text(heading) : null;
  const excerpt = document.body ? document.body.innerText.slice(0,12000) : '';
  const auth = /\/account-verification|\/login|\/registration/.test(location.pathname) || /Para continuar, ingresa a tu cuenta/.test(excerpt);
  const challenge = /\/captcha|\/challenge/.test(location.pathname) || /verifica que eres humano|verify you are human|robot check|comprueba que eres humano/i.test(excerpt);
  const error = /Hubo un error accediendo|Access Denied|ERR_NAME_NOT_RESOLVED|This site can.t be reached/i.test(excerpt);
  const priceCandidates = [];
  const variantSelector = '.ui-pdp-variations,.ui-pdp-outside_variations,.ui-pdp-outside-variations';
  const selectors = ['.ui-pdp-price__second-line .andes-money-amount', '.ui-pdp-price .andes-money-amount'];
  const seen = new Set();
  for (const selector of selectors) for (const el of document.querySelectorAll(selector)) {
    if (seen.has(el) || !visible(el)) continue;
    seen.add(el);
    const fraction = el.querySelector('.andes-money-amount__fraction');
    const cents = el.querySelector('.andes-money-amount__cents');
    const inPrimaryPriceRow = selector === selectors[0] && !!el.closest('.ui-pdp-price__second-line');
    const variantContainer = el.closest(variantSelector);
    const referencePrice = !!el.closest('s,del,.andes-money-amount--previous,.ui-pdp-price__original-value');
    const installmentPrice = !!el.closest('.ui-pdp-price__payments') || /meses|cuotas|mensual/i.test(text(el.parentElement));
    const rejectedReason = variantContainer ? 'variant_option_price' : !inPrimaryPriceRow ? 'outside_primary_price_row' : referencePrice ? 'reference_or_previous_price' : installmentPrice ? 'installment_price' : null;
    const ancestors = [];
    for(let parent=el.parentElement; parent && ancestors.length<8; parent=parent.parentElement) ancestors.push({tag:parent.tagName.toLowerCase(),class:parent.className||null});
    const numeric = fraction ? text(fraction).replace(/[.,\s]/g,'')+(cents ? '.'+text(cents) : '') : null;
    priceCandidates.push({selector:selector,display:text(el),ariaLabel:el.getAttribute('aria-label'),fraction:text(fraction),cents:text(cents),numeric:numeric,inPrimaryPriceRow:inPrimaryPriceRow,rejected:rejectedReason!==null,rejectedReason:rejectedReason,variantContainerClass:variantContainer?variantContainer.className:null,ancestors:ancestors,context:text(el.parentElement).slice(0,280)});
  }
  const eligible = priceCandidates.filter(x=>!x.rejected && x.numeric && /^\d+(\.\d{1,2})?$/.test(x.numeric));
  const distinctPrimaryAmounts = new Set(eligible.map(x=>x.numeric));
  const primaryPrice = distinctPrimaryAmounts.size === 1 ? eligible[0] : null;
  const images = Array.from(document.querySelectorAll('.ui-pdp-gallery img, img.ui-pdp-image')).filter(el=>visible(el)&&el.complete&&el.naturalWidth>=200&&el.naturalHeight>=150).map(el=>({alt:el.alt,src:el.currentSrc||el.src,naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,source:'rendered product gallery img'}));
  const variants = Array.from(document.querySelectorAll(variantSelector)).filter(visible).map(text).slice(0,3);
  return {pageUrl:safeUrl(location.href),pageTitle:document.title,readyState:document.readyState,productTitle:productTitle,productTitleSource:heading ? heading.tagName.toLowerCase()+'.'+heading.className : null,accountVerification:auth,challenge:challenge,errorPage:error,priceCandidates:priceCandidates,primaryPrice:primaryPrice,mainImage:images[0]||null,imageCandidates:images.slice(0,3),variantText:variants,photoAndPriceReadable:!!(productTitle&&primaryPrice&&images.length&&!auth&&!challenge&&!error)};
})();
