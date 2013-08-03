Date: 2013-12-31  
Status: Draft  
Tags: Architecture, SOA, Versioning  

# Shipping Oriented Architecture

If you're working on web-based software that's been under development for a few years, there's a reasonable probability that your system architecture is something like this:

-------------------------
presentation layer
-------------------------
api layer
-------------------------
business logic layer
-------------------------
data access layer
-------------------------
database
-------------------------

The layers are nicely separated into different disciplines, and most likely in distinct assemblies/jars/whatever. All the code is held together using dependency injection so it feels loosely coupled and testable. You're using AOP and code generation to remove the need to write boilerplate everywhere. Your database is in third normal form, except where you've explicitly denormalised for performance. You've got continuous integration builds and automated deployments.

And yet in spite of doing everything by the book, you've got a problem: You can't ship new features in any reasonable timeframe, and you can't work out why.

Sound familiar?

## The big systems problem


Layers are a lie. What you should have been doing is building many small systems rather than a single well architected large one.

[PARTITIONS IMAGE]

Jeff Bezos realised this over a decade ago. It's one of the reasons that Amazon is a $100bn business. I'm not saying it's _the_ reason, but you've got to admit, it's worth considering.


## The continuous integration problem

You shouldn't be pushing your new code into your new systems. Work on a pull model. Otherwise you have to regression test the whole lot anyway.

Ruby gets it right. Semantic versioning. Gemfile.lock. Only update when you need to update.


## The referential integrity problem

Referential integrity makes you think you need to know more than you actually need to know.

Digital signatures: Somebody I trust said this, so it's OK. E.g. receipts from external payment providers, integration with third party systems.


## The layers problem

You're building things you don't need.

XML -> JSON -> XML -> Tables -> JDBC -> Objects -> Objects -> JSON

In a read-mostly system you're often better just dumping your data out with minimal transformation. If you need to use it for multiple purposes, store it multiple times in multiple databases of differne types.


















