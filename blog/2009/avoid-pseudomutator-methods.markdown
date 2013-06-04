Date: 2009-11-12  
Tags: .NET, Design Guidelines

# Avoid pseudomutator methods
    
One of the goals of any library designer should be to help users fall into the pit of success by making the library as intuitive to use as possible. Unfortunately, they don't always succeed. I recently wrote a `Range` struct representing a range of numbers between two points, which has a method to merge two contiguous ranges into a single one. What would you expect the following code that uses it to print, assuming the struct has a reasonable override for `ToString`?

~~~ csharp
var a = new Range(0, 50);
var b = new Range(50, 100);
a.Merge(b);
Console.WriteLine(a);
~~~

If you said "0-100" then you've given the obvious answer, but unfortunately it isn't the right one. The answer is "0-50". As `Range` is a struct I made it immutable, so the `Merge` method is actually a pseudomutator: it is named and called like a method that changes the instance it is called on, but instead it leaves the instance unchanged and returns a new instance that is the result of the operation. As a consequence of this, the code has to be written as follows to get the expected result of "0-100".

~~~ csharp
var a = new Range(0, 50);
var b = new Range(50, 100);
var m = a.Merge(b);
Console.WriteLine(m);
~~~

The first code sample looks right, but is wrong. The second code sample looks wrong, but is right. We're not exactly in pit of success territory here.

Another way to write the `Merge` method would be to make it a static method that accepts two ranges and returns a merged range. As static methods do not access instance state it does not imply that the range arguments would be altered, and as they are typically pure it implies the result should be used, so the correct code should look correct. Which it does.

~~~ csharp
var a = new Range(0, 50);
var b = new Range(50, 100);
var m = Range.Merge(a, b);
Console.WriteLine(m);
~~~

My `Range` struct isn't the only place where things could be improved. Over the last few years I've noticed that the .NET framework structs `DateTime` and `TimeSpan`, which have many pseudomutator methods, are a frequent and recurring source of bugs because they make it easy to write wrong code that looks right. Virtually everybody has made a mistake like the one below at some point or another.

~~~ csharp
var dt = new DateTime(2009, 01, 01);
dt.AddYears(5);
Console.WriteLine(dt.Year); // oops, prints "2009"
~~~

In general the .NET framework is very well designed, and has a solid set of design guidelines, but in failing to recommend against pseudomutator methods they dropped the ball, and we'll continue paying for it in years to come with exactly this kind of bug. Don't contribute to the problem; avoid pseudomutator methods on your own immutable objects.