# XCallbackURL.swift

## Installation

### Carthage

```ruby
github "bolasblack/XCallbackURL.swift"
```

### CocoaPods

```
# TODO
```

## Usage

```swift
XCallbackURL.sharedInstance
    .processer { context in
        print("I can return a new context")
        return context
    }
    .handle("/tasks/:id") { context in
        print("Searching task: \(context.params["id"]!)")
    }
    .handle("/tasks/new") { context in
        print("Creating task")
        print("Goto \(context.successURLComponents!.string) after create")
    }

XCallbackURL.sharedInstance.perform(NSURL(string: "app://x-callback-url/tasks/new?x-success=launch%3A")!)

// print:
//   I can return a new context
//   Searching task: Optional("new")
//   I can return a new context
//   Creating task
//   Goto Optional("launch:") after create
```
