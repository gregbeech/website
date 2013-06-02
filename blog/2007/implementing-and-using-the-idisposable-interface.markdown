Date: 2007-03-07  
Tags: .NET, Design Guidelines, Garbage Collection  

# Implementing and using the IDisposable interface
    
You might be wondering why I'm writing about the `IDisposable` interface a full five years after the .NET framework was released, when you'd think that everybody knows everything about disposing objects anyway. But there are many people who are new to the framework and need some guidance, and many people who have been working with it for some time but still seem not to understand the significance of this interface or how to implement and use it correctly. In addition .NET 2.0 introduced the `SafeHandle` class which changed all the rules around finalizers so people who knew the rules for version 1.x may be a bit out of date.

## Why does `IDisposable` exist?

When you are using unmanaged resources such as handles and database connections, you should ensure that they are held for the minimum amount of time, using the principle of acquire late and release early. In C++ releasing the resources is typically done in the destructor, which is deterministically run at the point where the object is deleted. The .NET runtime, however, uses a garbage collector (GC) to clean up and reclaim the memory used by objects that are no longer reachable; as this runs on a periodic basis it means that the point at which your object is cleaned up is nondeterministic. The consequence of this is that destructors do not exist for managed objects as there is no deterministic place to run them.

Instead of destructors, .NET has finalizers which are implemented by overriding the `Finalize` method defined on the base `Object` class (though C# somewhat confusingly uses the C++ destructor syntax `~Object` for this). If an object overrides the `Finalize` method then rather than being collected by the GC when it is out of scope, the GC places it on a finalizer queue. In the next GC cycle all finalizers on the queue are run (on a single thread in the current implementation) and the memory from the finalized objects reclaimed. It's fairly obvious from this why you don't want to do clean up in a finalizer: it takes two GC cycles to collect the object instead of one and there is a single thread where all finalizers are run while every other thread is suspended, so it's going to hurt performance.

So if you don't have destructors, and you don't want to leave the cleanup to the finalizer, then the only option is to manually, deterministically, clean up the object. Enter the `IDisposable` interface which provides a standard for supporting this functionality and defines a single method, `Dispose`, where you put in the cleanup logic for the object. When used within a finally block, this interface provides equivalent functionality to destructors. The reason for finally blocks in code is primarily to support the `IDisposable` interface; this is why C++ uses simply `try`/`except` as there is no need for a finally block with destructors.

## Implementing the `IDisposable` interface

While objects can contain any other type of object in their fields, they can all be grouped into one of three categories with respect to the way they need to be cleaned up (for the moment I'm going to ignore `SafeHandle`, `CriticalFinalizerObject` _et al_ and discuss this in general terms):

- Unmanaged resources, e.g. handles - These are values that are obtained through P/Invoke calls to native APIs such as Win32, for example the `HANDLE` returned from `CreateFile` is an unmanaged resource. Unmanaged resources should be cleaned up when the containing object is disposed (in this case by calling `CloseHandle`), however they should also be cleaned up in the finalizer to ensure that if a user forgets to dispose of the object then the resource is not leaked.
- Managed resources that implement `IDisposable` - These are objects such as a `Stream` or `SqlConnection` which while not being unmanaged resources themselves, may contain unmanaged resources. These should be cleaned up when the containing object is disposed by calling their `Dispose` method, however they must not be cleaned up when the object is finalized because finalization is nondeterministic and the object may have already been finalized; the finalization process pays no attention to containment hierarchy.
- Managed resources that do not implement `IDisposable` - The simplest of all object types, managed resources that do not implement `IDisposable` do not need to be cleaned up and you can just leave them to the GC. If your class contains only this type of object then you do not need to implement `IDisposable` on it (note that there is one exception to this rule in .NET 1.x where they inexplicably didn't implement `IDisposable` on `XmlReader` or `XmlWriter`, however this is fixed in 2.0).

In the majority of classes you will not need to implement `IDisposable`, however in the ones that you do note that the cleanup of unmanaged resources is a shared requirement between the finalizer and the `Dispose` method. For this reason Microsoft recommend using a common method which takes a Boolean parameter indicating whether the class is being disposed or finalized, as shown below:

~~~ csharp
public class DisposableObject : `IDisposable`
{
    private bool disposed;

    ~DisposableObject()
    {
        this.Dispose(false);
    }

    public void Dispose()
    {
        if (!this.disposed)
        {
            this.Dispose(true);
            GC.SuppressFinalize(this);
            this.disposed = true;
        }
    }

    protected virtual void Dispose(bool disposing)
    {
        if (disposing)
        {
            // clean up managed resources
        }

        // clean up unmanaged resources
    }
}
~~~

The important implementation details are:

- The `Dispose(bool)` method is virtual so that it can be overridden by derived classes so they can clean up any resources before calling the base implementation.
- The `Dispose()` method is not virtual so it cannot be overridden, and performs checking to see whether the `Dispose` method has already been called as the method must support being called multiple times.
- When `Dispose` is called the object makes a call to `GC.SuppressFinalize` which tells the GC not to run the finalizer and thus prevents the two-stage collection, so garbage collection of your object is as quick as if you didn't have a finalizer at all.

Note that if your class does not use any unmanaged resources then you should still follow the same pattern with the two Dispose methods, however you should omit the finalizer. This ensures that if derived classes do use managed resources they have a place to clean them up, and if they don't then there is still a common design pattern they can work with.

## Aliasing the `IDisposable` interface

On some objects the method name `Dispose` may not make semantic sense. A good example of this is the `FileStream` class where a method called `Dispose` may look like it is disposing of (i.e. deleting) the file rather than just the stream object, and where a method called `Close` makes a lot more sense as that's what users are used to doing with files they are finished working with but want to keep. The good news is that using an explicit interface implementation you can still implement `IDisposable` but hide the `Dispose` method, and replace it with one called `Close`:

~~~ csharp
public class ClosableObject : IDisposable
{
    private bool closed;

    ~ClosableObject()
    {
        this.Dispose(false);
    }

    public void Close()
    {
        if (!this.closed)
        {
            this.Dispose(true);
            GC.SuppressFinalize(this);
            this.closed = true;
        }
    }

    void IDisposable.Dispose()
    {
        this.Close();
    }

    protected virtual void Dispose(bool disposing)
    {
        if (disposing)
        {
            // clean up managed resources
        }

        // clean up unmanaged resources
    }
}
~~~

Because the `Dispose` method is an explicit interface implementation, the object still supports the `Dispose` method but only if it is cast to type `IDisposable`. The explicit inteface call simply forwards the call through to the `Close` method. Note that the virtual method that does the cleanup is still called `Dispose(bool)` rather than `Close(bool)` as this is a common design pattern and anyone deriving from the class will expect the `Dispose(bool)` method to be present.

Although you can use this method to alias the `Dispose` method to have any name, only `Close` is used extensively within the .NET framework and so you should choose the most appropriate of the two options. Naming the method anything other than `Close` or `Dispose` will confuse consumers of the class. In addition while it is possible not to use an explicit interface implementation for the Dispose method, and thus have both `Close` and `Dispose` visible, this is confusing for consumers who will not know which one to call and should usually be avoided.

## Implementing methods on disposable classes

Given the built-in support for the `IDisposable` interface, it may seem odd that the CLR does not track which objects have been disposed, and does not mind in the slightest if you try to access an object that has been disposed of. In addition at the current time none of the main language compilers perform any semantic analysis to determine whether you access an object after it has been disposed of.

So where do these `ObjectDisposedExceptions` come from them? You have to throw them yourself! Each time somebody calls a method or property on your class then you need to check whether you can support the operation and throw an `ObjectDisposedException` if not, e.g.

~~~ csharp
public void SomeMethod()
{
    if (this.disposed)
    {
        throw new ObjectDisposedException(this.GetType().FullName);
    }
}
~~~

It isn't a requirement of implementing the `IDisposable` interface to throw `ObjectDisposedException` if any members are accessed after the method has been disposed, it only needs to be thrown for members which can no longer be supported after the resources have been disposed. For example calling `Write` on a `Stream` will always throw `ObjectDisposedException` after it has been disposed, however certain concrete implementations such as `MemoryStream` still allow you to do things like retrieving the underlying data even after the stream has been disposed, as the data is stored in a managed byte array and is not cleaned up by the `Dispose` method. If a member can still be used after `Dispose` has been called it should be documented, otherwise there is no need as the default assumption is that it cannot.

In order to allow derived classes to check whether the object has been disposed, and to provide a quicker way to check and throw the appropriate exception if it has, I tend to add the following members to my disposable base classes (and of course, `SomeMethod` above could be simplified to use `AssertNotDisposed`).

~~~ csharp
protected bool IsDisposed
{
    get
    {
        return this.disposed;
    }
}

protected virtual void AssertNotDisposed()
{
    if (this.disposed)
    {
        throw new ObjectDisposedException(this.GetType().FullName);
    }
}
~~~

## Deriving from disposable classes

Assuming that the base class has followed the above pattern then it is straightforward to derive from it and dispose of your own resources. The only design principle is that you should make sure that the base `Dispose` method is called under all circumstances using a `try`/`finally` construct, e.g.

~~~ csharp
public class DerivedObject : DisposableObject
{
    protected override void Dispose(bool disposing)
    {
        try
        {
            if (disposing)
            {
                // clean up managed resources
            }

            // clean up unmanaged resources
        }
        finally
        {
            base.Dispose(disposing);
        }
    }
}
~~~

Remember that you only need to do this if your derived class adds additional resources which need to be cleaned up, otherwise the base `Dispose` method will be sufficient. Note that if your derived class cleans up unmanaged resources here you should also add your own finalizer to class to call the `Dispose(bool)` method with a value of false; do not rely on the base class to provide this finalizer for you as many disposable objects do not have finalizers.

As with the base class, the derived class will need to check whether it has been disposed of on the entry to any members that need it to be in an un-disposed state. If you're lucky and the base class provides helpers such as `IsDisposed` and `AssertNotDisposed` then this is trivial, else you'll need to extend the `Dispose(bool)` method to also track a Boolean flag indicating that the class has been disposed for your own implementations.

## Implementing finalizers on disposable classes

Given that throughout this post I've told you how to implement the `IDisposable` interface so you can share common code between the finalizer and the `Dispose` method, it might seem unusual that this section is about to try to convince you not to write finalizers at all. The reason for this is .NET 2.0 introduced significant changes to the Common Language Runtime (CLR) to allow it to be hosted in SQL Server 2005 without affecting the reliabilty of the database, and these changes mean that not only it is unlikely you'll need to write a finalizer again, but you can make your code cleaner and more reliable without them!

There is already some great documentation written by Microsoft so rather than regurgitate it I'll just point you to the [MSDN Magazine article about the reliability features of .NET 2.0](http://msdn.microsoft.com/msdnmag/issues/05/10/reliability/default.aspx) and [Ravi Krishnaswamy's entry about writing SafeHandles](http://blogs.msdn.com/bclteam/archive/2005/03/15/396335.aspx) which should cover all your needs. The one thing I'll add is that the CLR does make a documented guarantee that (under normal circumstances) all non-critical finalizers will run before all critical ones, so if you have a class such a FileStream it can flush any unwritten content to its SafeFileHandle in the finalizer with the impunity that the SafeFileHandle will still be valid at that point.

Now the question is, given `SafeHandle`s and `CriticalHandle`s, in 99.99% of the cases where you implement `IDisposable` you won't need a finalizer so why bother using the `Dispose(bool)` pattern at all? I guess this comes down to three things. Firstly the non-virtual `Dispose()` method still encapsulates the logic about whether the class has already been disposed, so in the virtual `Dispose(bool)` method you don't need to worry about that and can just implement the cleanup logic. Secondly it provides a place for the 0.01% of cases where you do still need a finalizer on the object such as the `FileStream` case. And thirdly, it's a well known design pattern implemented on many of the framework classes such as `Stream`, so it makes your code more consistent and easier to use.

## Using disposable objects

So now we've covered the creation of disposable objects, it's time to turn to using them. As I've explained that finalization is bad for performance, it's clear that when using disposable objects you should make sure that the `Dispose` method is called under all circumstances, even if an `Exception` is thrown when using the object. One way to achieve this is with `try`/`finally` constructs:

~~~ csharp
SqlConnection connection = new SqlConnection("...");
try
{
    SqlCommand command = new SqlCommand("...", connection);
    try
    {
        // use the connection and command objects
    }
    finally
    {
        if (command != null)
        {
            command.Dispose();
        }
    }
}
finally
{
    if (connection != null)
    {
        connection.Dispose();
    }
}
~~~

This approach is technically perfect and will work under all circumstances, however it is quite verbose and can end up with some deep nesting when you start using multiple disposable objects together - for example we might also want a `TransactionScope` here which would result in another level of nesting. Fortunately the major .NET languages C# (all versions) and VB.NET (from version 2.0) have built-in support for the `IDisposable` interface. The following C# code is exactly equivalent to the above, and is expanded by the compiler into the same nested `try`/`finally` constructs:

~~~ csharp
using (SqlConnection connection = new SqlConnection("...")
using (SqlCommand command = new SqlCommand("...", connection))
{
    // use the connection and command objects
}
~~~

Neat huh? And with such concise syntax there's no excuse for the common lazy programming approach of not calling `Dispose` within a finally block. In fact, this approach is less typing than calling Dispose manually so the best approach is also in fact the laziest!

I'll finish off with a note concerning a particular micro-optimisation I have seen around the `Dispose` method, which is developers not calling it when working with a class they know doesn't use unmanaged resources such as a `MemoryStream` (it uses a byte array for internal storage so apparently doesn't need cleaning up). But did you know that if you have used one of the asynchronous methods `BeginRead` or `BeginWrite` on the `MemoryStream` then it may be caching a `WaitHandle`, which does wrap an unmanaged resource? Don't micro-optimise by not calling the `Dispose` method, even if you think it is unnecessary.