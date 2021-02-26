---
title: 'C# - How to add or remove items from Windows recent files'
author: eyal
type: post
toc: true
date: 2020-05-02T23:19:51+00:00
url: /programming/c-sharp-how-to-add-or-remove-items-from-windows-recent-files/
category:
  - Programming
tag:
  - c-sharp
  - pinvoke
  - shell-api

---
## Background

Starting Windows 7, Microsoft added a capability for displaying recently used files. This usually includes documents, pictures, and movies we've recently accessed. These files can be seen in various Windows components, including:

* Recent files
* Recent items
* Start menu or application's Jump List

The management of the listed files is done by the operating system.

In this post, I will show how to programmatically add and remove items from the Recent files list using C#.

## My Stack

  * Visual Studio 2019 Community Edition (16.5.1)
  * Console application built on .NET Framework 4.7.2 (C#) &#8211; 32/64 bit.
  * Windows 10 Pro 64-bit (10.0, Build 18363) (18362.19h1_release.190318-1202)

## Solution

1. I created a helper class that uses Windows Shell API [SHAddToRecentDocs](https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shaddtorecentdocs).
2. Imported the function using PInvoke.
3. Added 2 functions: 
  * AddFile -> adds the file to Recent files view.
  * ClearAll -> clears all files from Recent files view.


```C#
public static class RecentDocsHelpers
{
  public enum ShellAddToRecentDocsFlags
  {
    Pidl = 0x001,
    Path = 0x002,
    PathW = 0x003
  }

  [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
  private static extern void SHAddToRecentDocs(ShellAddToRecentDocsFlags flag, string path);

  public static void AddFile(string path)
  {
    SHAddToRecentDocs(ShellAddToRecentDocsFlags.PathW, path);
  }

  public static void ClearAll()
  {
    SHAddToRecentDocs(ShellAddToRecentDocsFlags.Pidl, null);
  }
}
```

### Usage

```C#
class Program
{
  static void Main(string[] args)
  {
    RecentDocsHelpers.ClearAll();

    // add c:\temp\sample.json to recent files.
    RecentDocsHelpers.AddFile(@"c:\temp\sample.json");
  }
}
```

## Limitation
1. You can not add executable files to Recent files.

## Result

{{<figure  width="800" height="261" src="/wp-content/uploads/2020/05/windows-recent-files-added-e1588421810539.png" caption="Windows recent files">}}  

## Useful resources

* Source code of this project on [GitHub](https://github.com/eyalmolad/gotask/tree/master/Utils/RecentFiles)
