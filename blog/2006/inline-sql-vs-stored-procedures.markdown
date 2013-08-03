Date: 2006-10-01  
Status: Published  
Tags: Data Access, SQL Server  

# Inline SQL vs stored procedures
    
I always use stored procedures for data access because I believe that in a well designed system they are the most maintainable solution. However, I've been hearing a lot of support for inline SQL recently, so I figured it's time for an objective look at the advantages and disadvantages of each.

## Performance

Performance is often quoted as an important reason for using stored procedures. I've lost count of the number of people I've heard say that stored procedures will run quicker as the execution plan for the query can be pre-created and cached by the database. This may have been true in older versions of SQL Server, however nowadays it is [a lot more complex than that](http://www.microsoft.com/technet/prodtechnol/sql/2005/recomp.mspx). As a very high level summary though, if you build your query through string concatenation then there is a good chance that the query plan will not be reused and so it is probably correct to say that it will run more slowly, however if you write a query with inline parameters then there is a good chance that the plan will be reused and so while you may take a performance hit on the first execution, after that there shouldn't be anything in it.

The other point people make about performance is that you have less network traffic as the query text that needs to be sent is smaller. Again this strikes me as something that was probably more important a number of years back. If you're using inline SQL it's unlikely that it will be a huge query, and over modern 100-megabit or gigabit networks it won't make an awful lot of difference whether you transmit 1 or 2 kilobytes of extra data. A little difference, yes. But enough to worry about? Probably not. I've performance tuned a number of systems and network bandwidth between the application tier and the SQL Server has never been a limiting factor.

## Security

Stored procedures can be locked down so that users can only execute those that they have permissions on, which allows control at a much more granular level than permissions at table level. When this is done, the privilege to perform direct operations on the tables can be removed from the users so that they can only access data through the subset of stored procedures they have permission on. Now if an account becomes compromised the attacker still cannot execute arbitrary commands against the data, and can still only access a limited subset of data.

This type of locking down can really improve the security of systems. But - and here's the big but - for this type of security to be useful the database and application has to be designed with it in mind, and the locking down actually has to be done! I've worked on a fair number of enterprise class systems, and worked with some of the best people in the country, and often the database is not locked down in this way. My guess is that in over 90% of cases it never happens, so in 90% of cases the permissions are not much more lax for inline SQL than stored procedures.

The other security aspect is resistance to SQL injection attacks, where a user can enter malicious code in one of your input fields in order to execute arbitrary commands against the database. If you build your SQL statements using string concatenation you are highly susceptible to SQL injection. Consider you're building up the following statement as part of a search form:

~~~ csharp
string sql = "SELECT * FROM Users WHERE FirstName = '" + firstNameInput.Text + "'";
~~~

No problem there right? But what if I decide to enter the following as my first name....

~~~ csharp
' OR FirstName LIKE '%' JOIN SELECT * FROM CreditCards ON CreditCards.UserId = Users.UserId; --
~~~

If you're using a data grid to display the results, I've just got all of the credit card details for your users (of course, it still shouldn't be useful as you've encrypted them - right? - but you get the principle). Generally it isn't quite this simple as I'd have to discover details of the database schema (which can be done with specially constructed statements) and I might have to modify the results set to get the columns I want, but with enough persistence this type of thing is possible.

If you're using parameterised inline SQL however, then SQL injection attacks are no more of an issue than when using stored procedures. My malformed parameter value will just be encoded as a plain string in exactly the same way as it would be when passed to a stored procedure, and won't match any users ([unless they have a very strange first name](http://xkcd.com/327/)!).</p>

## Maintainability

Let me draw parallels between databases and objects. Tables in databases are like private fields; they provide the storage of state but should not be externally visible as they are an implementation detail. Stored procedures are like methods; you pass in parameters and get results, and may be internally or externally visible. Views are like properties; they provide you with a view of the private fields but are abstracted from them, and may be internally or externally visible.

Why did I bother with that? Well most people accept that defining a public interface for a class based on its methods and properties is a good thing, and leaving the implementation details private so that the class may be optimised in the future is also a good thing. So how are databases any different? If you access tables directly using inline SQL, you are accessing the private implementation details, and making it very hard to ever change or optimise the underlying database. "But this never happens" I hear you cry. No? Well how about the big changes to the system tables in SQL Server 2005? Or a real world case I've seen where a Customer table needed to be broken out into seperate Customer and Address tables so multiple addresses could be supported, but it couldn't be done as there were literally hundreds of inline SQL statements accessing the Customer table directly?

By using stored procedures and views, you abstract the code from the underlying database structure, and enable yourself to make changes to optimise it. One of the really useful things about using stored procedures is that there are a number of dependency modelling tools which can work out from a database all dependency and call graphs from any object to another - try analysing your inline SQL statements using one of these! Of course one point I've implicitly raised here is that if your inline SQL statements are using only views as their data source then they are as maintainable as stored procedures.

Another maintainability benefit of stored procedures is actually writing and modifying them - with inline SQL you get no synax highlighting or verification, whereas when you write or modify stored procedures you get excellent tools which will help you construct the query, and you can debug the query in the editor without having to compile and run your code.

I said this was going to be objective, so now let's have a look at the potential down sides of stored procedures. I'm sure we've all seen databases where the stored procedures contain large amounts of business logic, or where there are stored procedures with the same name, but with _2, _3 suffixes, that do somewhat different things. These are bad, and can make the database less transparent than it should be. However, these problems are mitigated by using the golden rule of API design, which is that one stored procedure does one job, and it is named in such a way that makes its purpose clear. Using schema seperation as in SQL Server 2005 to give namespaces to stored procedures, we can create elegantly named and obvious stored procedures, such as Customer.CreateCustomer or Customer.UpdateCustomer.

Unmaintainable stored procedures are as much to do with your .NET API design as with the fact that they are stored procedures. In a well designed system, a customer will be an object, and there will be a central point where it is retrieved and updated in the database. Here there is no need for badly named or multiple stored procedures as they can often be named using the namespace of the type of entity they are acting on, and the same name as the method being called in the .NET API. So using stored procedures requires more discipline that inline SQL, but is this really a bad thing?

## Development speed

Now here I think we're getting to the point that most proponents of inline SQL will bring up - that it's quicker to write inline SQL than stored procedures. This point assumes you are building statements using string concatenation, as if you use parameterised inline SQL then you still have to write much the same query and you still have to build all the parameter objects for the command, and I have to concede that it is quicker to build a basic concatenated string than a parameterised command.

But does that mean it speeds up the development process over all?

Well, what happens when the person puts an apostrophe in the input field? You've got to remember to manually encode every single input to the statement. Even this could take as much time as building the parameters. And what about dates, have you correctly reformatted the input date string so that it is correct irrespective of the database culture? And did you remember the circumstances under which you need to surround the dates with `#` rather than `'`? And did you accidentally surround a number in quotes? Or a character type without quotes?

Any of these mistakes will result in bugs, some of which may not be found until much later in the development process. They will take time to debug and find and fix the issue, and you may need to redeploy the code to whatever rigs you're using. Can you do this quicker than building a parameterised command? No I thought not. And remember, it's much cheaper to get things right in the first place than it is to fix things up later in the development process.

## Conclusion

In all cases, building inline SQL statements using string concatenation is a bad idea. It gives you the greatest chance of poor performance, is prone to SQL injection attacks, and makes it difficult to perform maintenance on the underlying database. In addition, any time you might save by writing shorter code that doesn't create parameter objects will almost certainly be lost when you're debugging issues with it later on.

From the aspects of performance and development speed, there doesn't appear to be a lot to choose between parameterised inline SQL and stored procedures. Inline SQL is less secure due to compromised accounts being able to directly access tables rather than only being able to perform authorised operations on them (all be it with unauthorised parameters). However when it comes to maintainability that's when we hit the real meat; the fact that the database team can define a public interface of stored procedures, and then internally optimise the storage - linked with dependency modelling tools to let them see exactly what might be affected - is enough for me. The other advantages are just icing on the cake.

Using stored procedures can help to ensure you get the best possible performance, reduces the attack surface, increases maintainability, and improves overall development speed.

Don't use inline SQL statements.