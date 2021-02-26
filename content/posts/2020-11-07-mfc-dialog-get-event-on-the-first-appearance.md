---
title: MFC Dialog – Get event on the first appearance
author: eyal
type: post
toc: true
date: 2020-11-07T05:12:49+00:00
url: /programming/mfc-dialog-get-event-on-the-first-appearance/
category:
  - Programming
tag:
  - cpp
  - dialogs
  - message-loop
  - mfc
  - post-message
  - win32

---
## Background

Sometimes we still need to maintain some legacy code that was written ages ago. A long time ago, MFC library was the default choice for many programmers wanted to develop a Windows Desktop Application in C++.  Today, there are much better alternatives for the Desktop Applications developments that include: WPF, WinForms, Electron and more. 

In this post, I am going to show a simple technique of how to get a callback in the ```CDialog``` derived class when the dialog is first shown.

## My Stack

* Visual Studio 2019 Community.
* MFC Dialog Based application (32-bit)
* Windows 10 Pro 64-bit (10.0, Build 19041)

## The challenge

{{<figure  width="367" height="223" src="/wp-content/uploads/2020/11/form_on_form.png" caption="Modal dialog over dialog in C# Winforms">}} 

Consider the following requirement: Show a modal dialog for the user to enter a username and
a password, once the main dialog has been first shown. In .NET WinForms, all we have to do is add a handler to [Form.Shown](https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.form.shown?view=netcore-3.1) event and show the modal dialog.

The sample code in C# would look something like:

```C#
private void Form1_Shown(object sender, EventArgs e)
{
  using (var loginDlg = new LoginForm())
  {
    loginDlg.ShowDialog(this);
  }
}
```

MFC comes with [OnInitDialog][1] overridable function in case we need to perform some processing during the dialog initialization. Once called, all our controls are already created and have the valid window handle. The problem with OnInitDialog function is that the dialog is not yet been shown to the user. If we attempt to show the modal dialog in the OnInitDialog function of the main dialog, the main dialog will not be shown until we close the second modal dialog. Unfortunately, MFC does not provide us with the dialog 'shown' event.

## The solution

The main idea is to postpone the second modal dialog creation for after the main dialog has been shown. This means that after OnInitDialog, we will need to get some callback function called and display our second dialog.

How do we achieve this? Fortunately, Win32 API enables us to register [custom windows messages](https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-user) for a private window use. We will use the [PostMessage](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postmessagea) Win32 API function to post such message to our window's thread message loop. ```PostMessage``` function returns immediately and the message handler would be called asynchronously. 

### Define the new window message

Every window message has it's own unique number. According to [this MSDN article][2], we can use messages from ```WM_USER``` to ```0x7FFF```.

So lets define the message as:

```#define WM_FIRST_SHOWN WM_USER + 100```

### Adding the callback function

In the main dialog class, define the ```WM_FIRST_SHOWN``` message handler. It must have the return type of ```LRESULT``` and get ```WPARAM``` and ```LPARAM``` as the function parameters although we are not going to use the parameters in this sample.

Place the second dialog creation in the callback's implementation code.

``` C++
LRESULT CMFCDialogOnLoadDlg::OnDialogShown(WPARAM,LPARAM)
{
  CLoginDialog dlg;
  dlg.DoModal();
  
  return 0;
}
```

### Adding the message to the message map

We need to bind the message id (```WM_FIRST_SHOWN```) to the message handler function.

Please the following code in your message map:

``` C++
ON_MESSAGE(WM_FIRST_SHOWN,OnDialogShown)
```

### Posting the message

{{<figure  width="362" height="263" src="/wp-content/uploads/2020/11/dialog_on_dialog.png" caption="Dialog on dialog in MFC">}} 

Finally, we need to post the ```WM_FIRST_SHOWN``` message to the main window's thread message queue. Place the following code to the end of you ```OnInitDialog``` member function.

```PostMessage(WM_FIRST_SHOWN);```

## Resources

* MFC source code available at <a href="https://github.com/eyalmolad/gotask/tree/master/MFC/MFCDialogOnLoad" target="_blank" rel="noopener noreferrer">GitHub</a>
* C# Source code available at <a href="https://github.com/eyalmolad/gotask/tree/master/Winforms/WindowsFormsDialogOnLoad" target="_blank" rel="noopener noreferrer">GitHub</a>

[1]: https://docs.microsoft.com/en-us/cpp/mfc/reference/cdialog-class?view=msvc-160#oninitdialog
[2]: https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-user