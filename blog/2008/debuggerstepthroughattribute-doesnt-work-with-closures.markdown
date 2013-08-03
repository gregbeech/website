Date: 2008-10-16  
Status: Published  
Tags: C#, Debugging, Functional Programming  

# DebuggerStepThroughAttribute doesn't work with closures
    
When you're implementing framework code, annotating it with [`DebuggerStepThroughAttribute`](ttp://msdn.microsoft.com/en-us/library/system.diagnostics.debuggerstepthroughattribute.aspx) is extremely useful because it instructs the debugger to skip over the method or class it is placed on unless there is an explicit breakpoint in the method. This means that in the majority case where you're simply taking advantage of the framework you can skip over it, but when the framework itself has issues you are still able to debug it.

Our core frameworks make extensive use of higher-order programming techniques, passing around lambda expressions between functions to encapsulate differences in common patterns. Things can get pretty confusing when debugging because the control flow jumps frequently between where the lambdas are used and where they are defined. This means that it's important to have the attribute applied so users of the framework can skip all this complexity and concentrate on the task in hand.

Unfortunately, it doesn't work if the lambda expressions form closures.

The following program demonstrates the issue. Run it using F11 (step into) and you'll see that while the debugger doesn't step directly into `Run`, it does stop on the `Console.WriteLine` statement inside the lambda expression. If you remove the part from the lambda that substitutes `s` into the format string (i.e. delete the `, s` part) then you'll notice that it doesn't stop because the lambda no longer forms a closure.

~~~csharp
class Program
{
    static void Main()
    {
        Foo.Run("But it does!");
    }
}

[DebuggerStepThrough]
class Foo
{
    public static void Run(string s)
    {
        Action a = () => Console.WriteLine("Debugger should not stop here. {0}", s);
        a();
    }
}
~~~

When a closure is formed the compiler synthesizes a class that captures the values of the variables along with the method body, so the code structure that is produced is like the following (note that I've renamed the synthesized class and method to Closure and Run because the real names are things like `<>c__DisplayClass1` and `<Run>b__2` which are legal in CIL but not in C#). If you step into this you'll notice that it also stops on the `Console.WriteLine` statement.

~~~csharp
class Program
{
    static void Main()
    {
        Foo.Run("But it does!");
    }
}

[DebuggerStepThrough]
class Foo
{
    [CompilerGenerated]
    private sealed class Closure
    {
        public string s;

        public void Run()
        {
            Console.WriteLine("Debugger should not stop here. {0}", this.s);
        }
    }

    public static void Run(string s)
    {
        var closure = new Closure { s = s };
        Action a = closure.Run;
        a();
    }
}
~~~

We can now see that the problem is a result of the synthesised Closure class not having a `DebuggerStepThroughAttribute` applied by the compiler, and the debugger not checking whether the outer class has the attribute. It's debatable as to whether the compiler should propagate class- and method-level attributes to the synthesized class because I'm sure there are scenarios where this would cause undesirable behaviour, but it would be useful to be able to apply attributes to lambdas manually. However, it seems inexcusable that the debugger does not check the outer class because the inner class is a member of it, and thus the attribute should apply in the same way as it does to any other member.

I raised this as an [issue at Microsoft Connect](https://connect.microsoft.com/VisualStudio/feedback/ViewFeedback.aspx?FeedbackID=336367) to see if they might fix it, but unfortunately it followed the typical pattern of just about any issue that gets raised there. Initially it was closed without any thought being given to the issue, with a resolution saying it was by design. I re-opened it explaining that the resolution was unsatisfactory and that there is no workaround for what is clearly the wrong behavior. This was then followed by the debugger team saying it was the compiler team's problem, and the compiler team resolving it as something they won't fix, without giving any explanation.

So there you have it. The behaviour of `DebuggerStepThroughAttribute` is fundamentally broken with respect to closures, it's unlikely to be fixed in the foreseeable future, and there is no workaround. It's a good job lambdas and closures aren't a major feature of C# 3.0. Oh, wait.