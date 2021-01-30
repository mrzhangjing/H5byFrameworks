package wpbydfh.zgame.huawei.wxapi;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.tencent.mm.opensdk.constants.ConstantsAPI;
import com.tencent.mm.opensdk.modelbase.BaseReq;
import com.tencent.mm.opensdk.modelbase.BaseResp;
import com.tencent.mm.opensdk.modelmsg.SendAuth;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;

import org.cocos2dx.javascript.GlobalConst;
import org.cocos2dx.javascript.SDKHelper;


public class WXEntryActivity extends Activity implements IWXAPIEventHandler {

    //微信appId
    private IWXAPI api;
    //微信发送的请求将回调该方法
    private void regToWx(){
        api = WXAPIFactory.createWXAPI(this, SDKHelper.WX_APP_ID,true);
        api.registerApp(SDKHelper.WX_APP_ID);
        System.out.println("###############");
        System.out.println("In wxEntryActivity api is " + api);
    }
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        System.out.println("enter the wxEntryActivity");
        regToWx();
        //这句话很关键
        try {
            api.handleIntent(getIntent(), this);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        System.out.println("intent is " + intent);
        setIntent(intent);
        api.handleIntent(intent, this);
    }
    @Override
    public void onReq(BaseReq baseReq) {

    }

    //向微信发送的请求的响应信息回调该方法
    @Override
    public void onResp(BaseResp resp) {
        int errorCode = resp.errCode;
        System.out.println("errorCode ==" + errorCode + " resp.getType() =  " + resp.getType());
        // 判断类型
        switch(resp.getType()){
            case ConstantsAPI.COMMAND_SENDAUTH:
                switch (errorCode) {
                    case BaseResp.ErrCode.ERR_OK:
                        //用户同意
                        String code = ((SendAuth.Resp) resp).code;
                        System.out.println("code ==" + code);

                        SDKHelper.fetchWxAuthCodeAndCallBack(code);
//	            ((AppActivity)AppActivity.getContext()).handleWXResult(BaseResp.ErrCode.ERR_OK, code);
                        break;
                    case BaseResp.ErrCode.ERR_AUTH_DENIED:
                        //用户拒绝
                        break;
                    case BaseResp.ErrCode.ERR_USER_CANCEL:
                        //用户取消
                        break;
                    default:
                        break;
                }
                break;
            case ConstantsAPI.COMMAND_SENDMESSAGE_TO_WX:
                if (errorCode==BaseResp.ErrCode.ERR_OK){
                    SDKHelper.fetchWxShareResult(true);
                }else{
                    SDKHelper.fetchWxShareResult(false);
                }
                break;
            case ConstantsAPI.COMMAND_LAUNCH_WX_MINIPROGRAM:
                System.out.println(" COMMAND_SUBSCRIBE_MINI_PROGRAM_MSG errorCode ==" + errorCode + " resp.getType() =  " + resp.getType());
                if (errorCode==BaseResp.ErrCode.ERR_OK){
                    SDKHelper.jumpMiniResult(GlobalConst.WXMiniProgram,"true");

                }else{
                    SDKHelper.jumpMiniResult(GlobalConst.WXMiniProgram,"false");
                }
                break;
            default:
                break;
        }

        this.finish();
    }
}
