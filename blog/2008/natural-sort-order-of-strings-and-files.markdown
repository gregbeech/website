Date: 2008-11-12  
Tags: P/Invoke, Sorting  

# Natural sort order of strings and files
    
In Windows XP and Vista the algorithm used to sort files by name in Explorer does not simply compare the strings alphabetically, but has additional logic such as treating numeric characters as numbers. This means that a file named "20.txt" appears after "3.txt" in Explorer, even though alphabetically it would appear before it. The good news is that the algorithm used to do this is available for use in the form of [`StrCmpLogicalW`](http://msdn.microsoft.com/en-us/library/bb759947.aspx) ([more info from Michael Kaplan here](http://blogs.msdn.com/michkap/archive/2005/01/05/346933.aspx)).

It isn't exposed in .NET, however we can easily create a custom `IComparer<T>` implementation which uses it by P/Invoking the method as shown below. As always, you'd probably want to add some argument checking for null values etc. in production code.

~~~ csharp
[SuppressUnmanagedCodeSecurity]
internal static class SafeNativeMethods
{
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
    public static extern int StrCmpLogicalW(string psz1, string psz2);
}

public sealed class NaturalStringComparer : IComparer<string>
{
    public static readonly NaturalStringComparer Default = new NaturalStringComparer();

    public int Compare(string x, string y)
    {
        return SafeNativeMethods.StrCmpLogicalW(x, y);
    }
}

public sealed class NaturalFileInfoNameComparer : IComparer<fileinfo>
{
    public static readonly NaturalFileInfoNameComparer Default = new NaturalFileInfoNameComparer();

    public int Compare(FileInfo x, FileInfo y)
    {
        return SafeNativeMethods.StrCmpLogicalW(x.Name, y.Name);
    }
}
~~~

Nothing too hard there, but there are a couple of important implementation details. Firstly the P/Invoke declaration is declared in a class named SafeNativeMethods with the [`SuppressUnmanaedCodeSecurityAttribute`](http://msdn.microsoft.com/en-us/library/system.security.suppressunmanagedcodesecurityattribute.aspx) applied, which significantly improves performance and adheres to the [framework design guidelines for P/Invoke](http://blogs.msdn.com/fxcop/archive/2007/01/14/faq-how-do-i-fix-a-violation-of-movepinvokestonativemethodsclass.aspx). Secondly the comparer classes have a read-only field containing a default comparer instance so they can be used without having to instantiate instances for a minor performance and usability gain.