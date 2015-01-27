Date: 2015-01-27  
Status: Draft  
Tags: Security, Scala, Json4s, PII  

# Reducing sensitive information leakage

We tend to think quite a bit about protecting sensitive information, and in particular personally identifiable information (PII), when building software. Some of the simple measures typically taken are putting user information in separate databases and restricting access to them, or storing credit card details with a specialist provider rather than in your own infrastructure.

However, one of the most frequent causes of sensitive information leakage is logs. For example given the following class:

~~~scala
case class User(id: String, email: String, name: String)
~~~

It's all too easy to write something like the following:

~~~scala
val user = User("47d429adce", "johndoe@example.org", "John Doe")

logger.error(s"Failed to process request for $user")

// > Failed to process request for User(47d429adce, johndoe@example.org, John Doe)
~~~

And, whoops, you've accidentally dumped their email address and full name into your logs, which if you're doing things right are all collected and searchable in something like Graylog or Logstash. Even if you only keep logs for a relatively short period such as 30 days, this is still a fairly major leak.

It's pretty hard to prevent this even with careful developers and good code reviews because it's just so easy to leak sensitive information, and while it's obvious that a `User` class is going to contain that kind of thing, other classes may be rather less obvious.

A good way to solve this, inspired by [information flow theory](http://en.wikipedia.org/wiki/Information_flow_%28information_theory%29), is to mark the fields as being sensitive and then give them safe-by-default behaviour when dumped, e.g.

~~~scala
final case class Sensitive[A](value: A) {
  override def toString: String = "******"
}

object Sensitive {
  implicit def forAny[A](value: A): Sensitive[A] = Sensitive(value)
}

case class User(id: String, email: Sensitive[String], name: Sensitive[String])

// note we can still construct the user as before thanks to the implicit
val user = User("47d429adce", "johndoe@example.org", "John Doe")

logger.error(s"Failed to process request for $user")

// > Failed to process request for User(47d429adce, ******, ******)
~~~

Much better.

There are a couple of reasons you're better off using a type rather than, say, a `@sensitive` annotation. The most important one _is_ the safe-by-default behaviour because with a specialised type like this if the recipient doesn't know how to process it (e.g. third party logging libraries) then it'll print the masked value, unlike annotations which are ignored by recipients that don't understand them.

The other is that the sensitivity of a piece of data is an intrinsic part of the model. Much like an `Option[String]` declares that a string is optional and cannot be passed as a regular `String` argument directly, a `Sensitive[String]` also requires the developer to stop and think for a second before deciding whether it's appropriate to remove the sensitive marker. In an ideal world, this marker would be flowed all the way through to your application boundaries.

We can improve this further using the Scala idiom of creating wrapper classes for values that are likely to be passed around independently (e.g. instead of having the `email` property be a `String` we would make it an `Email`) which would make it a compile-time error to pass a name to a method expecting an email, and vice versa. By baking the sensitive marker into these we get a cleaner, more expressive model with better log output because we can see what information has been masked.

~~~scala
case class UserId(value: String) extends AnyVal
case class Email(value: Sensitive[String]) extends AnyVal
case class Name(value: Sensitive[String]) extends AnyVal
case class User(id: UserId, email: Email, name: Name)

val user = User(UserId("47d429adce"), Email("johndoe@example.org"), Name("John Doe"))

logger.error(s"Failed to process request for $user")

// > Failed to process request for User(UserId(47d429adce), Email(******), Name(******))
~~~












