---
title: Serialize and Deserialize object in C++ using RapidJSON
author: eyal
type: post
toc: true
date: 2020-04-08T20:12:03+00:00
url: /programming/serialize-and-deserialize-object-in-cpp-using-rapidjson/
category:
  - Programming
tag:
  - cpp
  - json
  - rapid-json
  - serialization
---

## Introduction

In one of my projects in C++, I had to work with an input in JSON format as we were using Django Web API that produces a JSON response for REST API calls.

Parsing the JSON format in C++ should be easy with the open source libraries such as [RapidJSON][1], [nlohmann/jsonm](https://github.com/nlohmann/json), [Boost.JSON](https://github.com/CPPAlliance/json).

My goal was to work with strongly-typed objects and keep the parsing behind the scenes.

Such task sounds trivial if you work in C# or other programming language that supports reflection, but in C++ it requires a bit more work.

Full source code of this post in [GitHub.][2]

## My stack

* Visual Studio 2019 Community Edition, 16.5.1
* RapidJSON 1.1.0 release
* Windows 10 Pro 64-bit (10.0, Build 18363)

## Preparing the project

1. In Visual Studio, create a new Console Application in C++. It can be both, 32-bit or 64-bit.
2. In Windows Explorer, open the root folder of the project in command line prompt.
3. Clone the RapidJSON repository using the following command line: 
  ```
    git clone https://github.com/Tencent/rapidjson.git
  ```   
4. I am going to use a very simple JSON  that represents a product in an inventory. It has a few properties of different types:

```JSON
{
  "id": 9,
  "name": "Bush Somerset Collection Bookcase",
  "category": "Furniture",
  "sales":122.0
}
```

## Creating the object model

As I mentioned before, in the serialize/deserialize process I want to be able to work with classes with strongly typed members and accessors functions.

For this purpose, I created an abstract base class ```JSONBase``` that provides following capabilities:
* Document parsing using RapidJSON
* Serializing to file and Deserializing from file

Inheriting from JSONBase requires an implementation of Serialize and Deserialize pure virtual functions.

```C++
class JSONBase
{
public:	
  bool DeserializeFromFile(const std::string& filePath);
  bool SerializeToFile(const std::string& filePath);	

  virtual std::string Serialize() const;
  virtual bool Deserialize(const std::string& s);

  virtual bool Deserialize(const rapidjson::Value& obj) = 0;
  virtual bool Serialize(rapidjson::Writer<rapidjson::StringBuffer>* writer) const = 0;
protected:
  bool InitDocument(const std::string & s, rapidjson::Document &doc);
};
```

## Creating the Product class

```C++
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
```

As my goal is to work with objects and not JSON, we need following:

* Create a class that derives from ```JSONBase``` that represents a ```Product```.
* Add member variables to the class. (id, name, category, sales)
* Add Getters/Setters for member variables.
* Implement the pure virtual functions Serialize and Deserialize

### Serialize

This function is called by the JSON base class passing the ```StringBuffer``` pointer. We need to write the property names and values to the buffer.

```C++
bool Product::Serialize(rapidjson::Writer<rapidjson::StringBuffer> * writer) const
{
  writer->StartObject();

    writer->String("id"); // create Id property
    writer->Int(_id);     // write the Id value from the object instance

    writer->String("name");
    writer->String(_name.c_str());

    writer->String("category");
    writer->String(_category.c_str());

    writer->String("sales");
    writer->Double(_sales);

  writer->EndObject();

  return true;
}
```

### Deserialize

Deserialize function is called by ```JSONBase``` class with the current object being parsed. We need to call the setter functions of our object to update the value from JSON.

```C++
bool Product::Deserialize(const rapidjson::Value & obj)
{
  Id(obj["id"].GetInt());
  Name(obj["name"].GetString());
  Category(obj["category"].GetString());
  Sales(obj["sales"].GetFloat());

  return true;
}
```

Notice that you should access every property with the correct type.

* int - GetInt()
* int64 - GetInt64()
* string - GetString()
* float - GetFloat()
* double - GetDouble()

Check this section in [RapidJSON tutorial](https://rapidjson.org/md_doc_tutorial.html#QueryNumber) for more info about the supported types.

## Usage

After we've done all the hard work with defining the classes, the usage is very straight forward:

### Loading JSON from file

```C++
JSONModels::Product product;
product.DeserializeFromFile("DataSample.json");
printf("Name:%s, Sales:%.3f", product.Name().c_str(), product.Sales());
```

### Loading JSON from file, changing values to writing back to file

```C++
JSONModels::Product product;
product.DeserializeFromFile("DataSample.json");            
product.Sales(product.Sales() + 100.0f); // increase the sales by 100
product.SerializeToFile("DataSampleNew.json");
```

In the next article, I am going to cover serializing/deserialzing JSON arrays in C++.

## Useful resources

* Full source code of this post in [GitHub][2]

[1]: https://rapidjson.org
[2]: https://github.com/eyalmolad/gotask/tree/master/C%2B%2B/RapidJSONSample