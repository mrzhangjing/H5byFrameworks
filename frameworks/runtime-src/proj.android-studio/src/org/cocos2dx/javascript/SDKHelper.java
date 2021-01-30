package org.cocos2dx.javascript;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.widget.Toast;

import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.TTAdConfig;
import com.bytedance.sdk.openadsdk.TTAdConstant;
import com.bytedance.sdk.openadsdk.TTAdManager;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTAdSdk;
import com.bytedance.sdk.openadsdk.TTAppDownloadListener;
import com.bytedance.sdk.openadsdk.TTRewardVideoAd;

import com.bytedance.sdk.openadsdk.activity.base.TTRewardVideoActivity;
import com.tencent.mm.opensdk.diffdev.OAuthErrCode;
import com.tencent.mm.opensdk.diffdev.OAuthListener;
import com.tencent.mm.opensdk.modelbiz.WXLaunchMiniProgram;
import com.tencent.mm.opensdk.modelmsg.SendAuth;
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX;
import com.tencent.mm.opensdk.modelmsg.WXImageObject;
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage;
import com.tencent.mm.opensdk.modelmsg.WXWebpageObject;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxJavascriptJavaBridge;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.FileInputStream;
import java.io.FileNotFoundException;

import wpbydfh.zgame.huawei.wxapi.Util;

public class SDKHelper implements OAuthListener {

    private static IWXAPI api;
    public static final String WX_APP_ID = "wx8afc704e3471a973";

    private static AppActivity app_instance;
    private static String m_authCode = "";


    public static String PROCESS_NAME_XXXX = "process_name_xxxx";
    public static TTAdNative mTTAdNative;
    public static TTRewardVideoAd mttRewardVideoAd = null;

//    private static AppActivity m_instance = null;
    private static boolean IsSeeAdComplete = false;

    public static void init(Cocos2dxActivity cxt){
        app_instance = (AppActivity) cxt;

        api = WXAPIFactory.createWXAPI(cxt, WX_APP_ID, true);
        api.registerApp(WX_APP_ID);

    }

    public static void wxLogin(){
        Log.e("SDKHelper", "login: ");
        if(api.isWXAppInstalled()){
            String state = System.currentTimeMillis() + "";
            SendAuth.Req req = new SendAuth.Req();
            req.scope = "snsapi_userinfo";
            req.state = state;
            api.sendReq(req);
        }else{
            Toast.makeText(app_instance, "请先安装微信", Toast.LENGTH_SHORT).show();
        }
    }

    public static void shareURLToWX(String url, String title, String description, boolean isPYQ){
        WXWebpageObject webpage = new WXWebpageObject();
        webpage.webpageUrl = url;

        WXMediaMessage msg = new WXMediaMessage(webpage);
        msg.title = title;
        msg.description = description;

        SendMessageToWX.Req req = new SendMessageToWX.Req();
        req.transaction = buildTransaction("webpage");
        req.message = msg;
        if (isPYQ){
            req.scene = SendMessageToWX.Req.WXSceneTimeline;
        }else{
            req.scene = SendMessageToWX.Req.WXSceneSession;
        }

        api.sendReq(req);
    }



    static void shareImageToWX(String imageUrl, boolean isPYQ){
        FileInputStream fis = null;
        try {
            fis = new FileInputStream(imageUrl);
        } catch (FileNotFoundException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        Bitmap bmp  = BitmapFactory.decodeStream(fis);

        WXImageObject imgObj = new WXImageObject(bmp);
        WXMediaMessage msg = new WXMediaMessage();
        msg.mediaObject = imgObj;

        Bitmap thumbBmp = Bitmap.createScaledBitmap(bmp, 100, 100, true);

        bmp.recycle();
        msg.thumbData = Util.bmpToByteArray(thumbBmp, true);
        SendMessageToWX.Req req = new SendMessageToWX.Req();
        req.transaction = buildTransaction("img");
        req.message = msg;
        if (isPYQ){
            req.scene = SendMessageToWX.Req.WXSceneTimeline;
        }else{
            req.scene = SendMessageToWX.Req.WXSceneSession;
        }

        api.sendReq(req);
    }

    static String buildTransaction(final String type) {
        return (type == null) ? String.valueOf(System.currentTimeMillis())
                :type + System.currentTimeMillis();
    }



    public static void jumpMiniProgram(final String XiaoChengXuId,final String path,final int type) {

        WXLaunchMiniProgram.Req req = new WXLaunchMiniProgram.Req();
        req.userName = XiaoChengXuId; // 填小程序原始id
        if(!path.equals("")){
            req.path = path;                  //拉起小程序页面的可带参路径，不填默认拉起小程序首页
        }
//		req.miniprogramType = WXLaunchMiniProgram.Req.MINIPTOGRAM_TYPE_RELEASE;// 可选打开 开发版，体验版和正式版
//		req.miniprogramType = WXLaunchMiniProgram.Req.MINIPROGRAM_TYPE_TEST;// 可选打开 开发版，体验版和正式版
//		req.miniprogramType = WXLaunchMiniProgram.Req.MINIPROGRAM_TYPE_PREVIEW;// 可选打开 开发版，体验版和正式版


//        req.miniprogramType = type;
        req.miniprogramType = WXLaunchMiniProgram.Req.MINIPROGRAM_TYPE_PREVIEW;

        api.sendReq(req);
    }


    @Override
    public void onAuthGotQrcode(String s, byte[] bytes) {

    }

    @Override
    public void onQrcodeScanned() {

    }

    @Override
    public void onAuthFinish(OAuthErrCode oAuthErrCode, String s) {

    }

    public static void fetchWxAuthCodeAndCallBack(String code) {
        if(m_authCode.equals(code)){
            return;
        }
        m_authCode = code;
        JSONObject obj = new JSONObject();
        try {
            obj.put("authCode", code);
            obj.put("isSuc", true);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        String ret = obj.toString();
//        doCallback(-1, ret, false);
        final String exes = "cc.wxLoginResult("+ ret + ")";
        doCallback(exes);
    }


    public static void fetchWxShareResult(boolean isSuc) {
        JSONObject obj = new JSONObject();
        try {
            obj.put("isSuc", isSuc);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        String ret = obj.toString();
        final String exes = "cc.wxShareResult("+ ret + ")";
        doCallback(exes);
    }


    public static void jumpMiniResult(final String key,final String data) {
        JSONObject obj = new JSONObject();
        try {
            obj.put("key",key);
            obj.put("data",data);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        String ret = obj.toString();
        final String exes = "cc.jumpMiniResult("+ ret + ")";
        doCallback(exes);
    }

    /*************************广告****************************/


    public static void initTTAdSdk(Context context) {
        TTAdManager ttadManager = TTAdSdk.init(context,
                new TTAdConfig.Builder()
                        .appId("5131817")
                        .useTextureView(true) //使用TextureView控件播放视频,默认为SurfaceView,当有SurfaceView冲突的场景，可以使用TextureView
                        .allowShowNotify(true) //是否允许sdk展示通知栏提示
                        .appName("APP测试")
                        .titleBarTheme(TTAdConstant.TITLE_BAR_THEME_DARK)
//                        .allowShowPageWhenScreenLock(true) //是否在锁屏场景支持展示广告落地页
                        .debug(true) //测试阶段打开，可以通过日志排查问题，上线时去除该调用
                        .directDownloadNetworkType(TTAdConstant.NETWORK_STATE_WIFI, TTAdConstant.NETWORK_STATE_3G) //允许直接下载的网络状态集合
                        .supportMultiProcess(false) //是否支持多进程，true支持
                        .asyncInit(true)
                        //.httpStack(new MyOkStack3())//自定义网络库，demo中给出了okhttp3版本的样例，其余请自行开发或者咨询工作人员。
                        .build());
        TTAdSdk.getAdManager().requestPermissionIfNecessary(app_instance);
        mTTAdNative = ttadManager.createAdNative(context);
    }


    public static void loadRewardVideo(AdSlot adSlot) {
        mTTAdNative.loadRewardVideoAd(adSlot, new TTAdNative.RewardVideoAdListener() {
            @Override
            public void onError(int code, String message) {
                doCallback("window.AppUtils.onErrorAdJSBCallback({errMsg:\""+message+"\"})");
                //                Toast.makeText(m_instance, message, Toast.LENGTH_SHORT).show();
            }
            //视频广告加载后的视频文件资源缓存到本地的回调
            @Override
            public void onRewardVideoCached() {
                //                Toast.makeText(m_instance, "rewardVideoAd video cached", Toast.LENGTH_SHORT).show();
            }
            //视频广告素材加载到，如title,视频url等，不包括视频文件
            @Override
            public void onRewardVideoAdLoad(TTRewardVideoAd ad) {
                mttRewardVideoAd = ad;
                //mttRewardVideoAd.setShowDownLoadBar(false);
                mttRewardVideoAd.setRewardAdInteractionListener(new TTRewardVideoAd.RewardAdInteractionListener() {
                    @Override
                    public void onAdShow() {
                        doCallback("window.AppUtils.onShowAdJSBCallback()");
                    }

                    @Override
                    public void onAdVideoBarClick() {
//                        Toast.makeText(m_instance, "rewardVideoAd bar click", Toast.LENGTH_SHORT).show();
                    }

                    @Override
                    public void onAdClose() {
                        if(IsSeeAdComplete){
                            doCallback("window.AppUtils.onFinishAdJSBCallback({isEnded:true})");
                        }else{
                            doCallback("window.AppUtils.onFinishAdJSBCallback({isEnded:false})");
                        }
                    }

                    @Override
                    public void onVideoComplete() {
                        IsSeeAdComplete = true;
                    }

                    @Override
                    public void onVideoError() {
                        doCallback("window.AppUtils.onErrorAdJSBCallback({errMsg:\"视频播放出错\"})");
                    }

                    @Override
                    public void onRewardVerify(boolean rewardVerify, int rewardAmount, String rewardName, int i1, String s1) {
                        IsSeeAdComplete = true;
                    }

                    @Override
                    public void onSkippedVideo() {
                        doCallback("window.AppUtils.onFinishAdJSBCallback({isEnded:false})");
                    }
                });
                mttRewardVideoAd.setDownloadListener(new TTAppDownloadListener() {
                    @Override
                    public void onIdle() {

                    }

                    @Override
                    public void onDownloadActive(long totalBytes, long currBytes, String fileName, String appName) {

                    }

                    @Override
                    public void onDownloadPaused(long totalBytes, long currBytes, String fileName, String appName) {

                    }

                    @Override
                    public void onDownloadFailed(long totalBytes, long currBytes, String fileName, String appName) {

                    }

                    @Override
                    public void onDownloadFinished(long totalBytes, String fileName, String appName) {

                    }

                    @Override
                    public void onInstalled(String fileName, String appName) {

                    }
                });

//                TTRewardVideoActivity.this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
                playRewardVideo();
            }
        });
    }

    /**
     *
     * @param userId
     * @param extra
     * @param isVertical 是否为竖版
     */
    public static void showRewardVideo(String userId, String extra, boolean isVertical) {
        final AdSlot adSlot = new AdSlot.Builder()
                .setCodeId(isVertical ? "945718023" : "945717417")
                .setSupportDeepLink(true)
                .setAdCount(2)
                .setRewardName("金币") //奖励的名称
                .setRewardAmount(1)   //奖励的数量
                .setExpressViewAcceptedSize(500, 500)
//                .setImageAcceptedSize(500, 500)
                //必传参数，表来标识应用侧唯一用户；若非服务器回调模式或不需sdk透传
                //可设置为空字符串
                .setUserID(userId)
                .setMediaExtra(extra) //用户透传的信息，可不传
                .setOrientation(isVertical ? TTAdConstant.VERTICAL : TTAdConstant.HORIZONTAL)  //设置期望视频播放的方向，为TTAdConstant.HORIZONTAL或TTAdConstant.VERTICAL
                .build();

        loadRewardVideo(adSlot);
    }

    public static void playRewardVideo() {
        app_instance.runOnUiThread(new Runnable() {
            @Override
            public void run(){
                if (mttRewardVideoAd != null) {
                    TTAdSdk.getAdManager().requestPermissionIfNecessary(app_instance);
                    mttRewardVideoAd.showRewardVideoAd(app_instance, TTAdConstant.RitScenes.CUSTOMIZE_SCENES, "sence_test");
                    System.out.println("ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE 111");
                    mttRewardVideoAd = null;
                }
            }
        });
    }

    public static void playRewardVideoJs(String userId, String extra, boolean isVertical) {
        IsSeeAdComplete = false;
        final String _userId = userId;
        final String _extra = extra;
        final boolean _isVertical = isVertical;
        showRewardVideo(_userId,_extra, _isVertical);
    }

     public static void JavaCopy(final String str){
         app_instance.runOnUiThread(new Runnable(){
             @Override
             public void run() {
                 ClipboardManager cm = (ClipboardManager)app_instance.getSystemService(Context.CLIPBOARD_SERVICE);
                 ClipData clip = ClipData.newPlainText("kk",str);
                 cm.setPrimaryClip(clip);
             }
         });
     }


    public static void doCallback(final String callback){
        app_instance.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Cocos2dxGLSurfaceView.getInstance().queueEvent(new Runnable() {
                    @Override
                    public void run() {
                        System.out.println("chenggong  ==  "+ callback);
                        Cocos2dxJavascriptJavaBridge.evalString(callback);
                    }
                });
            }
        });
    }


}
