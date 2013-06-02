Date: 2007-07-03  
Tags: .NET, Events, Threading  

# Two common misconceptions regarding threading and events
    
Events in .NET are a fairly simple programming model - you subscribe to an event and when it is raised your handler is called. There are two common misconceptions about threading with .NET events though. The first is that people believe event handlers are run in a multi-threaded manner, when in fact they aren't. The second is that raising an event isn't affected by multi-threading issues, when in fact it might be.

Let's tackle the issue of event handlers first. If you're used to COM+ and its publish/subscribe model of events then you might imagine that .NET events work in the same way, and that the event is multicast to all the handlers at the same time. What actually happens is that each handler registered to receive the event is run in turn, in the order that they were registered for the event. If you want to prove this to yourself you can create a small test program similar to the following, which will output the same thread identifier for each handler, no matter how many handlers are registered.

~~~ csharp
class Program
{
    static event EventHandler MyEvent;

    static void Main(string[] args)
    {
        for (int i = 0; i &lt; 5; i++)
        {
            MyEvent += delegate(object sender, EventArgs e)
                {
                    Console.WriteLine(Thread.CurrentThread.ManagedThreadId);
                };
        }

        MyEvent(null, EventArgs.Empty);
    }
}
~~~

The reason for this behaviour is that events in .NET are really just syntactic sugar around the [`System.MulticastDelegate`](http://msdn2.microsoft.com/en-us/library/system.multicastdelegate.aspx) class which restricts the operations you are permitted to perform on it outside the declaring class to just adding or deleting a handler. You can see that this is the case by removing the `event` keyword from the above program so that `MyEvent` is now just a plain multicast delegate, and it will run in exactly the same way.

So what are the implications of this? Well one interesting one is that the `EventArgs` instance you pass through the events is seen by each handler in turn, so if one handler modifies it then the next one will see the modified class. As this is usually not what you want you should make your `EventArgs` classes immutable, except in specific cases such as in WinForms where the `Closing` event provides a mutable Cancel property on its `EventArgs` which allows handlers to indicate they want to cancel the form being closed.

Now let's have a look at raising events. The last line in the above sample raises the `MyEvent` event, and in this controlled environment it's fine as we know there are handlers registered for it. In the real world you don't always know this so it's a good idea to check whether the event is null before trying to raise it, as otherwise a `NullReferenceException` will occur. I find it a little odd that removing the last handler from a `MulticastDelegate` returns null rather than an empty invocation list, but that's the way it works, so there's no point in arguing. Including the null check in the code to raise the events gives us:

~~~ csharp
if (MyEvent != null)
{
    MyEvent(null, EventArgs.Empty);
}
~~~

The trouble with this code is that in a multi-threaded environment, between the time you check whether `MyEvent` is null and when you raise `MyEvent`, all the handlers could be removed, so this is actually a classic race condition. The solution is to cache the handler in its current state, check whether that is null, and then raise the cached handler. This is safe because adding or removing handlers actually creates a whole new delegate object, so even if the event is changed it won't affect the cached handler. The thread-safe code for raising an event is thus:

~~~ csharp
EventHandler handler = MyEvent;
if (handler != null)
{
    handler(null, EventArgs.Empty);
}
~~~

Hopefully that's the two most common misconceptions about events and threading in .NET cleared up. There is one more issue with the way events are implemented in C# with respect to threading, but I'm going to leave that for another day.