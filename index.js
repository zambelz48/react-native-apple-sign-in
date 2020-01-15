import React from 'react';
import { NativeModules, requireNativeComponent, Platform } from 'react-native';

const iOSVersionEligible = () => {
  const platformVersion = parseInt(Platform.Version, 10)
  const version = isNaN(platformVersion) ? 0 : platformVersion

  return version >= 13
}

const appleSignInModule = iOSVersionEligible() ? NativeModules.AppleSignIn : null

export const RNSignInWithAppleButton = appleSignInModule ? requireNativeComponent('RNCSignInWithAppleButton') : null;

export const SignInWithAppleButton = (buttonStyle, callBack) => {
  if (Platform.OS !== 'ios' || !appleSignInModule) {
    return null
  }

  return <RNSignInWithAppleButton 
    style={buttonStyle} 
    onPress={async () => {
      const scopes = [
        appleSignInModule.Scope.FULL_NAME,
        appleSignInModule.Scope.EMAIL
      ]

      await appleSignInModule.requestAsync({ requestedScopes: scopes }) 
        .then((response) => {
          callBack(response) //Display response
        }, (error) => {
          callBack(error) //Display error
        });
      }
    }
  />
}

export default appleSignInModule
