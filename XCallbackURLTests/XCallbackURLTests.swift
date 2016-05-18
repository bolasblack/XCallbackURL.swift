//
//  XCallbackURLTests.swift
//  XCallbackURLTests
//
//  Created by c4605 on 16/5/18.
//  Copyright © 2016年 c4605. All rights reserved.
//

import Quick
import Nimble
import PathToRegex
import XCTest
@testable import XCallbackURL

class XCallbackURLContextSpec: QuickSpec {
    override func spec() {
        let regex = try! pathToRegex("/tasks/:id")
        let normalURL = NSURL(string: "app://x-callback-url/tasks/0?x-success=launch%3A&x-error=drafts%3A&x-cancel=workflow%3A&x-source=Launch%20Center%20Pro")!
        let context = XCallbackURL.Context(id: "", url: normalURL, regex: regex)
        
        describe(".params") {
            it("support express style url") {
                let context1 = XCallbackURL.Context(id: "", url: NSURL(string: "app://x-callback-url/tasks/0")!, regex: regex)
                let context2 = XCallbackURL.Context(id: "", url: NSURL(string: "app://x-callback-url/tasks/1?id=321&hello=world")!, regex: regex)
                
                expect(context1.params["id"]!).to(equal("0"))
                expect(context2.params["id"]!).to(equal("1"))
                expect(context2.params["hello"]!).to(equal("world"))
            }
        }
        
        describe(".sourceName") {
            it("works") {
                expect(context.sourceName!).to(equal("Launch Center Pro"))
            }
        }
        
        describe(".successURLComponents") {
            it("works") {
                expect(context.successURLComponents!.string!).to(equal("launch:"))
            }
        }
        
        describe(".errorURLComponents") {
            it("works") {
                expect(context.errorURLComponents!.string!).to(equal("drafts:"))
            }
        }
        
        describe(".cancelURLComponents") {
            it("works") {
                expect(context.cancelURLComponents!.string!).to(equal("workflow:"))
            }
        }
    }
}

class XCallbackSpec: QuickSpec {
    override func spec() {
        let xCallbackURL = XCallbackURL.sharedInstance
        
        var projectTasksUrlCalledCount = 0
        var projectsUrlCalledCount = 0
        var tasksUrlCalledCount = 0
        var contexts: [XCallbackURL.Context] = []
        
        beforeEach {
            xCallbackURL.clearProcessers()
            xCallbackURL.clearHandlers()
            
            projectTasksUrlCalledCount = 0
            projectsUrlCalledCount = 0
            tasksUrlCalledCount = 0
            contexts = []
            
            xCallbackURL
                .handle("/projects/tasks") { context in
                    contexts.append(context)
                    projectTasksUrlCalledCount += 1
                }
                .handle("/projects/:id") { context in
                    contexts.append(context)
                    projectsUrlCalledCount += 1
                }
                .handle("/tasks") { context in
                    contexts.append(context)
                    tasksUrlCalledCount += 1
                }
        }
        
        describe("#handle") {
            it("works") {
                xCallbackURL
                    .perform(NSURL(string: "app://x-callback-url/projects/tasks")!)
                    .perform(NSURL(string: "app://x-callback-url/projects/1")!)
                    .perform(NSURL(string: "app://x-callback-url/tasks")!)
                expect(projectTasksUrlCalledCount) == 1
                expect(projectsUrlCalledCount) == 2
                expect(tasksUrlCalledCount) == 1
            }
        }
        
        describe("#processer") {
            it("be called before every handler") {
                var processerCalledCount = 0
                xCallbackURL
                    .processer { context in
                        processerCalledCount += 1
                        return context
                    }
                    .perform(NSURL(string: "app://x-callback-url/projects/tasks")!)
                    .perform(NSURL(string: "app://x-callback-url/projects/2")!)
                    .perform(NSURL(string: "app://x-callback-url/tasks")!)
                expect(processerCalledCount) == 4
            }
            
            it("can modify XCallbackURL.Context") {
                xCallbackURL
                    .processer { context in
                        var result = context
                        if context.id == "/projects/tasks" {
                            let urlComponents = NSURLComponents(string: context.url.absoluteString)!
                            let newQueryItem = NSURLQueryItem(name: "hello", value: "world")
                            if let _ = urlComponents.queryItems {
                                urlComponents.queryItems!.append(newQueryItem)
                            } else {
                                urlComponents.queryItems = [newQueryItem]
                            }
                            let newURL = urlComponents.URL
                            result = XCallbackURL.Context(id: context.id, url: newURL, regex: context.regex)
                        }
                        return result
                    }
                    .perform(NSURL(string: "app://x-callback-url/projects/tasks")!)
                    .perform(NSURL(string: "app://x-callback-url/projects/2")!)
                    .perform(NSURL(string: "app://x-callback-url/tasks")!)
                expect(contexts[0].params["hello"]!).to(equal("world"))
            }
        }
    }
}