---
title: 'Reverse list elements in C#'
author: eyal
type: post
toc: true
date: 2020-04-06T22:15:04+00:00
url: /programming/reverse-list-elements-in-c-sharp/
category:
  - Programming
tag:
  - .netcore
  - c-sharp
  - generics
  - linq
  - list

---
## Background

.NET core provides a generics class List to store a strongly types objects that can be accessed by index.

This class provides us with many methods to add, remove, access, sort or manipulate the objects within the list.

In this sample, I am going to demonstrate the following ```Reverse``` options:

  * Reverse using the ```System.Collections.Generic List```'s methods.
  * Reverse using ```Linq``` method

## Code Samples

### List Initialization

I am going to create a list of integers and set the values using a collection initializer.

```C#
var list = new List<int>
{
    1, 5, 6, 7, 9, 10, 99, 777
};
```

Note that using a collection initializer as shown above produces the same code as separately using the Add function multiple times:

```C#
var list = new List<int>();
list.Add(1);
list.Add(5);
list.Add(6);
list.Add(7);
list.Add(9);
list.Add(10);
list.Add(99);
list.Add(777);
```

Printing to console the original list, produces the following output:

{{<figure  width="216" height="228" src="/wp-content/uploads/2020/04/original-list-int.png" caption="Original list of items sample output">}}  


### Reverse using List<T> Reverse Methods

The name of the method is self-explanatory &#8211; it reverses the order of the elements in the list.

**Important note:** The Reverse methods are reversing the list in-place, meaning your original List object is being changed.

The Reverse method has 2 overloads:

* ```Reverse(void)``` - Reverses the all the elements in the given list
* ```Reverse(int, int)``` - Reverses the order of the elements in the specified range

#### Full reverse in-place

```C#
list.Reverse();
```

{{<figure  width="227" height="253" src="/wp-content/uploads/2020/04/reversed-full-list-int.png" caption="Reverse full list in C#">}}

#### Partial reverse in-place

```C#
list.Reverse(0, 3)
```

{{<figure  width="294" height="223" src="/wp-content/uploads/2020/04/reversed-first-3-items-int.png" caption="Reverse first 3 items in C# List">}}


### Reverse using Linq Reverse Method

In case your wish to keep the original list unchanged, the following Linq code will create another list with reversed items:

```C#
list.AsEnumerable().Reverse();
```

This is also available as query syntax:

```C#
(from i in list select i).Reverse();
```

Full code:

```C#
public class Program
{
  static void Main(string[] args)
  {
    // initialize list.
    var list = new List<int>
    {
      1, 5, 6, 7, 9, 10, 99, 777 
    };

    PrintList("Original List:",  list);

    list.Reverse();
    PrintList("Reversed full:", list);
    list.Reverse(); // reverse back since the list is changed.

    // reverse first 3 items.
    list.Reverse(0, 3);
    PrintList("Reversed first 3 items:", list);
    list.Reverse(0, 3); // reverse back.


    PrintList("Reversed Using LINQ full:", list.AsEnumerable().Reverse());

    PrintList("Reversed Using LINQ Query Syntax:", (from i in list select i).Reverse());
  }

  static void PrintList<T>(string message, IEnumerable<T> list)
  {
    Console.WriteLine($"{message}\r\n{string.Join("\r\n", list)}");
  }
}
```

## Useful links
* [List<T> Reverse](https://docs.microsoft.com/en-us/dotnet/api/system.collections.generic.list-1.reverse?view=netframework-4.8#System_Collections_Generic_List_1_Reverse_System_Int32_System_Int32_)