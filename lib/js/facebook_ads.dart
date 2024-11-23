import 'dart:js' as js;

void loadRewardedAd() {
  try {
    // Calling the JS function to show the rewarded ad
    js.context.callMethod('showRewardedAd');
  } catch (e) {
    print('Error loading rewarded ad: $e');
  }
}

void onRewardedAdCompleted(Function callback) {
  try {
    // Allow Dart to pass the callback function to JavaScript
    js.context.callMethod('onRewardedAdCompleted', [js.allowInterop(callback)]);
  } catch (e) {
    print('Error setting up ad completion listener: $e');
  }
}
