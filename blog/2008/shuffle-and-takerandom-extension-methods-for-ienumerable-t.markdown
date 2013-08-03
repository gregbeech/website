Date: 03 Sep 2008  
Status: Published  
Tags: Algorithms, Linq, Sorting  

# Shuffle and TakeRandom extension methods for IEnumerable<T>
    
It's a fairly common practice on web sites to display sets of randomly ordered items, whether it's a selection of your friends, items related to the one you're looking at, or even something as simple as a tag cloud. Sometimes the entire set of items is randomised, and sometimes you want to take a random selection from the set and display that (the latter is typically done so you can cache a larger set of data and then take items from it without going to the database again).

The `System.Linq.Enumerable` class provides a lot of methods to process collections, but it appears that randomisation is beyond its remit. As such I wrote a couple of extension methods to shuffle a collection and take a random selection from it, which use the Durstenfeld implementation of the [Fisher-Yates algorithm](http://en.wikipedia.org/wiki/Fisher-Yates_shuffle) to give an unbiased shuffle in O(n) time.

~~~csharp
public static class EnumerableExtensions
{
    public static IEnumerable<T> Shuffle<T>(this IEnumerable<T> source)
    {
        var array = source.ToArray();
        var n = array.Length;
        while (n > 1)
        {
            var k = ThreadSafeRandom.Next(n);
            n--;
            var temp = array[n];
            array[n] = array[k];
            array[k] = temp;
        }

        return array;
    }

    public static IEnumerable<T> TakeRandom<T>(this IEnumerable<T> source, int count)
    {
        return source.Shuffle().Take(count);
    }
}
~~~

These work perfectly well, but unfortunately the `TakeRandom` method isn't as efficient as it could be because the `Shuffle` method always shuffles the entire list even though we're only interested in the first count elements. This implementation of the algorithm can't be stopped to retrieve the first elements as it constructs the result at the end of the list, and although we could use the existing `Reverse` extension method to work around this it would be somewhat inefficient.

Instead, we can rewrite the algorithm in reverse so that it constructs the result at the start, and then stop it after count iterations to retrieve the part-shuffled sequence. The reversed algorithm can be trivially implemented as a for loop in a private function and then consumed by both the public `Shuffle` and `TakeRandom` methods.

~~~csharp
public static class Enumerable
{
    public static IEnumerable<T> Shuffle<T>(this IEnumerable<T> source)
    {
        var array = source.ToArray();
        return ShuffleInternal(array, array.Length);
    }

    public static IEnumerable<T> TakeRandom<T>(this IEnumerable<T> source, int count)
    {
        var array = source.ToArray();
        return ShuffleInternal(array, Math.Min(count, array.Length)).Take(count);
    }

    private static IEnumerable<T> ShuffleInternal<T>(T[] array, int count)
    {
        for (var n = 0; n < count; n++)
        {
            var k = ThreadSafeRandom.Next(n, array.Length);
            var temp = array[n];
            array[n] = array[k];
            array[k] = temp;
        }

        return array;
    }
}
~~~

These methods still aren’t perfect as there is a potential O(n) operation to convert the sequence to an `IList<T>` even when only a few random elements are required, because we need to access the elements by index. However, this is rather difficult to avoid in shuffle algorithms. You'll notice also that unlike most Linq methods they do not use deferred execution; this is because [methods using deferred execution should be re-entrant](/blog/methods-involving-deferred-execution-should-be-reentrant) and due to their random nature these are not.

Finally I should point out that if you're doing anything that requires completely unpredictable shuffling (e.g. a deck of cards in a casino application) you need to replace the random number generator with a cryptographically strong one such as the .NET [RandomNumberGenerator](http://msdn.microsoft.com/en-us/library/system.security.cryptography.randomnumbergenerator.aspx).
