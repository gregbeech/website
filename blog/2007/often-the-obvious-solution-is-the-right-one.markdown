Date: 25 Apr 2007  
Tags: Design Guidelines, Exceptions, Rants

# Often the obvious solution is the right one
    
The rule "don't use exceptions for flow control" is one that should rarely be broken, partly because it makes the code much less readable, and partly because it will seriously compromise the performance of a solution. To give you an idea of the sort of impact exceptions can have, one website I tuned threw an exception if an item wasn't contained in its custom cache, which was often; by simply changing it to return `null` I vastly simplified the code and saw an eightfold increase in performance (based on concurrent users with average request time under threshold).

However, sometimes it is possible to take this rule too far. Take, for example, the simple action of attempting to open a file which has a chance of being inaccessible either due to permissions, or because another user has it exclusively open. I have previously seen people who are attempting to avoid exceptions at all cost propose solutions which would do things such as check the ACL for the file against the currently logged on user, then enumerate the handles held open by other processes to see if the file was locked. Quite apart from the fact that the latter check would require administrator/debugger privileges, it's subject to a race condition: between when you complete this check and when you open the file, another user or process may take an exclusive lock on the file.

Because of this race condition, you're going to have to write the code to handle failures anyway, and in the case of failure all your checks to attempt to avoid the failure will just have meant it took longer. They'll also slow down the (presumably) more common case where opening the file succeeded. You already have the best solution, and it was just to write no extra code: The best way to see whether you can open a file is to try to open the file.

There are numerous other places where this same logic applies. The best way to see if you can connect to a database is to try to connect to the database. The best way to see if you can create or open a named mutex is to try to create or open the mutex. In fact, when attempting to access any resource which is external to or not exclusively controlled by your application, the best way to see if you can do something with it is to try to do whatever you wanted to do.

Just do things the simple way. Take the free lunch. It's the last one you'll get for a while.