Date: 2006-01-03  
Status: Published  
Tags: C#, Exceptions

# Why doesn't C# have exception filters?
    
Recently I was working on a simple message receiver from MSMQ queues. The `MessageQueue.Peek()` method is pretty poorly designed as instead of returning a `Boolean` or `null` when there is no message on the queue, it throws a `MessageQueueException` with the `MessageQueueErrorCode` set to `IOTimeout`. Why is this bad? Firstly exceptions should only be thrown on unexpected circumstances and a queue being empty is an expected situation. Secondly it forces you to use exceptions for flow control by catching the exception and translating this specific error code into a non-error situation.

What I ended up doing was something like this, which trapped the error if it was a timeout but rethrew it if it was a 'real' exception:

~~~csharp
public static Message PeekMessage(MessageQueue queue, TimeSpan timeout)
{
    Message message = null;
    try
    {
        message = queue.Peek(timeout);
    }
    catch (MessageQueueException ex)
    {
        if (ex.MessageQueueErrorCode != MessageQueueErrorCode.IOTimeout)
        {
            throw;
        }
    }
    return message;
}

~~~
What I really wanted to do, however, was only catch the exception if it had the IOTimeout error code. This is partly because the real method was quite a bit more complex with logging etc. and as such it is possible to forget to actually rethrow the exception, and partly because due to the Windows SEH mechanism the stack trace information is corrupted by a rethrow. Interestingly, if I was writing this using Visual Basic .NET it would have been possible using the following code:

~~~vb
Public Shared Function PeekMessage(
    ByVal queue As MessageQueue, ByVal timeout As TimeSpan) As Message
    
    Dim myMessage As Message = Nothing
    Try        
        myMessage = queue.Peek(timeout)        
    Catch ex As MessageQueueException _
        When ex.MessageQueueErrorCode = MessageQueueErrorCode.IOTimeout
        'swallow the exception'
    End Try
    Return myMessage
End Function
~~~

You might think that this is some sort of hacky functionality built into the VB.NET compiler which really just generates the same sort of MSIL as the C# code would, but actually what it does is expose a part of the CLR's exception handling model which isn't accessible to C# developers. As well as the commonly used `try`/`catch`/`finally` blocks, there are two other blocks defined in MSIL for structured exception handling:

 - `filter` - This block is similar to a `catch` block, except that instead of just matching the exception type it allows arbitrary statements to be evaluated and a `Boolean` left on the stack indicating whether it matched the conditions and it should handle the exception.
 - `fault` - This block is similar to a `finally` block in that is observes error state but does not modify it, however the `fault` block is only run when an exception occurs so can allow clean-up which would only be valid under error conditions. This cannot be implemented in either C# or VB.NET.
 
When a VB.NET `Catch` block has conditions the VB.NET compiler translates it into an MSIL filter block instead of a `catch` block. In the circumstance here it will explicitly check the type of the exception and then check its `MessageQueueErrorCode` property. Interestingly a filter block is not required to check the exception type which is probably why it is implemented in VB.NET, so that applications mixing structured error handling with the pre-.NET error model can catch exceptions based on the error number.

I really like this ability to inspect an exception before you decide to catch it, particularly because if you can't actually handle the exception you don't corrupt the stack trace, and as I generally code in C# it would be great to see it added to the language. We already use the 'if' keyword to check Boolean conditions, so how about the following syntax extension which forces the exception to be typed if you want to access the object but also allows it to be inspected?

~~~csharp
public static Message PeekMessage(MessageQueue queue, TimeSpan timeout)
{
    Message message = null;
    try
    {
        message = queue.Peek(timeout);
    }
    catch (MessageQueueException ex) 
       if (ex.MessageQueueErrorCode == MessageQueueErrorCode.IOTimeout)
    {
        // swallow the exception
    }
    return message;
}
~~~

The same syntax of appending an `if` block would also allow filtering to be applied to generic `catch` blocks (i.e. those without a typed exception object) as shown below. Whether this is a good thing is questionable as these untyped blocks are generally reserved for non-compliant unmanaged exceptions (as in the .NET framework and some languages like Managed C++ it is possible to throw any type of object as an exception but languages such as C# can only catch and access those derived from `System.Exception`) but there's probably a legitimate use somewhere.

~~~csharp
try
{
    //do something
}
catch if (/* some condition */)
{
    //handle
}
~~~