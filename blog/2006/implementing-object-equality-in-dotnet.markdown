Date: 2006-07-04  
Status: Published  
Tags: .NET  

# Implementing object equality in .NET
    
At first glance it seems simple to implement object equality in .NET, just override the `Equals` method inherited from `System.Object`, but in reality there actually are a lot of potential problems. You need to consider comparing null objects, and also the string representation, hash code and immutability of the object otherwise your application might behave oddly in specific circumstances. Here's a simple guide to implementing object equality and comparability in .NET.

I find it easier to understand things with a concrete example rather than talking in abstract terms, so I'll be using a simple area class as the basis for all discussion points, as shown below:

~~~ csharp
public class Area
{
    private int height;
    private int width;
   
    public Area(int height, int width)
    {
        this.height = height;
        this.width = width;
    }

    public int Height
    {
        get { return this.height; }
        set { this.height = value; }
    }

    public int Width
    {
        get { return this.width; }
        set { this.width = value; }
    }

    public long Size
    {
        get { return (long)this.width * this.height; }
    }
}
~~~

When implementing your own equality check, the central point for all callers is the instance `Equals(object)` method. This is used for direct instance equality checks, and is also called by the static `object.Equals(object, object)` method after it does basic null checks, so is a good place to centralise your logic. Personally I like to create a strongly typed instance `Equals` method and forward the calls to this, which usefully provides us with an implementation of the `IEquatable<T>` interface.

~~~ csharp
public bool Equals(Area obj)
{
    if (object.ReferenceEquals(obj, null))
    {
        return false;
    }

    return this.height == obj.height && this.width == obj.width;
}

public override bool Equals(object obj)
{
    return this.Equals(obj as Area);
}
~~~

The reason we use `object.ReferenceEquals` to check for null rather than using the `==` operator is that later we may want to implement our own custom version of this operator. Because the operator will ultimately call through to our custom `Equals` method this would become recursive and result in a `StackOverflowException`.

One of the very strong recommendations in the .NET framework is that when you override the `Equals` method, you should also override `GetHashCode`. The hash code of the object should be created from the internal state of the object as [two equal objects must return the same hash code](http://msdn2.microsoft.com/en-us/library/system.object.gethashcode.aspx). A common way to create a reasonably well distributed custom hash code is to XOR the hash codes of the member variables together, however as the hash code of an integer is the integer itself we can bypass this and just XOR the two fields.

Overriding `ToString` is also worthwhile when overriding `Equals`, as typically objects that can be compared for equality have a reasonable string representation (if not, then you should consider whether implementing equality is the correct thing to do).

~~~ csharp
public override int GetHashCode()
{
    return this.height ^ this.width;
}

public override string ToString()
{
    return string.Format("{0}W x {1}H", this.width, this.height);
}
~~~

Unfortunately, overriding `GetHashCode` presents us with a problem. The hash code of an object must never change as if you insert it into a structure such as a `Hashtable` or `Dictionary<TKey,TValue>` which stores it using the hash code, then change the hash code, the structure will report that it cannot find the object. As we calculate the hash code from the internal state, the logical conclusion is that the internal state cannot change - i.e. the object must be immutable. As such to implement equality properly, we must remove the property setters and declare the member variables with the `readonly` keyword.</p>

The completed immutable class is shown below with `IEquatable<T>` defined and static `==` and `!=` operators included. These operators use the static `object.Equals(object, object)` method which will perform any appropriate checks for null, then call the overridden instance `Equals` method on one of the objects. In addition, on something like an area, we may also want to implement other operators such as greater or less than. If the objects can be compared into an order (in this case, smallest to largest), then the recommendation is to implement the `IComparable` and `IComparable<T>`interfaces and in a similar manner pass through to these from the static operators.

~~~ csharp
public class Area : IEquatable<Area>, IComparable<Area>, IComparable
{
    private readonly int height;
    private readonly int width;
   
    public Area(int height, int width)
    {
        this.height = height;
        this.width = width;
    }

    public int Height
    {
        get { return this.height; }
    }

    public int Width
    {
        get { return this.width; }
    }

    public long Size
    {
        get { return (long)this.width * this.height; }
    }

    public static bool operator ==(Area a, Area b)
    {
        return object.Equals(a, b);
    }

    public static bool operator !=(Area a, Area b)
    {
        return !object.Equals(a, b);
    }

    public static bool operator >(Area a, Area b)
    {
        return Comparer<Area>.Default.Compare(a, b) > 0;
    }

    public static bool operator <(Area a, Area b)
    {
        return Comparer<Area>.Default.Compare(a, b) < 0;
    }

    public static bool operator >=(Area a, Area b)
    {
        return Comparer<Area>.Default.Compare(a, b) >= 0;
    }

    public static bool operator <=(Area a, Area b)
    {
        return Comparer<Area>.Default.Compare(a, b) <= 0;
    }

    public int CompareTo(Area other)
    {
        if (object.ReferenceEquals(other, null) || this.Size > other.Size)
        {
            return 1;
        }

        return this.Size == other.Size ? 0 : -1;
    }

    public int CompareTo(object obj)
    {
        return this.CompareTo(obj as Area);
    }

    public bool Equals(Area obj)
    {
        if (object.ReferenceEquals(obj, null))
        {
            return false;
        }

        return this.height == obj.height && this.width == obj.width;
    }

    public override bool Equals(object obj)
    {
        return this.Equals(obj as Area);
    }

    public override int GetHashCode()
    {
        return this.height ^ this.width;
    }

    public override string ToString()
    {
        return string.Format("{0}W x {1}H", this.width, this.height);
    }
}
~~~

Seems like quite a lot of work just to allow people to check whether objects are equal doesn't it? Fortunately the pattern for doing it is pretty prescriptive and you generally don't need to implement it on many objects as often equality just doesn't make sense. Note that although I have been talking in terms of classes here the same guidelines apply to structs, except you can make it even simpler by getting rid of the unnecessary null checks. In fact, this `Area` class would probably be better implemented as a struct because it meets all of the [requirements for a struct](http://msdn2.microsoft.com/en-us/library/ms229017.aspx), being only eight bytes in size and immutable.