Date: 2013-07-04  
Status: Published  
Tags: Debugging, Humour  

# Blue screen of nostalgia

A long time ago I wrote a blog post detailing [how to trap ASP.NET assertions](/blog/how-to-integrate-debug-assert-with-your-asp-net-web-application) and return a custom error page instead of the default (stupid) behaviour of popping up a modal dialogue box from a server process.

What I didn't explain at the time was that I often like to put little jokes in software (yeah, I know, it's unprofessional, but it's fun) and so our assertion screen wasn't just the boring error page I described in that post. It was one designed to give developers a bit more of a shock.

As time went on I forgot all about it because we got much better at writing software that didn't have any assertion failures. The company got bigger, we got a load of new developers who'd never even seen it, and it faded into history. Until last week when there was a very confused email...

> To: *Team Movies Technology  
> Subject: Blue screen of death in the browser??? - disable developer options such as checking-in or breathing?

With the attached screenshot:

{:.center}
![blinkbox blue screen of death](/blinkbox-bsod.jpeg)

I can't believe it still exists after all these years!

It still makes me laugh when I think how much panic it used to cause people when they thought their computer had really blue-screened. Even when you'd seen it before and knew it was a trick you never _entirely_ got used to it.

I also remembered one of the easter eggs from the early days which has long since been removed. It was an admin site setting which let us configure (on a per user basis) a percentage chance of following any link on the site [Rickrolling](http://knowyourmeme.com/memes/rickroll) the user instead of doing what it was supposed to. If people annoyed us then we'd just knock it up a few percent and it would irritate the hell out of them... and of course the bug reports were always closed as "no repro" because we'd just change the setting back to zero!

Timescales are _never_ too tight for the occasional undocumented feature ;-)