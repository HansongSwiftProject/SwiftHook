//
//  ParametersCheck.swift
//  SwiftHook
//
//  Created by Yanni Wang on 17/8/20.
//  Copyright © 2020 Yanni. All rights reserved.
//

import Foundation

private let KVOPrefix = "NSKVONotifying_"

private let retainSelector = NSSelectorFromString("retain")
private let releaseSelector = NSSelectorFromString("release")
private let autoreleaseSelector = NSSelectorFromString("autorelease")
private let blacklistSelectors = [retainSelector, releaseSelector, autoreleaseSelector]

// MARK: private

// TODO: when hook dealloc, Can't get the default objc parameter.
// TODO: test case: hook before dealloc, strong retain object!
func parametersCheck(object: AnyObject, selector: Selector, mode: HookMode, closure: AnyObject) throws {
    guard !(object is AnyClass) else {
        throw SwiftHookError.canNotHookClassWithObjectAPI
    }
    guard let baseClass = object_getClass(object) else {
        throw SwiftHookError.internalError(file: #file, line: #line)
    }
    try parametersCheck(targetClass: baseClass, selector: selector, mode: mode, closure: closure)
}

func parametersCheck(targetClass: AnyClass, selector: Selector, mode: HookMode, closure: AnyObject) throws {
    guard !blacklistSelectors.contains(selector) else {
        throw SwiftHookError.unsupport(value: .blacklist)
    }
    let isHookingDeallocSelector = selector == deallocSelector
    if isHookingDeallocSelector {
        guard targetClass is NSObject.Type else {
            throw SwiftHookError.unsupport(value: .pureSwiftObjectDealloc)
        }
    }
    guard !NSStringFromClass(targetClass).hasPrefix(KVOPrefix) else {
        throw SwiftHookError.unsupport(value: .KVOedObject)
    }
    
    guard let method = class_getInstanceMethod(targetClass, selector) else {
        throw SwiftHookError.noRespondSelector
    }
    
    guard let methodSignature = Signature(method: method),
        let closureSignature = Signature(closure: closure) else {
            throw SwiftHookError.missingSignature
    }
    
    guard closureSignature.signatureType == .closure else {
        throw SwiftHookError.internalError(file: #file, line: #line)
    }
    guard methodSignature.signatureType == .method else {
        throw SwiftHookError.internalError(file: #file, line: #line)
    }
    
    let closureReturnType = closureSignature.returnType
    var closureArgumentTypes = closureSignature.argumentTypes
    let methodReturnType = methodSignature.returnType
    var methodArgumentTypes = methodSignature.argumentTypes
    
    guard methodArgumentTypes.count >= 2, closureArgumentTypes.count >= 1 else {
        throw SwiftHookError.internalError(file: #file, line: #line)
    }
    closureArgumentTypes.removeFirst()
    if isHookingDeallocSelector {
        methodArgumentTypes.removeFirst(2)
    }
    
    switch mode {
    case .before, .after:
        guard closureReturnType == .voidTypeValue else {
            // TODO: 这里整合到一个新的方法，参数有 是否是isHookingDeallocSelector，Before after or instead 等等
            throw getIncompatibleClosureSignatureError(mode: mode, type: .returnType, closureSignature: closureSignature, methodSignature: methodSignature)
        }
        if !closureArgumentTypes.isEmpty {
            guard closureArgumentTypes == methodArgumentTypes else {
                throw getIncompatibleClosureSignatureError(mode: mode, type: .parametersType, closureSignature: closureSignature, methodSignature: methodSignature)
            }
        }
    case .instead:
        // Original closure (first parameter)
        guard closureArgumentTypes.count == methodArgumentTypes.count + 1 else {
            throw SwiftHookError.incompatibleClosureSignature(description: "For `instead` mode. The number of hook closure parameters should be equal to the number of method parameters + 1 (The first parameter is the `original` closure. The rest is the same as method's). The hook closure parameters number is \(closureArgumentTypes.count). The method parameters number is \(methodArgumentTypes.count).")
        }
        let originalClosureType = closureArgumentTypes[0]
        guard originalClosureType == .closureTypeValue else {
            throw SwiftHookError.incompatibleClosureSignature(description: "For `instead` mode. The type of the hook closure's first parameter should be a closure (It's `original` closure). But it's `\(originalClosureType.name)`")
        }
        guard let originalClosureSignature = originalClosureType.internalClosureSignature else {
            throw SwiftHookError.internalError(file: #file, line: #line)
        }
        closureArgumentTypes.removeFirst()
        
        let originalClosureReturnType = originalClosureSignature.returnType
        var originalClosureArgumentTypes = originalClosureSignature.argumentTypes
        
        guard originalClosureReturnType == methodReturnType else {
            throw getIncompatibleClosureSignatureError(mode: mode, type: .returnType, isInsteadOriginalClosure: true, closureSignature: closureSignature, methodSignature: methodSignature)
        }
        guard originalClosureArgumentTypes.count >= 1 else {
            throw SwiftHookError.internalError(file: #file, line: #line)
        }
        originalClosureArgumentTypes.removeFirst()
        guard originalClosureArgumentTypes == methodArgumentTypes else {
            throw getIncompatibleClosureSignatureError(mode: mode, type: .parametersType, isInsteadOriginalClosure: true, closureSignature: closureSignature, methodSignature: methodSignature)
        }
        
        // Hook closure
        guard closureReturnType == methodReturnType else {
            throw getIncompatibleClosureSignatureError(mode: mode, type: .returnType, closureSignature: closureSignature, methodSignature: methodSignature)
        }
        guard closureArgumentTypes == methodArgumentTypes else {
            throw getIncompatibleClosureSignatureError(mode: mode, type: .parametersType, closureSignature: closureSignature, methodSignature: methodSignature)
        }
    }
}

// MARK: Incompatible Closure Signature SwiftHookError

enum IncompatibleType {
    case parametersType
    case returnType
}

func getIncompatibleClosureSignatureError(mode: HookMode, type: IncompatibleType, isInsteadOriginalClosure: Bool = false, closureSignature: Signature, methodSignature: Signature) -> SwiftHookError {
    let description: String
    
    switch type {
    case .parametersType:
        let closureParametersTypeDescription = closureSignature.argumentTypes.map({$0.name}).joined(separator: "")
        let methodParametersTypeDescription = methodSignature.argumentTypes.map({$0.name}).joined(separator: "")
        switch mode {
        case .before, .after:
            description = "For `befor` and `after` mode. The parameters type of the hook closure must be the same as method's. The closure parameters type is `\(closureParametersTypeDescription)`. But the method parameters type is `\(methodParametersTypeDescription)`. They are not the same."
        case .instead:
            if isInsteadOriginalClosure {
                description = "For `instead` mode. The parameters type of the original closure (the hook closure's first parameter) must be the same as the method's. The original closure parameters type is `\(closureParametersTypeDescription)`. But the method parameters type is `\(methodParametersTypeDescription)`. They are not the same."
            } else {
                description = "For `instead` mode. The parameters type of the hook closure except firt one (The first parameter is the `original` closure) must be the same as the method's. But now the parameters type of the hook closure except firt one is `\(closureParametersTypeDescription)`. But the method parameters type is `\(methodParametersTypeDescription)`. They are not the same."
            }
        }
    case .returnType:
        switch mode {
        case .before, .after:
            description = "For `befor` and `after` mode. The return type of the hook closure mush be `void`. But it's `\(closureSignature.returnType.name)`"
        case .instead:
            if isInsteadOriginalClosure {
                description = "For `instead` mode. The return type of the original closure (the hook closure's first parameter) should be the same as method's return type. But the return type of the original closure is `\(closureSignature.returnType.name)`, The return type of the method is `\(methodSignature.returnType.name)`"
            } else {
                description = "For `instead` mode. The return type of the hook closure should be the same as method's return type. But the return type of the hook closure is `\(closureSignature.returnType.name)`, The return type of the method is `\(methodSignature.returnType.name)`"
            }
        }
    }
    return SwiftHookError.incompatibleClosureSignature(description: description)
}
