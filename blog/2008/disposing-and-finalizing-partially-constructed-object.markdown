Date: 2008-08-27  
Tags: .NET, Design Guidelines, Garbage Collection  

# Disposing and finalizing partially constructed objects
    
On [MSDN forums](http://forums.msdn.microsoft.com) there was a question about [whether class constructors should be permitted to do a lot of work or not](http://forums.msdn.microsoft.com/en-US/csharpgeneral/thread/e39ed467-bca7-4432-8266-1f095c220c2c):

> I have a dilemma and a dispute with some colleagues: should the constructor of a C# class do a lot or the minimum and latter in a method call put a lot of logic?

> I am coming from a C++ background and there it is better to do just simple data initialization in the constructor, throwing an exception from a constructor is bad since the object is not fully constructed yet.

> Does the same argument work in C#?

> Should I do the minimum work in the constructor?

>My colleagues' position is that having a minimal constructor will leave the state of the object as not fully defined and then changed by a subsequent call to another method.

The two main factors to whether a constructor should do a significant amount of work are whether it should leave the class in a state ready to be used for real work if possible, and whether it matters if the constructor throws an exception and leaves the instance in a partially constructed state. I think we can all agree that it is much more intuitive to construct an object and have it ready for use than to construct it and have to call some sort of `Initialize` method afterwards, so lets assume that the real issue is with resource clean-up of partially constructed objects.

Rather than offer opinion here, I wrote a simple program to demonstrate disposal and finalization of a partially constructed object.

~~~ csharp
class Program
{
    static void Main(string[] args)
    {
        Foo foo = null;
        try
        {
            foo = new Foo();
        }
        catch (Exception ex)
        {
            Console.WriteLine("{0} occurred constructing Foo", ex.GetType());
        } 
        
        try
        {
            foo.Dispose();
        }
        catch (Exception ex)
        {
            Console.WriteLine("{0} occurred disposing Foo", ex.GetType());
        } 

        GC.Collect();
        GC.WaitForPendingFinalizers();
    }
}

class Foo : IDisposable
{
    public Foo()
    {
        throw new Exception();
    }

    ~Foo()
    {
        Console.WriteLine("Foo finalizer called");
    }

    public void Dispose()
    {
        Console.WriteLine("Foo dispose called");
    }
}
~~~

The output from this program is:

> System.Exception occurred constructing Foo  
> System.NullReferenceException occurred disposing Foo  
> Foo finalizer called  

From this we can ascertain that if the object is not constructed correctly then the reference to the object will not be assigned, which means that no methods can be called on it, so the `Dispose` method cannot be used to deterministically clean up managed resources. The implication here is that if the constructor creates expensive managed resources which need to be cleaned up at the earliest opportunity then it should do so in an exception handler within the constructor as it will not get another chance.

We can also ascertain that the finalizer will be called on the object even if the constructor throws an exception. This is possible because, unlike C++, C[LR objects do not start as their base type and then morph into derived types as they are constructed but start out as the type they will end up as](http://blogs.msdn.com/slippman/archive/2004/01/28/63917.aspx) so the garbage collector knows what type the object is and where the finalizer is in the method table. As such, the presence of a finalizer does not affect whether you should throw exceptions from a constructor because as long as you write the finalizer code defensively to only clean up unmanaged resources that have been allocated (which you should be doing anyway) then it will work fine whether the object was fully constructed or not.

And, of course, there is the final scenario in which the constructor neither allocates expensive managed resources, nor any unmanaged resources, so it doesn't matter whether you throw an exception because the partially constructed instance will just be cleaned up by the garbage collector.

In summary, do as much work as needed to get the object in a usable state in the constructor, but clean up any expensive managed resources you allocate in an exception handler if you can't complete it successfully.