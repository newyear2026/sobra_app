package com.sobrita.sheinprobe;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.graphics.Color;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.PixelCopy;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

public class ProbeActivity extends Activity {
    static final String TAG="SobritaSheinProbe";
    static final String DEFAULT_URL="https://www.shein.com.mx/Women-Long-Dresses-p-568117802.html";
    final Handler handler=new Handler(Looper.getMainLooper());
    WebView web;
    TextView status;
    JSONObject report;
    JSONArray observations, errors;
    String script, runId, requestedUrl;
    int generation=0, successes=0;
    boolean done=false;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout=new LinearLayout(this); layout.setOrientation(LinearLayout.VERTICAL); layout.setBackgroundColor(Color.WHITE);
        layout.setOnApplyWindowInsetsListener((v,insets)->{
            if(Build.VERSION.SDK_INT>=30){android.graphics.Insets bars=insets.getInsets(android.view.WindowInsets.Type.systemBars());v.setPadding(bars.left,bars.top,bars.right,bars.bottom);}
            else v.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());
            return insets;
        });
        status=new TextView(this); status.setTextSize(12); status.setPadding(12,10,12,10); status.setTextColor(Color.rgb(18,38,91));
        layout.addView(status,new LinearLayout.LayoutParams(-1,-2));
        web=new WebView(this); layout.addView(web,new LinearLayout.LayoutParams(-1,0,1)); setContentView(layout);
        WebSettings settings=web.getSettings();
        settings.setJavaScriptEnabled(true); settings.setDomStorageEnabled(true); settings.setAllowFileAccess(false); settings.setAllowContentAccess(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        // Keep Android WebView's original UA, ordinary cookie behavior and network stack.
        // No browser cookie import, proxy, API client, JavaScript bridge or SSL override.
        try { InputStream in=getAssets().open("extract.js"); ByteArrayOutputStream out=new ByteArrayOutputStream(); byte[] b=new byte[4096]; int n; while((n=in.read(b))!=-1)out.write(b,0,n); in.close(); script=new String(out.toByteArray(),StandardCharsets.UTF_8); }
        catch(Exception e){throw new RuntimeException(e);}
        web.setWebViewClient(new WebViewClient(){
            @Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest request){
                Uri u=request.getUrl(); String host=u.getHost();
                return !"https".equals(u.getScheme()) || host==null || !(host.equals("shein.com.mx")||host.endsWith(".shein.com.mx")||host.equals("shein.com")||host.endsWith(".shein.com"));
            }
            @Override public void onPageFinished(WebView view,String url){ final int g=generation; handler.postDelayed(()->capture(g,"page_finished"),2500); }
            @Override public void onReceivedError(WebView view,WebResourceRequest req,WebResourceError error){if(req.isForMainFrame())recordError("network",error.getErrorCode(),String.valueOf(error.getDescription()));}
            @Override public void onReceivedHttpError(WebView view,WebResourceRequest req,WebResourceResponse response){if(req.isForMainFrame())recordError("http",response.getStatusCode(),response.getReasonPhrase());}
        });
        start(getIntent());
    }
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);start(intent);}
    void start(Intent intent){
        String url=intent.getStringExtra("url"); if(url==null)url=DEFAULT_URL;
        Uri initial=Uri.parse(url); String host=initial.getHost(); String path=initial.getPath();
        if(!"https".equals(initial.getScheme())||host==null||!(host.equals("shein.com.mx")||host.endsWith(".shein.com.mx")||host.equals("mx.shein.com")||host.equals("m.shein.com"))||path==null||!path.matches(".*-p-[0-9]+\\.html")){status.setText("Rejected: only public SHEIN product HTTPS URLs are allowed.");return;}
        generation++; final int g=generation; handler.removeCallbacksAndMessages(null); web.stopLoading();
        done=false;successes=0;requestedUrl=url;runId=intent.getStringExtra("run_id");
        if(runId==null)runId="probe_"+System.currentTimeMillis();runId=runId.replaceAll("[^a-zA-Z0-9_-]","_");
        report=new JSONObject();observations=new JSONArray();errors=new JSONArray();
        try {
            report.put("runId",runId).put("requestedUrl",url).put("startedAtUtc",now()).put("androidSdk",Build.VERSION.SDK_INT).put("androidRelease",Build.VERSION.RELEASE).put("deviceModel",Build.MODEL).put("userAgent",web.getSettings().getUserAgentString()).put("targetSdk",getApplicationInfo().targetSdkVersion).put("extractorVersion","0.1-shein-diagnostic-only");
            PackageInfo info=WebView.getCurrentWebViewPackage();if(info!=null)report.put("webViewPackage",info.packageName).put("webViewVersion",info.versionName);
            report.put("javascriptEnabled",true).put("domStorageEnabled",true).put("uaOverride",false).put("officialApiUsed",false).put("manualLoginUsed",false).put("cookiesImported",false).put("cookiePolicy","Default WebView behavior; site may set ordinary cookies. No cookie values inspected or exported.");
            report.put("observations",observations).put("mainFrameErrors",errors);
        }catch(Exception e){throw new RuntimeException(e);}
        status.setText("Sobrita SHEIN WebView diagnostic — loading\n"+url);web.loadUrl(url);
        for(int delay:new int[]{6000,13000,23000})handler.postDelayed(()->capture(g,"timer"),delay);
        handler.postDelayed(()->finishRun(g,"diagnostic_complete",null),25000);
    }
    void recordError(String type,int code,String description){try{errors.put(new JSONObject().put("type",type).put("code",code).put("description",description));}catch(Exception ignored){}}
    void capture(int g,String trigger){
        if(done||g!=generation)return;
        web.evaluateJavascript(script,value->{
            if(done||g!=generation)return;
            try{
                Object parsed=new JSONTokener(value).nextValue();
                if(!(parsed instanceof JSONObject)){recordError("extraction",0,"No JSON object returned");return;}
                JSONObject item=(JSONObject)parsed;item.put("observedAtUtc",now()).put("trigger",trigger);observations.put(item);
                if(item.optBoolean("accountVerification")||item.optBoolean("challenge")){finishRun(g,"account_or_challenge_screen",item);return;}
                status.setText("Sobrita SHEIN WebView diagnostic — checking\n"+item.optString("pageUrl")+"\nCollecting public page candidates; not yet verified");
            }catch(Exception e){recordError("extraction",0,e.toString());}
        });
    }
    void finishRun(int g,String reason,JSONObject last){
        if(done||g!=generation)return;done=true;handler.removeCallbacksAndMessages(null);
        try{
            if(last==null&&observations.length()>0)last=observations.getJSONObject(observations.length()-1);
            boolean success=false; // Diagnostics never assert extraction success from candidates alone.
            report.put("finishedAtUtc",now()).put("completionReason",reason).put("diagnosticComplete",true).put("extractionConfirmed",false).put("finalObservation",last==null?JSONObject.NULL:last);
            byte[] bytes=report.toString(2).getBytes(StandardCharsets.UTF_8);
            java.io.FileOutputStream out=openFileOutput(runId+".json",MODE_PRIVATE);out.write(bytes);out.close();
            Log.i(TAG,"RESULT "+runId+" diagnosticComplete=true"+" reason="+reason+" file="+runId+".json");
            int prices=last==null||last.optJSONArray("priceCandidates")==null?0:last.optJSONArray("priceCandidates").length();
            int images=last==null||last.optJSONArray("largeImageCandidates")==null?0:last.optJSONArray("largeImageCandidates").length();
            status.setText("Sobrita SHEIN WebView — DIAGNOSTIC COMPLETE\n"+reason+"\n"+(last==null?"":last.optString("pageTitle"))+"\nPrice candidates: "+prices+" · Images: "+images+" (unverified)");
            handler.postDelayed(()->captureWindow(runId),800);
        }catch(Exception e){Log.e(TAG,"Saving result failed",e);status.setText("Saving result failed: "+e);}
    }
    void captureWindow(String id){
        try{
            android.view.View decor=getWindow().getDecorView();
            Bitmap bitmap=Bitmap.createBitmap(decor.getWidth(),decor.getHeight(),Bitmap.Config.ARGB_8888);
            if(Build.VERSION.SDK_INT>=26)PixelCopy.request(getWindow(),bitmap,result->{
                if(result==PixelCopy.SUCCESS)saveBitmap(id,bitmap);
                else{decor.draw(new Canvas(bitmap));saveBitmap(id,bitmap);}
            },handler);
            else{decor.draw(new Canvas(bitmap));saveBitmap(id,bitmap);}
        }catch(Exception e){Log.e(TAG,"Screenshot failed",e);}
    }
    void saveBitmap(String id,Bitmap bitmap){
        try{java.io.FileOutputStream out=openFileOutput(id+".png",MODE_PRIVATE);bitmap.compress(Bitmap.CompressFormat.PNG,100,out);out.close();Log.i(TAG,"SCREENSHOT "+id+".png");}
        catch(Exception e){Log.e(TAG,"Screenshot save failed",e);}finally{bitmap.recycle();}
    }
    String now(){SimpleDateFormat f=new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",Locale.US);f.setTimeZone(TimeZone.getTimeZone("UTC"));return f.format(new Date());}
    @Override public void onDestroy(){handler.removeCallbacksAndMessages(null);web.destroy();super.onDestroy();}
}
