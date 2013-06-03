Date: 2008-08-04  
Tags: Code Style, Pragmatism  

# Code without comments is code that doesn't work
    
The other week Jeff Atwood posted a blog entry named [Coding Without Comments](http://www.codinghorror.com/blog/archives/001150.html) that stated... well I'm actually not sure. It started by making the valid point that comments should indicate why your code works the way it does and shouldn't be needed to explain what it does, but then went entirely off track and ended up pretty much stating that all comments are detrimental to code quality:

> While comments are neither inherently good or bad, they are frequently used as a crutch. You should always write your code as if comments didn't exist. This forces you to write your code in the simplest, plainest, most self-documenting way you can humanly come up with.

The example used in the blog post was refactoring some code that calculated a square root using the Newton-Raphson approximation to make it more clear how it worked. Which is all very useful. But the problem is that there are [a lot of different ways to calculate a square root](http://en.wikipedia.org/wiki/Methods_of_computing_square_roots) which make trade-offs in terms of speed, accuracy, memory usage and simplicity, and by the end of the post we still didn't know why the Newton-Raphson method was chosen in the first place because there were no comments with that information. And I really doubt this is something you want to encode in the method name:

~~~ csharp
var sqrt = NewtonRaphsonSquareRootBecauseItConvergesQuicklyWithAGoodInitialGuess(n);
~~~

Clearly the claim that you should write code as if comments didn't exist is a fallacy because they are necessary to explain why you wrote it that way (or, indeed, why you didn't write it another way). But what about my claim that code without comments doesn't even work? This is down to the probability that code without any comments hasn't been used in the real world.

As our codebase at [blinkbox](http://www.blinkbox.com/) matures, there are more and more parts of it that have long comments explaining why things are implemented the way they are, what alternatives were considered and discounted, what circumstances were observed in the live environment that cause this edge case or that edge case or the other edge case, and even in some cases why the code looks wrong but needs to be that way. Some particularly tortuous parts have significantly more comments than code itself.

Code without this type of comment is code that has never been hardened by real-world use; code that has never hit the 0.1% edge cases; code that simply doesn't work properly. I'm sure Jeff will find this out once he's had [Stack Overflow](http://stackoverflow.com) up and running for a few months.