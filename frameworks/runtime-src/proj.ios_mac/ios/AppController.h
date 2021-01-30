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
#import <UIKit/UIKit.h>
#import "WXApi.h"

@class RootViewController;

@interface AppController : NSObject <UIApplicationDelegate,WXApiDelegate>
{
}

//微信相关
+ (NSString*)getAppID;
+ (int)isWXAppInstalled;
+ (int)openWXApp;
+ (void)shareURLToWX:(NSString *)url title:(NSString*)title des:(NSString*)des isPYQ:(BOOL)isPYQ;       //分享url到微信
+ (void)shareImageToWX:(NSString *)imageUrl isPYQ:(BOOL)isPYQ;     //分享图片到微信
+ (void)jumpMiniProgram:(NSString *)miniId path:(NSString*)path;    //跳转小程序

@property(nonatomic, readonly) RootViewController* viewController;

+ (void)payUseIOSRMI:(NSString *)appfeeid roleId:(NSString *)roleId cpOrderId:(NSString *)cpOrderId;
+ (void)finishCheckOrderIOSRMI:(NSString *)roleIdAndOrderIdAndItemId;
+ (void)recoveryOrder;

@end

