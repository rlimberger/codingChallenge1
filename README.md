codingChallange1
================

A coding challenge i had to do for a job interview. 

This iOS app connects to a server that is sending specific commands. The server was written
in python by the company i was interviewing for. One of the contrains of the project was only 
to use native iOS sdk APIs.

The iOS app i implemented, uses low level network API's and GCD dispatch sources to handle
the incoming network traffic asynchronously.

The rest of the app is pretty standard tableView and NSNotification pattern.
