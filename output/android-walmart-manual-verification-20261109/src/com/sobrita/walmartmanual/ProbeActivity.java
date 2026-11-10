package com.sobrita.walmartmanual;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
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
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

public class ProbeActivity extends Activity {
    static final String TAG="SobritaWalmartManual";
    static final String DEFAULT_URL="https://www.walmart.com.mx/ip/audifonos-inalambricos-apple-airpods-4-blancos/00019594968846";
    final Handler handler=new Handler(Looper.getMainLooper());
    WebView web;TextView status;Button inspectButton;
    JSONObject report;JSONArray observations,errors=new JSONArray();
    String script,assetScript,runId,requestedUrl;int generation=0;boolean inspecting=false;
    @Override public void onCreate(Bundle saved){
        super.onCreate(saved);
        LinearLayout layout=new LinearLayout(this);layout.setOrientation(LinearLayout.VERTICAL);layout.setBackgroundColor(Color.WHITE);
        layout.setOnApplyWindowInsetsListener((v,insets)->{if(Build.VERSION.SDK_INT>=30){android.graphics.Insets bars=insets.getInsets(android.view.WindowInsets.Type.systemBars());v.setPadding(bars.left,bars.top,bars.right,bars.bottom);}else v.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());return insets;});
        status=new TextView(this);status.setTextSize(12);status.setPadding(12,8,12,8);status.setTextColor(Color.rgb(18,38,91));layout.addView(status,new LinearLayout.LayoutParams(-1,-2));
        inspectButton=new Button(this);inspectButton.setText("보안 확인 후 정보 읽기");inspectButton.setOnClickListener(v->inspect(null));layout.addView(inspectButton,new LinearLayout.LayoutParams(-1,-2));
        web=new WebView(this);layout.addView(web,new LinearLayout.LayoutParams(-1,0,1));setContentView(layout);
        WebSettings settings=web.getSettings();settings.setJavaScriptEnabled(true);settings.setDomStorageEnabled(true);settings.setAllowFileAccess(false);settings.setAllowContentAccess(false);settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        // Preserve default UA, ordinary WebView cookies and the displayed page across inspection.
        // Never automate, dismiss, solve or bypass a security prompt or login.
        try{InputStream in=getAssets().open("extract.js");ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] b=new byte[4096];int n;while((n=in.read(b))!=-1)out.write(b,0,n);in.close();script=new String(out.toByteArray(),StandardCharsets.UTF_8);assetScript=script;}catch(Exception e){throw new RuntimeException(e);}
        web.setWebViewClient(new WebViewClient(){
            @Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest req){Uri u=req.getUrl();if(!req.isForMainFrame())return !"https".equals(u.getScheme());String h=u.getHost();return !"https".equals(u.getScheme())||h==null||!(h.equals("walmart.com.mx")||h.endsWith(".walmart.com.mx"));}
            @Override public void onPageFinished(WebView v,String url){if(!inspecting)status.setText("Walmart 수동 확인 테스트\n보안 확인은 직접 완료한 뒤 위 버튼을 눌러 주세요.\n"+safeUrl(url));}
            @Override public void onReceivedError(WebView v,WebResourceRequest req,WebResourceError e){if(req.isForMainFrame())recordError("network",e.getErrorCode(),String.valueOf(e.getDescription()));}
            @Override public void onReceivedHttpError(WebView v,WebResourceRequest req,WebResourceResponse r){if(req.isForMainFrame())recordError("http",r.getStatusCode(),r.getReasonPhrase());}
        });
        startPage(getIntent());
    }
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);if("inspect".equals(intent.getStringExtra("action")))inspect(intent);else startPage(intent);}
    boolean allowedProduct(String url){Uri u=Uri.parse(url);String h=u.getHost(),p=u.getPath();return "https".equals(u.getScheme())&&h!=null&&(h.equals("walmart.com.mx")||h.endsWith(".walmart.com.mx"))&&p!=null&&p.matches("/ip/[^/]+/[0-9]+/?");}
    void startPage(Intent intent){
        String url=intent.getStringExtra("url");if(url==null)url=DEFAULT_URL;
        if(!allowedProduct(url)){status.setText("Only public Walmart product HTTPS URLs are allowed.");return;}
        generation++;handler.removeCallbacksAndMessages(null);inspecting=false;inspectButton.setEnabled(true);errors=new JSONArray();
        requestedUrl=url;runId=cleanId(intent.getStringExtra("run_id"));status.setText("Walmart 수동 확인 테스트 — 페이지 여는 중\n"+url);web.loadUrl(url);
    }
    void inspect(Intent intent){
        if(inspecting)return;if(requestedUrl==null){status.setText("Open a product page first.");return;}
        if(intent!=null&&intent.hasExtra("run_id"))runId=cleanId(intent.getStringExtra("run_id"));
        // Operator-controlled, app-private DOM extractor override; does not navigate or clear state.
        script=assetScript;boolean overrideUsed=false;
        try{File override=new File(getFilesDir(),"extract-override.js");if(override.isFile()&&override.length()>0&&override.length()<100000){InputStream in=new FileInputStream(override);ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] buffer=new byte[4096];int count;while((count=in.read(buffer))!=-1)out.write(buffer,0,count);in.close();script=new String(out.toByteArray(),StandardCharsets.UTF_8);overrideUsed=true;}}catch(Exception e){recordError("extractor_override",0,e.toString());}
        generation++;final int g=generation;handler.removeCallbacksAndMessages(null);inspecting=true;inspectButton.setEnabled(false);observations=new JSONArray();report=new JSONObject();
        try{
            Object verification=intent!=null&&intent.hasExtra("user_confirmed_verification")?intent.getBooleanExtra("user_confirmed_verification",false):JSONObject.NULL;
            report.put("runId",runId).put("requestedUrl",requestedUrl).put("startedAtUtc",now()).put("androidSdk",Build.VERSION.SDK_INT).put("androidRelease",Build.VERSION.RELEASE).put("targetSdk",getApplicationInfo().targetSdkVersion).put("deviceModel",Build.MODEL).put("userAgent",web.getSettings().getUserAgentString());
            PackageInfo pkg=WebView.getCurrentWebViewPackage();if(pkg!=null)report.put("webViewPackage",pkg.packageName).put("webViewVersion",pkg.versionName);
            report.put("extractorVersion","0.1-walmart-user-triggered-public-dom-diagnostic").put("manualVerificationCompleted",verification).put("manualVerificationEvidence",verification==JSONObject.NULL?"unknown; pressing inspect does not establish completion":"explicit user confirmation supplied by operator");
            report.put("extractorOverrideUsed",overrideUsed);
            report.put("inspectionTrigger",intent==null?"native_button":"intent_action_inspect").put("pageReloadedForInspection",false).put("cookiesClearedForInspection",false).put("uaOverride",false).put("officialApiUsed",false).put("manualLoginUsed",false).put("securityPromptAutomated",false).put("cookiePolicy","Default WebView state retained; values are not inspected or exported.");
            report.put("observations",observations).put("mainFrameErrors",errors);
        }catch(Exception e){throw new RuntimeException(e);}
        status.setText("현재 화면의 공개 상품 정보 확인 중\n보안 확인·로그인은 자동 조작하지 않습니다.");
        capture(g,1);handler.postDelayed(()->finish(g,"inspection_timeout"),12000);
    }
    void capture(int g,int index){
        if(!inspecting||g!=generation)return;
        web.evaluateJavascript(script,value->{
            if(!inspecting||g!=generation)return;
            try{Object o=new JSONTokener(value).nextValue();if(o instanceof JSONObject){JSONObject row=(JSONObject)o;row.put("observedAtUtc",now()).put("sampleIndex",index);observations.put(row);}else recordError("inspection",0,"No object returned");}catch(Exception e){recordError("inspection",0,e.toString());}
            if(index==1)handler.postDelayed(()->capture(g,2),2000);else finish(g,"two_snapshots_recorded");
        });
    }
    void finish(int g,String reason){
        if(!inspecting||g!=generation)return;inspecting=false;handler.removeCallbacksAndMessages(null);inspectButton.setEnabled(true);
        try{
            JSONObject last=observations.length()>0?observations.getJSONObject(observations.length()-1):null;
            boolean blocked=last!=null&&(last.optBoolean("challenge")||last.optBoolean("accountVerification"));
            report.put("finishedAtUtc",now()).put("completionReason",blocked?"security_or_auth_screen_retained":reason).put("diagnosticComplete",true).put("extractionConfirmed",false).put("finalObservation",last==null?JSONObject.NULL:last);
            atomicWrite(runId+".json",report.toString(2).getBytes(StandardCharsets.UTF_8));
            status.setText("DIAGNOSTIC COMPLETE — "+(blocked?"보안 확인 화면 유지":"상품 정보 후보 기록")+"\n"+(last==null?"":last.optString("pageTitle"))+"\n결과: "+runId+" (자동 성공 판정 없음)");
            Log.i(TAG,"RESULT "+runId+" file="+runId+".json");final String savedId=runId;handler.postDelayed(()->captureWindow(savedId),800);
        }catch(Exception e){Log.e(TAG,"Result save failed",e);status.setText("Result save failed: "+e);}
    }
    void atomicWrite(String name,byte[] bytes)throws Exception{File temp=new File(getFilesDir(),name+".part"),dest=new File(getFilesDir(),name);FileOutputStream out=new FileOutputStream(temp);out.write(bytes);out.flush();out.getFD().sync();out.close();if(!temp.renameTo(dest))throw new java.io.IOException("Atomic rename failed for "+name);}
    void captureWindow(String id){try{android.view.View decor=getWindow().getDecorView();Bitmap bitmap=Bitmap.createBitmap(decor.getWidth(),decor.getHeight(),Bitmap.Config.ARGB_8888);if(Build.VERSION.SDK_INT>=26)PixelCopy.request(getWindow(),bitmap,r->{if(r!=PixelCopy.SUCCESS)decor.draw(new Canvas(bitmap));saveBitmap(id,bitmap);},handler);else{decor.draw(new Canvas(bitmap));saveBitmap(id,bitmap);}}catch(Exception e){Log.e(TAG,"Screenshot failed",e);}}
    void saveBitmap(String id,Bitmap bitmap){try{ByteArrayOutputStream out=new ByteArrayOutputStream();bitmap.compress(Bitmap.CompressFormat.PNG,100,out);atomicWrite(id+".png",out.toByteArray());Log.i(TAG,"SCREENSHOT "+id+".png");}catch(Exception e){Log.e(TAG,"Screenshot save failed",e);}finally{bitmap.recycle();}}
    void recordError(String type,int code,String message){try{errors.put(new JSONObject().put("type",type).put("code",code).put("description",message));}catch(Exception ignored){}}
    String cleanId(String id){return (id==null?"manual_"+System.currentTimeMillis():id).replaceAll("[^a-zA-Z0-9_-]","_");}
    String safeUrl(String raw){try{return Uri.parse(raw).buildUpon().clearQuery().fragment(null).build().toString();}catch(Exception e){return "";}}
    String now(){SimpleDateFormat f=new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",Locale.US);f.setTimeZone(TimeZone.getTimeZone("UTC"));return f.format(new Date());}
    @Override public void onDestroy(){handler.removeCallbacksAndMessages(null);web.destroy();super.onDestroy();}
}
