Date: 2007-06-15  
Status: Published  
Tags: .NET, Architecture, Exceptions, Monitoring, Pragmatism  

# Pragmatic exception management, part 2
    
In [the first entry in this series](/blog/pragmatic-exception-management-part-1) I looked at what medium-to-large-companies and developers want from an exception management framework, and derived some requirements from this. To recap, these are the high level requirements, which you'll note that no current framework is even close to meeting:

1. Publish all exceptions to the Event Log
2. No configuration files required
3. Auto-generate boiler plate exception code from a concise metadata format
4. Auto-generate management packs that raise appropriate alerts from the same metadata
5. Framework can be learned in less than twenty minutes (by a proficient .NET developer)
6. Reduce solution development time below what it would have been without the framework

Now we'll take the requirements into the design phase and see how these could be translated to a real exception management framework that people actually want to use.

Lets start with publishing the exceptions themselves. The .NET Framework is object oriented, so when you want to do something with an object, you look for a method on that object to do it. `String.Format()`, `DateTime.Add()`, `Object.ToString()`, `Exception.Publish()`. Oops. Did we just define the obvious way to publish an exception? Great, so what we need is a base class that implements a Publish method. This method can be hard-coded to write the exceptions to the Event Log, fulfilling criteria #1.

To make each individual type of exception easily recognisable to the monitoring application, the easiest way is to associate a particular event ID with each exception type. So if the exception is going to publish itself to the Event Log with a distinct event ID, then [the obvious place to store the event ID is as a member of the exception](/blog/why-do-we-have-different-types-of-exception). We'll also store the other details like category and severity. As all the information required to publish an exception is contained within it, we have fulfilled criteria #2 of not needing any configuration files.

For #3 we're looking for a flexible, concise metadata format, which puts XML squarely in the frame. Details such as the name, event ID, category, severity etc. can be defined in here, as can custom properties. To allow the XML to be easily written we can install a schema for IntelliSense, and to allow easy code generation we can register a Visual Studio custom tool which will regenerate the code every time the XML file is saved (in much the same way as the strongly typed resource generator).

It's a little known fact that MOM/SCOM define an XML storage format for their management packs. So with an XSLT stylesheet we could transform our exception definitions into a MOM/SCOM XML file and then convert that to a full blown management pack. If we extend the XML format defined for #3 to allow space for troubleshooting info and definitions of alerts then we've pretty much met requirement #4. For completeness lets also have an MSBuild task so we can generate the pack as part of the build process.

Learning how to publish exceptions is simply a matter of learning that there is a Publish method on all publishable exceptions. The side effect of this is, of course, that exceptions defined outside this framework cannot be published. If you think about it this is a good thing, as these exceptions cannot be picked up easily by the monitoring application and have no troubleshooting information associated with them, so we're enforcing the good practice of giving an exception meaning before publishing it by wrapping it in a more detailed one.

As for learning how to generate the exceptions themselves, the XML format will have auto-complete capability due to the IntelliSense schema, so as long as that's a fairly straightforward schema any competent developer should have no trouble picking it up. Then just enter a custom tool name and the exceptions get generated. Generating the management pack will take barely 5 minutes to add a custom MSBuild task to the daily build process.

So I think we've met requirement #5 of learning the framework in less than twenty minutes: Call a Publish method, write some XML, and add a build task. How about #6 though? Well based on the XML format we have defined you can define an exception with troubleshooting information in five lines of XML - and two of those are just closing tags! This will generate around fifty lines of fully documented and localised C# (or VB.NET) plus a management pack. So yes, it's an awful lot quicker to use the framework than not to use it.

Convinced?

Internally we used the first version of the framework on a couple of projects while we were developing it, to help us work out the implementation details and lower level requirements. We then pretty much re-wrote the whole lot to simplify some things, improve some things, and put full CodeDom support through the code generation so it's cross-language capable. The feedback has been overwhelmingly positive, particularly regarding the management pack generation, and it's already in production providing the diagnostics for mission critical solutions.

What do you think though? Would you be prepared to give up the ultra-flexible capabilities of something like the Enterprise Library for a pared down and almost entirely non-configurable framework like this? Let me know as we're currently trying to decide whether to keep this as an internal toolset for us and our customers, or whether to release it into the wild.