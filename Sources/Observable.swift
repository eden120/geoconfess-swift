/*
The MIT License (MIT)

Copyright (c) 2014-2016 Paulo Mattos, Antoine Berton

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//
//  Observable.swift
//  GeoConfess
//
//  Simple API for *observing* Model-ish objects.
//  Inspired by the *KVO* (key-value observing) framework, but:
//
//  * typesafer API
//  * less boilerplate code
//  * do not required `dynamic` properties
//  * do not required `NSObject` as superclass
//  * also works for static/singleton objects
//
//  For more informaiton about KVO technology:
// 
//  * http://goo.gl/oepR5Q
//  * http://goo.gl/vrdepy
//

import Foundation

/// Base protocol for observing changes in `Observable` objects.
/// Callbacks (and events) are model specific so no operations are defined here.
protocol Observer: class {
	/* empty */
}

/// Base protocol for *observable* objects (eg, models).
/// Designed for model-ish objects in the MVC pattern.
protocol Observable {
	
	associatedtype ObserverType = Observer
	
	// MARK: - Registering for Observation
	
	/// Registers the specified object.
	func addObserver(observer: ObserverType)
	
	/// Removes the specified object.
	func removeObserver(observer: ObserverType)
}

// MARK: - ObserverSet Class

/* ---

// TODO: Rationable for a non-generic `ObserverSet` class:

protocol SomeReferenceType: class { } // OK
func run(ref: SomeReferenceType) -> AnyObject { return ref } // OK

struct GenericType<T: AnyObject> { weak var x: T? } // OK
var generic: GenericType<SomeReferenceType>! // WON'T COMPILE

// Swift 2.2, X error: Using 'SomeReferenceType' as a concrete
// type conforming to protocol 'AnyObject' is not supported.

--- */

/// Reusable implementation of the `Observable` protocol.
class ObserverSet: Observable {

	/// Currently registered observers.
	///
	/// **Array vs Set**. We avoid `Set` so the insertion order is preserved
	/// and we don't add `Hashable` e `Equatable` as additional requirements.
	private var observers = [Weak<AnyObject>]()
	
	init() {
		/* empty */
	}

	func removeAllObservers() {
		precondition(NSThread.isMainThread(), "We may need a lock here")
		observers.removeAll(keepCapacity: true)
	}

	// MARK: - Observable Protocol
	
	func addObserver(observer: Observer) {
		precondition(NSThread.isMainThread(), "We may need a lock here")
		for weakRef in observers {
			if weakRef.object === observer {
				return
			}
		}
		observers.append(Weak(observer))
	}
	
	func removeObserver(observer: Observer) {
		precondition(NSThread.isMainThread(), "We may need a lock here")
		for (index, weakRef) in observers.enumerate() {
			if weakRef.object === observer {
				observers.removeAtIndex(index)
				break
			}
		}
	}
	
	// MARK: - Firing Notifications
	
	/// Fires the specified notification.
	func notifyObservers(notify: Observer -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			for weakRef in self.observers {
				if let observer = weakRef.object {
					notify(observer as! Observer)
				}
			}
		}
	}
}
