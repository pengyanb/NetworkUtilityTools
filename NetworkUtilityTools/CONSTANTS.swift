//
//  NutConstants.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 12/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

enum CONSTANTS_ENUM{
    case ENUM_SEGUE_IDENTIFIER(String)
    case ENUM_TABLE_CELL_IDENTIFIER(String)
    case ENUM_NOTIFICATION_IDENTIFIER(String)
    case ENUM_ENCODING_INFO(String, UInt)
    case ENUM_TIMEOUT_DELAY(Double)
    case ENUM_NSUSER_DEFAULT_KEY(String)
    case ENUM_SERVER_BEHAVIOR_KEY(String)
    
    func getAssociatedString()->String{
        switch self{
        case let .ENUM_SEGUE_IDENTIFIER(segueIdentifier) : return segueIdentifier
        case let .ENUM_TABLE_CELL_IDENTIFIER(cellIdentifier) : return cellIdentifier
        case let .ENUM_NOTIFICATION_IDENTIFIER(notiIdentifier) : return notiIdentifier
        case let .ENUM_ENCODING_INFO(encodingName, _) : return encodingName
        case let .ENUM_NSUSER_DEFAULT_KEY(key): return key
        case let .ENUM_SERVER_BEHAVIOR_KEY(key): return key
        default: return ""
        }
    }
    func getAssociatedUInt()->UInt{
        switch self{
            case let .ENUM_ENCODING_INFO(_, encodingValue) : return encodingValue
            default: return 0
        }
    }
    func getAssociatedDouble()->Double{
        switch self{
        case let ENUM_TIMEOUT_DELAY(timeout): return timeout
        default: return 0
        }
    }
}

struct CONSTANTS {
    //Segue identifier
    static let SEGUE_SELECT_PING_TOOL = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectPingTool")
    static let SEGUE_SELECT_TRACE_ROUTE = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectTraceRoute")
    
    static let SEGUE_SELECT_UDP_LISTENER = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectUdpListener")
    static let SEGUE_UDP_LISTENER_OPTIONS = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("showUdpListenerOptions")
    
    static let SEGUE_SELECT_UDP_BROADCASTER = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectUdpBroadcaster")
    
    static let SEGUE_SELECT_TCP_CLIENT = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectTcpClient")
    static let SEGUE_TCP_CLIENT_OPTIONS = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("showTcpClientOptions")
    
    static let SEGUE_SELECT_TCP_SERVER = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectTcpServer")
    static let SEGUE_TCP_SERVER_OPTIONS = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("showTcpServerOptions")
    
    static let SEGUE_SELECT_UPNP_CHECKER = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectUpnpChecker")
    
    static let SEGUE_SELECT_SERVICE_MONITOR = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectServiceMonitor")
    static let SEGUE_SERVICE_MONITOR_OPTIONS = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("showServiceMonitorOptions")
    
    static let SEGUE_SELECT_WHATS_MY_IP = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectWhatsMyIp")
    static let SEGUE_SELECT_PORT_SCANNER = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("selectPortScanner")
    static let SEGUE_SHOW_PORT_SCANNER_DETECTED_IP_DETAIL = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("showPortScannerDetectedIpDetail")
    static let SEGUE_SHOW_PORT_SCANNER_STREAM_PLAYER = CONSTANTS_ENUM.ENUM_SEGUE_IDENTIFIER("showPortScannerStreamPlayer")
    
    //cell identifier
    static let TABLE_CELL_UDP_LISTENER = CONSTANTS_ENUM.ENUM_TABLE_CELL_IDENTIFIER("udpListenerCapturedInfoCell")
    static let TABLE_CELL_TCP_SERVER = CONSTANTS_ENUM.ENUM_TABLE_CELL_IDENTIFIER("tcpServerClientsTableCell")
    
    //Notification identifier
    static let NOTI_PING_MODEL_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("PingToolModelChanged")
    static let NOTI_TRACE_ROUTE_MODEL_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("TraceRouteModelChanged")
    static let NOTI_UDP_MODEL_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("UdpListenerModelChanged")
    static let NOTI_UDP_BROADCASTER_INFO = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("UdpBroadcasterInfo")
    static let NOTI_TCP_CLIENT_INFO = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("TcpClientInfo")
    static let NOTI_TCP_SERVER_INFO = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("TcpServerInfo")
    static let NOTI_UPNP_CHECKER_MODEL_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("UpnpCheckerModelChanged")
    static let NOTI_SERVICE_MONITOR_MODEL_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("ServiceMonitorModelChanged")
    static let NOTI_SERVICE_MONITOR_RESULT_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("ServiceMonitorResultChanged")
    static let NOTI_PORT_SCANNER_MODEL_CHANGED = CONSTANTS_ENUM.ENUM_NOTIFICATION_IDENTIFIER("PortScannerModelChanged")
    
    //TIMEOUT CONSTANT
    static let TIMEOUT_UDP_BROADCAST = CONSTANTS_ENUM.ENUM_TIMEOUT_DELAY(3)
    
    //User Default keys
    static let NSUSER_DEFAULT_PING_TOOL_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_PING_TOOL_DEFAULT_KEY")
    static let NSUSER_DEFAULT_TRACE_ROUTE_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_TRACE_ROUTE_DEFAULT_KEY")
    static let NSUSER_DEFAULT_UDP_BROADCASTER_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_UDP_BROADCASTER_DEFAULT_KEY")
    static let NSUSER_DEFAULT_UDP_LISTENER_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_UDP_LISTENER_DEFAULT_KEY")
    static let NSUSER_DEFAULT_TCP_CLIENT_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_TCP_CLIENT_DEFAULT_KEY")
    static let NSUSER_DEFAULT_TCP_SERVER_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_TCP_SERVER_DEFAULT_KEY")
    static let NSUSER_DEFAULT_UPNP_CHECKER_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_UPNP_CHECKER_DEFAULT_KEY")
    static let NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_SERVICE_MONITOR_DEFAULT_KEY")
    static let NSUSER_DEFAULT_SERVICE_MONITOR_RESULT_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_SERVICE_MONITOR_RESULT_KEY")
    static let NSUSER_DEFAULT_PORT_SCANNER_SETTING_KEY = CONSTANTS_ENUM.ENUM_NSUSER_DEFAULT_KEY("NUT_PORT_SCANNER_SETTINGS_KEY")

    
    //Server Behavior
    static let SERVER_BEHAVIOR_ECHO = CONSTANTS_ENUM.ENUM_SERVER_BEHAVIOR_KEY("Auto Echo")
    static let SERVER_BEHAVIOR_MANUAL = CONSTANTS_ENUM.ENUM_SERVER_BEHAVIOR_KEY("Manual Reply")
    
    //Encoding identifier
    static let ENCODING_RAW_DATA = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Raw Data", 0)
    static let ENCODING_ISO_Latin1 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("ISO Latin1", NSISOLatin1StringEncoding)
    static let ENCODING_ISO_Latin2 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("ISO Latin2", NSISOLatin2StringEncoding)
    static let ENCODING_ASCII = CONSTANTS_ENUM.ENUM_ENCODING_INFO("ASCII", NSASCIIStringEncoding)
    static let ENCODING_Non_Lossy_ASCII = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Non Lossy ASCII", NSNonLossyASCIIStringEncoding)
    static let ENCODING_UTF8 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF8", NSUTF8StringEncoding)
    static let ENCODING_UTF16 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF16", NSUTF16StringEncoding)
    static let ENCODING_UTF16_Little_Endian = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF16 Little Endian", NSUTF16LittleEndianStringEncoding)
    static let ENCODING_UTF16_Big_Endian = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF16 Big Endian", NSUTF16BigEndianStringEncoding)
    static let ENCODING_UTF32 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF32 String", NSUTF32StringEncoding)
    static let ENCODING_UTF32_Little_Endian = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF32 Little Endian", NSUTF32LittleEndianStringEncoding)
    static let ENCODING_UTF32_Big_Endian = CONSTANTS_ENUM.ENUM_ENCODING_INFO("UTF32 Big Endian", NSUTF32BigEndianStringEncoding)
    static let ENCODING_Unicode = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Unicode", NSUnicodeStringEncoding)
    static let ENCODING_Windows_CP1250 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Windows CP1250", NSWindowsCP1250StringEncoding)
    static let ENCODING_Windows_CP1251 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Windows CP1251", NSWindowsCP1251StringEncoding)
    static let ENCODING_Windows_CP1252 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Windows CP1252", NSWindowsCP1252StringEncoding)
    static let ENCODING_Windows_CP1253 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Windows CP1253", NSWindowsCP1253StringEncoding)
    static let ENCODING_Windows_CP1254 = CONSTANTS_ENUM.ENUM_ENCODING_INFO("Windows CP1254", NSWindowsCP1254StringEncoding)
}