Date: 2008-06-09  
Tags: C#, Data Access, Functional Programming, Linq  

# A functional approach to data access code, updated for C# 3.0
    
Last year I noted that most data access code follows very similar patterns, and described how [higher order procedures can be used to encapsulate them](/blog/a-functional-approach-to-data-access-code) using C# 2.0, which leads to much simpler and more concise code. Recently I've refined the approach and updated it to use the new C# 3.0 features such as object initializers, lambda expressions, Linq and extension methods, which makes it a truly compelling way to do data access.

Let's assume we've got the same `Member` class as last time, and a couple of helper methods to translate the member from an `IDataRecord` and to translate the error, which for now just returns the error as-is. Our goal will also be the same - to be able execute a `SqlCommand`, passing the translation helper methods into the execute method, and let it take care of producing either a member or a collection of members, or translating any errors that occur.

~~~ csharp
public class Member
{
    public string Name { get; set; }
    public int Age { get; set; }
}

internal static Member TranslateMember(IDataRecord record)
{
    return new Member
        {
            Name = record.GetString(0),
            Age = record.GetInt32(1)
        };
}

internal static Exception TranslateError(SqlException error)
{
    return error;
}
~~~

The core of the new approach is much the same as last time, with an `ExecuteReader` method that takes a procedure to translate the `SqlDataReader` into the result type, and a procedure to translate any exception that occurs into a meaningful one; it also handles opening/closing the connection as necessary because it's pretty obvious that if you're executing a command you want the connection open. The difference to last time is that this is now defined as an extension method on `SqlCommand` so it is available directly on the command object.

~~~ csharp
public static TResult ExecuteReader<TResult>(
    this SqlCommand command,
    Func<SqlDataReader, TResult> resultSelector,
    Func<SqlException, Exception> errorSelector)
{
    TResult result;
    var behaviour = CommandBehavior.Default;
    try
    {
        if (command.Connection.State != ConnectionState.Open)
        {
            command.Connection.Open();
            behaviour = CommandBehavior.CloseConnection;
        }

        using (var reader = command.ExecuteReader(behaviour))
        {
            result = resultSelector(reader);
        }
    }
    catch (SqlException ex)
    {
        if (behaviour == CommandBehavior.CloseConnection &amp;&amp;
            command.Connection.State == ConnectionState.Open)
        {
            command.Connection.Close();
        }

        throw errorSelector(ex);
    }

    return result;
}
~~~

The `TranslateError` method can be passed into this directly, but the `TranslateMember` method can't because it doesn't perform the necessary read operations on the `SqlDataReader` to advance it through the records. Last time I wrote some overly-complex code to create patterns for reading items and collections and then curry those with the translation method; this time I'll write much clearer code using Linq. Unfortunately `SqlDataReader` doesn't implement `IEnumerable<T>`, so to enable Linq queries over it we need to add a sneaky extension method to turn it into one:

~~~ csharp
public static IEnumerable<IDataRecord> AsEnumerable(
    this SqlDataReader reader)
{
    while (reader.Read())
    {
        yield return reader;
    }
}
~~~

Now we can add our extension methods to `SqlCommand` to read and translate the `SqlDataReader` into either a single item or an enumerable list of items. Note that when creating the enumerable list we need to force execution of the query using either `Single` or `ToList` as appropriate, otherwise the query won't actually execute until after the method has returned and the underlying reader is already closed.

~~~ csharp
public static TItem ExecuteItem<TItem>(
    this SqlCommand command,
    Func<IDataRecord, TItem> itemSelector,
    Func<SqlException, Exception> errorSelector)
{
    Func<SqlDataReader, TItem> resultSelector =
        reader => (from record in reader.AsEnumerable()
                   select itemSelector(record)).Single();
    return command.ExecuteReader(resultSelector, errorSelector);
}

public static IEnumerable<TItem> ExecuteEnumerable<TItem>(
    this SqlCommand command,
    Func<IDataRecord, TItem> itemSelector,
    Func<SqlException, Exception> errorSelector)
{
    Func<SqlDataReader, IEnumerable<TItem>> resultSelector =
        reader => (from record in reader.AsEnumerable()
                   select itemSelector(record)).ToList().AsReadOnly();
    return command.ExecuteReader(resultSelector, errorSelector);
}
~~~

That's all the framework code we need to achieve the goal of being able to write data access code without any of the usual boilerplate stuff needed to open connections, advance data readers, or catch exceptions. It's the same result as last time, only now the enhanced methods are available directly from the command object and the code is much more comprehensible. We can now write data access methods like this:

~~~ csharp
public static IEnumerable<Member> GetMembers()
{
    using (var connection = new SqlConnection("..."))
    using (var command = new SqlCommand("Members.GetMembers"))
    {
        command.Type = CommandType.StoredProcedure;
        return command.ExecuteEnumerable<Member>(TranslateMember, TranslateError);
    }
}

public static Member GetMember(string name)
{
    using (var connection = new SqlConnection("..."))
    using (var command = new SqlCommand("Members.GetMemberByName"))
    {
        command.Type = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@Name", name);
        return command.ExecuteItem<Member>(TranslateMember, TranslateError);
    }
}
~~~

(Note that the `<Member>` qualifier is necessary on these methods because the C# 3.0 type inference algorithm doesn't appear to be able to determine the type of `TItem`, even though it should be fairly obvious from the return type of the member translation procedure.)

As a final touch, in our codebase I marked the extension methods on `SqlCommand` and `SqlDataReader` with `DebuggerStepThroughAttribute` because this is really framework code and is typically irrelevant to the user when debugging; usually you want to step directly into your `Translate*` methods without wading through them.