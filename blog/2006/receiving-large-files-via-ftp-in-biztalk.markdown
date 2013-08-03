Date: 2006-02-22  
Status: Published  
Tags: BizTalk  

# Receiving large files via FTP in BizTalk
    
On a recent project I needed to download some messages into BizTalk 2004 from an FTP site. The smaller files seemed to work fine, but larger files were failing, being left on the FTP server, and being reattempted periodically in an effectively infinite loop. If you have any issues with the FTP adapter, there is a setting in the Receive Location properties which allows you to specify an FTP log file - examination of this file showed that the files were being downloaded successfully, but the connection was then timing out some time after that.

As FTP is a non-transaction protocol, the FTP adapter receives a file as follows to ensure it remains on the server if it fails to be saved to the Message Box database, and thus the file cannot be lost in the transfer process:

1. Download the file
2. Run the receive pipeline
3. Store the message in the Message Box database
4. Delete the file from the FTP serve

Some internet research unearthed that the FTP adapter has a two minute (not configurable) timeout after which it will close the connection and abort if this process is not completed. As is often the case with files being received via FTP these were flat files, and to further complicate matters they were also zipped, so a fairly intensive receive pipeline was being used to decompress and parse them into XML. With the larger files the time taken to execute the pipeline could exceed the two minute timeout which caused the entire receive to fail.

As there was no way to significantly reduce the execution time of the pipeline the only way around it was to not run the pipeline at this point, so the fairly simple solution I used was:

1. Change the pipeline on the FTP Receive Location to the built-in PassThruReceive pipeline
2. Create a new FILE Send Port which subscribes to the Receive Port, using the built-in PassThruTransmit pipeline, to put the unmodified file in a temporary location on disk
3. Add a new FILE Receive Location in a new Receive Port which monitors the temporary disk location and uses the original receive pipeline to import the messages into BizTalk

As there are no timeouts in the FILE adapter this allows the receive pipeline as much time as it needs to decompress and parse the file. This solution also works fine when you have multiple hosts as you can set the temporary storage location to be a network share, and it can be made reliable by hosting the share on a cluster.