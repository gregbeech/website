Date: 2008-02-28  
Tags: .NET  

# Methods involving deferred execution should be reentrant
    
If you create a method to return a random set of items from an enumerable list, implemented using an iterator...

~~~ csharp
public static IEnumerable<T> GetRandom<T>(this IEnumerable<T> items)
{ 
    var random = new Random();
    foreach (var item in items) 
    {
        if (random.Next() < 0.5) 
        {
            yield return item;
        }
    }
}
~~~

...then use it like this, where `PrintColors` uses a `foreach` loop to print each colour...

~~~ csharp
var colors = new[] { "red", "orange", "yellow", "green", "blue", "indigo", "violet" };
var randomColors = colors.GetRandom(); 
PrintColors(randomColors); 
PrintColors(randomColors);
~~~

...would you expect the colours printed by each method to be the same?

The intuitive answer seems to be yes - after all you called the `GetRandom` method and then passed the result to `PrintColors`. But, as you've probably guessed by now, the correct answer is no.

Welcome to the world of deferred execution.

In fact the body of `GetRandom` will be executed twice! Once within the first `PrintColors`, and once within the second `PrintColors`. This is because when `randomColors` is assigned it does not actually execute any code within `GetRandom`, it simply stores a reference to it, and it is when you start enumerating that `GetRandom` will execute. If you enumerate again then `GetRandom` will execute again, resulting in different random numbers, and different results.

You'll see the same effect with the following functionally equivalent Linq code, as Linq queries that return enumerators are usually implemented with deferred execution:

~~~ csharp
var randomColors = from c in colors where random.Next() < 0.5 select c;
PrintColors(randomColors); 
PrintColors(randomColors);
~~~

If you don't understand deferred execution then this is completely baffling; even if you do it can take some time to work out what's going on. We ran into a very similar issue today, and without actually stepping through the code and tracing the execution path it's virtually impossible to predict that the results would be different within each method.

Of course the issue only arose because the results of executing the query each time are different. If the results are always the same, and there are no side effects, then executing the query multiple times might be a bit inefficient but it won't cause functional problems. Which leads us to the following rule: Methods involving deferred execution must be [reentrant](http://en.wikipedia.org/wiki/Reentrant).

The `GetRandom` method cannot be written to be reentrant as an iterator, so we need to ensure that the code returns a fixed collection of items. One way to do this is to build a list with a foreach loop, which is immediately executed and doesn't have any hidden semantics.

~~~ csharp
public static IEnumerable<T> GetRandom<T>(this IEnumerable<T> items)
{
    var randomItems = new List<T>(); 
    foreach (var item in items) 
    { 
        if (random.Next() < 0.5) 
        { 
            randomItems.Add(item); 
        }
    }

    return randomItems;
}
~~~

Similarly the Linq version can be safely re-written by forcing query execution to occur exactly once, using the ToList extension method to convert the enumerator into a list before passing to the other methods.

~~~ csharp
var randomColors = (from c in colors where random.Next() < 0.5 select c).ToList(); 
PrintColors(randomColors); 
PrintColors(randomColors);
~~~

Whichever approach you choose, put a comment there indicating why you are forcing immediate execution so you don’t come back to it in a month and think "hey I could convert that into an iterator" or "I could get rid of that unnecessary `ToList` call".