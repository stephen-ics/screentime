**Chapter 9: Memory Management (ARC) – Understanding How Swift Manages Memory**

Swift uses **Automatic Reference Counting (ARC)** to track and manage your app's memory usage. In most cases, this means memory management "just works" in Swift, and you don't need to think about it yourself. ARC automatically frees up the memory used by class instances when those instances are no longer needed.

However, it's important to understand how ARC works, especially to avoid *strong reference cycles*, which can lead to memory leaks. ARC only applies to instances of *classes*. Structures and enumerations are *value types*, not reference types, and are not managed by ARC directly (their contents might be, if they contain class instances).

**9.1 How ARC Works**
Every time you create a new instance of a class, ARC allocates a chunk of memory to store information about that instance. This memory holds the type of the instance, along with the values of any stored properties associated with that instance.

When an instance is no longer needed, ARC deallocates the memory used by that instance so the memory can be used for other purposes. This ensures that class instances do not take up space in memory when they are no longer needed.

To make sure that instances don't disappear while they are still in use, ARC tracks how many properties, constants, and variables are currently referring to each class instance. ARC will not deallocate an instance as long as at least one active reference to that instance still exists.
This is called a *strong reference*.

**9.2 ARC in Action**

```swift
class PersonARC {
    let name: String
    init(name: String) {
        self.name = name
        print("\(name) is being initialized")
    }
    deinit {
        print("\(name) is being deinitialized")
    }
}

var reference1: PersonARC?
var reference2: PersonARC?
var reference3: PersonARC?

reference1 = PersonARC(name: "John Appleseed")
// Output: John Appleseed is being initialized
// There is now one strong reference to this PersonARC instance.

reference2 = reference1
reference3 = reference1
// There are now three strong references to this PersonARC instance.

reference1 = nil
reference2 = nil
// There is still one strong reference (from reference3). The instance is not deallocated.

print("Setting reference3 to nil...")
reference3 = nil
// Output: Setting reference3 to nil...
// Output: John Appleseed is being deinitialized
// Now there are no more strong references, and ARC deallocates the instance.
```

**9.3 Strong Reference Cycles Between Class Instances**
It's possible to write code in which an instance of a class *never* gets to a point where it has zero strong references. This can happen if two class instances hold a strong reference to each other, such that each instance keeps the other alive. This is known as a *strong reference cycle*.

```swift
class Apartment {
    let unit: String
    init(unit: String) { self.unit = unit }
    var tenant: PersonARC? // Can be nil, but it's a strong reference if set
    deinit { print("Apartment \(unit) is being deinitialized") }
}

// Modify PersonARC to have an apartment
class PersonARCWithApartment {
    let name: String
    var apartment: Apartment? // Strong reference to Apartment
    init(name: String) {
        self.name = name
        print("\(name) is being initialized")
    }
    deinit {
        print("\(name) is being deinitialized")
    }
}

var john: PersonARCWithApartment?
var unit4A: Apartment?

john = PersonARCWithApartment(name: "John") // john has 1 strong ref
unit4A = Apartment(unit: "4A")        // unit4A has 1 strong ref

// Create the cycle:
john!.apartment = unit4A // Apartment instance now has 2 strong refs (unit4A and john.apartment)
unit4A!.tenant = john    // Person instance now has 2 strong refs (john and unit4A.tenant)

// Break our external references
john = nil
unit4A = nil

// AT THIS POINT:
// The PersonARCWithApartment instance (for John) still has a strong reference from unit4A.tenant.
// The Apartment instance (for 4A) still has a strong reference from john.apartment.
// Neither deinit will be called, and the memory for these objects is leaked.
```

**9.4 Resolving Strong Reference Cycles**
Swift provides two ways to resolve strong reference cycles when you work with properties of class type: *weak references* and *unowned references*.

*   **Weak References (`weak`):**
    A weak reference is a reference that does not keep a strong hold on the instance it refers to, and so does not stop ARC from deallocating the referenced instance. Because of this, ARC automatically sets a weak reference to `nil` when the instance it refers to is deallocated. Weak references must always be declared as optional types (`Type?` or `Type!`) to allow their value to be changed to `nil`.
    Use a weak reference when the other instance has a shorter lifetime—that is, when the other instance can be deallocated first. In our `Apartment`/`Person` example, an apartment can exist without a tenant, and a tenant can exist without an apartment. The relationship can be `nil` for either.

    ```swift
    class PersonWeak {
        let name: String
        var apartment: ApartmentWeak? // Still strong for this example's focus
        init(name: String) { self.name = name }
        deinit { print("PersonWeak \(name) is being deinitialized") }
    }

    class ApartmentWeak {
        let unit: String
        weak var tenant: PersonWeak? // WEAK reference to PersonWeak
        init(unit: String) { self.unit = unit }
        deinit { print("ApartmentWeak \(unit) is being deinitialized") }
    }

    var bob: PersonWeak? = PersonWeak(name: "Bob")
    var apt101: ApartmentWeak? = ApartmentWeak(unit: "101")

    bob!.apartment = apt101 // Bob has strong ref to apt101
    apt101!.tenant = bob    // apt101 has WEAK ref to Bob

    bob = nil // Bob is deinitialized.
              // The Apartment's tenant property becomes nil because it was weak.
              // Output: PersonWeak Bob is being deinitialized

    apt101 = nil // apt101 is now deinitialized
                 // Output: ApartmentWeak 101 is being deinitialized
    ```
    Now the cycle is broken because `ApartmentWeak.tenant` doesn't keep `PersonWeak` alive.

*   **Unowned References (`unowned`):**
    Like a weak reference, an unowned reference does not keep a strong hold on the instance it refers to. However, unlike a weak reference, an unowned reference is used when the other instance has the *same lifetime or a longer lifetime*. You indicate an unowned reference by placing the `unowned` keyword before a property or variable declaration.
    An unowned reference is expected to *always* have a value. ARC never sets an unowned reference's value to `nil`, which means unowned references are defined using non-optional types.
    **Important:** If you try to access the value of an unowned reference after the instance it refers to has been deallocated, you will trigger a runtime error (crash). Use unowned references only when you are sure that the reference will always refer to an instance that has not been deallocated.

    Consider a `Customer` and a `CreditCard`. A credit card will always be associated with a customer, and a credit card should not exist if its customer doesn't.

    ```swift
    class Customer {
        let name: String
        var card: CreditCard? // Customer might or might not have a card
        init(name: String) { self.name = name }
        deinit { print("Customer \(name) deinitialized") }
    }

    class CreditCard {
        let number: UInt64
        unowned let customer: Customer // UNOWNED reference to Customer (non-optional)
                                      // Assumes a card cannot exist without a customer.
        init(number: UInt64, customer: Customer) {
            self.number = number
            self.customer = customer
        }
        deinit { print("Card #\(number) deinitialized") }
    }

    var alice: Customer? = Customer(name: "Alice")
    alice!.card = CreditCard(number: 1234_5678_9012_3456, customer: alice!)

    alice = nil // Deallocates Alice, which then deallocates her CreditCard
                // because the card's unowned reference to alice doesn't keep alice alive.
    // Output:
    // Customer Alice deinitialized
    // Card #1234567890123456 deinitialized
    ```

*   **Unowned Optional References (`unowned(unsafe)`, `unowned(safe)` - `unowned` is `unowned(safe)` by default):**
    You can mark an optional reference to a class as `unowned`. In terms of ARC, an `unowned optional reference` and a `weak reference` can both be used in the same contexts. The difference is that when you use an `unowned optional reference`, you're responsible for making sure it always refers to a valid object or is set to `nil`. `unowned(safe)` (the default `unowned`) checks for `nil` on access and crashes if it's an invalid reference, while `unowned(unsafe)` doesn't check, potentially leading to memory corruption if the reference is dangling. Weak is generally safer for optional relationships where one side can become `nil`.

*   **Strong Reference Cycles for Closures:**
    Strong reference cycles can also occur if you assign a closure to a property of a class instance, and the body of that closure captures the instance (e.g., by referring to `self` or `self.someProperty`). This capture might be indirect if the closure captures a method that uses `self`.
    This happens because closures, like classes, are reference types.

    *   **Defining a Capture List:** To resolve closure-based strong reference cycles, define a *capture list* as part of the closure's definition. A capture list defines the rules to use when capturing one or more reference types within the closure's body.

        ```swift
        class HTMLElement {
            let name: String
            let text: String?
            lazy var asHTML: () -> String = { [unowned self] in // Capture self as unowned
                // Or use [weak self] and then guard let strongSelf = self else { return "" }
                if let text = self.text {
                    return "<\(self.name)>\(text)</\(self.name)>"
                } else {
                    return "<\(self.name) />"
                }
            }
            init(name: String, text: String? = nil) {
                self.name = name
                self.text = text
            }
            deinit { print("\(name) is being deinitialized") }
        }

        var paragraph: HTMLElement? = HTMLElement(name: "p", text: "hello, world")
        print(paragraph!.asHTML())

        paragraph = nil // HTMLElement instance is now deinitialized because 'self' in asHTML was unowned (or weak)
                       // Output: p is being deinitialized
        ```
        If `[unowned self]` or `[weak self]` was not used, `self` inside the closure would be a strong reference to the `HTMLElement` instance, and the `asHTML` property (which holds the closure) would also have a strong reference back to the `HTMLElement` instance, creating a cycle.
        *   `[weak self]`: Use when `self` might become `nil` within the closure's lifetime. Inside the closure, `self` will be an optional.
        *   `[unowned self]`: Use when the closure and the instance it captures will always be deallocated at the same time, and `self` will not be `nil` when the closure is called.

--- 