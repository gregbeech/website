Date: 2008-09-09  
Status: Published  
Tags: Algorithms, Sorting, Testing

# Determining the bias of a shuffle algorithm
    
Last time I wrote [`Shuffle` and `TakeRandom` extension methods for `IEnumerable<T>`](/blog/shuffle-and-takerandom-extension-methods-for-ienumerable-t) which use the Fisher-Yates algorithm to perform an unbiased shuffle of a sequence and take a random subset from it. In order to optimise the performance of the `TakeRandom` method I had to reverse the documented implementation of the shuffle so it produced the results at the start of the sequence rather than the end, and thus allow it to be short-circuited once enough values had been randomised.

It all looks fine in theory, but as even simple algorithms are notoriously hard to implement correctly I wouldn't have been happy publishing it without testing to ensure that (a) the shuffle works, and (b) it really is unbiased.

One way to determine the bias is to shuffle integer sequences and then add the values at corresponding indexes, giving the total value at each index. If the shuffle is unbiased then each value should appear at each index an equal number of times, and so the total value calculated for each index should be the same. If we compute the [percentage relative standard deviation](http://en.wikipedia.org/wiki/Relative_standard_deviation) (%RSD) of the totals, a value of zero indicates an unbiased algorithm and any non-zero value indicates biased one, with larger values being more biased.</p>  <p>Below are a couple of extension methods to compute the [standard deviation](http://en.wikipedia.org/wiki/Standard_deviation) and relative standard deviation for sequences of integers. It's impressive how terse the syntax is to do this with the Linq extensions; however, it is frustrating that in C# there is no way to create them as open generic methods and indicate that they apply to anything that can have mathematical operations performed on it, so if you want versions of these that work with sequences of `float` you have to cut-and-paste the implementations and replace the `int`keyword.

~~~csharp
public static class EnumerableExtensions
{
    public static double StandardDeviation(this IEnumerable<int> values)
    {
        return StandardDeviationInternal(values, values.Average());
    }

    public static double RelativeStandardDeviation(this IEnumerable<int> values)
    {
        var average = values.Average();
        var standardDeviation = StandardDeviationInternal(values, average);
        return (standardDeviation * 100.0) / average;
    }

    private static double StandardDeviationInternal(IEnumerable<int> values, double average)
    {
        return Math.Sqrt(values.Select(value => Math.Pow(value - average, 2.0)).Average());
    }
}
~~~

To compute the %RSD we need to consider the effect that the randomness has on the distribution of the values. With a low number of sequences shuffled there may be a uneven distribution of randomness leading to invalid results, however as the number of sequences shuffled increases the randomness should be more evenly distributed and cancel itself out (assuming an unbiased random number generator). From this we can see that as the number of sequences shuffled approaches infinity, the calculated %RSD approaches the correct answer.

Unfortunately we haven't got time to shuffle an infinite number of sequences, so my test application makes do with shuffling a logarithmic range from 100 to 100,000,000 sequences of the numbers 1..10, printing the results to the console:

~~~csharp
class Program
{
    static void Main()
    {
        for (var i = 100; i <= 100000000; i *= 10)
        {
            ShuffleTest(i);
        }

        Console.ReadLine();
    }

    private static void ShuffleTest(int iterations)
    {
        var totals = new int[10];
        var generator = Enumerable.Range(1, 10);
        for (var iteration = 0; iteration < iterations; iteration++)
        {
            var index = 0;
            foreach (var value in generator.Shuffle())
            {
                totals[index] += value;
                index++;
            }
        }

        Console.WriteLine(
            "{0,-9} iterations: {1:0.000} %RSD", 
            iterations, 
            totals.RelativeStandardDeviation());
    }
}
~~~

Plotting the results in Excel using logarithmic scales shows that as the number of iterations increases the %RSD does approach zero; by one hundred million iterations the measured %RSD is only 0.005. We can therefore say with confidence that the shuffle implementation from the previous entry is completely unbiased.

{:.center}
![Percentage RSD against Shuffle Iterations](/unbiased-algorithm-deviation.png)

If you want to compare this against a biased algorithm then shown below is a common mistake people make when implementing the Fisher-Yates shuffle, where the random range is computed from 0 rather than n:

~~~csharp
private static IEnumerable<T> ShuffleInternal<T>(T[] array, int count)
{
    // WARNING! This algorithm has a mistake. Do not use!
    for (var n = 0; n < count; n++)
    {
        var k = ThreadSafeRandom.Next(0, array.Length);
        var temp = array[n];
        array[n] = array[k];
        array[k] = temp;
    }

    return array;
}
~~~

Plotting the results on the same chart as the correctly implemented algorithm shows that this one approaches a value of approximately 3.17 %RSD and so is proven to be biased:

{:.center}
![Percentage RSD against Shuffle Iterations with mistake](/biased-algorithm-deviation.png)

This isn't the only approach to prove that a shuffle algorithm implementation is unbiased, but it is quick to implement and run, and gives a high level of confidence in the results. You can, and should, test any other shuffle algorithm you implement in a similar manner.