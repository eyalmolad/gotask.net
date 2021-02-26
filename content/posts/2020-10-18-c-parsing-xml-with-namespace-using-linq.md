---
title: 'C# Parsing XML with namespace using LINQ'
author: eyal
type: post
toc: true
date: 2020-10-18T12:58:33+00:00
url: /programming/c-parsing-xml-with-namespace-using-linq/
category:
  - Programming
tag:
  - .netcore
  - anonymous-type
  - linq
  - linq-to-xml
  - parsing
  - serialization
  - xml
  - xml-namespace

---
## Background

In one of my previous posts, I wrote about [deserializing XML with namespace](/programming/deserializing-xml-with-namespace-in-c-sharp/) using ```XmlSerializer``` that requires creating custom model classes in order to perform the serialization. Today, I am going to cover another powerful method for parsing - [LINQ to XML](https://docs.microsoft.com/en-us/dotnet/standard/linq/linq-xml-overview).

## My Stack

{{<figure class="alignright" width="287" height="65" src="/wp-content/uploads/2020/10/xml_logo.png" caption="Xml element tag">}}  

* Visual Studio 2019 Community.
* .NET Core 3.1 / C#
* Windows 10 Pro 64-bit (10.0, Build 19041)

## Implementation

### Simple LINQ-XML reading

Consider the following XML that contains no namespaces.

```XML
<?xml version="1.0" encoding="utf-8" ?>
<Root>
  <Items>
    <Books>
      <Book>
        <ISBN>978-1788478120</ISBN>
        <Name>C# 8.0 and .NET Core 3.0 – Modern Cross-Platform Development: Build applications with C#, .NET Core, Entity Framework Core, ASP.NET Core, and ML.NET using Visual Studio Code, 4th Edition</Name>
        <Price>35.99</Price>
      </Book>
      <Book>
        <ISBN>978-1789133646</ISBN>
        <Name>Hands-On Design Patterns with C# and .NET Core: Write clean and maintainable code by using reusable solutions to common software design problems</Name>
        <Price>34.99</Price>
      </Book>
    </Books>
  </Items>
</Root>
```

In order to read the ```Books``` elements, we could use the following sample code:

``` C#
var root = XElement.Load("SimpleBooks.xml");

var books = root.Descendants("Items").Descendants("Books").Descendants("Book");

foreach (var book in books)
  Console.WriteLine($"Book name: {book.Element("Name").Value}");
```

Another approach could be taking an advantage of the <a href="https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/anonymous-types" target="_blank" rel="noopener noreferrer">anonymous types</a> in .NET. The sample code below reads all the books into an anonymous type containing the 3 elements from the XML as read only properties.

``` C#
// 2. Convert to anonymous type.
var books = from book in root.Descendants("Items").Descendants("Books").Descendants("Book")
      select new
      {
        Name = book.Element("Name").Value,
        ISBN = book.Element("ISBN").Value,
        Price = book.Element("Price").Value
      };

foreach (var book in books)
  Console.WriteLine($"Book name: {book.Name}");
```

### Simple LINQ-XML reading with namespaces

A quick reminder from the previous article - why do we need [namespaces in our XML files](/programming/deserializing-xml-with-namespace-in-c-sharp/)?

The short answer would be to prevent any element's naming conflicts in the same file. Remember, XML files can be very long and complex written by different people, so naming conflicts might be very common. A comparable example could be names of the classes in the C# code - once inside namespace the chance for conflict is very low. To create the uniqueness, we usually use URI's that we own, but actually the namespace name can be any string. There are more details in this question regarding [URI's and namespaces](https://softwareengineering.stackexchange.com/questions/122002/why-do-we-need-uris-for-xml-namespaces).

For the sample, I am going to add a namespace to the ```Books``` element of the XML.

```xmlns="https://gotask.net"```

So our XML looks like:

```XML
<?xml version="1.0" encoding="utf-8" ?>
<Root>
  <Items xmlns="https://gotask.net">
    <Books>
      <Book>        
        <ISBN>978-1788478120</ISBN>
        <Name>C# 8.0 and .NET Core 3.0 – Modern Cross-Platform Development: Build applications with C#, .NET Core, Entity Framework Core, ASP.NET Core, and ML.NET using Visual Studio Code, 4th Edition</Name>
        <Price>35.99</Price>
      </Book>
      <Book>
        <ISBN>978-1789133646</ISBN>
        <Name>Hands-On Design Patterns with C# and .NET Core: Write clean and maintainable code by using reusable solutions to common software design problems</Name>
        <Price>34.99</Price>
      </Book>
    </Books>
  </Items>
</Root>
```

Running the previous code on this code will produce no results. The reason is that each element has it's own fully qualified name once we have a namespace - the element ```Books``` is actually ```https://gotask.net:Books```. and our code is searching for ```items.Descendants("Books")```.

In order to correctly parse the file above, we need to specify the namespace using [XNamespace](https://docs.microsoft.com/en-us/dotnet/api/system.xml.linq.xnamespace?view=netcore-3.1) class in every call for ```Descendants```.

``` C#
XNamespace x = "https://gotask.net";

var books = root.Descendants(x + "Items").Descendants(x + "Books").Descendants(x + "Book");

foreach (var book in books)
   Console.WriteLine($"Book name: {book.Element(x + "Name").Value}");
```

### Nested namespaces

Consider the following XML, where the ```Items``` element is in one namespace, but the ```Books``` child element is in other:

``` XML
<?xml version="1.0" encoding="utf-8" ?>
<Root>
  <Items xmlns="https://gotask.net">
    <Books xmlns="https://books.net">
      <Book>
        <ISBN>978-1788478120</ISBN>
        <Name>C# 8.0 and .NET Core 3.0 – Modern Cross-Platform Development: Build applications with C#, .NET Core, Entity Framework Core, ASP.NET Core, and ML.NET using Visual Studio Code, 4th Edition</Name>
        <Price>35.99</Price>
      </Book>
      <Book>
        <ISBN>978-1789133646</ISBN>
        <Name>Hands-On Design Patterns with C# and .NET Core: Write clean and maintainable code by using reusable solutions to common software design problems</Name>
        <Price>34.99</Price>
      </Book>
    </Books>
  </Items>
</Root>
```

In the sample code below, we need to specify both namespaces.

``` C#
XNamespace x = "https://gotask.net";

XNamespace y = "https://books.net";

var books = root.Descendants(x + "Items").Descendants(y + "Books").Descendants(y + "Book");

foreach (var book in books)
    Console.WriteLine($"Book is {book.Element(y + "Name").Value}");
```

### Multiple namespaces with prefix

[XML standard](https://www.xml.com/pub/a/2005/04/13/namespace-uris.html) allows us to define multiple namespaces for the same element. Once we define ```xmlns=https://somename.net```, we are actually defining a default namespace without a prefix. In order to define another namespace, we need to specify the prefix ```xmlns:bk=https://books.net```.

In order to create child elements that belongs to ```https://books.net``` namespace, we need to declare with ```<bk:book></bk:book>```. Elements without the prefix will belong to the default namespace.

So lets consider this is our new XML. We have 2 namespaces defined, ```https://gotask.net``` is the default one and ```https://books.net``` has the ```bk``` prefix.

We have one ```Book``` element in the bk namespace and the other one in the default.

``` XML
<?xml version="1.0" encoding="utf-8" ?>
<Root>
  <Items xmlns="https://gotask.net" xmlns:bk="https://books.net">
    <Books>
      <bk:Book>
        <bk:ISBN>978-1788478120</bk:ISBN>
        <bk:Name>C# 8.0 and .NET Core 3.0 – Modern Cross-Platform Development: Build applications with C#, .NET Core, Entity Framework Core, ASP.NET Core, and ML.NET using Visual Studio Code, 4th Edition</bk:Name>
        <bk:Price>35.99</bk:Price>
      </bk:Book>
      <Book>
        <ISBN>978-1789133646</ISBN>
        <Name>Hands-On Design Patterns with C# and .NET Core: Write clean and maintainable code by using reusable solutions to common software design problems</Name>
        <Price>34.99</Price>
      </Book>
    </Books>
  </Items>
</Root>
```

The code below, reads only the ```Books``` belonging to the ```bk``` namespace.

``` C#
XNamespace x = "https://gotask.net";

XNamespace b = "https://books.net";

var books = root.Descendants(x + "Items").Descendants(x + "Books").Descendants(b + "Book");

foreach (var book in books)
  Console.WriteLine($"Book name: {book.Element(b + "Name").Value}");
```

The code below, reads only the ```Books``` belonging to the default namespace.

``` C#
XNamespace x = "https://gotask.net";

var books = root.Descendants(x + "Items").Descendants(x + "Books").Descendants(x + "Book");

foreach (var book in books)
  Console.WriteLine($"Book name: {book.Element(x + "Name").Value}");
```

## Useful links

* The full source code available at <a href="https://github.com/eyalmolad/gotask/tree/master/XML/LinqToXML" target="_blank" rel="noopener noreferrer">GitHub</a>.