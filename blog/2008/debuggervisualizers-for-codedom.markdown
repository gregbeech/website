Date: 2008-11-05  
Tags: Code Generation, CodeDom, Debugging, Visual Studio  

# DebuggerVisualizers for CodeDom

Code generation is a great way to remove the chore of writing and maintaining boiler-plate code. If you're frequently going to be repeating and updating similar code then it's well worth the effort to write a domain-specific language (which can be as simple as an XML schema) and a compiler (which can just be a small console application) to spit out C#, or whatever your language of choice is.

A lot of people seem to use string concatenation to output code, but once you get used to the CodeDom object model it's actually easier to use because you don't have to worry about generating the code sequentially, or escaping strings, or the exact syntax of what you're trying to achieve. And of course you can also generate other languages simply by changing the code provider.

One thing that can be a pain with CodeDom though is getting feedback on exactly what you're emitting at any given point, so I wrote a couple of visualizers that let you see in C# or VB.NET what the output of anything from an entire compile unit to a single expression will be while you're debugging it. By hovering over any of the CodeDom constructs you'll see the little magnifying glass indicating visualizers are available:

{:.center}
![Percentage RSD against Shuffle Iterations](/codedom-visualizer-dropdown-menu.png)

Then you can choose the language and a visualizer window pops up with the code output:

{:.center}
![CodeDom C# visualizer window](/codedom-csharp-visualizer-window.png)

{:.center}
![CodeDom Visual Basic visualizer window](/codedom-vb-visualizer-window.png)

There are two visualizers based on a common class, differing only in the name of the language and the code provider they pass in. As a result it is easy to add other languages (for example C++/CLI and JScript.NET both have `CodeDomProvider` classes) but I've just shown two here as they're the ones most people are likely to be interested in. To allow the code to compile you need to add a reference to the following DLLs:

- Microsoft.VisualStudio.DebuggerVisualizers
- System.Drawing
- System.Windows.Forms

You may see two versions of the first assembly available in Visual Studio's add reference dialog, 8.0.0.0 and 9.0.0.0; choose the latter if you want the visualizer to work in Visual Studio 2008.

~~~ csharp
internal sealed class CSharpCodeDomVisualizer : CodeDomVisualizer
{
    public CSharpCodeDomVisualizer() 
        : base("C#", new CSharpCodeProvider())
    {
    }
}

internal sealed class VBCodeDomVisualizer : CodeDomVisualizer
{
    public VBCodeDomVisualizer()
        : base("Visual Basic", new VBCodeProvider())
    {
    }
}

internal abstract class CodeDomVisualizer : DialogDebuggerVisualizer
{
    private readonly string languageName;
    private readonly CodeDomProvider compiler;

    protected CodeDomVisualizer(string languageName, CodeDomProvider compiler)
    {
        this.languageName = languageName;
        this.compiler = compiler;
    }

    protected override void Show(
        IDialogVisualizerService windowService, IVisualizerObjectProvider objectProvider)
    {
        var writer = new StringWriter();
        var options = new CodeGeneratorOptions { BracingStyle = "C" };
        var item = objectProvider.GetObject();
        if (item is CodeCompileUnit)
        {
            this.compiler.GenerateCodeFromCompileUnit((CodeCompileUnit)item, writer, options);
        }
        else if (item is CodeNamespace)
        {
            this.compiler.GenerateCodeFromNamespace((CodeNamespace)item, writer, options);
        }
        else if (item is CodeTypeDeclaration)
        {
            this.compiler.GenerateCodeFromType((CodeTypeDeclaration)item, writer, options);
        }
        else if (item is CodeTypeMember)
        {
            this.compiler.GenerateCodeFromMember((CodeTypeMember)item, writer, options);
        }
        else if (item is CodeStatement)
        {
            this.compiler.GenerateCodeFromStatement((CodeStatement)item, writer, options);
        }
        else if (item is CodeExpression)
        {
            this.compiler.GenerateCodeFromExpression((CodeExpression)item, writer, options);
        }

        using (var form = new Form
            {
                Text = this.languageName + " CodeDom Visualizer",
                ClientSize = new Size(640, 480),
                FormBorderStyle = FormBorderStyle.SizableToolWindow,
                KeyPreview = true,                   
                Controls =
                    {
                        new TextBox
                            {
                                Dock = DockStyle.Fill,
                                Multiline = true,
                                Text = writer.ToString(),
                                Font = new Font("Consolas", 10f),
                                ScrollBars = ScrollBars.Both,
                                WordWrap = false
                            }
                    }
            })
        {
            form.KeyUp += (sender, e) =&gt; { if (e.KeyData == Keys.Escape) form.Close(); };
            windowService.ShowDialog(form);
        }
    }
}
~~~

As you can see the visualizer uses the code provider to generate the output value and displays it in a multi-line text box. The hook into the `KeyUp` event allows you to use the Esc key to dismiss the visualizer rather than having to click the close button.

To let Visual Studio know about the visualizers, and the type of objects that they apply to, we need to add a couple of assembly-level attributes:

~~~ csharp
[assembly: DebuggerVisualizer(typeof(CSharpCodeDomVisualizer), 
    typeof(VisualizerObjectSource),
    Description = "C# CodeDom Visualizer", 
    Target = typeof(CodeObject))]
[assembly: DebuggerVisualizer(typeof(VBCodeDomVisualizer), 
    typeof(VisualizerObjectSource),
    Description = "Visual Basic CodeDom Visualizer", 
    Target = typeof(CodeObject))]
~~~

Finally, the deployment stage involves copying the compiled assembly to the \Common7\Packages\Debugger\Visualizers\ folder under the Visual Studio installation directory (typically C:\Program Files\Microsoft Visual Studio 9.0\ for Visual Studio 2008). You don't even need to restart Visual Studio for them to be picked up - the next time you start debugging they will automatically be available.