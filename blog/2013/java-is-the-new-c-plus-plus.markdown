Date: 2013-12-31
Tags: C++, Java, Languages

# Java is the new C++

Back in the early 1990s, Java was conceived as an alternative to C++, which would be portable, garbage collected, and easier to learn, but still retaining a C-like syntax to make programmers feel more comfortable migrating to it. There are a variety of reasons why Java became so popular on launch, marketing not being the least of them, and now it's one of the most popular languages in the world. Perhaps _the_ most popular, depending on who you believe.

When Java was released in 1996, I wasn't a developer. In fact, I think at that point the most code I had written was:

~~~basic
10 PRINT "HELLO WORLD"
20 GOTO 10
30 END
~~~

As such, I'm going to have to take the words of the older and more grizzled developers I know that yes, for building many types of software, Java was a much better language than C++. Presumably it still is. The trouble is, the game has moved on, and C++ isn't the main competition any more. 

It's the best part of 20 years since Java was launched, and time has left the language behind. Can you think of another modern language that doesn't have lambda expressions and proper closures? And yeah, I know they're supposed to be coming in Java 8, but they've been supposed to be coming for years. And even then Java 8's release data has slipped back to 2014 (at least), which just encourages derogatory comparison with C++0x... er, I mean C++11.

What's even worse is that Java developers know that it's a clumsy, outdated language. When you point out the incredibly verbose syntax, the pain of checked exceptions (which has to go down as one of _the_ most stupid language features in history), the incomprehensibility of `T[]` not being assignment compatible with `Iterable<T>`, and the fact that it's impossible to transform a collection of something into a collection of something else without either writing five lines of `for`-loop or importing a third party library and writing five lines of anonymous inner class, they'll still defend it as being "good enough".

It isn't. Not by a long shot.

Defending Java as a "good enough" language only further reinforces my opinion that if anybody describes themselves as an "X developer", you can replace "X" with "Crap" and have a reasonable probability of being correct. If you don't care about the tools you use every day - and a language _is_ just a tool - then it's hard to believe you're going to care much about what you produce with it.

The last stand of the Java developer when trying to defend the language is that at least it's easy to learn. But that isn't true either. What they mean is that because Java has so little expressive power that there isn't much in the way of language features to learn, which is true, but Java still goes out of its way to make the few concepts it can express appear complex.

Let's start with primitives such as `int` and `byte` which aren't objects, and their counterparts `Integer` and `Byte` which are. Because Java isn't really an object-oriented language, if you want to have an integer that is an object you have to convert your `int` to `Integer`; this is necessary if you want to put it in a collection because they can only store objects. If somebody is learning the language, is now a good point to start explaining the difference between reference and value types? Probably not. Especially as most developers still think that value types live on the stack and reference types live on the heap and will try and explain it in those terms.

This might not seem _so_ bad, as nowadays Java will auto-box your `int` to an `Integer` if you try to add it to a collection. But if you try and call a method on it, e.g. `(3).toString()`, then it won't auto-box it and you'll get a compiler error, so we're now in an inconsistent world where primitives are sometimes treated like objects and other times not. And while it's easy to convert `int` to `Integer`, you're back to a `for` loop if you want to convert `int[]` to `Integer[]`.

While we're on the subject of arrays, although generally you find the number of elements in a Java collection using the `size()` method, the array type - not being a real object and thus not supporting methods - has a `length` field instead. Strings aren't sure whether they're an array or a collection of characters, so they hedge their bets and use a `length()` method.

That isn't the biggest array WTF in Java though, because that's waiting for you when you try to pass an array of `T` to a method that's expecting an `Iterable<T>` and you get a compiler error complaining that they're incompatible types. I'm sorry, but in what world is an array _not_ iterable? Yeah, I know it's because arrays are special types that aren't really objects and don't really exist, but that's no excuse - it's the same in .NET but at least Microsoft put a load of hacks in their VM to make scenarios that _ought_ to work _actually_ work.

What's more ridiculous is that there _are_ some hacks in Java to make arrays appear more like their real-object collection cousins. For example, the "modern" `for` loop (yeah, that does seem to be its real name) can iterate over both `T[]` and `Iterable<T>` even though neither are assignment compatible nor share any common interface.

Sticking with the array theme, in Java it's possible to check whether a variable contains an array of integers at runtime by writing `myVar instanceof Integer[]`. However, if you want to check whether it contains a list of integers then you're shit out of luck, because writing `myVar instanceof List<Integer>` will just see the compiler come back with an error that it's an illegal type for `instanceof`. You actually can only check that it's a list of _something_ by writing `myVar instanceof List<?>` because generic type information is erased at compile time and so doesn't exist at runtime. You might not think this is such a big deal, but it causes significant complexity in some libraries; want to explain [how to deserialize JSON to a generic type](http://wiki.fasterxml.com/JacksonPolymorphicDeserialization#A5.1_Missing_type_information_on_Serialization) to a beginner?

We've barely covered primitive types and basic collections and already we're up to paragraphs on the needless complexities inherent in Java. We haven't even got onto the different types of variance. An, yes, variance. Java offers two types of generic variance which I'm going to call "broken" variance and "where's that book again?" variance.

"Broken" variance is demonstrated by arrays, where their covariance and mutability can lead to some surprising errors at runtime that can't be caught by the type system:

~~~java
Animal[] animals = new Giraffe[10];
animals[0] = new Turtle(); // BOOM!
~~~

This is broken because it [should always be legal to put a Turtle into an array of animals](http://blogs.msdn.com/b/ericlippert/archive/2007/10/17/covariance-and-contravariance-in-c-part-two-array-covariance.aspx).

"Where's that book again?" variance is demonstrated by pretty much all the other variance in Java, where it's so unintuitive you can really only figure out why things aren't doing what you expect, and how to fix it, by going back to the reference manual. For example, you'd expect a generic iterator to be contravariant as types only come 'out', and thus that you'd be able to treat an `List<String>` as an `Iterable<Object>`, but:

~~~java
Iterable<Object> items = new ArrayList<String>(); // error: incompatible types
~~~

Needless to say, in non-broken languages that support non-broken variance, this stuff just works:

~~~csharp
IEnumerable<object> items = new List<string>(); // in C# this is totally ok
~~~

---

TODO: Checked exceptions are about the worst feature in any language, ever, e.g. JCA, which makes you catch exceptions documented as not being able to occur.

---

So let's sum up where we are: Primitives that aren't objects, except when they are. Arrays that aren't iterable, but language constructs that can treat them as such. Types that exist at compile time but not at runtime. Two types of variance, both significantly different, both broken, and one of which is so complex that virtually nobody actually understands it. And an exception system that forces advanced concepts on people immediately.

I feel like I've barely scratched the surface here, but actually that's most of what Java as a language has to offer. I guess I could talk about the fact that `protected` allows both derived types _and_ types in the same package to access the members, or that package-private doesn't allow sub-packages to access types. But that would just be rubbing salt into the wounds.

A language that's easy to learn? I can't think of any modern language that's more needlessly complex.

Let's take a look at what people really mean when they say other languages are harder to learn: that they can do more. I'll take a simple example that I needed to do this week, which was prepend a single zero-byte to an array. In Java your code is going to look something like this:

~~~java
byte[] temp = new byte[bytes.length + 1];
System.arraycopy(bytes, 0, temp, 1, bytes.length);
bytes = temp;
~~~

Whereas in Scala, an increasingly popular JVM language, it's going to look more like this:

~~~scala
bytes +:= 0
~~~

Yeah, I'm not kidding. Those code fragments are equivalent.

I know what you're thinking though. The Scala code looks more cryptic. But much like `a += b` expands to `a = a + b` in Java, `a +:= b` expands to `a = a.+:(b)` in Scala, where the part before the `=` is the method name; `+:` is a legal method name in Scala. All you have to remember is a universal expansion rule, which is arguably simpler than the localised expansion rule in Java.

So after a while, the extra power stops being cryptic, and starts becoming natural. I certainly find it easier because it's regular, unlike the Java code where I had to refer to the documentation to see which order the parameters for `arraycopy` come in, and nearly made an off-by-one error while typing it.








---
not everything is bad - the virtual machine (excluding its lack of generic support), the package system, the frameworks, all sensible things that are recognised as good ideas. (there's almost certainly prior art, but i can't be arsed to research)

but you don't need *java* to use them.



