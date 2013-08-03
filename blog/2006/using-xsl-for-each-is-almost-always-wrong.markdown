Date: 2006-08-17  
Status: Published  
Tags: XML  

# Using xsl:for-each is almost always wrong
    
In fact I can't think of a single place where it is a good idea to use `xsl:for-each`, but in software there are very few absolutes and so its possible there might be one or two. By replacing it with `xsl:apply-templates` you can make your XSLT stylesheet flatter in structure, easier to read, more flexible and more maintainable.

To root this in the real world, lets take a small piece of XML that we can transform which gives us stock quotes for some companies. Obviously the full version would be somewhat more complex, but this should be sufficient to make the point:

~~~ xml
<StockQuotes xmlns="urn:stock-quotes">
  <StockQuote>
    <Symbol>US:MSFT</Symbol>
    <Quote Time="2006-08-17T13:35:07+01:00">
      <Current>24.7</Current>
      <Change>0.32</Change>
    </Quote>
    <Quote Time="2006-08-17T12:34:07+01:00">
      <Current>24.38</Current>
      <Change>0.11</Change>
    </Quote>
  </StockQuote>
  <StockQuote>
    <Symbol>US:SUNW</Symbol>
    <Quote Time="2006-08-17T13:27:46+01:00">
      <Current>4.82</Current>
      <Change>0.2</Change>
    </Quote>
    <Quote Time="2006-08-17T12:28:55+01:00">
      <Current>4.62</Current>
      <Change>-0.13</Change>
    </Quote>
  </StockQuote>
</StockQuotes>
~~~

Say we wanted to display this to a user, we might want to create an HTML page which displays the quotes as rows in a table. Using the `xsl:for-each` approach the stylesheet could look similar to the following:

~~~ xml
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:q="urn:stock-quotes">  
  <xsl:template match="/">
    <html>
      <body>
        <h1>Your Stock Quotes</h1>
        <table>
          <tr>
            <th>Quote Time</th>
            <th>Current</th>
            <th>Change</th>
          </tr>
          <xsl:for-each select="q:StockQuotes/q:StockQuote">
            <tr>
              <td colspan="3"><xsl:value-of select="q:Symbol"/></td>
            </tr>
            <xsl:for-each select="q:Quote">
              <tr>
                <td><xsl:value-of select="@Time"/></td>
                <td><xsl:value-of select="q:Current"/></td>
                <td><xsl:value-of select="q:Change"/></td>
              </tr>
            </xsl:for-each>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
~~~

This looks pretty horrible to me - there are nested loops, and even with an input format as simple as the one we have it's starting to get quite a deep hierarchy. In addition, if we wanted to add formatting and so on to the rows (as would be common in the real world) it quickly becomes tricky to work out where in the hierarchy is currently being edited.

Now let's have a look at how we can rewrite this by replacing the `xsl:for-each` with an `xsl:apply-templates`, and move the formatting logic for each stock item into its own seperate template:

~~~ xml
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:q="urn:stock-quotes">
  <xsl:template match="/">
    <html>
      <body>
        <xsl:apply-templates select="q:StockQuotes"/>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="q:StockQuotes">
    <h1>Your Stock Quotes</h1>
    <table>
      <tr>
        <th>Quote Time</th>
        <th>Current</th>
        <th>Change</th>
      </tr>
      <xsl:apply-templates select="q:StockQuote"/>
    </table>
  </xsl:template>
  <xsl:template match="q:StockQuote">
    <tr>
      <td colspan="3"><xsl:value-of select="q:Symbol"/></td>
      <xsl:apply-templates select="q:Quote"/>
    </tr>
  </xsl:template>
  <xsl:template match="q:Quote">
    <tr>
      <td><xsl:value-of select="@Time"/></td>
      <td><xsl:value-of select="q:Current"/></td>
      <td><xsl:value-of select="q:Change"/></td>
    </tr>
  </xsl:template>
</xsl:stylesheet>
~~~

In this version of the stylesheet, wherever there was an `xsl:for-each`, there is now an `xsl:apply-templates` (in fact here is an additional one as I took the opportunity to move the heading and table into the template that matches the `StockQuotes` element). In an analogy to procedural programming, which most people are more familiar with, you can think of a template as being like a method so what we have done here is refactored the code from one large method into a number of smaller, more manageable methods.

Now if we want to add formatting information to any part of the output, it is easy to see exactly where we are working as each element has its own separate template. It is now also possible to collapse sections we aren't interested in using Visual Studio 2005's outlining view, so if the `Quote` element is the only one we need to edit the stylesheet can be collapsed to the following, which can't be done with a hierarchical `xsl:for-each` stylesheet.

~~~ xml
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:q="urn:stock-quotes">
  <xsl:template match="/">...
  <xsl:template match="q:StockQuotes">...
  <xsl:template match="q:StockQuote">...
  <xsl:template match="q:Quote">
    <tr>
      <td><xsl:value-of select="@Time"/></td>
      <td><xsl:value-of select="q:Current"/></td>
      <td><xsl:value-of select="q:Change"/></td>
    </tr>
  </xsl:template>
</xsl:stylesheet></pre>
~~~

If you want a further plus side, how about tracking history in source control? Say you need to add another container element to your XML format further down the line, to support more functionality, then with the `xsl:for-each` approach you'll need to indent every child element further so it will look like the whole stylesheet has changed. With the template approach you just add in another template at the root level, and everything else stays the same.

Everything you can do with `xsl:for-each` can be done with templates, such as applying `xsl:sort`, and you can pass parameters into them using `xsl:parameter` and `xsl:with-param`. Even better for more advanced work is the mode attribute on the template, which lets you handle the same element type in different ways depending on the mode in which the template is called.

In summary, by using templates you have everything to gain and nothing to lose. Next time you find yourself typing "`xsl:for-each`", stop and think how you could achieve the same effect with templates.