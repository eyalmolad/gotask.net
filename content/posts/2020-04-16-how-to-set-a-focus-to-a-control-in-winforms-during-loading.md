---
title: How to set the focus during loading to a control in WinForms
author: eyal
type: post
date: 2020-04-16T18:13:46+00:00
toc: true
url: /programming/winforms/how-to-set-a-focus-to-a-control-in-winforms-during-loading/
category:
  - Winforms
tag:
  - c-sharp
  - combobox
  - textbox
  - listbox

---
## Background

Usually when creating forms with different controls, we would like the form be opened with a specific control in focus. This is usually true for Textboxes, but could be also very relevant for other controls such as ComboBox, Radio control, Listbox, and more. There are several ways to achieve this functionality with a very little of coding.

## My Stack

* Visual Studio 2019 Community Edition (16.5.1)
* WinForms application built on .NET Framework 4.7.2 (C#) 32/64 bit.
* Windows 10 Pro 64-bit (10.0, Build 18363) (18362.19h1_release.190318-1202)

## Solutions

{{<figure  width="500" height="303" src="/wp-content/uploads/2020/04/win-form-sample-1.png" caption="Windows Form in sample controls">}}  


### 1. Default behavior - the lowest TabIndex

By default, Windows will set the initial focus to the control with the lowest ```TabIndex``` value.

### 2. Setting the active control property

A ```Form``` inherited class contains the inherited property ```ActiveControl``` of type ```Control```. As all Windows UI elements inherit from a Control, setting this reference to one of our controls in the Load event handler will automatically make it focused once the dialog is first shown.

```C#
private void Form1_Load(object sender, EventArgs e)
{
  ActiveControl = textBox1;
}
```

Note that the control must have the following properties set to ```True``` value:

* Visible
* Enabled

In case the one of the properties above is ```False```, the focused control will be the next control according to the ```TabIndex.```

### 3. Calling the Focus() member function

I mentioned before that all Windows UI elements are inherited from the Control class. This class provides us the ```Focus()``` member function.

We can use this function to capture the focus to a specific control, but unfortunately it will not work in [Load](https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.form.load?view=netframework-4.8) event handler. The reason is that we can not set focus to a control that haven't been rendered (shown).

However, WinForms provides us the [Show](https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.form.shown?view=netframework-4.8) event that occurs whenever the form is first displayed. In the event handler, we can call for Focus function as shown in the code below:

```C#
private void Form1_Shown(object sender, EventArgs e)
{
  textBox1.Focus();
}
```
### 4. Calling the Select() member function

Looking at the [source code of Control.cs class](https://referencesource.microsoft.com/#System.Windows.Forms/winforms/Managed/System/WinForms/Control.cs,6c9dc153b2c496ae), calling the ```Select``` function without parameters is similar to setting the ```ActiveControl```.
