Date: 2009-01-21  
Tags: ASP.NET MVC, REST, Web Services  

# Deserializing the request body into a parameter with ASP.NET MVC
    
After a few weeks of prototyping a RESTful API using both WCF 3.5 and ASP.NET MVC, I came to the conclusion that ASP.NET MVC is by far the superior implementation choice. However, there are some nice features in WCF which ASP.NET MVC doesn't have out of the box; one of those is the ability to treat a parameter that isn't defined in the URI path or query string as the body of the request, and automatically deserialize the body into the parameter value.

So, for example, in WCF you could write the signature for a `POST` method like this, where `Comment` is the request body:

~~~ csharp
[OperationContract]
[WebInvoke(Method = "POST", UriTemplate = "/{id}/Comments")]
public void CreateComment(int id, Comment comment)
{
    // implementation
}
~~~

Whereas ASP.NET MVC you'd have to do it something like this (assume that `DeserializeBody` is a helper method implemented somewhere in the codebase):

~~~ csharp
[ActionName("Comments")]
[AcceptVerbs(HttpVerbs.Post)]
public ActionResult CreateComment(int id)
{
    Comment comment = DeserializeBody<Comment>(this.HttpContext.Request);
    // implementation
}
~~~

This isn't nearly as clean as the WCF approach, it's much less self-documenting in terms of the method signature, and it makes unit testing of the controllers harder because rather than just passing the `Comment` object in, the request context needs to be set up to include a serialized version of the comment. Fortunately, ASP.NET MVC has a lot of easy-to-use extensibility points, so we can do something about it.

ASP.NET MVC routing works differently to WCF, because only the URI path is defined in the route rather than both the path and querystring. As such we don't know which values might be included in the querystring, so it isn't possible to use the same technique of automatically mapping any unlisted parameters to be the request body. Instead we'll do the next best thing and create a custom `RequestBodyAttribute` to mark it with – which also conveniently allows us to hook into the `IModelBinder` framework.

~~~ csharp
[AttributeUsage(AttributeTargets.Parameter)]
public sealed class RequestBodyAttribute : CustomModelBinderAttribute
{
    public override IModelBinder GetBinder()
    {
        return new RequestBodyModelBinder();
    }
}
~~~

The important detail is that the attribute inherits from `CustomModelBinderAttribute` which instructs ASP.NET MVC to call the `GetBinder` method and use our custom binder implementation to map the request to the parameter rather than the normal `DefaultModelBinder`. In our binder we'll check the `Content-Length` header and assume the value is null if it is zero, then check the `Content-Type` header and deserialize the body in the appropriate format.

The binder is as follows, where `ContentFormat` is an enumeration with the values you can see. In the places where things haven't worked out as planned I've put placeholder exceptions with the appropriate HTTP status; you should replace these with either the appropriate type of exception if you're doing error rewriting, or by simply setting the status on the response and ending it.

~~~ csharp
internal sealed class RequestBodyModelBinder : IModelBinder
{
    public ModelBinderResult BindModel(ModelBindingContext bindingContext)
    {
        object body = null;
        if (bindingContext.HttpContext.Request.ContentLength != 0)
        {
            var contentFormat = GetContentFormat(bindingContext);
            XmlObjectSerializer serializer;
            switch (contentFormat)
            {
                case ContentFormat.Json:
                    serializer = new DataContractJsonSerializer(bindingContext.ModelType);
                    break;

                case ContentFormat.Xml:
                    serializer = new DataContractSerializer(bindingContext.ModelType);
                    break;

                case ContentFormat.Unknown:
                    throw new Exception("415 Missing Content Type");

                default:
                    throw new Exception("415 Unsupported Media Type");
            }

            try
            {
                body = serializer.ReadObject(bindingContext.HttpContext.Request.InputStream);
            }
            catch (SerializationException ex)
            {
                throw new Exception("400 Bad Request", ex);
            }
        }

        return new ModelBinderResult(body);
    }

    private static ContentFormat GetContentFormat(RequestContext bindingContext)
    {
        var contentType = bindingContext.HttpContext.Request.ContentType;
        if (string.IsNullOrEmpty(contentType))
        {
            return ContentFormat.Unknown;
        }
       
        if (contentType.Contains("application/json"))
        {
            return ContentFormat.Json;
        }

        if (contentType.Contains("application/xml") || contentType.Contains("text/xml"))
        {
            return ContentFormat.Xml;
        }

        return ContentFormat.Other;
    }
}
~~~

Now we can write our ASP.NET MVC method signature in a very similar way to the WCF one, and have the request body transparently deserialized and passed in as a parameter just by putting an attribute on it.

~~~ csharp
[ActionName("Comments")]
[AcceptVerbs(HttpVerbs.Post)]
public ActionResult CreateComment(int id, [RequestBody] Comment comment)
{
    // implementation
}
~~~