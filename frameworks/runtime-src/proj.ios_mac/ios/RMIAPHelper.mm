//
//  RMIAPHelper.m
//  BookCat
//
//  Created by rm-imac on 14-4-18.
//
//

typedef NS_ENUM(NSInteger, Payment) {
    IAP20000 = 20000,
    IAP20001 = 20001,
    IAP20002 = 20002,
    IAP20003 = 20003,
    IAP20004 = 20004,
    IAP20005 = 20005,
    IAP20006 = 20006,
};
//在内购项目中创的商品单号
#define kProductID_IAP20000 @"wpbydfh.zgame.huawei.20000"  //￥12
#define kProductID_IAP20001 @"wpbydfh.zgame.huawei.20001"  //￥30
#define kProductID_IAP20002 @"wpbydfh.zgame.huawei.20002"  //￥50
#define kProductID_IAP20003 @"wpbydfh.zgame.huawei.20003"  //￥108
#define kProductID_IAP20004 @"wpbydfh.zgame.huawei.20004"  //￥328
#define kProductID_IAP20005 @"wpbydfh.zgame.huawei.20005"  //￥648
#define kProductID_IAP20006 @"wpbydfh.zgame.huawei.20006"  //￥998

#include "cocos2d.h"
#import "RMIAPHelper.h"
#include "cocos/scripting/js-bindings/jswrapper/SeApi.h"
#import "CBToast.h"
//#import "scripting/lua-bindings/manual/CCLuaBridge.h"

@interface RMIAPHelper()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property(nonatomic,weak)   SKPaymentQueue* paymentQueue;

@end

@implementation RMIAPHelper

static RMIAPHelper*    _instance = NULL;

+(RMIAPHelper*)getInstance
{
    if(_instance == nil)
    {
        _instance = [[RMIAPHelper alloc]init];
        [_instance setup];
    }
    return _instance;
}


-(void)initPayMentQueue
{
    if(_paymentQueue == nil){
        _paymentQueue = [SKPaymentQueue defaultQueue];
        //监听SKPayment过程
        [_paymentQueue addTransactionObserver:self];
    }
}

/* 测试接口 */
-(void)viewDidLoads
{
    NSLog(@"viewDidLoads");
    NSArray * productArray = [[NSArray alloc] initWithObjects:@"wpbydfh.zgame.huawei.20000", nil];
    [self validateProductIdentifiers:productArray];
}

-(void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest * productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    [productsRequest start];
}


-(void)pay:(NSString *)appfeeid roleId:(NSString *)roleId cpOrderId:(NSString *)cpOrderId
{
//    NSLog(@"测试打印 pay 1");
    [self initPayMentQueue];
    if(SKPaymentQueue.canMakePayments){
        NSArray *transactions = _paymentQueue.transactions;
        if(transactions.count > 0) {
            //检测是否有未完成的交易
            SKPaymentTransaction* transaction = [transactions firstObject];
            if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
                [_paymentQueue finishTransaction:transaction];
                return;
            }
       }
        
        _instance->_roleId = roleId;
        _instance->_cpOrderId = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", cpOrderId]];
        _instance->_itemId = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", appfeeid]];
        [_instance buy:appfeeid];
    }else{
        NSLog(@"不允许程序内付费");
    }
}




+(void)release
{
    [_instance->_transactions removeAllObjects];
    [_instance->_transactions release];
    [_instance destroy];
    _instance = nil;
}

-(void)clearTransaction
{
    NSArray* transactions = _instance->_paymentQueue.transactions;
    if (transactions.count > 0) {
       //检测是否有未完成的交易
       SKPaymentTransaction* transaction = [transactions firstObject];
       if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
           [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
           return;
       }
    }
}

-(void)setup
{
    // NSLog(@"测试打印 setup 1");
    NSLog(@"RMIAPHelper 开启交易监听");
    _transactions = [[NSMutableArray alloc] initWithCapacity:10];
    [_transactions retain];
}

-(void)destroy
{
    //解除监听
    [_paymentQueue removeTransactionObserver:self];
    _paymentQueue = nil;
    NSLog(@"RMIAPHelper 注销交易监听");
    
}

-(BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

-(void)buy:(NSString*)productId
{
//     NSLog(@"测试打印 buy 1");
    if([self canMakePayments])
    {
        [self clearTransaction];
        [self requestProduct:productId];
    }else
    {
        NSLog(@"不支持内购");
        [self.delegate iapNotSupported:self];
    }
}

-(void)requestProduct:(NSString*)productId
{
    NSLog(@"测试打印 requestProduct 1 %@", productId);
    NSArray *product = nil;
    NSString *proId = [@"wpbydfh.zgame.huawei." stringByAppendingString:productId];
//    NSLog(@"productId : %@", proId);
    product = [[NSArray alloc] initWithObjects:proId, nil];
    NSSet *nsset = [NSSet setWithArray:product];
    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
    request.delegate=self;
    [request start];
    
    [self.delegate requestProduct:self start:request];
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
//     NSLog(@"测试打印 productsRequest 1");
    [self.delegate requestProduct:self received:request];

    NSLog(@"didReceiveResponse called:");
    NSLog(@"prodocuId:%@",response.products);
    NSLog(@"=======================================================");

    NSArray *productArray = response.products;
    if(productArray != nil && productArray.count>0)
    {
        SKProduct *product = [productArray objectAtIndex:0];
//        NSLog(@"SKProduct 描述信息%@", [product description]);
//        NSLog(@"产品标题 %@" , product.localizedTitle);
//        NSLog(@"产品描述信息: %@" , product.localizedDescription);
//        NSLog(@"价格: %@" , product.price);
//        NSLog(@"Product id: %@" , product.productIdentifier);
        
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
//        NSLog(@"productIdentifier :%@",payment.productIdentifier);
        
        NSString *productStr = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@;%@;%@",_instance->_roleId,_instance->_cpOrderId,_instance->_itemId]];
        payment.applicationUsername = productStr;
        [self saveDataWithProductIdentifier:product.productIdentifier orderId:productStr];
        
        [_paymentQueue addPayment:payment];
        [self.delegate paymentRequest:self start:payment];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
            [mdict setValue:@"payFinish" forKey:@"eventName"];
            [mdict setValue:@NO forKey:@"isPurchase"];
            [self callJsPayCallBack:mdict];
        });
    }
}

#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
//    NSLog(@"测试打印 paymentQueue 1");
    for(SKPaymentTransaction* transaction in transactions)
    {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing://正在将事务添加到服务器队列中。
//                NSLog(@"测试打印 paymentQueue 2");
                break;
            case SKPaymentTransactionStatePurchased://事务处于队列中，用户已被收费。客户应完成交易。
//                NSLog(@"测试打印 paymentQueue 3");
                [self.delegate paymentRequest:self purchased:transaction];
                //回到到lua 同步后台or服务器确认订单,在调用finishTransaction
                [_instance payFinish:transaction];
                break;
            case SKPaymentTransactionStateRestored://事务已从用户的购买历史记录中还原。客户应完成交易。
//                NSLog(@"测试打印 paymentQueue 4");
                //回到到lua 同步后台or服务器确认订单,在调用finishTransaction
                [self.delegate paymentRequest:self restored:transaction];
                [_instance payFinish:transaction];
                break;
            case SKPaymentTransactionStateFailed://事务在添加到服务器队列之前被取消或失败。
//                NSLog(@"测试打印 paymentQueue 5");
                [self.delegate paymentRequest:self failed:transaction];
                [self failedTransaction:transaction];
                break;
            default:
//                NSLog(@"测试打印 paymentQueue 6");
                [self.delegate paymentRequest:self failed:transaction];
                [self failedTransaction:transaction];
                break;
        }
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code == SKErrorPaymentCancelled) {
        [CBToast showToastAction:@"你已取消购买"];
    } else if (transaction.error.code == SKErrorPaymentInvalid) {
        [CBToast showToastAction:@"支付无效"];
    } else if (transaction.error.code == SKErrorPaymentNotAllowed) {
        [CBToast showToastAction:@"不允许支付"];
    } else if (transaction.error.code == SKErrorStoreProductNotAvailable) {
        [CBToast showToastAction:@"产品无效"];
    } else if (transaction.error.code == SKErrorClientInvalid) {
        [CBToast showToastAction:@"客服端无效"];
    }
    [self removeOrderIdWithProductIdentifier:transaction.payment.productIdentifier];
    //失败也结束
    [_paymentQueue finishTransaction:transaction];
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    [mdict setValue:@"payFinish" forKey:@"eventName"];
    [mdict setValue:@NO forKey:@"isPurchase"];
    [self callJsPayCallBack:mdict];
}

- (void)insertToContainer:(SKPaymentTransaction*)newTransaction{
    BOOL isInner = NO;
    for(SKPaymentTransaction* transaction in _instance->_transactions)
    {
        if([transaction isEqual:newTransaction]){
            isInner = true;
            break;
        }
    }
    if(!isInner){
        [_instance->_transactions addObject:newTransaction];
    }
}

//支付完成
- (void)payFinish:(SKPaymentTransaction*) transaction
{
    [_instance insertToContainer:transaction];
    NSData *data = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] appStoreReceiptURL] path]];
    NSString *receiptStr = [data base64EncodedStringWithOptions:0];
    NSString * roleIdAndOrder = transaction.payment.applicationUsername ?: [self getOrderIdWithProductIdentifier:transaction.payment.productIdentifier];
    
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    [mdict setValue:@"payFinish" forKey:@"eventName"];
    if([roleIdAndOrder isEqual:@""]){
        [mdict setValue:@NO forKey:@"isPurchase"];
        [mdict setValue:receiptStr forKey:@"receiptStr"];
        [mdict setValue:roleIdAndOrder forKey:@"roleIdAndOrder"];
        
        [self removeOrderIdWithProductIdentifier:transaction.payment.productIdentifier];
        [_paymentQueue finishTransaction:transaction];
    }else{
        NSString *productStr = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@;%@",roleIdAndOrder, transaction.transactionIdentifier]];
        [self saveDataWithProductIdentifier:transaction.payment.productIdentifier orderId:productStr];
        
        [mdict setValue:@YES forKey:@"isPurchase"];
        [mdict setValue:receiptStr forKey:@"receiptStr"];
        [mdict setValue:productStr forKey:@"roleIdAndOrder"];
    }
    [self callJsPayCallBack:mdict];
}

//完成之后需要通知苹果支付完成 lua调用
- (void)finishCheckOrder:(NSString *)roleIdAndOrderIdAndItemId
{
//    NSLog(@"测试打印 finishCheckOrder 1");
    NSArray *array = [roleIdAndOrderIdAndItemId componentsSeparatedByString:@";"];
    NSString *itemId = array[2];
    NSString *productIdentifier = [@"com.dafuhao.fish" stringByAppendingString:itemId];
    [self removeOrderIdWithProductIdentifier:productIdentifier];
    for(SKPaymentTransaction* transaction in _transactions)
    {
        [_paymentQueue finishTransaction:transaction];
        [_transactions removeObject:transaction];
//        if([transaction.payment.productIdentifier isEqualToString:productIdentifier]){
//            [_paymentQueue finishTransaction:transaction];
//            [_transactions removeObject:transaction];
//            NSLog(@"测试打印 finishCheckOrder 2");
//            return;
//        }
    }
}
//订单恢复接口
- (void)recoveryOrder
{
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    [mdict setValue:@"recoveryOrder" forKey:@"eventName"];
    [self callJsPayCallBack:mdict];
    //这个初始化,必须在回调赋值之后,否则 订单回复会找不到回调
    [self initPayMentQueue];
}


//交易完成之后，调用； 据我理解应该是[_paymentQueue finishTransaction:transaction]; 调用成功之后的回掉
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    NSLog(@"removedTransactions called: removedTransactions");
}

//恢复失败
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"restoreCompletedTransactionsFailedWithError called:");
    NSLog(@"error:%@",error);
    NSLog(@"=======================================================");
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished called:");
    NSLog(@"SKPaymentQueue:%@",queue);
    NSLog(@"=======================================================");
}
// Sent when the download state has changed.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    NSLog(@"updatedDownloads called:");
    NSLog(@"=======================================================");
}

#pragma 恢复流程
//发起恢复
-(void)restore
{
    [_paymentQueue restoreCompletedTransactions];
}

//定义参数的返回
-(void)callJsPayCallBack:(NSMutableDictionary*) mdict
{
    NSLog(@"callJsPayCallBack...");
    NSError * error = nil;
    NSData * data = [NSJSONSerialization dataWithJSONObject:mdict options:NSJSONWritingPrettyPrinted error:&error];
    NSString * jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    std::string param = [jsonString UTF8String];
    std::string jsCallStr = cocos2d::StringUtils::format("cc.callJsPayCallBack(%s);", param.c_str());
//    NSLog(@"callJsPayCallBack = %s", jsCallStr.c_str());
    se::ScriptEngine::getInstance()->evalString(jsCallStr.c_str());
}

//对应产品ID，保存订单号
- (void)saveDataWithProductIdentifier:(NSString *)identifier orderId:(NSString *)orderId
{
    if (!identifier || !orderId) {
        return;
    }
    NSString *currentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [currentPath stringByAppendingPathComponent:@"fishSKPay.plist"];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }
    [dic setValue:orderId forKey:identifier];
    BOOL flag = [dic writeToFile:filePath atomically:YES];
    if(!flag) {
        NSLog(@"orderId保存失败");
    }
}

//获取某一订单号
- (NSString *)getOrderIdWithProductIdentifier:(NSString *)productIdentifier {
    if (!productIdentifier) {
        return nil;
    }
    
    NSString *currentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [currentPath stringByAppendingPathComponent:@"fishSKPay.plist"];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    return [dic valueForKey:productIdentifier];
}


//成功后删除对应订单号
- (void)removeOrderIdWithProductIdentifier:(NSString *)productIdentifier {
    if (!productIdentifier) {
        return;
    }
    NSString *currentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [currentPath stringByAppendingPathComponent:@"fishSKPay.plist"];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    [dic removeObjectForKey:productIdentifier];
    BOOL flag = [dic writeToFile:filePath atomically:YES];
    if(!flag) {
        NSLog(@"orderId重新保存失败");
    }
}


@end
