Date: 2007-08-26  
Status: Published  
Tags: Code Contracts, Code Style, Debugging  

# Document your assumptions with Debug.Assert instead of comments

From reviewing significant amounts of code over the last few years I have concluded that most people don't use `Debug.Assert` very much, if at all. I find this surprising because I use `Debug.Assert` a lot. Used prudently it can reduce bugs in code, make it more self documenting, and as an additional benefit you can even improve performance!When writing methods people frequently make assumptions, such as that the internal state of the class is correct, or that the arguments passed into a private method are valid (because they should have been checked by the non-private method calling it). Sometimes people even document these assumptions with comments such as "the encryption key will already have been populated by the constructor".

The trouble is that commented assumptions don't help much when they are wrong. What if the encryption key wasn't already populated? The program will carry on regardless until it fails at some point in the future. And because you didn't trap the problem at the point where it became clear that something was already wrong (i.e. at the comment documenting the assumption) then it's much harder to work out where the problem really occurred because the failure itself could occur further down the line in a largely unrelated method. And if it's a really horrible problem like the encryption algorithm auto-generated a key because you didn't supply one, you may not even be able to recover as you may have data that you cannot decrypt!

So every time you find yourself making an assumption "I know this will be there", "this should be in that state", "the argument should not be null as the public method will have validated it", document it by using Debug.Assert rather than a comment. Then, if your assumption is incorrect, your application will come to a grinding halt at the point where the problem became apparent.

And the best part of this? While it can help you find the problems during development, there's no performance hit when it comes to the release version because `Debug.Assert` statements are marked with the `[Conditional("DEBUG")]` attribute so in release builds it's as if they don't even exist. You can use this fact to improve the performance of your application by using `Debug.Assert` rather than check-and-throw to validate private method arguments.

In a way though, the best part is also the worst part. You need to be very careful you don't introduce bugs due to side effects. Because `Debug.Assert` statements are removed from release builds, you should ensure that they have no side effects which could cause problems. A classic one I've seen, and done myself a few times, is to assert that a data reader reads when you're expecting a single item, i.e.

~~~ csharp
Debug.Assert(reader.Read(), "Expected an item to be returned if no error was raised.");
~~~

When this line gets removed from the release build of the application, it also removes the call to `reader.Read` so on the next line you'll get an `InvalidOperationException` stating that an invalid attempt was made to read when no data is present. It's a particularly confusing error because when you check the source, you'll see that you asserted that the reader did in fact read! The correct way to write this would be:

~~~ csharp
bool read = reader.Read();
Debug.Assert(read, "Expected an item to be returned if no error was raised.");
~~~

As a summary, I'll restate this in the usual .NET Framework design guidelines manner so it can be easily inserted into a coding standards document. It turns out the guidelines for the use of `Debug.Assert` are pretty simple:

- _Do_ use `Debug.Assert` to validate any assumption you are making.
- _Do not_ use `Debug.Assert` to evaluate statements that have side effects.