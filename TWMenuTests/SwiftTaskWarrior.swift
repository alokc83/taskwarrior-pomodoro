//
//  SwiftTaskWarrior.swift
//  TWMenuTests
//
//  Created by Jarosław Wojtasik on 28/08/2018.
//  Copyright © 2018 Adam Coddington. All rights reserved.
//

import Foundation

public class SwiftTaskWarrior {
    // MARK - ### Fields ###
    let overrides: [String]
    let environment: [String: String]
    lazy var myCustomQueue = DispatchQueue(label: "task worker")
    
    public init (overrides: [String] = [], environment: [String: String] = [:] ) {
        self.overrides = overrides
        self.environment = environment
    }
    
    // MARK: - ### Public API ###
    public func add(description: String) -> Int? {
        return add([description])
    }
    
    public func add(_ raw: [String]) -> Int? {
        let out = run(cmd: "add", params: raw)
        let id = out.components(separatedBy: .whitespaces).last?.trimmingCharacters(in: CharacterSet(charactersIn: ".\n"))
        return Int(id ?? "")
    }
    
    public func next() {
        _ = run(cmd: "next")
    }
    
    public func config(key: String, val: String) {
        _ = run(cmd: "config", params: ["rc.confirmation=off", "\(key)", "\(val)"])
    }
    
    public func show(_ name: String?) {
        _ = run(cmd: "show", params: [name ?? ""] + ["rc.confirmation=off"])
    }
    
    public func log(_ raw: [String]) {
        _ = run(cmd: "log", params: raw)
    }
    
    public func annotate(filter: [String], text: String) {
        _ = run(filter: filter, cmd: "annotate", params: [text])
    }
    
    public func uuids(filter: [String]) -> [String] {
        let uuids = run(filter: filter, cmd: "uuids")
        let list = uuids.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").map { String($0) }
        return list
    }
    
    
    // MARK: - ### Private API ###
    func run(cmd: String, params: [String] = [], _ input: String? = nil) -> String {
        return run(filter: [], cmd: cmd, params: params, input)
    }
    
    func run(filter: [String], cmd: String, params: [String] = [], _ input: String? = nil) -> String {
        let arguments: [String] = filter + [cmd] + self.overrides + params
        var output: String = ""
        let queueStart = Date()
        myCustomQueue.sync {
            let task = Process()
            task.launchPath = "/opt/homebrew/bin/task"
            task.arguments = arguments
            print("-> task \(task.arguments?.joined(separator: " ") ?? "")")
            print("----------------")
            
            let oPipe = Pipe()
            
            task.standardOutput = oPipe
            if let a = input { task.standardInput = Pipe(withInput: a) }
            task.environment = self.environment
            task.launch()
            
            let before = Date()
            task.waitUntilExit()
            let took = before.timeIntervalSinceNow
            print("----------------")
            print(": \(-took * 1000) ms")
            let data = oPipe.fileHandleForReading.readDataToEndOfFile()
            output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
            print("^^^^^^^^^^^^")
            print(output)
            print("______")
        }
        print(": \(-queueStart.timeIntervalSinceNow * 1000) ms")
        return output
    }
}

extension Pipe {
    public convenience init(withInput input: String) {
        self.init()
        self.fileHandleForWriting.write(input.data(using: .utf8) ?? Data())
    }
}
