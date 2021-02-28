---
title: 'C# – Creating an Excel Addin with User Defined Functions'
author: eyal
type: post
toc: true
date: 2020-10-14T20:00:42+00:00
url: /programming/vsto/c-sharp-creating-excel-addin-with-user-defined-functions/
category:
  - VSTO
tag:
  - dot-net
  - c-sharp
  - excel
  - excel-dna
  - office-programming
  - ribbon-xml
  - udf
---
## Background

In one of my previous posts, I demonstrated how to create a simple [VSTO Addin for Excel](https://gotask.net/programming/vsto/c-sharp-vsto-addin-sample-for-excel-word-power-point-outlook/)</a> that adds a button on the ribbon. In this post, I am going to show how to add a user defined functions using [Excel-DNA](https://excel-dna.net) as well as use the ribbon functionality.

## My Stack

* Visual Studio 2019 Community.
* .NET Framework 4.7.2 / C#
* Office 365, Desktop Edition.
* Windows 10 Pro 64-bit (10.0, Build 19041)


## User Defined Function (UDF)

Excel provides a large set of built in functions, giving a user the ability to perform various calculations and manipulations on the data. But what happens if a user needs a custom calculation, that needs to be used over multiple cells? Starting Excel 2002, Microsoft introduced the User Defined Functions. This capability enables you to wrap some common calculation or string manipulation in a function and call it transparently as any other Excel build-in function.

### Example

Lets say we want to reverse a string in a cell. There are lot of examples of how to do that using the Excel built in functions. One of the examples is using [TEXTJOIN](https://support.microsoft.com/en-us/office/textjoin-function-357b449a-ec91-49d0-80c3-0e8fc845691c) function:

```EXCEL
=TEXTJOIN("",1,MID(A1,ABS(ROW(INDIRECT("1:"&LEN(A1)))-(LEN(A1)+1)),1))
```

Additional techniques could be found on [ExcelJet](https://exceljet.net/formula/reverse-text-string).

Much cleaner alternative would be creating a UDF that does this in C# and calling the function from the Excel spreadsheet with:

```EXCEL
=ReverseString(A1)
```

## Creating an Excel Addin that supports UDF

From Visual Studio menu, create a new .NET Framework Class Library project.

### Installing dependencies

1. First we need to reference the Excel-DNA project that enables us to make native XLL addins using C#. In the Visual Studio Package Manager Console type:

```SHELL
Install-Package ExcelDna.AddIn
```

Note: After installing the ExcelDna.Addin package, your project extension will be changed to xll which is a format for an addin that adds UDF functionality. You can read more about the <a href="https://docs.microsoft.com/en-us/office/client-developer/excel/creating-xlls" target="_blank" rel="noopener noreferrer">XLL addins on MSDN</a>.

2. Since we want to create also some visual components and interact will the Excel elements we need to add the reference to: Microsoft.Office.Interop.Excel.dll. This component is usually located in your Office directory.

### Setting up the control classes

Since we want to combine the ExcelDna.Addin and the Ribbon objects, we can't use the regular VSTO, but need to create the control classes manually.

1. Create a class that implements the ```ExcelDna.Integration.IExcelAddIn``` interface. 
  
```C#
public class ExcelRibbonUDFAddin : IExcelAddIn
{
  public void AutoOpen()
  {
    // startup code
  }

  public void AutoClose()
  {
    // clean up
  }
}
```
    
2. Create the ribbon controller class that derives from ```ExcelDna.Integration.CustomUI.ExcelRibbon``` base class.
    
```C#
[ComVisible(true)]
public class RibbonController : ExcelRibbon, IDisposable
{
  private Microsoft.Office.Core.IRibbonUI _ribbonUi;

  private Application App
  {
    get => (Application)ExcelDnaUtil.Application;
  }            

  public override string GetCustomUI(string ribbonID) =>
      @"<customUI xmlns='http://schemas.microsoft.com/office/2009/07/customui'>
          <ribbon>
             <tabs>
              <tab id='sample_tab' label='GoTask'>
                <group id='sample_group' label='Operations'>                                        
                  <button id='do_reverse_range' label='Reverse' size='large' getImage='OnDoReverseGetImage' onAction='OnDoReverse'/>
                </group>
              </tab>
            </tabs>
          </ribbon>
        </customUI>";

  public void OnLoad(Microsoft.Office.Core.IRibbonUI ribbonUI)
  {
    _ribbonUi = ribbonUI;          
  }        
   
  public void Dispose()
  {            
  }
}
```

1. ExcelDnaUtil.Application returns the Excel Application object instance. 
2. GetCustomUI returns the Ribbon XML string. You can find the full specification regarding the 

<a href="https://docs.microsoft.com/en-us/visualstudio/vsto/ribbon-xml?view=vs-2019" target="_blank" rel="noopener noreferrer">Ribbon XML format on MSDN</a>.


### Adding the UDF functionality

Create a new static class that will contain the ```Reverse``` string function implementation. Make sure that you add ```ExcelFunction``` attribute to it.

Every time you add ```=ReverseString``` to any cell in the Excel, this function will be called.

```C#
public static class CustomFunctions
{
  [ExcelFunction(Description = "Reverse string function")]
  public static string ReverseString(string str)
  {
    var charArray = str.ToCharArray();
    Array.Reverse(charArray);
    return new string(charArray);
  }
}
```

### Testing the project

{{<figure class="alignright"  width="240" height="228" src="/wp-content/uploads/2020/10/reverse-string-excel-e1602775342176.png" caption="Excel functions intellisense">}}

1. Build the project and run it in Debug mode. This should open the Excel application with the addin loaded.

2. Go to some cell and type ```=ReverseString``` passing a reference to a cell or hard coded string.

3. Your target cell should contain the reversed string. Since you are running in the debug mode, you can always set a breakpoint in the ReverseString function.

## Adding the reverse function to an existing range

After we built the basic sample, we can connect it to a button on the ribbon that reverses the string of the selected range and inserts the results to the new column.

For this, we need to implement the ribbon button action function in the Ribbon Controller class:

```C#
public void OnDoReverse(Microsoft.Office.Core.IRibbonControl control)
{
  var selectedRange = App.Selection;

  if (selectedRange == null) return;

  foreach (Range cell in selectedRange)
  {
    var next = cell.Offset[0, 1];
    next.Formula = $"=ReverseString({cell.Address})";
  }
}
```

{{<figure  width="300" height="294" src="/wp-content/uploads/2020/10/image_2020-10-15_184255-e1602780284748.png" caption="Reverse string in Excel Result">}}

## Useful resources

* Source code of this project on <a href="https://github.com/eyalmolad/gotask/tree/master/VSTO/UDF/ExcelRibbonUDF" target="_blank" rel="noopener noreferrer">GitHub</a>
