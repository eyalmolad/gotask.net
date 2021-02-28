---
title: 'C# – VSTO – Extract images from PowerPoint presentation'
author: eyal
type: post
toc: true
date: 2020-10-31T07:43:24+00:00
url: /programming/vsto/c-sharp-extract-images-from-powerpoint-presentation/
category:
  - VSTO
tag:
  - dot-net
  - c-sharp
  - image
  - interop
  - open-xml
  - powerpoint
  - ribbon-xml
  - vsto
  - windows-api-codepack
  - zip
---

## Background

In one of my previous posts, I created a very basic VSTO example that adds a button to the [PowerPoint ribbon](/programming/vsto/c-sharp-vsto-addin-sample-for-excel-word-power-point-outlook/).

Recently, I had a task I needed to enumerate all the pictures in the Power Point presentation and extract them into a zip file.

Power Point presentation might contain many different shapes, such as rectangles, lines, arrows, textboxes, pictures and more. Each shape might contain a text, but it might also contain a picture. 

In this post, I am going to show how to extract the images using 2 different techniques:

* PowerPoint COM Interop API
* Extract directly from ZIP file

## My Stack
* Visual Studio 2019 Community.
* .NET Framework 4.7.2 / C#
* Office 365, Desktop Edition.
* Windows 10 Pro 64-bit (10.0, Build 19041)
* PowerPoint Interop DLL version 15


## Working with PowerPoint C# Interop version 15.0.0.0

### Step 1 - Create a button

As shown in the previous example, I am adding a button element to the Ribbon XML. This button will have a callback set in the action attribute.

``` XML
<customUI xmlns='http://schemas.microsoft.com/office/2009/07/customui'>
  <ribbon>
     <tabs>
      <tab id='sample_tab' label='GoTask'>
        <group id='sample_group' label='Operations'>
          <button id='extract_images' label='Extract Images' size='large' getImage='OnGetImage' onAction='OnExtractImage'/>
        </group>
      </tab>
    </tabs>
  </ribbon>
</customUI>
```

### Step 2 - Collect the images from different shapes

PowerPoint presentation can store the images in a few shapes types. All the different shape types are represented by [MsoShapeType](https://docs.microsoft.com/en-us/office/vba/api/office.msoshapetype) enum. In order to recognize the Shape type, we are going to use [Shape.Type](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.shape.type) and [Shape.PlaceholderFormat.ContainedType](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.shape.placeholderformat) properties: 

* Picture - ```MsoShapeType.msoPicture``` or ```MsoShapeType.msoLinkedPicture```
* Picture contained in a placeholder ```MsoShapeType.msoPlaceholder```
* Other shapes that might have a [PictureFormat](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.pictureformat) property properly initialized.

In the [sample presentation](https://github.com/eyalmolad/gotask/blob/master/VSTO/PowerPointExtractImages/SamplePresentation.pptx), I've created a few shapes that contain pictures in different formats.

In order to extract the image, I am going to use the PowerPoint Shape [Export](https://docs.microsoft.com/en-us/previous-versions/office/office-12/ff761596(v=office.12))function.

In order to choose a directory for saving the images, I am going to use the CommonOpenFileDialog implemented in [Microsoft-WindowsAPICodePack-Shell](https://www.nuget.org/packages/Microsoft-WindowsAPICodePack-Shell/). Here is the sample implementation of using a directory picker:

``` C#
private string GetSaveDir()
{
  using (var dialog = new CommonOpenFileDialog())
  {
    dialog.IsFolderPicker = true;

    var result = dialog.ShowDialog();

    if (result == CommonFileDialogResult.Ok)
    {
      return dialog.FileName;
    }
  }

  return null;
}
```

The code below iterates over all slides in the presentation and extracts the images from the shapes.

Please note the following remarks:

* The extracted images are in PNG format using the ```PpShapeFormat.ppShapeFormatPNG``` enum. You can specify JPG, BMP or other formats defined in the ```PpShapeFormat``` enum.

* Pay attention for the ```shape.PictureFormat.CropBottom``` check. Generally, every shape has ```PictureFormat``` set to a non-null value. So we can't count on filtering out the shapes that have this property set to null. The trick is to try to access one of the properties (CropBottom or other). If the exception is thrown, we can skip the object (it's not a picture).

``` C#
var i = 1;
foreach (Slide slide in app.ActivePresentation.Slides)
{
  foreach (Shape shape in slide.Shapes)
  {
    var doExport = false;

    if (shape.Type == MsoShapeType.msoPicture ||
      shape.Type == MsoShapeType.msoLinkedPicture)
    {
      doExport = true;
    }
    else if (shape.Type == MsoShapeType.msoPlaceholder)
    {
      if (shape.PlaceholderFormat.ContainedType == MsoShapeType.msoPicture ||
        shape.PlaceholderFormat.ContainedType == MsoShapeType.msoLinkedPicture)
      {
        doExport = true;
      }
    }
    else
    {
      try
      {
        // this is just a dummy code. In case there is no picture in the
        // shape, any attempt to read the CropBottom variable will throw 
        // an exception
        var test = shape.PictureFormat.CropBottom > -1;
        doExport = true;
      }
      catch
      {
        doExport = false;
      }
    }

    if(doExport) 
      shape.Export(Path.Combine(saveDirectory, $"{i++}.png"), PpShapeFormat.ppShapeFormatPNG);
  }
}
```

When running this code on the presentation provided with the project, it should export 4 pictures to the chosen directory. (Picture's credit: [Unsplash](https://unsplash.com))

## Working with ZIP file to extract the images

The pptx format is actually a zip file with a well formed structure defined in the Open-XML format. You could open the pptx file with any zip file extractor and look at it's contents. Fortunately, the pictures are stored in the ```ppt\media``` directory within the archive.

All I have to do now it to extract the archive and grab the images.

I am going to use the .NET [ZipFile](https://docs.microsoft.com/en-us/dotnet/api/system.io.compression.zipfile?view=netcore-3.1) class located in ```System.IO.Compression``` namespace.

1. Open the pptx file using ```ZipFile.Open```
2. Create a temporary ```temp_zip``` directory to extract the files to
3. Copy the media files
4. Delete the temporary ```temp_zip``` directory

```C#
private void ExtractWithZip(string pptxFile, string directory)
{
  var zipDir = "";

  using (var arh = ZipFile.Open(pptxFile, ZipArchiveMode.Read))
  {
    zipDir = Path.Combine(directory, "temp_zip");
    Directory.CreateDirectory(zipDir);
    arh.ExtractToDirectory(zipDir); // extract

        // iterate over files in the extracted dir.
    foreach (var f in Directory.GetFiles(Path.Combine(zipDir, @"ppt\media")))
      File.Copy(f, Path.Combine(directory, Path.GetFileName(f)));
  }

  // clean up
  try
  {
    var dirToDelete = new DirectoryInfo(zipDir);
    dirToDelete.Delete(true);
  }
  catch
  {
    //
  }
}
```

## Useful resources

* Source code of this project on [GitHub](https://github.com/eyalmolad/gotask/tree/master/VSTO/PowerPointExtractImages)

