//
//  AppDelegate.swift
//  SensorsDataSwiftDemo
//
//  Created by 王灼洲 on 2017/11/9.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //MARK:初始化sdk
        let options = SAConfigOptions(serverURL: "http://zhaohaiying.cloud.sensorsdata.cn:8006/sa?project=default&token=9d8f18c23084485f", launchOptions: launchOptions)
        options.maxCacheSize = 10000;
        options.autoTrackEventType = [.eventTypeAppClick,.eventTypeAppStart,.eventTypeAppEnd,.eventTypeAppViewScreen]
        SensorsAnalyticsSDK.sharedInstance(withConfig: options)
        
        SensorsAnalyticsSDK.sharedInstance()?.setFlushNetworkPolicy(SensorsAnalyticsNetworkType.typeALL)
        SensorsAnalyticsSDK.sharedInstance()?.enableHeatMap()
        SensorsAnalyticsSDK.sharedInstance()?.addWebViewUserAgentSensorsDataFlag()
      
        
        let dict :Dictionary  = ["key":"value","key1":"value1"]
        SensorsAnalyticsSDK.sharedInstance()?.track("testEvent" ,withProperties: dict )
        SensorsAnalyticsSDK.sharedInstance()?.enableTrackScreenOrientation(true)
        
        
        self.window = UIWindow()
        let rootVC:UIViewController = ViewController()
        self.window?.rootViewController = UINavigationController(rootViewController :rootVC);
        self.window?.makeKeyAndVisible()
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

