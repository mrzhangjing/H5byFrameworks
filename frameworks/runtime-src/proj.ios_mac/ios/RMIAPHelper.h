//
//  RMIAPHelper.h
//  BookCat
//
//  Created by rm-imac on 14-4-18.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <StoreKit/SKPaymentTransaction.h>


@class RMIAPHelper;
@protocol RMIAPHelperDelegate <NSObject>

//购买
-(void)requestProduct:(RMIAPHelper*)sender start:(SKProductsRequest*)request;
-(void)requestProduct:(RMIAPHelper*)sender received:(SKProductsRequest*)request;

-(void)paymentRequest:(RMIAPHelper*)sender start:(SKPayment*)payment;
-(void)paymentRequest:(RMIAPHelper*)sender purchased:(SKPaymentTransaction*)transaction;
-(void)paymentRequest:(RMIAPHelper*)sender restored:(SKPaymentTransaction*)transaction;
-(void)paymentRequest:(RMIAPHelper*)sender failed:(SKPaymentTransaction*)transaction;

//恢复
-(BOOL)restoredArray:(RMIAPHelper*)sender withArray:(NSArray*)productsIdArray;

//其他
//不支持内购
-(void)iapNotSupported:(RMIAPHelper*)sender;
@end

@interface RMIAPHelper : NSObject{
    NSString* _roleId;
    
    NSString* _cpOrderId;
    
    NSString* _itemId;
    
//    int _recoveOrderHandler;//恢复订单回调
    
    NSMutableArray<SKPaymentTransaction*> * _transactions;//保存相关订单,带后台或者服务器确认之后,再销毁
}

+(RMIAPHelper*)getInstance;

-(void)pay:(NSString *)appfeeid roleId:(NSString *)roleId cpOrderId:(NSString *)cpOrderId;
-(void)finishCheckOrder:(NSString *)roleIdAndOrderIdAndItemId;
-(void)recoveryOrder;



@property(nonatomic,assign) id<RMIAPHelperDelegate> delegate;
@property int handlerID;

//@property (nonatomic,copy)NSString *_cpOrderId;

-(void)setup;
-(void)destroy;
-(void)buy:(NSString*)productId;

-(void)restore;

@end
