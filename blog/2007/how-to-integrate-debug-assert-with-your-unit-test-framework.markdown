Date: 2007-08-29  
Tags: Code Contracts, Code Style, Debugging, Testing

# How to integrate Debug.Assert with your unit test framework
    
In the [last entry about `Debug.Assert`](/blog/document-your-assumptions-with-debug-assert-instead-of-comments) I stated that you should document your assumptions using `Debug.Assert` so that the code fails immediately if any of your assumptions are incorrect. This is really useful when you're doing ad-hoc testing, or you are writing and running your own unit tests to find any bugs, but can cause problems when running automated regression passes (for example on the build server) because a `Debug.Assert` failure can pop up a modal dialog which can make the process appear to hang. But before you go and remove all those `Debug.Assert` statements to prevent this, lets have a look how we can solve the problem by delving into how it works.

A bit of research on MSDN shows that when `Debug.Assert` is called, it checks the condition and then passes through to `Debug.Fail` if the condition is true. However `Debug.Fail` is not what throws up the modal dialog; `Debug.Fail` calls the `TraceListener.Fail` method on each of the trace listeners that is configured for the application, and it is the [`DefaultTraceListener` that shows the modal dialog](http://msdn2.microsoft.com/en-us/library/kxadhf3k.aspx). To prevent the modal dialog we can therefore remove the default trace listener using configuration for the tests:

~~~ xml
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <system.diagnostics>
    <trace>
      <listeners>
        <clear/>
      </listeners>
    </trace>
  </system.diagnostics>
</configuration>
~~~

The problem with this is that it has effectively disabled all of our `Debug.Assert` statements, so they are no longer any more effective than the comments they replaced. In an ideal world, we'd like to prevent that modal dialog from popping up, but still cause the code (and associated tests) to fail with the message that the assert statement would have printed. I'm sure you can see where this is going by now.

As the `DefaultTraceListener` provides most of the functionality we want, such as redirecting the trace output to the underlying Win32 tracing API which is picked up by most unit test hosts for reporting purposes, we can derive from that and implement our own `Fail` method which instead of creating a modal dialog calls the test fail method for whichever testing framework we are using. Note that `Fail(string)` passes through to `Fail(string, string)` so we only need to override the latter. The following code shows a test trace listener that works with either MSTest or NUnit, depending on which namespace you import:

~~~ csharp
public class TestTraceListener : DefaultTraceListener
{
    public override void Fail(string message, string detailMessage)
    {
        if (!string.IsNullOrEmpty(detailMessage))
        {
            message += Environment.NewLine + detailMessage;
        }

        Assert.Fail(message);
    }
}
~~~

The configuration is then changed to add this listener, similarly to below though you will need to put in appropriate values for the namespace and assembly, as well as the version, culture and public key token attributes if your trace listener assembly is in the Global Assembly Cache.

~~~ xml
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <system.diagnostics>
    <trace>
      <listeners>
        <clear/>
        <add name="Test" type="TestAssembly.TestTraceListener, TestAssembly"/>
      </listeners>
    </trace>
  </system.diagnostics>
</configuration>
~~~

Now when any of your `Debug.Assert` statements fail, the test will fail with the message that was passed to `Debug.Assert`, and a stack trace showing where in the code the failure occurred. This prevents your regression passes from hanging, and gives you a head start in diagnosing the causes of the failures.