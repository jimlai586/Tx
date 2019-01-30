# Tx
A RxSwift  alternative

Triggered by the following quote from 
[RxSwift examples](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Examples.md).

>**It doesn't get any simpler than that.** There are [more examples](../RxExample) in the repository, so feel free to check them >out.

>They include examples on how to use Rx in the context of MVVM pattern or without it.

## Doesn't it?

Let's see if we can simplify it using one page home-made library and native SDK.

```swift

// bind UI control values directly
// use username from `usernameOutlet` as username values source
self.usernameOutlet.rx.text
    .map { username in

        // synchronous validation, nothing special here
        if username.isEmpty {
            // Convenience for constructing synchronous result.
            // In case there is mixed synchronous and asynchronous code inside the same
            // method, this will construct an async result that is resolved immediately.
            return Observable.just(Availability.invalid(message: "Username can't be empty."))
        }
```
This is to "observe" some text input event and process the string when the event fires.

But you only need to implement @objc func textDidChange(_ sender: UITextField) in UITextFieldDelegate and 

give it a callback to do the same thing.

99.9% of the time only 1 view controller (which holds that textfield) is required to be notified of the event in such use 

cases. 

Or in other words, you don't need to observe shit. 

You expect it to happen, and should arrange callback handler accordingly in compile time.

Why uses run-time approach for a compile-time problem?

Calback would look something like (String) -> ().

Now the following code is to show how you can transform it in a functional pipeline.

The thing is, again you don't need to observe shit, to do a functional pipeline.

You should be able to write your own if you are skilled enough to actually know how to write RxSwift.

How hard is it to do some functional stuff in a language with generic, type-inference, custom operator and first-class functions?

```swift
        // ...

        // User interfaces should probably show some state while async operations
        // are executing.
        let loadingValue = Availability.pending(message: "Checking availability ...")

        // This will fire a server call to check if the username already exists.
        // Its type is `Observable<Bool>`
        return API.usernameAvailable(username)
          .map { available in
              if available {
                  return Availability.available(message: "Username available")
              }
              else {
                  return Availability.unavailable(message: "Username already taken")
              }
          }
          // use `loadingValue` until server responds
          .startWith(loadingValue)
    }
// Since we now have `Observable<Observable<Availability>>`
// we need to somehow return to a simple `Observable<Availability>`.
// We could use the `concat` operator from the second example, but we really
// want to cancel pending asynchronous operations if a new username is provided.
// That's what `switchLatest` does.
    .switchLatest()
// Now we need to bind that to the user interface somehow.
// Good old `subscribe(onNext:)` can do that.
// That's the end of `Observable` chain.
    .subscribe(onNext: { validity in
        errorLabel.textColor = validationColor(validity)
        errorLabel.text = validity.message
    })
```
Again, you don't need to observe shit.

Updating view is part of the callback. 

A callback function that gets called every time to update some view !? Crazy, right?

Also two-way binding isn't really all that useful. In this case the event flow is UITextField -> UILabel.

You don't need to bind the other way, e.g.; UILabel -> UITextField, because UILabel is not editable.

Most of the time, it's model -> view, or user-input -> view. 

So in most of the time, property observer just works.

```swift
// This will produce a `Disposable` object that can unbind everything and cancel
// pending async operations.
// Instead of doing it manually, which is tedious,
// let's dispose everything automagically upon view controller dealloc.
    .disposed(by: disposeBag)
```

**...or instead of disposing everthing automagically upon view controller dealloc, which is tedious, hidden, prone-to-human-
error, having nothing to do with bussiness logic, let's dispose disposed(by: disposeBag).**

## YDNTS

As in "you don't need that shit".

So far in this example, we've learned exactly how RxSwift makes everything more difficult than it should be, by ignoring 

language feature such as property observer, pretending callback is not a thing, insisting that you need binding on everthing, 

requring shit-load of boilerplate, coupling functional operator with observer, and rewriting entire UIKit that you now rely 

on third-party to do native SDK's job for you.

And it has the audacity to tell you... 

***It doesn't get any simpler than that.***

It does. It gets a lot simpler than that.

## Let me give you an example of how I do it

```swift
        name.rxEndEditing ~< {$0.count > 5} >~ action { (isValid, vc) in
            vc.nameMsg.text = isValid ? "" : "name > 5"
            vc.toggle.0 = isValid
        }
```

Struct and operator definitions can be found in this repo. 

Use a custom textfield, implement UITextFieldDelegate, design callback, apply some operator for functional map, 

and make sure that all event ends up in an action (which takes the concept from Redux). 

An action is a sink for side effects.

You have clean event source, which is your customization, so you control everything.

You have functional pipeline that turns String to Bool, and can be infered by compiler.

You have grouped side effects together so they are easier to track and manage.

No KVO, no observable, no dispose.

***It doesn't get any simpler than that.***









