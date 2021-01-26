//
//  SCPStoreKitManager.h
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 22/11/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

@import Foundation;
@import StoreKit;

#import "NSError+SCPStoreKitManager.h"

typedef void(^ProductsReturnedSuccessfully)(NSArray<SKProduct *> *products);
typedef void(^InvalidProducts)(NSArray<SKProduct *> *invalidProducts);
typedef void(^Failure)(NSError *error);

typedef void(^PaymentTransactionStatePurchasing)(NSArray<SKPaymentTransaction *> *transactions);
typedef void(^PaymentTransactionStateFailed)(NSArray<SKPaymentTransaction *> *transactions);
typedef void(^PaymentTransactionStatePurchased)(NSArray<SKPaymentTransaction *> *transactions);
typedef void(^PaymentTransactionStateRestored)(NSArray<SKPaymentTransaction *> *transactions);

@interface SCPStoreKitManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong, readonly) NSArray *products;

+ (id)sharedInstance;

- (void)requestProductsWithIdentifiers:(NSSet<NSString *> *)productsSet productsReturnedSuccessfully:(ProductsReturnedSuccessfully)productsReturnedSuccessfullyBlock invalidProducts:(InvalidProducts)invalidProductsBlock failure:(Failure)failureBlock;

- (void)requestPaymentForProduct:(SKProduct *)product paymentTransactionStatePurchasing:(PaymentTransactionStatePurchasing)paymentTransactionStatePurchasingBlock paymentTransactionStatePurchased:(PaymentTransactionStatePurchased)paymentTransactionStatePurchasedBlock paymentTransactionStateFailed:(PaymentTransactionStateFailed)paymentTransactionStateFailedBlock paymentTransactionStateRestored:(PaymentTransactionStateRestored)paymentTransactionStateRestoredBlock failure:(Failure)failureBlock;

- (void)restorePurchasesPaymentTransactionStateRestored:(PaymentTransactionStateRestored)paymentTransactionStateRestoredBlock paymentTransactionStateFailed:(PaymentTransactionStateFailed)paymentTransactionStateFailedBlock failure:(Failure)failureBlock;

- (NSString *)localizedPriceForProduct:(SKProduct *)product;

@end
