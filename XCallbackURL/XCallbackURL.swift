//
//  XCallbackURL.swift
//  XCallbackURL
//
//  Created by c4605 on 16/5/18.
//  Copyright © 2016年 c4605. All rights reserved.
//

import Foundation
import PathToRegex
import Regex

public class XCallbackURL {
    public typealias Callback = (context: Context) -> Void
    public typealias Processer = (context: Context) -> Context
    
    struct Handler {
        var id: String!
        var regex: Regex!
        var fn: Callback!
    }
    
    public struct Context {
        public var id: String!
        public var url: NSURL!
        public var regex: Regex!
        
        public var params: [String:String?] {
            let queryDictionary = url.queryDictionary
            guard let match = regex.findFirst(url.path!) else { return queryDictionary }
            return regex.groupNames.reduce(queryDictionary) { memo, groupName -> [String:String?] in
                guard let urlParamValue = match.group(groupName) else { return memo }
                var mutableMemo = memo
                mutableMemo[groupName] = urlParamValue
                return mutableMemo
            }
        }
        
        public var sourceName: String? {
            return self.params["x-source"]!
        }
        
        public var successURLComponents: NSURLComponents? {
            return self.getCallbackURL("success")
        }
        
        public var errorURLComponents: NSURLComponents? {
            return self.getCallbackURL("error")
        }
        
        public var cancelURLComponents: NSURLComponents? {
            return self.getCallbackURL("cancel")
        }

        func getCallbackURL(type: String) -> NSURLComponents? {
            guard let urlString = self.params["x-\(type)"]! else { return nil }
            return NSURLComponents(string: urlString)
        }
    }
    
    var handlers: [Handler] = []
    var processers: [Processer] = []

    public static let sharedInstance = XCallbackURL()
    
    public func clearHandlers() {
        self.handlers = []
    }
    
    public func clearProcessers() {
        self.processers = []
    }
    
    public func processer(processer: Processer) -> XCallbackURL {
        self.processers.append(processer)
        return self
    }
    
    public func handle(urlTemplate: String, handler: Callback) -> XCallbackURL {
        guard let regex = try? pathToRegex(urlTemplate) else { return self }
        self.handlers.append(Handler(id: urlTemplate, regex: regex, fn: handler))
        return self
    }
    
    public func perform(url: NSURL) -> XCallbackURL {
        guard let _ = url.path else { return self }
        self.handlers.forEach{ handler in
            guard url.path! =~ handler.regex else { return }
            let context = Context(id: handler.id, url: url, regex: handler.regex)
            let processedInfo = self.processers.reduce(context) { memo, processer -> Context in
                return processer(context: memo)
            }
            handler.fn(context: processedInfo)
        }
        return self
    }
}