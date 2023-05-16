//
//  DefaultOutputDeviceListener.swift
//  flutter_volume_controller
//
//  Created by yosemiteyss on 11/5/2023.
//

import Foundation
import FlutterMacOS

class DefaultOutputDeviceListener: NSObject, FlutterStreamHandler {
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        do {
            let args = arguments as! [String: Any]
            let emitOnStart = args[MethodArg.emitOnStart] as! Bool
            
            try SoundOutputManager.shared.addDefaultOutputDeviceListener({ device in
                let jsonStr = device.toJSONString()
                events(jsonStr)
            })
            
            if emitOnStart {
                let device = try SoundOutputManager.shared.retrieveDefaultOutputDevice()
                let jsonStr = device.toJSONString()
                events(jsonStr)
            }
        } catch {
            return FlutterError(
                code: ErrorCode.registerVolumeListener,
                message: ErrorMessage.registerVolumeListener,
                details: error.localizedDescription
            )
        }
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        try? SoundOutputManager.shared.removeDefaultOutputDeviceListener()
        return nil
    }
}
