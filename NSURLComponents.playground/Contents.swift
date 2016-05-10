//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

let components = NSURLComponents()
components.scheme = "https"
components.host = "udacity.com"
components.path = "/nanodegree"

print(components.URL)
