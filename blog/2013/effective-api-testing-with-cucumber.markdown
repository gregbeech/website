Date: 2013-08-03  
Status: Draft   
Tags: Cucumber, Gherkin, Testing  

# Effective API testing with Cucumber

At [blinkbox books](http://www.blinkboxbooks.com) we're making extensive use of Cucumber to capture business requirements and ensure that the code fulfils them. If you're getting started with Cucumber, a lot of the good practices for writing Gherkin specifications and effectively automating them is captured by [The Cucumber Book](http://pragprog.com/book/hwcuc/the-cucumber-book) which is, like most of the Pragmatic Bookshelf, a very good book indeed.

However, in the chapter where they discuss testing REST APIs they really dropped the ball. It's completely and utterly incorrect, and you should not be testing your REST APIs in this way.

Let's take an example scenario from chapter 12, "Testing a REST Web Service", to see the approach they're suggesting:

~~~gherkin
Scenario: List fruit
  Given the system knows about the following fruit:
    | name       | color  |
    | banana     | yellow |
    | strawberry | red    |
  When the client requests GET /fruits
  Then the response should be JSON:
    """
    [
      {"name": "banana", "color": "yellow"},
      {"name": "strawberry", "color": "red"}
    ]
    """
~~~

You'll note that this is significantly different from a normal Gherkin specification because it includes significant technical detail such as the HTTP verb `GET`, the URL `/fruits` and an entire JSON object for the response. It's also incredibly tightly coupled to the implementation.

This completely goes against the advice given in the rest of the books, for example at the start of chapter 5 it says:

> When you're writing Cucumber features, make readability your main goal. Otherwise, a reader can easily feel like they're reading a computer program rather than a specification document, which is something we want you to try to avoid at all costs. After all, if your features aren't easy to read, you might as well just be writing your tests in plain old Ruby code.

Good advice indeed. The level of technical detail in the above scenario would be appropriate in a lower level testing framework such as RSpec, which is intended to be used to test specific implementation details, but feels wholly out of place in a Gherkin specification.

The above scenario also falls foul of a number of the points in chapter 6, "When Cucumbers Go Bad", namely:

- Incidental Details: The details such as the specific HTTP verb used and, in particular, the URL of the resource itself, feel like incidental details. It's not clear why any stakeholder would need to know these details.
- Imperative Steps: The step to `GET /fruits` is clearly failing to create its own domain language, instead deferring to the specifics of the underlying HTTP protocol. The recommendation to raise the level of abstraction and write steps in a declarative style is completely ignored.
- Brittle Features: The JSON document implies an implicit ordering, but is this based on the order the data was inserted into the system? Or alphabetical based on name? It's not clear. Given the JSON matching semantics aren't specified it seems that this test could be brittle when an unrelated change causes a different sort order to be returned. It might even be a flickering scenario, where sometimes the sort order is correct, but sometimes not.
- Duplication: At the moment there doesn't look like any duplication, but once you start creating lots of tests for fruits there will be many, many JSON documents littered throughout the Gherkin specifications. Want to add a new attribute to the JSON? Time to go back and change them all...

There's an attempt at an explanation for why the authors have entirely ignored everything about the approach they espoused in the first eleven chapters:

> __Joe asks: I Thought Scenarios Should Avoid Technical Terms Like JSON__
>
> It's always important to make a scenario readable by a stakeholder. However, for a REST interface, the stakeholder is going to be another programmer writing a client for the REST interface. In such cases, it's fine to expose technical details.

But this is based on a false premise.

In this simple scenario there aren't much in the way of requirements, but in the real world you're likely to have some other constraints such as the fact that you can't make smoothies from fruits that aren't in stock, so you probably need a way to return only available fruits. You might also need to know how many fruits are available -- but for watermelons or pineapples which are large and require pre-preparation in the form of peeling and chopping it may be weight rather than count. And some fruits such as oranges may be pre-squeezed, so those quantities might be measured in volume.

You presumably also need recipes to suggest which fruits go together, and some sort of price list for pre-selected combinations and ad-hoc blends, and perhaps even the available sizes of cups, and so on, and so on. In other words, there's likely to be a moderately complex logical data and operation model hiding behind even this throwaway scenario.

Is the client programmer the stakeholder for those?

I sure as hell hope not.

Unless you're a really small company with a few developers hacking out code to try and get it off the ground - in which case you're probably not using Cucumber because you don't have the time - then you probably have product managers who define the vision for the future and specify how these things should work (albeit usually with input from the development and test team). The product team own the requirements, and thus _they_ are the stakeholders for the API, and the Gherkin specifications need to be written with _them_ in mind.

Are all of your product managers familiar with the details of HTTP and JSON? The difference between `PUT` and `PATCH`? The difference between `200 OK` and `202 Accepted`? Of couse not. Heck, even most developers are embarrassingly unaware of most of the commonly used parts of HTTP.

So if you're writing Gherkin for REST APIs -- or, indeed, any APIs -- then you need to write it using the same approach as you would with any other Gherkin. Just pretend chapter 12 doesn't exist.

You might think I'm unfairly picking on a single book here, but the fact is that The Cucumber Book is the _de facto_ book for learning Cucumber and when they have got something so hideously wrong it means that the wrong approach is going to get widely propagated. We even tried their approach at our company before realising that with more complex APIs it led to a huge amount of repetition and brittle scenarios, and was utterly useless for describing the actual behaviour of the API to anybody, including other developers.

So, let's have a go at writing the scenario to be more readable and less brittle:

~~~gherkin
Scenario: List fruit
  Given the system knows about the following fruit:
    | name       | color  |
    | banana     | yellow |
    | strawberry | red    |
  When the client requests a list of fruits
  Then the response should be a list containing two fruits
  And one fruit should have the name "banana" and the color "yellow"
  And one fruit should have the name "strawberry" and the color "red"
~~~





