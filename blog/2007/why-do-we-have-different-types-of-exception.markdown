Date: 2007-05-27  
Status: Published  
Tags: .NET, Design Guidelines, Exceptions

# Why do we have different types of exception?
    
The short answer is to allow them to be handled differently in a programmatic manner. You've probably done it hundreds if not thousands of times - creating a `try`/`catch` block and catching an exception based on its type to handle it in a particular way. So the headline question in itself isn't particularly interesting; however the answer's simple premise leads us to a couple of the fundamentals of structured error handling.

## When to throw different types of exception

To understand when to throw different types of exception, you need to think about how callers might handle the different possible problems in accessing a member. Consider the `Read` method of the `NetworkStream` class; when called there are a number of problems that could occur:

- The buffer passed in to receive data is null (`ArgumentNullException`)
- One of the indexes or sizes was invalid (`ArgumentOutOfRangeException`)
- The stream cannot be read from (`IOException`)
- The object has been disposed (`ObjectDisposedException`)

There is a different exception type for each symptom that can possibly occur. Note that I said symptom, not cause. For example there are a number of possible causes of the stream not being readable, such as the stream being created without allowing read access, or the underlying socket being closed, but to the calling code the symptom is the same: the stream cannot be read from. The symptom is something you can take programmatic action to handle, the cause is not.

Now I'm not saying the cause of the problem isn't important - indeed it is why we have properties on the exception such as `Message` and `StackTrace` which provide information about the cause - but it's only important for human inspection. In the case of an `IOException` the message and some debugging might lead us to faulty code which closes a socket when it shouldn't so the program can be fixed and recompiled, but this information is of no use to the code itself as we haven't reached the stage of self-debugging and patching code.

Throw a different type of exception for each symptom that can be programmatically handled differently.

## When to create custom exception types

Generally the advice given when creating class libraries is to reuse the built-in exception types wherever possible, and only create custom exception types if the built-in exceptions do not meet your needs. To define what needs means here we again go back to the reason for different exception types in the first place - programmatic handling.

If we were writing a data access layer for a system which has customers, a fairly common requirement in the business world, then at some point we're going to be inserting a customer based on their information such as name, address etc. If the data access layer is requested to insert the details for an existing customer we need to notify the calling code that the customer already exists with an exception.

Using something like `InvalidOperationException` with an appropriate message might be fine and gets the point across, but it doesn't really help the calling code handle it as although it knows the customer already exists, it doesn't have the information to access them. On the other hand, if we created a new exception type such as `CustomerAlreadyExistsException` and annotated it with a `CustomerId` property, then the calling code can potentially handle the symptom in a better way, possibly by returning that identifier and pretending the insertion was successful.

Create a custom exception type when you need to annotate the exception with additional information to aid in the programmatic handling of the symptom.