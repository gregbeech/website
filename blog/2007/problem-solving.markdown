Date: 2007-02-23  
Tags: Rants  

# Problem solving
    
On the [MSDN forums](http://forums.microsoft.com/msdn/) there are usually a few posts each week along the lines of "Please tell me what you think of this..." followed by a fairly long listing of entirely uncommented code. Presumably the poster is looking for feedback on the quality of the code but they are missing the fundamental point of writing code: Why did they write it in the first place?

If the code you write solves the problem that it needed to then it is good code, irrespective of how poor the quality of coding may be. If it does not solve the problem that you needed it to then it is bad code, irrespective of how wonderful the quality of the coding. If you didn't have a problem to solve in the first place, then why did you write it? Code that doesn't set out to solve any problem is neither bad nor good; it's just a waste of time.

Of course I'm oversimplifying here when I say any code that solves the problem it needed to is good code, but you've got to admit it's a better start than code that doesn't solve the problem, or code that solves no problem at all.

Typically, however, code that does solve a problem is good, assuming that you include things such as satisfactory handling of failure paths in the criteria for determining whether the problem has been solved. Anyone can develop a solution that works when everything is going well, but it takes a lot more thought and effort to handle the cases where things go wrong.