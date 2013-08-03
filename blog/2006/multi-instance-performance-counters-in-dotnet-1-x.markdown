Date: 2006-04-04  
Status: Published  
Tags: Installers, Monitoring, Performance  

# Multi-instance performance counters in .NET 1.x

Custom performance counters are great for monitoring your system's performance in key areas... they're also good for monitoring the performance of systems you're calling into so that if you miss Service Level Agreements (SLAs) you've got the proof that it's not your code at fault! When you're taking the same type of measurements for different systems multi-instance performance counter instances are the obvious approach, however it isn't completely straightforward to get them working in .NET 1.0 or 1.1 (note that version 2.0 is much improved and this article doesn't apply to it).

When performance counters are installed, registry entries need to be created. Although the PerformanceCounter class has methods which allow you to do this at runtime, don't do this as it requires the application to run with Administrator privileges which is hardly good for security. A simple installer can be written as shown below, and then the assembly can be installed using InstallUtil to create the performance counters.

~~~csharp
[RunInstaller(true)]
public class MyInstaller : Installer
{
    public MyInstaller()
    {
        PerformanceCounterInstaller installer = new PerformanceCounterInstaller();
        installer.CategoryName = "My Service";
        installer.CategoryHelp = "Counters for my service.";
        installer.Counters.Add(new CounterCreationData(
            "Requests",
            "Number of requests",
            PerformanceCounterType.NumberOfItems64));
    }
}
~~~

There are two potential problems with the counter as created by this installer. Firstly the counter type is undefined, and the category options may be incorrect. Either of these may prevent your counters from working (though it's only with multi-instance ones that I have noticed any issues).

## Counter Type

The registry entry for each created performance counter category has a `DWORD` value named `IsMultiInstance` which can have one of the following settings:

- `0` - Counter is single instance (a global counter)
- `1` - Counter is multi-instance
- `0xFFFFFFFF` - Unknown whether counter is single or multi-instance

The unknown value is the default when installing counters with .NET 1.x which seems to work fine for global counters, however multi-instance ones don't always seem to work properly. Fortunately it's simple to add a method to your installer that will change this value depending on your requirements:

~~~csharp
private static void SetMultiInstance(string categoryName, bool multiInstance)
{
    string key = string.Format(
        CultureInfo.InvariantCulture, 
        "SYSTEM\\CurrentControlSet\\Services\\{0}\\Performance", 
        categoryName);
    using (RegistryKey categoryKey = Registry.LocalMachine.OpenSubKey(key, true))
    {
        if (categoryKey == null)
        {
            throw new InstallException("Category is not installed.");
        }
        categoryKey.SetValue("IsMultiInstance", multiInstance ? 1 : 0);
    }
}
~~~

To call this method as part of the installation, simply override OnInstall, call the base method to do the standard installation, and then perform the custom step:

~~~csharp
public override void Install(IDictionary stateSaver)
{
    base.Install(stateSaver);            
    SetMultiInstance("My Service", true);
}
~~~

## Category Options

The registry entry for each .NET performance counter also has a `DWORD` value named `CategoryOptions`. The purpose of this entry is not well described in any documentation but eventually I managed to find [this blog entry from the .NET Framework Base Class Library (BCL) team](http://blogs.msdn.com/bclteam/archive/2005/03/16/396856.aspx) which details its purpose, and essentially it controls the way the memory for performance counter instances is handled within each process. There are three possible values for this listed in the entry:

- `0` - No memory reuse; all versions of .NET can read/write
- `1` - Reuse when instance name is the same length; all versions of .NET can read/write
- `3` - Reuse all memory; .NET 2.0 can read/write but .NET 1.x can only read

The value this is set to on install depends on which version of InstallUtil you use. When using InstallUtil from v1.x of the framework it is set to 1 which is fine, however when you use InstallUtil from v2.0 to install a v1.x assembly it it set to 3 (i.e. cannot be written to by .NET 1.1!). Oddly no errors are thrown when writing to the counters; they just didn't seem to record the data reliably.

To fix this problem a similar method to the counter type can be used to set the value to 1 as part of the installation which is the most efficient memory handling available in .NET 1.1:

~~~csharp
private static void SetCategoryOptions(string categoryName, int categoryOptions)
{
    string key = string.Format(
        CultureInfo.InvariantCulture,
        "SYSTEM\\CurrentControlSet\\Services\\{0}\\Performance",
        categoryName);
    using (RegistryKey categoryKey = Registry.LocalMachine.OpenSubKey(key, true))
    {
        if (categoryKey == null)
        {
            throw new InstallException("Category is not installed.");
        }
        categoryKey.SetValue("CategoryOptions", categoryOptions);
    }
}
~~~

The complete installer class which will correctly install the multi-instance performance counters will look similar to the following. It may be more useful to move the SetCategoryOptions and SetMultiInstance methods either into a utility class or a common base class so that they can be referenced by other performance counter installers.

~~~csharp
[RunInstaller(true)]
public class MyInstaller : Installer
{
    public MyInstaller()
    {
        PerformanceCounterInstaller installer = new PerformanceCounterInstaller();
        installer.CategoryName = "My Service";
        installer.CategoryHelp = "Counters for my service.";
        installer.Counters.Add(new CounterCreationData(
            "Requests",
            "Number of requests",
            PerformanceCounterType.NumberOfItems64));
        this.Installers.Add(installer);
    }
    
    public override void Install(IDictionary stateSaver)
    {
        base.Install(stateSaver);            
        SetMultiInstance("My Service", true);
        SetCategoryOptions("My Service", 1);
    }
    
    private static void SetCategoryOptions(string categoryName, int categoryOptions)
    {
        string key = string.Format(
            CultureInfo.InvariantCulture,
            "SYSTEM\\CurrentControlSet\\Services\\{0}\\Performance",
            categoryName);
        using (RegistryKey categoryKey = Registry.LocalMachine.OpenSubKey(key, true))
        {
            if (categoryKey == null)
            {
               throw new InstallException("Category is not installed.");
            }
            categoryKey.SetValue("CategoryOptions", categoryOptions);
        }
    }
    
    private static void SetMultiInstance(string categoryName, bool multiInstance)
    {
        string key = string.Format(
            CultureInfo.InvariantCulture,
            "SYSTEM\\CurrentControlSet\\Services\\{0}\\Performance",
            categoryName);
        using (RegistryKey categoryKey = Registry.LocalMachine.OpenSubKey(key, true))
        {
            if (categoryKey == null)
            {
                throw new InstallException("Category is not installed.");
            }
            categoryKey.SetValue("IsMultiInstance", multiInstance ? 1 : 0);
        }
    }
}
~~~