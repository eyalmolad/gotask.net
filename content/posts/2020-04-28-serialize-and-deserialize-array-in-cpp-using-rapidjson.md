---
title: Serialize and Deserialize array in C++ using RapidJSON
author: eyal
type: post
toc: true
date: 2020-04-28T18:56:46+00:00
url: /programming/serialize-and-deserialize-array-in-cpp-using-rapidjson/
category:
  - Programming
tag:
  - array
  - cpp
  - json
  - object-model
  - rapid-json
  - serialization

---

## Introduction
In my previous article, I covered [serializing/deserializing JSON][1] in C++ to a simple object using [RapidJSON](https://rapidjson.org).

When working with JSON, my goal is to work always with object models and keep the actual JSON parsing behind the scenes. This keeps the readability and maintainability of the code as JSON manipulation, type checking and exception handling is done is a single class and not across the entire application. This also enables a future replacement of the JSON parsing library without the need to change the code of the entire application.

## My stack

* Visual Studio 2019 Community Edition, 16.5.1
* RapidJSON 1.1.0 release
* Windows 10 Pro 64-bit (10.0, Build 18363)

## Preparing the project

* I am going to use the same C++ Console Application from the previous post about [JSON Serialization in C++][1].
* My JSON will be an array of products in an inventory. Here is the sample of 3 products in inventory:

```JSON
[
  {
    "id": 1,
    "name": "Bush Somerset Collection Bookcase",
    "category": "Furniture",
    "sales": 22.0
  },
  {
    "id": 2,
    "name": "Mitel 5320 IP Phone VoIP phone",
    "category": "Technology",
    "sales": 907.1519775390625
  },
  {
    "id": 3,
    "name": "Poly String Tie Envelopes",
    "category": "Office Supplies",
    "sales": 3.2639999389648439
  }
]
```

## Creating the object models

For the single product, we used the following object model:

1. We added member variable for every JSON property with the correct type (id, name, sales, category)
2. Implemented getters/setters
3. Implemented Serialize and Deserialize functions

```C++
namespace JSONModels
{
  class Product : public JSONBase
  {
  public:
    Product();		
    virtual ~Product();			

    virtual bool Deserialize(const rapidjson::Value& obj);
    virtual bool Serialize(rapidjson::Writer<rapidjson::StringBuffer>* writer) const;

    // Getters/Setters.
    const std::string& Name() const { return _name; }
    void Name(const std::string& name) { _name = name; }

    const std::string& Category() const { return _category; }
    void Category(const std::string& category) { _category = category; }

    float Sales() const { return _sales; }
    void Sales(float sales) { _sales = sales; }

    int Id() const { return _id; }
    void Id(int id) { _id = id; }		
  private:
    std::string _name;
    std::string _category;
    float _sales;
    int _id;
  };	
}
```

In the next step, we need to create a class that will hold a list of ```Product``` objects.

```C++
namespace JSONModels
{
  class Products : public JSONBase
  {
  public:		
    virtual ~Products() {};
    virtual bool Deserialize(const std::string& s);		

    // Getters/Setters.
    std::list<Product>& ProductsList() { return _products; }
  public:
    virtual bool Deserialize(const rapidjson::Value& obj) { return false; };
    virtual bool Serialize(rapidjson::Writer<rapidjson::StringBuffer>* writer) const;
  private:
    std::list<Product> _products;
  };
}
```

### Serialize

This function is called by JSONBase class once the object is being serialized. Our list is stored in the memory, so we need to write it to the ```StringBuffer```.

In this code, we iterate over all Product in our ```_product``` list and call for Serialize function of the Product class.

```C++
bool Products::Serialize(rapidjson::Writer<rapidjson::StringBuffer>* writer) const
{
  writer->StartArray();

     for (std::list<Product>::const_iterator it = _products.begin(); it != _products.end(); it++)
     {
        (*it).Serialize(writer);
     }
  writer->EndArray();

  return true;
}
```

### Deserialize

Deserialize function is called by JSONBase class with JSON string parameter.

1. First we need to call for ```InitDocument``` function to parse the string
2. Once the ```doc``` object is initialized, we need to iterate over all JSON objects, call for Deserialize and finally add to ```_products``` list.

```C++
bool Products::Deserialize(const std::string& s)
{
  rapidjson::Document doc;
  if (!InitDocument(s, doc))
    return false;

  if (!doc.IsArray())
    return false;

  for (rapidjson::Value::ConstValueIterator itr = doc.Begin(); itr != doc.End(); ++itr)
  {
    Product p;
    p.Deserialize(*itr);
    _products.push_back(p);
  }

  return true;
}
```

## Usage

### Loading JSON array from file

```C++
// load json array
JSONModels::Products products;
products.DeserializeFromFile("DataSampleArray.json");

for (std::list<JSONModels::Product>::const_iterator it = products.ProductsList().begin();
  it != products.ProductsList().end(); it++)
{
  // print some values.
  printf("Name:%s, Sales:%.3f", (*it).Name().c_str(), (*it).Sales());
}
```

### Adding a new object to the existing list

```C++
// add new product
JSONModels::Product newProduct;
newProduct.Id(101);
newProduct.Name("Global Value Mid-Back Manager's Chair, Gray");
newProduct.Category("Furniture");
newProduct.Sales(213.115f);    
products.ProductsList().push_back(product);
```

### Saving the list to a new file

```C++
// save to new array file.
products.SerializeToFile("DataSampleArrayNew.json")
```

## Useful resources
* Full source code of this post in [GitHub][2]

[1]: /programming/serialize-and-deserialize-object-in-cpp-using-rapidjson/
[2]: https://github.com/eyalmolad/gotask/tree/master/C%2B%2B/RapidJSONSample