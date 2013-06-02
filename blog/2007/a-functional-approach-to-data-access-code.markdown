Date: 2007-09-29  
Tags: C#, Data Access, Functional Programming

# A functional approach to data access code
    
To get a better understanding of how Lambda functions - and the functional programming capabilities they imply - might be used in C# 3.0, I've started playing around with [Scheme](http://en.wikipedia.org/wiki/Scheme_(programming_language)) (an introductory set of [video lectures from MIT are available free to download](http://swiss.csail.mit.edu/classes/6.001/abelson-sussman-lectures/)). One commonly used functional paradigm of not encapsulating a specific function in a procedure, but encapsulating knowledge about how to perform a type of function in a procedure and then building the specific procedure using that, made me realise that a significant portion of the data access code I have written in the last few weeks is actually redundant. Each data retrieval method we have follows this sort of pattern:

~~~ csharp 
try
    if the connection is not open
        open the connection
    end if
    execute the command and get a data reader
    while there is data available
        translate the current record into an object
    end while
end try
catch database error
    translate to a meaningful error and throw that
end catch
~~~

The only bits that tend to vary are how the data and errors are translated; the rest is all cut-and-pasted between functions. I've always known it was repetitive, but until now it hasn't really bothered me too much as that was the way I've always done it, and the way everybody I've worked with has done it. Now I've decided it's time to remove the redundant code, so I had a quick go at formulating a functionally inspired approach to data access. The code will work in C# 2.0 or later, though for 2.0 it does need a couple of helper delegates defined as follows which are already part of C# 3.0's corresponding .NET Framework 3.5:

~~~ csharp
public delegate R Func<A1, R>(A1 arg1);
public delegate R Func<A1, A2, R>(A1 arg1, A2 arg2);
~~~

To encapsulate the pattern described by the pseudo-code above, we need a higher-order procedure that takes the command to execute, a procedure to translate from the data reader into the return type, and a procedure to translate any database errors that occur:

~~~ csharp
internal static T ExecuteReader<T>(
    SqlCommand command,
    Func<SqlDataReader, T> objectMap,
    Func<SqlException, Exception> errorMap)
{
    T item;
    CommandBehavior behaviour = CommandBehavior.Default;
    try
    {
        if (command.Connection.State != ConnectionState.Open)
        {
            command.Connection.Open();
            behaviour = CommandBehavior.CloseConnection;
        }

        using (SqlDataReader reader = command.ExecuteReader(behaviour))
        {
            item = objectMap(reader);
        }
    }
    catch (SqlException ex)
    {
        if (behaviour == CommandBehavior.CloseConnection &amp;&amp; 
            command.Connection.State == ConnectionState.Open)
        {
            command.Connection.Close();
        }

        throw errorMap(ex);
    }

    return item;
}
~~~

This method still doesn't quite capture the two patterns we commonly use though. The first is when a collection of items is requested, we want to read each item from the reader and add it to a collection. The second is when a particular item is requested we want to check that the item was returned, throw an exception if not, and then read the item from the reader. Rather than write the loop/check code each time we call `ExecuteReader`, we can encapsulate these patterns a couple of helper methods:

~~~ csharp
internal static Collection<T> ReadCollection<T>(
    SqlDataReader reader,
    Func<SqlDataReader, T> recordMap)
{
    Collection<T> collection = new Collection<T>();
    while (reader.Read())
    {
        collection.Add(recordMap(reader));
    }

    return collection;
}

internal static T ReadItem<T>(
    SqlDataReader reader,
    Func<SqlDataReader, T> recordMap)
{
    if (!reader.Read())
    {
        throw new InvalidOperationException("No data returned.");
    }

    return recordMap(reader);
}
~~~

However the method signatures for `ReadCollection` and `ReadItem` don't match the `Func<SqlDataReader, T>` prototype on the `ExecuteReader` method because they take an additional parameter of the object mapping function to use to translate each item. The solution to this is to [curry the methods](http://en.wikipedia.org/wiki/Currying) at the call site by providing the object mapping function at that point. To demonstrate lets have a look at how these functions can now be used to retrieve a collection of members, where a member is represented by the very simple class:

~~~ csharp
public class Member
{
    public string Name;
    public int Age;
}
~~~

The infrastructure pieces we need for this are a method that can read a row from a data reader into a member object, and a method to translate any errors that might occur. Typically `SqlException` translation would be done on the basis of the error number so you'd probably have a single function for the entire data access layer which just consists of a very large switch statement, but for simplicity here we'll use an identity function that returns the original error.

~~~ csharp
internal static Member ReadMember(SqlDataReader reader)
{
    Member member = new Member();
    member.Name = reader.GetString(0);
    member.Age = reader.GetInt32(1);
    return member;
}

internal static Exception TranslateError(SqlException error)
{
    return error;
}
~~~

So now we can bring all the pieces together in the data access method to get members. First we create an object mapping procedure by currying the `ReadCollection` helper method with the `ReadMember` method. This is then passed in to the `ExecuteReader` function along with the static `TranslateError` method, though of course we could provide a custom error translation procedure if necessary.

~~~ csharp
public static Collection<Member> GetMembers()
{
    Func<SqlDataReader, Collection<Member>> curry = 
        delegate(SqlDataReader reader)
            {
                return ReadCollection(reader, new Func<SqlDataReader, Member>(ReadMember));
            };

    Collection<Member> members;
    using (SqlConnection connection = new SqlConnection("..."))
    using (SqlCommand command = new SqlCommand("SELECT * FROM Member", connection))
    {
        members = ExecuteReader(command, curry, TranslateError);
    }

    return members;
}
~~~

That's a lot smaller and cleaner than the original code, but I know what you're thinking... Every procedure is going to have to curry either `ReadItem` or `ReadCollection` with an object-specific mapping function, and then cut and paste the bit of code that creates the connection and executes the command, so why don't we extract that out into another higher-order procedure as well?

It's certainly possible, as you can see from the code below, but it's starting to look a little messy due to the strong typing requirements. The method needs an additional generic type to specify the type of container the pattern returns the items in (which will either be the type of the item itself or a collection of the items with these two patterns), and as you can see the function prototype for the pattern we want to pass in is verging on unreadable. Although you can catch errors at design time rather than runtime, I think this method definition shows why C# isn't an ideal functional programming environment when compared with dynamically typed languages such as Scheme.

~~~ csharp
internal static TContainer ExecuteReader<TItem, TContainer>(
    SqlCommand command,
    Func<SqlDataReader, Func<SqlDataReader, TItem>, TContainer> pattern,
    Func<SqlDataReader, TItem> objectMap,
    Func<SqlException, Exception> errorMap)
{
    Func<SqlDataReader, TContainer> curry =
        delegate(SqlDataReader reader)
            {
                return pattern(reader, objectMap);
            };

    TContainer item;
    using (SqlConnection connection = new SqlConnection("..."))
    {
        command.Connection = connection;
        item = ExecuteReader(command, curry, errorMap);
        command.Connection = null;
    }

    return item;
}
~~~

To prevent us from needing to use this rather ungainly method very often we can create a couple of curried helper methods which encapsulate our patterns for getting collections and items as follows:

~~~ csharp
internal static Collection<T> ExecuteReaderForCollection<T>(
    SqlCommand command,
    Func<SqlDataReader, T> objectMap,
    Func<SqlException, Exception> errorMap)
{
    return ExecuteReader<T, Collection<T>>(command, ReadCollection, objectMap, errorMap);
}

internal static T ExecuteReaderForItem<T>(
    SqlCommand command,
    Func<SqlDataReader, T> objectMap,
    Func<SqlException, Exception> errorMap)
{
    return ExecuteReader<T, T>(command, ReadItem, objectMap, errorMap);
}
~~~

That's it! All of the complex methods to encapsulate the data access patterns are written, so now we can write the methods to get a single member or multiple members in a very simple way, and we don't have to worry about how it works under the covers. We just provide the command, an object mapping procedure, an error mapping procedure, and return the results, which if you look back at the start of the article was the exact result we were after.

~~~ csharp
public static Collection<Member> GetMembers()
{
    using (SqlCommand command = new SqlCommand("SELECT * FROM Member"))
    {
        return ExecuteReaderForCollection<Member>(command, ReadMember, TranslateError);
    }
}

public static Member GetMember(string name)
{
    using (SqlCommand command = new SqlCommand("SELECT * FROM Member WHERE NAME = @Name"))
    {
        command.Parameters.AddWithValue("@Name", name);
        return ExecuteReaderForItem<Member>(command, ReadMember, TranslateError);
    }
}
~~~

Looks like I'll be re-writing the data access code on Monday.
