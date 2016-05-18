//
//  NSURL+queryDictionary.swift
//  XCallbackURL
//
//  Created by c4605 on 16/5/18.
//  Copyright © 2016年 c4605. All rights reserved.
//

import Foundation

extension NSURL {
    internal var queryDictionary: [String:String?] {
        guard let _ = self.query, let urlComponents = NSURLComponents(string: self.absoluteString)
            else { return [:] }
        guard let queryItems = urlComponents.queryItems else { return [:] }
        return queryItems.reduce([String:String?]()) { memo, queryItem -> [String:String?] in
            var mutableMemo = memo
            mutableMemo[queryItem.name] = queryItem.value
            return mutableMemo
        }
    }
}