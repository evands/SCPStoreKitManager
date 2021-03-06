//
//  SCPStoreKitManager.m
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 22/11/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import "SCPStoreKitManager.h"

@interface SCPStoreKitManager()

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@property (nonatomic, copy) ProductsReturnedSuccessfully productsReturnedSuccessfullyBlock;
@property (nonatomic, copy) InvalidProductIdentifiers invalidProductIdentifiersBlock;
@property (nonatomic, copy) Failure failureBlock;

@property (nonatomic, copy) PaymentTransactionStatePurchasing paymentTransactionStatePurchasingBlock;
@property (nonatomic, copy) PaymentTransactionStatePurchased paymentTransactionStatePurchasedBlock;
@property (nonatomic, copy) PaymentTransactionStateFailed paymentTransactionStateFailedBlock;
@property (nonatomic, copy) PaymentTransactionStateRestored paymentTransactionStateRestoredBlock;

@property (nonatomic, strong, readwrite) NSArray *products;

@end

@implementation SCPStoreKitManager

+ (id)sharedInstance
{
    static SCPStoreKitManager *sharedInstance = nil;
	
    static dispatch_once_t onceToken;
	
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
	
    return sharedInstance;
}

- (id)init
{
	self = [super init];
	
	if(self)
	{
		self.numberFormatter = [[NSNumberFormatter alloc] init];
		
		[_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	}
	
	return self;
}

- (void)requestProductsWithIdentifiers:(NSSet<NSString *> *)productsSet productsReturnedSuccessfully:(ProductsReturnedSuccessfully)productsReturnedSuccessfullyBlock invalidProducts:(InvalidProductIdentifiers)invalidProductIdentifiersBlock failure:(Failure)failureBlock;
{
	self.productsReturnedSuccessfullyBlock = productsReturnedSuccessfullyBlock;
	self.invalidProductIdentifiersBlock = invalidProductIdentifiersBlock;
	self.failureBlock = failureBlock;
	
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsSet];
	
	[productsRequest setDelegate:self];
	
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	if(_productsReturnedSuccessfullyBlock)
	{
		self.products = response.products;
		
		_productsReturnedSuccessfullyBlock(response.products);
	}
	
	if([[response invalidProductIdentifiers] count] > 0 && _invalidProductIdentifiersBlock)
	{
		_invalidProductIdentifiersBlock([response invalidProductIdentifiers]);
	}
}

- (void)requestPaymentForProduct:(SKProduct *)product paymentTransactionStatePurchasing:(PaymentTransactionStatePurchasing)paymentTransactionStatePurchasingBlock paymentTransactionStatePurchased:(PaymentTransactionStatePurchased)paymentTransactionStatePurchasedBlock paymentTransactionStateFailed:(PaymentTransactionStateFailed)paymentTransactionStateFailedBlock paymentTransactionStateRestored:(PaymentTransactionStateRestored)paymentTransactionStateRestoredBlock failure:(Failure)failureBlock
{
	self.paymentTransactionStatePurchasingBlock = paymentTransactionStatePurchasingBlock;
	self.paymentTransactionStatePurchasedBlock = paymentTransactionStatePurchasedBlock;
	self.paymentTransactionStateFailedBlock = paymentTransactionStateFailedBlock;
	self.paymentTransactionStateRestoredBlock = paymentTransactionStateRestoredBlock;
    self.failureBlock = failureBlock;
	
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	
	if([SKPaymentQueue canMakePayments])
	{
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}
	else
	{
		if(failureBlock)
		{
			failureBlock([NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodePaymentQueueCanNotMakePayments errorDescription:@"SKPaymentQueue can not make payments" errorFailureReason:@"Has the SKPaymentQueue got any uncompleted purchases?" errorRecoverySuggestion:@"Finish all transactions"]);
		}
	}
}

- (void)restorePurchasesPaymentTransactionStateRestored:(PaymentTransactionStateRestored)paymentTransactionStateRestoredBlock paymentTransactionStateFailed:(PaymentTransactionStateFailed)paymentTransactionStateFailedBlock failure:(Failure)failureBlock
{	
	self.paymentTransactionStateFailedBlock = paymentTransactionStateFailedBlock;
	self.paymentTransactionStateRestoredBlock = paymentTransactionStateRestoredBlock;
    self.failureBlock = failureBlock;
	
	if([SKPaymentQueue canMakePayments])
	{
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	}
	else
	{
		if(failureBlock)
		{
			failureBlock([NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodePaymentQueueCanNotMakePayments errorDescription:@"SKPaymentQueue can not make payments" errorFailureReason:@"Has the SKPaymentQueue got any uncompleted purchases?" errorRecoverySuggestion:@"Finish all transactions"]);
		}
	}
}

#pragma mark - SKPaymentTransactionObserver methods

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self validateQueue:queue withTransactions:queue.transactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    [self validateQueue:queue withTransactions:transactions];
}

- (void) validateQueue:(SKPaymentQueue *)queue withTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    if([transactions count] > 0)
	{
		[transactions enumerateObjectsUsingBlock:^(SKPaymentTransaction *transaction, NSUInteger idx, BOOL *stop) {
			
			switch([transaction transactionState])
			{
				case SKPaymentTransactionStatePurchased:
				case SKPaymentTransactionStateFailed:
				case SKPaymentTransactionStateRestored:
				{
					[queue finishTransaction:transaction];
				   break;
				}
				default:
				{
					break;
				}
			}
			
		}];
	}
	
	if(_paymentTransactionStatePurchasingBlock)
	{
		NSArray *purchasingTransactions = [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"transactionState == %i", SKPaymentTransactionStatePurchasing]];
		
		if([purchasingTransactions count] > 0)
		{
			_paymentTransactionStatePurchasingBlock(purchasingTransactions);
		}
	}
	
	if(_paymentTransactionStatePurchasedBlock)
	{
		NSArray *purchasedTransactions = [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"transactionState == %i", SKPaymentTransactionStatePurchased]];
		
		if([purchasedTransactions count] > 0)
		{
			_paymentTransactionStatePurchasedBlock(purchasedTransactions);
		}
	}
	
	if(_paymentTransactionStateFailedBlock)
	{
		NSArray *failedTransactions = [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"transactionState == %i", SKPaymentTransactionStateFailed]];
		
		if([failedTransactions count] > 0)
		{
			_paymentTransactionStateFailedBlock(failedTransactions);
		}
	}
	
	if(_paymentTransactionStateRestoredBlock)
	{
		NSArray *restoredTransactions = [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"transactionState == %i", SKPaymentTransactionStateRestored]];
		
		if([restoredTransactions count] > 0)
		{
			_paymentTransactionStateRestoredBlock(restoredTransactions);
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if(_failureBlock)
    {
        _failureBlock(error);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	if(_failureBlock)
	{
		_failureBlock(error);
	}
}

- (NSString *)localizedPriceForProduct:(SKProduct *)product
{
	[_numberFormatter setLocale:product.priceLocale];
	NSString *formattedPrice = [_numberFormatter stringFromNumber:product.price];
	
	return formattedPrice;
}

@end
