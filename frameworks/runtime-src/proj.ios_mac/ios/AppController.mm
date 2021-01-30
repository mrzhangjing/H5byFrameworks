/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2016 Chukong Technologies Inc.
 Copyright (c) 2017-2018 Xiamen Yaji Software Co., Ltd.
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import "AppController.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "SDKWrapper.h"
#import "platform/ios/CCEAGLView-ios.h"
#import "WXApi.h"
#import "CBToast.h"
#include "cocos/scripting/js-bindings/jswrapper/SeApi.h"

#import "RMIAPHelper.h"

#define WXAppId            @"wx8afc704e3471a973"    //App ID
#define UNIVERSALLINK           @"https://fishlandpage.threegame.cn/ddzUniversalLinks/9LDG8MU24Y.wpbydfh.zgame.huawei" //Universal Links



using namespace cocos2d;

@implementation AppController;

Application* app = nullptr;
@synthesize window;

/****** 定义一个全局的UIImageView ******/
UIImageView * myImageView = nullptr;
static AppController* _appController = nil;
/****** 定义一个全局的UIImageView ******/

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[SDKWrapper getInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    // Add the view controller's view to the window and display.
    float scale = [[UIScreen mainScreen] scale];
    CGRect bounds = [[UIScreen mainScreen] bounds];
    window = [[UIWindow alloc] initWithFrame: bounds];
    
    /****** 初始化UIImageView ******/
    _appController = self;
    myImageView = [[UIImageView alloc]initWithFrame:bounds];
    UIImage * image = [UIImage imageNamed:@"LaunchScreenBg.png"];
    [myImageView setImage:image];
    [myImageView setContentMode:UIViewContentModeScaleAspectFill];
    myImageView.layer.zPosition = MAXFLOAT;
    [window addSubview:myImageView];
    [window bringSubviewToFront:myImageView];
    
    [myImageView release];
    /****** 初始化UIImageView ******/
    
    // cocos2d application instance
    app = new AppDelegate(bounds.size.width * scale, bounds.size.height * scale);
    app->setMultitouch(true);
    
    //输出微信的log信息
    [WXApi startLogByLevel:WXLogLevelDetail logBlock:^(NSString * _Nonnull log) {
        NSLog(@"%@", log);
    }];

    if([WXApi registerApp:WXAppId universalLink:UNIVERSALLINK]){
        NSLog(@"初始化成功");

//        //自检函数
//        [WXApi checkUniversalLinkReady:^(WXULCheckStep step, WXCheckULStepResult* result) {
//            NSLog(@"%@, %u, %@, %@", @(step), result.success, result.errorInfo, result.suggestion);
//        }];
    } 
    
    // Use RootViewController to manage CCEAGLView
    _viewController = [[RootViewController alloc]init];
#ifdef NSFoundationVersionNumber_iOS_7_0
    _viewController.automaticallyAdjustsScrollViewInsets = NO;
    _viewController.extendedLayoutIncludesOpaqueBars = NO;
    _viewController.edgesForExtendedLayout = UIRectEdgeAll;
#else
    _viewController.wantsFullScreenLayout = YES;
#endif
    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: _viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:_viewController];
    }
    
    [window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(statusBarOrientationChanged:)
        name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    //run the cocos2d-x game scene
    app->start();
    
    /****** 延时两秒移除UIImageView ******/
   // 延时多久可以根据自己过渡到第一个场景显示出来的时间进行调节
   [NSTimer scheduledTimerWithTimeInterval:1.5
                                    target:self
                                  selector:@selector(onLoadFinished)
                                  userInfo:nil
                                   repeats:NO];
   /****** 延时两秒移除UIImageView ******/
    
    return YES;
}

/****** 移除UIImageView ******/
-(void) onLoadFinished {
    [_appController removeSplashView];
    _appController = nil;
}

- (void)removeSplashView {
    myImageView.layer.zPosition = 0;
    [myImageView removeFromSuperview];
    myImageView = nil;
}

/****** 移除UIImageView ******/

- (void)statusBarOrientationChanged:(NSNotification *)notification {
    CGRect bounds = [UIScreen mainScreen].bounds;
    float scale = [[UIScreen mainScreen] scale];
    float width = bounds.size.width * scale;
    float height = bounds.size.height * scale;
    Application::getInstance()->updateViewSize(width, height);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    app->onPause();
    [[SDKWrapper getInstance] applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    app->onResume();
    [[SDKWrapper getInstance] applicationDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    [[SDKWrapper getInstance] applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    [[SDKWrapper getInstance] applicationWillEnterForeground:application];    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[SDKWrapper getInstance] applicationWillTerminate:application];
    delete app;
    app = nil;
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


#pragma mark - 第三方分享、登录回调
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options{
    NSLog(@"openURL");
    return [WXApi handleOpenURL:url delegate:self];
}

#pragma mark Universal Link
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {

    NSURL *url = userActivity.webpageURL;
    NSLog(@"sssss%@", url.description);
    return [WXApi handleOpenUniversalLink:userActivity delegate:self];
}

-(void) onResp:(BaseResp*)resp{
    NSLog(@"onResp");
    if([resp isKindOfClass:[SendAuthResp class]])
    {
        SendAuthResp *aresp = (SendAuthResp *)resp;
        if (aresp.errCode== 0) {
            //_wxCode = aresp.code;
            NSLog(@"resp.Code = %@",aresp.code);
            NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
            [mdict setValue:aresp.code forKey:@"code"];
            NSError * error = nil;
            NSData * data = [NSJSONSerialization dataWithJSONObject:mdict options:NSJSONWritingPrettyPrinted error:&error];
            NSString * jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];

            NSLog(@"wxCode = %@",jsonString);
            [self callJsEngineCallBack:@"cc.jsWXLoginCallback" :jsonString:NO];  //此处的cc.jsEngineCallback是creator里面js定义的全局函数
        }
    }else if ([resp isKindOfClass:[SendMessageToWXResp class]]){
        SendMessageToWXResp* response = (SendMessageToWXResp*)resp;
        BOOL isSuc = YES;
        switch (response.errCode) {
            case WXSuccess:
                break;
            case WXErrCodeUserCancel:
                isSuc = NO;
                break;
            default:
                isSuc = NO;
                break;
        }
        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
        [mdict setValue:[NSNumber numberWithBool:isSuc] forKey:@"isSuc"];
        NSError * error = nil;
        NSData * data = [NSJSONSerialization dataWithJSONObject:mdict options:NSJSONWritingPrettyPrinted error:&error];
        NSString * jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"wxShare = %@", jsonString);
        [self callJsEngineCallBack:@"cc.jsShareCallback" :jsonString:NO];
        
    }else if([resp isKindOfClass:[WXLaunchMiniProgramResp class]]){
        WXLaunchMiniProgramResp *response = (WXLaunchMiniProgramResp *)resp;
        BOOL isSuc = YES;
        switch (response.errCode) {
            case WXSuccess:
                break;
            case WXErrCodeUserCancel:
                isSuc = NO;
                break;
            default:
                isSuc = NO;
                break;
        }
        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
        if (isSuc) {
            [mdict setValue:@"true" forKey:@"data"];
        }else{
            [mdict setValue:@"false" forKey:@"data"];
        }
        [mdict setValue:@"WXMiniProgram" forKey:@"key"];
        NSError * error = nil;
        NSData * data = [NSJSONSerialization dataWithJSONObject:mdict options:NSJSONWritingPrettyPrinted error:&error];
        NSString * jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"miniProgram = %@", jsonString);
        [self callJsEngineCallBack:@"cc.jsJumpMiniProgram" :jsonString:NO];
    }
}

//定义参数的返回
-(void)callJsEngineCallBack:(NSString*) funcNameStr :(NSString*) contentStr :(BOOL)isStr
{
    NSLog(@"callJsEngineCallBack...");
    
    std::string funcName = [funcNameStr UTF8String];
    std::string param = [contentStr UTF8String];
    std::string jsCallStr = cocos2d::StringUtils::format("%s(%s);",funcName.c_str(), param.c_str());
    if(isStr){
        jsCallStr = cocos2d::StringUtils::format("%s(\"%s\");",funcName.c_str(), param.c_str());
    }
    NSLog(@"jsCallStr = %s", jsCallStr.c_str());
    se::ScriptEngine::getInstance()->evalString(jsCallStr.c_str());
}


+(void)login
{
    //构造SendAuthReq结构体
    SendAuthReq* req =[[[SendAuthReq alloc]init]autorelease];
    req.scope = @"snsapi_userinfo";
    req.openID = WXAppId;
    req.state = @"login";
    //第三方向微信终端发送一个SendAuthReq消息结构

    [WXApi sendReq:req completion:^(BOOL success) {
            NSLog(@"唤起微信:%@", success ? @"成功" : @"失败");
    }];
    //NSLog(@"微信登录 weixin login");
}

+(NSString*)getAppID{
    return WXAppId;
}

+(int)isWXAppInstalled{
    BOOL isInstall = [WXApi isWXAppInstalled];
    return isInstall ? 0: 1;
}


+ (int)openWXApp
{
    if ([WXApi isWXAppInstalled]) {
        BOOL tmp = [WXApi openWXApp];
        return tmp ? 0 : -1;
    }else{
        [CBToast showToastAction:@"检查到您手机没有安装微信，请安装后使用该功能"];
    }
    return -1;
}

//分享链接到微信
+ (void)shareURLToWX:(NSString*) url title:(NSString*)title des:(NSString*)des isPYQ:(BOOL)isPYQ
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title  = title;
    message.description = des;
    WXWebpageObject *webpageObject = [WXWebpageObject object];
    webpageObject.webpageUrl = url;
    message.mediaObject = webpageObject;
    
    
    SendMessageToWXReq *sendMsg  = [[SendMessageToWXReq alloc] init];
    sendMsg.message =  message;
    sendMsg.bText = NO;
    if(isPYQ){
        sendMsg.scene  = WXSceneTimeline;
    }else{
        sendMsg.scene  = WXSceneSession;
    }
    
    [WXApi sendReq:sendMsg completion:^(BOOL success) {
            NSLog(@"唤起微信:%@", success ? @"成功" : @"失败");
    }];
}

//分享图片到微信
+ (void)shareImageToWX:(NSString *)imageUrl isPYQ:(BOOL)isPYQ
{
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    if(isPYQ){
        req.scene  = WXSceneTimeline;
    }else{
        req.scene  = WXSceneSession;
    }
    
    WXMediaMessage *message = [WXMediaMessage message];
    
    NSData *imageData = [NSData dataWithContentsOfFile:imageUrl];
    WXImageObject *ext = [WXImageObject object];
    //    UIImage * img = [UIImage imageNamed:path];
    ext.imageData = imageData;
    
    message.mediaObject = ext;
    
    req.message = message;
    
    [WXApi sendReq:req completion:^(BOOL success) {
            NSLog(@"唤起微信:%@", success ? @"成功" : @"失败");
    }];
}

+ (void)jumpMiniProgram:(NSString *)miniId path:(NSString*)path miniProgramType:(NSUInteger)miniProgramType{

    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = miniId;  //拉起的小程序的username
    if(![path isEqualToString:@""]){
        launchMiniProgramReq.path = path;   //拉起小程序页面的可带参路径，不填默认拉起小程序首页
    }
//    launchMiniProgramReq.miniProgramType = (WXMiniProgramType)miniProgramType; //拉起小程序的类型
    launchMiniProgramReq.miniProgramType = WXMiniProgramTypeRelease; //拉起小程序的类型
    [WXApi sendReq:launchMiniProgramReq completion:^(BOOL success) {
            NSLog(@"唤起微信:%@", success ? @"成功" : @"失败");
    }];
}


+ (void)payUseIOSRMI:(NSString *)appfeeid roleId:(NSString *)roleId cpOrderId:(NSString *)cpOrderId
{
    [[RMIAPHelper getInstance] pay:appfeeid roleId:roleId cpOrderId:cpOrderId];
//    [CBToast showToastAction:@"检查到您手机没有安装微信，请安装后使用该功能"];
}
//完成支付
+ (void)finishCheckOrderIOSRMI:(NSString *)roleIdAndOrderIdAndItemId
{
    [[RMIAPHelper getInstance] finishCheckOrder:roleIdAndOrderIdAndItemId];
}


//恢复订单
+ (void)recoveryOrder
{
    [[RMIAPHelper getInstance] recoveryOrder];
}

 + (void)JavaCopy:(NSString*) param{
     NSLog(@"收到的参数1是：%@", param); // "收到的参数是：我是js传过来的参数1"
     //获得ios的剪切板
     UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
     //改变剪切板的内容
     pasteboard.string = param;
     return;
 }

@end
