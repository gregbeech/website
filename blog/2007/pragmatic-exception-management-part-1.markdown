Date: 2007-06-06    
Tags: .NET, Architecture, Exceptions, Monitoring, Pragmatism 

# Pragmatic exception management, part 1

At [Netstore](http://www.netstore.co.uk/) we've spent quite some time over the last six months implementing a custom diagnostics and exception management framework. You might think this is a sign of the Not Invented Here syndrome, which I guess it is, but believe me we wouldn't have spent the equivalent of a fortune in consulting days building it unless we thought there was a good reason. The trouble is, after evaluating all the other frameworks such as the Enterprise Library, we just couldn't find anything that met our requirements.

Note that our requirements relate to our market sector which is server applications for medium to large companies and local government. If you're writing applications for home use or smaller companies then not all of this thinking will not apply to you - it isn't intended to - but you may find some truisms anyway.

## What companies want from an exception management framework

The majority of medium and large sized companies run automated monitoring applications such as System Center Operations Manager which raise alerts to operators when things go wrong with servers and applications. You only need to look at Microsoft's mandate that all their server products must be shipped with a management pack to realise the importance of these monitoring applications to customers. They're what keep systems running. They're what keep companies running.

The obvious conclusion is that what companies want from an exception management framework is for alerts to be raised to their operators when particular exceptions occur, and ideally be able to associate troubleshooting information with those alerts. They don't care how this happens, they just want it to happen.

If we're going to raise these alerts, we need to look at how monitoring applications get most of the application data they operate on. Examining the management packs provided with products like SQL Server and BizTalk shows that there are are two main places:

- The Windows Event Log
- Performance Counters

Not WMI sinks. Not custom databases. Not log files. Not XML files. Not message queues. In fact, none of the esoteric places that frameworks like the Enterprise Library encourage you to write to. Just the plain boring old Windows Event Log and performance counters. And while you may choose to increment performance counters when particular exceptions occur, the majority of the time these are concerned with other types of operational information such as throughput and latency. So really that only leaves us with one place to put information about exceptions: the Event Log.

When you think about it, this is the perfect place to put the information. It exists in every version of Windows your .NET application is capable of running on and every version uses the exact same APIs which are available via WMI, Scripting, VBA, Win32 and .NET. You can differentiate between events easily and programmatically based on their source, event ID and severity. You can categorise them, you can add localizable text to them, and you can attach binary data to them for additional diagnostic information.

So we've solved the problem of getting the data to the management server; all exceptions will be published to the event log. How we convert these into alerts is a problem yet to be solved, but hopefully when we look at it from the other side of the coin the answer will drop out.

## What developers want from an exception management framework

Developers don't like writing exception management code. It's what [Raymond Chen would refer to as a tax](http://blogs.msdn.com/oldnewthing/archive/2005/08/22/454487.aspx) - something that has to be done for the overall good rather than because it particularly benefits your feature of the product. So what developers want from an exception management framework falls mainly into two categories: simplicity and productivity.

### Simplicity

As a developer you don't want to write exception management code, and you don't want to spent time learning about the framework either. If you can spend less than twenty minutes learning how the exception management framework works and then get back to more interesting things like writing real code or learning about Windows Workflow then it's a lot less painful than if you have to spend a full day reading documentation, exploring deep class hierarchies, and configuring configuration files.

Another simplicity factor is reducing the number of dependencies - every extra assembly we have to deploy is an extra assembly we have to spend time and effort on versioning. I accept that I may have to reference one DLL but really that's all I want. I don't want another ten associated DLLs covering things like loading configuration sections that I don't want to use anyway: All I want to do is publish an exception, why do I need a configuration file? Or a configuration file that points to a configuration file? Configuration files are just another thing we have to deploy and keep in sync.

### Productivity

One of the things that developers hate about creating custom exceptions is all the boiler plate code. Sure, with ReSharper you can use a template to put in the basic class structure with the regulation four constructors, but if you want to add any custom properties to the exception there's the pain of adding in custom serialization and remembering just which security attribute you have to apply to GetObjectData. And then you have to remember to localise the default message. If our exception management framework could reduce the time it takes to write this code, maybe by generating it, then it would increase productivity in the same sort of way as generic collections did.

And how about documentation? We always have to write documentation for operators about which events may be raised in the Event Log by the solution and the troubleshooting information associated with them. What if we could auto-generate this documentation as part of the exception management framework? Wait - scratch that! What if we could generate a management pack that could be imported directly into the management server? Then we wouldn't have to document it at all! Another productivity gain, and one in the area developers hate even more than exception management.

## From observations to requirements

Note that we haven't developed anything yet. We haven't designed anything yet. All we've done is look at the things that the interested parties want from an exception management framework. From these, we can now create a set of high level requirements:

### Functional

- Publish all exceptions to the Event Log
- No configuration files required
- Auto-generate boiler plate exception code from a concise metadata format
    - Generated code should be FxCop compliant
    - Generated code should be fully commented to allow MSDN-style documentation generation
- Auto-generate management packs that raise appropriate alerts from the same metadata
    - Be extensible to different types of monitoring application

### Non-Functional

- Framework can be learned in less than twenty minutes (by a proficient .NET developer)
- Reduce solution development time below what it would have been without the framework

That wasn't so complex was it? All it took was a few architects and developers discussing their real world experiences over some lunch, and we have a set of requirements that satisfies everyone. But see if you can find an exception management framework that meets them. We couldn't. Not even close. Which is why, next time, we'll be looking at how this can be implemented.