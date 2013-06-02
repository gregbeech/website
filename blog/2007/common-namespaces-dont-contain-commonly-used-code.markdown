Date: 2007-09-25  
Tags: .NET, Design Guidelines  

# Common namespaces don't contain commonly used code

One thing that irritates me about software development is peoples apparent obsession with sub-namespaces called `Common` which they use to contain code that is used throughout the rest of the project/solution. `Common` namespaces are a code smell which often means you don't really understand your problem domain and so have lumped a load of largely unrelated classes together into a generic namespace; the other major culprit for this type of bad practice is the `Utility` namespace. But the frustrating point everyone seems to miss is that `Common` namespaces should not contain code that is commonly used with other classes in sibling namespaces.

The example often cited as justification for having a `Common` is that the .NET Framework has the `System.Data.Common` namespace, so is must be a reasonable naming convention. But have a look at what's in there: things like `IDbDataReader`, `IDbConnection` and `IDbCommand`. Now look at your latest `SqlClient` data access code and see if you're using any of those entities, or even whether you've imported `System.Data.Common`. No, thought not. These are not entities that are used alongside the `SqlClient` namespace, they are used instead of it when you want to write generic data access code. They are alternative, not complimentary.

Code that is really common to sub-namespaces is in a namespace further up the hierarchy. Things you actually use with the `System.Data.SqlClient` namespace are in the `System.Data` namespace, for example the `CommandType` and `ConnectionState` enumerations.

So what you really mean when you use a `MyProduct.Area.Common` namespace is that this is the non-specific version of `MyProduct.Area.Something` and `MyProduct.Area.SomethingElse`, and that those sibling namespaces will implement interfaces from the `Common` namespace, but will not usually be used with the objects in it. To use the namespace `Common` in any other way is semantically incorrect.