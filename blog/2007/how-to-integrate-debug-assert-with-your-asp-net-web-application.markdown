Date: 2007-09-04  
Tags: ASP.NET, ASP.NET MVC, Code Contracts, Code Style, Debugging

#How to integrate Debug.Assert with your ASP.NET web application

In the last two entries about `Debug.Assert` I looked at [why you should use it document your assumptions](/blog/document-your-assumptions-with-debug-assert-instead-of-comments), and [how you can integrate it with your test framework](/blog/how-to-integrate-debug-assert-with-your-unit-test-framework) so that tests fail when any of the assertions fail. This time I'll show you how you can use a similar technique to integrate it with your ASP.NET applications to replace the default behaviours with a web page detailing the failure.

ASP.NET has two configurable behaviours with regard to `Debug.Assert`; if the `assertuienabled` configuration setting is true then it displays a modal dialog box, otherwise it writes an entry to the event log. Neither of these is ideal because typically ASP.NET applications run under a non-interactive account so there would be nobody to see (or close) the modal dialogs, and entries to the event log can be overlooked or ignored too easily.

To display the failure web page, we can override the `Fail` method of the `DefaultTraceListener`. Within the method we get the information about the failure, access the current `HttpResponse`, and write the results of the assertion failure to that. A sample ASP.NET trace listener is shown below which shows the basic information such as the error message and stack trace, though of course you can modify this to include anything else that's useful to you:

~~~ csharp
public class AspNetTraceListener : DefaultTraceListener
{
    public override void Fail(string message, string detailMessage)
    {
        HttpContext context = HttpContext.Current;
        if (context != null)
        {
            // get the stack trace - we are four frames from the assert
            StackTrace stack = new StackTrace(4);
            string title = "Debug.Assert Failed: " + message;

            // clear the response and set the new contant type
            context.Response.Clear();
            context.Response.ContentType = "text/html";

            // write the error to the output stream             
            HtmlTextWriter writer = new HtmlTextWriter(context.Response.Output);
            writer.RenderBeginTag(HtmlTextWriterTag.Html);

            writer.RenderBeginTag(HtmlTextWriterTag.Head);
            writer.RenderBeginTag(HtmlTextWriterTag.Title);
            writer.WriteEncodedText(title);
            writer.RenderEndTag();
            writer.RenderBeginTag(HtmlTextWriterTag.Style);
            writer.WriteLine("body { font-family: Tahoma, sans-serif; }");
            writer.WriteLine("h1 { color: red; size: 2.5em; }");
            writer.RenderEndTag();
            writer.RenderEndTag();

            writer.RenderBeginTag(HtmlTextWriterTag.Body);
            writer.RenderBeginTag(HtmlTextWriterTag.H1);
            writer.WriteEncodedText(title);
            writer.RenderEndTag();

            if (!string.IsNullOrEmpty(detailMessage))
            {
                writer.RenderBeginTag(HtmlTextWriterTag.P);
                writer.WriteEncodedText(detailMessage);
                writer.RenderEndTag();
            }

            writer.RenderBeginTag(HtmlTextWriterTag.Pre);
            writer.WriteEncodedText(stack.ToString());
            writer.RenderEndTag();
            writer.RenderEndTag();

            writer.RenderEndTag();

            // terminate the response
            context.Response.End();
        }
        else
        {
            // no http context available so pass to base method
            base.Fail(message, detailMessage);
        }
    }
}
~~~

With the trace listener written the following configuration needs to be inserted into the Web.config file, though you will need to put in appropriate values for the namespace and assembly, as well as the version, culture and public key token attributes if your trace listener assembly is in the Global Assembly Cache.

~~~ xml
<system.diagnostics>
  <assert assertuienabled="false"/>
  <trace autoflush="true" indentsize="0">
    <listeners>
      <clear/>
      <add name="AspNet" type="MyAspNetApp.AspNetTraceListener, MyAspNetApp"/>
    </listeners>
  </trace>
</system.diagnostics>
~~~

An important detail here is that any current trace listeners are cleared. This is because ASP.NET configures the `DefaultTraceListener` by default, and as the new ASP.NET trace listener also passes the trace output through to the underlying Win32 trace API leaving it in there would result in duplicate trace message output.

That's it for this series about `Debug.Assert`; hopefully if you weren't convinced about using it before then you've now seen how it can help you to ensure your code is correct, and that it can be easily integrated with any type of application to display failures however you like.