Date: 2008-07-10  
Tags: Architecture, Data Access  

# Object-Relational Mapping frameworks won't improve your timescales
    
On every database-backed project I've worked on, which is quite a few ranging from 4 to over 50 developers, the number of people working on the database is relatively small. Typically in a three-tier application the ratio of developers on UI:services:data is around 5:2:1 because high quality user interface development requires a lot of work, and it is far more time consuming to display data in an attractive way than it is to retrieve or save it. At [blinkbox](http://www.blinkbox.com) the ratio is even higher at about 8:2:1.

This means that even if you assume that the services/data teams spend all their time writing data access code, and you could improve the productivity there, you still won't save a huge amount of development time because your main overhead is in the user interface team, and the data access method doesn't affect them too much (or shouldn't if you've designed your API properly).

In reality services/data don't spend all their time writing data access code or stored procedures. I've spent all of the last year leading our services team and working closely with the data team. As a rough estimate, I reckon I spend about 5% of my time writing data access code and the rest on thinking through scenarios, designing and creating higher level APIs, tuning caching, implementing security, implementing logging, adding performance counters, and troubleshooting issues that have nothing to do with data access because we use [a very thin layer on top of `SqlClient`](/blog/a-functional-approach-to-data-access-code-updated-for-c-sharp-3-0) which has no surprising side effects. The database guys probably spend about 20% of their time writing stored procedures, and the rest on schema refactoring (which is only possible due to the stored procedure layer), data migration, reporting, performance optimisation, and asynchronous data publishing

Which means that even if you reduce all the time spent on data access code time to zero, you could only save about (0.25 * 0.05) + (0.13 * 0.20) = 0.038 = 3.8% of your overall development time, which really isn't significant enough to worry about. You'll lose more time than that from hangovers due to office parties.

Any improvement in productivity in data access code will have a negligible effect on the timescales of a project, so don't buy into Object-Relational Mapping frameworks on the premise that they will save you time, because even if they could the time just isn't there to save.