Date: 2007-02-03  
Tags: C#, Code Style  

# Even good Hungarian notation is still bad

I was bored this weekend so I ended up trawling through a bunch of blog archives and came across posts from some well respected people about why they believe Hungarian notation (in its originally intended form) is a good thing. There are entries from [Eric Lippert](http://blogs.msdn.com/ericlippert/archive/2003/09/12/52989.aspx), [Joel Spolsky](http://www.joelonsoftware.com/articles/Wrong.html) and [Larry Osterman](http://blogs.msdn.com/larryosterman/archive/2004/06/22/162629.aspx) which essentially have the same point that originally Hungarian notation was intended to reflect the purpose of the variable, not the underlying data type, and in this form it is a very valuable naming convention. I'd have to agree. Sort of.

One of the examples cited in all three of these entries (in different forms) is concerned with ensuring that two integers with different purposes are never added. For example if you have an integer that represents a byte array size then it would begin with `cb` (count of bytes) whereas if it was an index in an array it would begin `i` (index) so if you ever saw `cbValue = cbMyArray + iMyArray` then it would be instantly obvious it was wrong as there's no good reason to add an index to an array size.

But the problem is that is isn't instantly obvious – it's only instantly obvious if you've learned the conventions that make it obvious. At least the prefixes in the array example are fairly widely used, but an example quoted by Joel for websites advocates prefixing strings which haven't been HTML-encoded with `us` (unsafe) and those which have with `s` (safe) to ensure that unsafe strings aren't inadvertently written to the page output. Anyone who hasn't read the documentation for these prefixes (because everybody reads documentation right?) will have no idea what they mean and probably just assume that `s` stands for `string` and that `us` stands for some kind of `unsigned string`, whatever that might be!

So that's why I sort of agree. I completely agree with the sentiment that the naming convention needs to take into account the purpose of the variable, but it needs to be done in a transparent way that doesn't require the developer to learn any number of arcane prefixes. If you are looking at somebody else's code to try and fix a bug, which of these two equivalent lines of code adding integers is more obviously wrong and what is the error?

~~~ csharp
cbFoo = cchBar + cbBlah;

bytesInFoo = charsInBar + bytesInBlah;
~~~

In the first line if you have learnt the convention that `cb` means count of bytes, and `cch` means count of characters then it's instantly obvious that something is wrong as the two are not equivalent in this modern age of multi-byte character sets. But it's only obvious if you have learned the convention. In the second line, you don't need to learn any conventions to see the error because it's spelled out for you in plain English. Sure, it's a little wordier, but you've got an auto-complete editor so you only need to type the first couple of characters in either case.

So we've established that we do need a coding practice of embedding the purpose of variables in their names, but I believe it's better to do it in a plain-text verbose way rather than with arcane prefixes. And I've got the [.NET Framework naming guidelines](http://msdn2.microsoft.com/en-us/library/ms229045.aspx) backing here:

> Do choose easily readable identifier names. For example, a property named HorizontalAlignment is more readable in English than AlignmentHorizontal.

> Do favor readability over brevity. The property name CanScrollHorizontally is better than ScrollableX (an obscure reference to the X-axis).

> Do not use Hungarian notation.

The problem is we need a name for it. "Hungarian" was chosen as the original designation for the prefixed naming convention because its inventor Charles Simonyi was Hungarian and because it looked a bit like a foreign language with all the random letters. I propose "German" notation for the new verbose method as the German language tends to concatenate a lot of words to form a single one. Unfortunately, I didn't invent this form of notation, so I doubt the name will stick...