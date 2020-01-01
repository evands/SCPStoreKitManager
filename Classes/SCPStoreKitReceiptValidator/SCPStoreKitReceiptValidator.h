//
//  SCPStoreKitReceiptValidator.h
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 10/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

@import Foundation;
@import StoreKit;

#import "SCPStoreKitReceipt.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^Success)(SCPStoreKitReceipt *receipt);
typedef void(^Failure)(NSError *error);

@interface SCPStoreKitReceiptValidator : NSObject <SKProductsRequestDelegate, UIAlertViewDelegate>

+ (nonnull instancetype)sharedInstance;

- (void)validateReceiptWithBundleIdentifier:(NSString *)bundleIdentifier bundleVersion:(NSString *)bundleVersion tryAgain:(BOOL)tryAgain showReceiptAlert:(BOOL)showReceiptAlert alertViewTitle:(nullable NSString *)alertViewTitle alertViewMessage:(nullable NSString *)alertViewMessage success:(Success)successBlock failure:(Failure)failureBlock;

- (void)validateReceiptWithBundleIdentifier:(NSString *)bundleIdentifier bundleVersion:(NSString *)bundleVersion acceptOtherVersions:(BOOL)looseVersionChecking tryAgain:(BOOL)tryAgain showReceiptAlert:(BOOL)showReceiptAlert alertViewTitle:(nullable NSString *)alertViewTitle alertViewMessage:(nullable NSString *)alertViewMessage success:(Success)successBlock failure:(Failure)failureBlock;

NS_ASSUME_NONNULL_END

@end
