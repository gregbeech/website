Date: 2013-05-10   
Tags: Caching, HTTP, REST  

# RESTful API Design: The Fundamentals

TODO: Intro

## Resources and Representations

One of the most frequently confused aspects of REST is the difference between a resource and a representation. A resource is a noun, for example a book or a person, but a representation is a particular way of looking at a noun using a specific JSON/XML/HTML/etc. structure. In other words, a single resource can have a number of different representations, and a number of different representations can all represent the same resource.

Mapping this to HTTP, the resource being acted upon is defined by the URL. For example the book "Ultimatum" by Simon Kernick might be located at:

    /catalogue/books/9781448136698

The representation that is returned is determined by HTTP content negotiation using the Accept header, for example the following header would indicate that the caller wants a JSON response:

    Accept: application/json

However, using a generic markup language media type is a sign of another commonly confused aspect of REST: the difference between schema and markup language. The schema defines the structure of the data in the representation, and this schema is then encoded using a markup language. Conflating the two means that it's impossible to version the schema because you're only communicating information to the client about the markup language, not the schema of the data that it is encoding, meaning you cannot make breaking changes to your schema when requirements change. To solve this problem we define our own media type, for example:

    Accept: application/vnd.example.data.v1+json

The `vnd.` part means this is a vendor-specific media type as opposed to one registered with IANA, the `.v1` part allows us to have different versions of the schema, and the `+json` part indicates the markup language used to encode the schema. This means we can easily modify the media type to move to a new schema (`.v2`) or to allow us to encode the schema in a different markup language (`+xml`, `+html`).

It should become apparent from this why some commonly used means of versioning or requesting a particular markup type in APIs which claim to be RESTful are invalid, and make them anything but:

* Specifying the version of the representation in the URL path (e.g. `/v1/catalogue/books/9781448136698`, `/v2/catalogue/books/9781448136698`) implies that there are two different resources, when in fact there are two representations of a single resource.
* Specifying the markup language in the URL query(e.g. `/catalogue/books/9781448136698?format=json`, `/catalogue/books/9781448136698?format=xml`) implies that there are two different resources (as the query string forms part of the resource identity; more on this later) and also tends to preclude versioning of representation schema.

## URLs

When most people thing of REST, they think about nice pretty semantic URLs. However, from a RESTful standpoint, the structure of URLs doesn't matter at all. A semantic URL like this...

    /catalogue/books/9781448136698

...is no more correct than one like this...

    /bbd54f83026d454b991bb2cf01c185a4

...as long as the URL represents a particular resource. Semantic URLs are nice for people as it helps us to structure our thinking, but it's nothing to do with REST.

Another point often confused is the status of query strings - and with good reason. Originally the query was defined as information to be interpreted by the resource identified by the path, but [RFC 3986 redefined this](http://tools.ietf.org/html/rfc3986#section-3.4) so that the query forms part of the resource identifier. This means that the following URL...

    `/catalogue/books?offset=50&count=25`

...should be interpreted as "The book list resource that spans items 50-74" as opposed to "Items 50-74 from within the book list resource". In other words, the result of a URL with a query is a resource in its own right, not a subset of the resource defined by the path. This is a subtle distinction, but can be important when thinking about semantics.

## Methods

The most important HTTP methods used in REST and their usual semantics are:

* `GET` - Gets the resource at a URL.
* `PUT` (to non-existent URL) - Creates a resource at the URL, and returns the resource.
* `PUT` (to existing URL) - Updates the resource at the URL in its entirety, and returns the resource.
* `POST` - Creates a resource (typically appending it to a list) and returning the resource.
* `DELETE` - Deletes the resource at a URL, and returns nothing.

Note that these descriptions are guidelines but there is some room for flexibility allowed by the HTTP specification. For example:

* `DELETE` may be used as a 'reset' method by interpreting it as having deleted the old entity and immediately created a default replacement one, which it could return as `DELETE`s are permitted to return an entity-body.
* `POST` may be used to create an entity at a known URL when the creation is complex, e.g. the submitted entity is used as the input for processing that results in the creation of the result entity.

Some other methods that may be useful are:

* `HEAD` - Checks for the existence of a resource at a URL, but does not return it.
* `OPTIONS` - May be used to provide metadata about the resource at a URL (e.g. what methods it supports, what parameters it accepts).
* `PATCH` - Updates the resource at the URL by applying a set of changes, and returns the resource. Defined in [RFC 5789](https://tools.ietf.org/html/rfc5789).

## Hypertext



## Caching

Caching is an intrinsic part of REST, and an intrinsic part of the HTTP protocol, so needs to be treated as a first class citizen when designing a RESTful API; doing so also allows you to make significant performance gains. The [rules for caching in HTTP are extremely complex](/blog/an-incomplete-and-probably-incorrect-guide-to-http-caching) but it's worth covering the general principles here.

The two main factors that contribute to how cacheable a response is are:

* Scope - How widely can the response be cached? This can vary from not at all to publicly cacheable (i.e. allowing a CDN or any internet proxy to cache it).
* Lifetime - How long can the response be cached for? This can vary from no time at all to forever (note: a year is the maximum specifiable, but some caches will treat this as forever).

The server is responsible for declaring these using a combination of the `Cache-Control`, `Date` and `Expires` headers (plus `Pragma` for backwards compatibility with HTTP 1.0 caches). However there are some restrictions which may be introduced by the protocol - for example HTTPS responses are never publicly cacheable because intermediate servers cannot decrypt the contents of the response.

For the best performance, resources should be cached in the widest scope possible for the longest time possible. If a resource is publicly cacheable then the API can be fronted by a CDN, which means that for subsequent client requests the API origin server won't even be hit, reducing both response time and server load; if you're lucky it may also get cached by intermediate proxies or edge servers. If a resource is not publicly cacheable then all clients must hit the API origin server for every request.

However, the scope and lifetime of a response is the lowest common denominator of any piece of data it contains. For example, book metadata may rarely change so could be declared as being publicly cacheable for a week. If, to reduce the number of requests, pricing information is introduced into the representation and this has a contractual maximum change period of four hours, then the entire book can now only be cached for four hours. If user-specific data such as whether the book has been purchased is introduced into the representation, then the entire book representation becomes user-specific and cannot be cached publicly.

Designing a performant RESTful API requires careful balancing of response scope and lifetime against the number of separate HTTP calls, and the expected levels of parallelism of clients need to be considered. In general terms you should avoid aggregating entities with different scopes or lifetimes into a resource unless performance testing has demonstrated a real-world problem.

## Authentication and Authorisation

While not strictly a RESTful principle, most RESTful APIs will require authorisation to access some endpoints so it's worth covering the basics here. The terms "authentication" and "authorisation" are frequently interchanged, but they are quite separate concepts:

* Authentication: Exchange of credentials for a set of claims related to your identity (typically stored in a token).
* Authorisation: Evaluation of claims to determine whether you have permission to perform an action.

Generally authentication will not be handled by a RESTful API; the process is intrinsically procedural, often stateful, and involves sequences of varying complexity depending on the protocol. A common example of authentication is signing into a website where you exchange an email/password credential for a bearer token (as a cookie).

However, RESTful APIs often perform authorisation. This is typically broken down into two phases:

Processing any authentication tokens in the request and construction of a resultant claim set (typically stored in a principal).
Evaluation of the claim set against the requirements for the endpoint. If the user does not meet the requirements for the end point, the "identity" claim is missing (i.e. the user is not signed in), and signing in could result in the user being allowed access then return 401 Unauthorized. Otherwise, if either the is already signed in, or signing in could not possibly resolve the lack of permission (e.g. the endpoint is GeoIP restricted so depends on context not identity), then return 403 Forbidden.

In terms of passing authorisation tokens to a RESTful API then the only semantically correct option is in the headers; as previously discussed it is not valid to put it in the URL because the token does not form part of the identity of the resource, even if information in the token may be used to select a particular resource. Typically if the token is a cookie it will be passed in the Cookie header, otherwise it will be passed in the Authorization header. Note that if using bearer tokens (e.g. cookies) then the endpoint must use transport layer security to protect the token (i.e. HTTPS).

As a sidebar to this section, forget device authorisation or encrypted API keys and the like as a concept. There was a fad for this a few years back, and some misguided souls still depend on it for 'security' but the fact is it's not only pointless, but outright dangerous as it offers a sense of security that just doesn't exist. Unless we're talking about trusted 3rd parties with pre-shared keys - which we're not - then any content a client generates to send can, by definition, be generated by a client and thus can, by definition, be spoofed by a malicious client emulating an 'authorised' client.