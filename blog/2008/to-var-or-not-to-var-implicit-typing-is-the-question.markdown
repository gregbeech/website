Date: 2008-03-24  
Status: Published  
Tags: C#, Code Style  

# To var or not to var, implicit typing is the question
    
The introduction of the `var` keyword in C# 3.0 was required to support anonymous types, however it may also be used to declare variables for named types. This seems to have sparked quite a lot of debate about where the use of `var` is appropriate. The [C# Reference documentation page](http://msdn2.microsoft.com/en-us/library/bb383973.aspx) suggests that:

> Overuse of `var` can make source code less readable for others. It is recommended to use `var` only when it is necessary, that is, when the variable will be used to store an anonymous type or a collection of anonymous types.

However the [MSDN C# Programming Guide's page on implicitly typed local variables](http://msdn2.microsoft.com/en-us/library/bb384061.aspx) is less restrictive:

> The `var` keyword can also be useful when the specific type of the variable is tedious to type on the keyboard, or is obvious, or does not add to the readability of the code. One example where `var` is helpful in this manner is with nested generic types such as those used with group operations. In the following query, the type of the query variable is `IEnumerable<IEnumerable<Student>>`. As long as you and others who must maintain your code understand this, there is no problem with using implicit typing for convenience and brevity.

And [Ilya Ryzenkhov](http://www.blogger.com/profile/14966746474791511643), ReSharper's product manager, is [positively in favour of using var wherever possible](http://resharper.blogspot.com/2008/03/varification-using-implicitly-typed.html):

>Using var keyword can significantly improve your code, not just save you some typing [...]

> [...] by actively using var keyword and refactoring your code as needed you improve the way your code speaks for itself.

I'm sure that the use of `var` will follow conventions such as [Hungarian notation](/blog/even-good-hungarian-notation-is-still-bad) down the path of religious debate, with protagonists on either side of the fence having unwavering views that their way is the One True Way. I don't much care for religious debates as they tend to take time away from more important things like _actually shipping a product_ but whenever one comes up you need to make a decision that works for you and your development team to keep the coding style relatively consistent. So, should you use the `var` keyword liberally or not?

Rather than make a decision based on all the conflicting recommendations I took the [scientific approach and experimented](http://www.xkcd.com/397/). As I'm a ReSharper user, I left the 'convert to implicit type' suggestion active and acted on it in every method I wrote or edited over a two week period to see if I'd miss the explicit type declarations. And you know what?

I didn't.

Not one bit.

Not only did I not miss them, I found that I was writing clearer code with less redundancy and better naming of local variables. And I did find some APIs we'd written which returned slightly odd or unexpected types, or had poor names, and rather than just accepting it as I may have done with the additional type annotations I refactored the APIs so that they made sense even when used with the var keyword. In fact, everything Ilya Ryzhenkhov postulated turned out to be correct.

Some people in the office were concerned that it would make code reviews more difficult, but that wasn't the case either. Code reviews aren't about checking whether the code compiles - you've already got a rather good tool called a compiler for that - they're to check things like the control flow, efficiency and naming. Stripping the type information away helps this because you're looking purely at the names of objects and the things you're doing to them, and not worrying about whether the concrete type is an `XmlNode` or an `XmlElement`; as long as the APIs you're calling accept the object, and it supports the properties/methods you need then it doesn't really matter.

However, there is one scenario where I think explicit typing may be more appropriate: financial calculations. If you're performing financial calculations you want to be absolutely, one-hundred-percent sure that you're using decimals for all parts of the calculation and not accidentally introducing floating point, rounding or truncation errors. The best way to do that is to explicitly declare everything as decimal.

Our internal standard at [blinkbox](http://www.blinkbox.com/) is to always use `var` in new code (except calculations where exact precision is required) and convert older code to use `var` when it is touched. I won't say that this is the best option for everybody else, but I'd urge you to try it for a couple of weeks before dismissing the idea out of hand.