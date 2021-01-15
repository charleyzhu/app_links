import Flutter
import UIKit

public class SwiftAppLinksPlugin: NSObject, FlutterPlugin {
  fileprivate var methodChannel: FlutterMethodChannel
  fileprivate var initialLink: String?
  fileprivate var latestLink: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "com.llfbandit.app_links/messages", binaryMessenger: registrar.messenger())

    let instance = SwiftAppLinksPlugin(methodChannel: methodChannel)

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    registrar.addApplicationDelegate(instance)
  }

  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "getInitialAppLink":
        result(initialLink)
        break
      case "getLatestAppLink":
        result(latestLink)
        break      
      default:
        result(FlutterMethodNotImplemented)
        break
    }
  }

  // Universal Links
  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void) -> Bool {

    switch userActivity.activityType {
      case NSUserActivityTypeBrowsingWeb:
        guard let url = userActivity.webpageURL else {
          return false
        }
        handleLink(url: url)
        return true
      default: return false
    }
  }
    /*
     engine code
     
     https://github.com/flutter/engine/blob/3073402ae484487e52b8f09d04f3e1d382e697ea/shell/platform/darwin/ios/framework/Source/FlutterPluginAppLifeCycleDelegate.mm#L106
     
 - (BOOL)application:(UIApplication*)application
     didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
   for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in [_delegates allObjects]) {
     if (!delegate) {
       continue;
     }
     if ([delegate respondsToSelector:_cmd]) {
       if (![delegate application:application didFinishLaunchingWithOptions:launchOptions]) {
         return NO; // <<------ this return
       }
     }
   }
   return YES;
 }
     
     */
  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
      if let urlObj = launchOptions[UIApplication.LaunchOptionsKey.url] {
        if let url = urlObj as? URL {
            handleLink(url: url)
        }
      }
    // return false ，Interrupt subsequent plug-in calls， Functions with the same name in UniLinksPlugin will not be called
      return false
  }

  
    /*
     engine code
     
     https://github.com/flutter/engine/blob/3073402ae484487e52b8f09d04f3e1d382e697ea/shell/platform/darwin/ios/framework/Source/FlutterPluginAppLifeCycleDelegate.mm#L313
     
 - (BOOL)application:(UIApplication*)application
             openURL:(NSURL*)url
             options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
   for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
     if (!delegate) {
       continue;
     }
     if ([delegate respondsToSelector:_cmd]) {
       if ([delegate application:application openURL:url options:options]) {
         return YES; // <<------ this return
       }
     }
   }
   return NO;
 }
     */
    
    // Custom URL schemes
  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    
    handleLink(url: url)
    
    // return true ，Interrupt subsequent plug-in calls，Functions with the same name in UniLinksPlugin will not be called
    return true
  }

  fileprivate func handleLink(url: URL) -> Void {
    debugPrint("iOS handleLink: \(url.absoluteString)")

    if (initialLink == nil) {
      initialLink = url.absoluteString
    }

    latestLink = url.absoluteString

    methodChannel.invokeMethod("onAppLink", arguments: latestLink)
  }
}
