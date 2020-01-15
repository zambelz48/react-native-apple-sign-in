#import "AppleSignIn.h"

#import <React/RCTUtils.h>
@implementation AppleSignIn

-(dispatch_queue_t)methodQueue
{
	return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

- (BOOL)isIOSVersionEligible {
	int iOSVersion = [[[UIDevice currentDevice] systemVersion] intValue];
	return iOSVersion >= 13;
}

-(NSDictionary *)constantsToExport
{
	if (![self isIOSVersionEligible]) {
		return @{};
	}

	NSDictionary* scopes = @{@"FULL_NAME": ASAuthorizationScopeFullName, @"EMAIL": ASAuthorizationScopeEmail};
	NSDictionary* operations = @{
		@"LOGIN": ASAuthorizationOperationLogin,
		@"REFRESH": ASAuthorizationOperationRefresh,
		@"LOGOUT": ASAuthorizationOperationLogout,
		@"IMPLICIT": ASAuthorizationOperationImplicit
	};
	NSDictionary* credentialStates = @{
		@"AUTHORIZED": @(ASAuthorizationAppleIDProviderCredentialAuthorized),
		@"REVOKED": @(ASAuthorizationAppleIDProviderCredentialRevoked),
		@"NOT_FOUND": @(ASAuthorizationAppleIDProviderCredentialNotFound),
	};
	NSDictionary* userDetectionStatuses = @{
		@"LIKELY_REAL": @(ASUserDetectionStatusLikelyReal),
		@"UNKNOWN": @(ASUserDetectionStatusUnknown),
		@"UNSUPPORTED": @(ASUserDetectionStatusUnsupported),
	};
	
	return @{
		@"Scope": scopes,
		@"Operation": operations,
		@"CredentialState": credentialStates,
		@"UserDetectionStatus": userDetectionStatuses
	};
}


+ (BOOL)requiresMainQueueSetup
{
	return YES;
}


RCT_EXPORT_METHOD(requestAsync:(NSDictionary *)options
				  resolver:(RCTPromiseResolveBlock)resolve
				  rejecter:(RCTPromiseRejectBlock)reject)
{
	if (![self isIOSVersionEligible]) {
		return;
	}

	_promiseResolve = resolve;
	_promiseReject = reject;
	
	ASAuthorizationAppleIDProvider* appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
	ASAuthorizationAppleIDRequest* request = [appleIDProvider createRequest];
	request.requestedScopes = options[@"requestedScopes"];
	if (options[@"requestedOperation"]) {
		request.requestedOperation = options[@"requestedOperation"];
	}
	
	ASAuthorizationController* ctrl = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
	ctrl.presentationContextProvider = self;
	ctrl.delegate = self;
	[ctrl performRequests];
}


- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
	if (![self isIOSVersionEligible]) {
		return nil;
	}

	return RCTKeyWindow();
}


- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization {
	if (![self isIOSVersionEligible]) {
		return;
	}

	ASAuthorizationAppleIDCredential *credential = authorization.credential;
	NSPersonNameComponents *userInfo = credential.fullName;
	NSString *authorizationCode = [[NSString alloc] initWithData:credential.authorizationCode encoding:NSUTF8StringEncoding];
	NSString *identityToken = [[NSString alloc] initWithData:credential.identityToken encoding:NSUTF8StringEncoding];

	NSDictionary* user = @{
		@"userInfo": @{
				@"user": RCTNullIfNil(credential.user),
				@"email": RCTNullIfNil(credential.email),
				@"namePrefix": RCTNullIfNil(userInfo.namePrefix),
				@"nameSuffix": RCTNullIfNil(userInfo.nameSuffix),
				@"givenName": RCTNullIfNil(userInfo.givenName),
				@"middleName": RCTNullIfNil(userInfo.middleName),
				@"nickname": RCTNullIfNil(userInfo.nickname),
				@"familyName": RCTNullIfNil(userInfo.familyName)
		},
		@"authorizedScopes": RCTNullIfNil(credential.authorizedScopes),
		@"realUserStatus": RCTNullIfNil(@(credential.realUserStatus)),
		@"state": RCTNullIfNil(credential.state),
		@"authorizationCode": RCTNullIfNil(authorizationCode),
		@"identityToken": RCTNullIfNil(identityToken)
	};
	
	_promiseResolve(user);
}


-(void)authorizationController:(ASAuthorizationController *)controller
		  didCompleteWithError:(NSError *)error {
	if (![self isIOSVersionEligible]) {
		return;
	}

	NSLog(@" Error code%@", error);
	_promiseReject(@"authorization", error.description, error);
}
//RCT_EXPORT_METHOD(sampleMethod:(NSString *)stringArgument numberParameter:(nonnull NSNumber *)numberArgument callback:(RCTResponseSenderBlock)callback)
//{
//    // TODO: Implement some actually useful functionality
//    callback(@[[NSString stringWithFormat: @"numberArgument: %@ stringArgument: %@", numberArgument, stringArgument]]);
//}


@end
