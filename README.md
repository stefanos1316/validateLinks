[![Build Status](https://travis-ci.org/stefanos1316/validateLinks.svg?branch=master)](https://travis-ci.org/stefanos1316/validateLinks)
[![GPL Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=103)](https://opensource.org/licenses/GPL-3.0/)

# About validateLinks

A tool aiming to report the links' status for a user's repository (cloned locally), local directory, or a link.

Our mission here is to provide a tool that can check if the links found in different documents tpyes (not PDF supported yet) are broken or not. 
Also, we extend the features of our tool to perform First Depth Search (FDS) to identify even more links found under tree directories.
The tool can output results in a terminal or in a file (for post analysis). 


# Dependencies

* Install lynx command for --link option


# Try it out

Use -h or --help to get a Linux-like _man_ page regarding the command-line arguments.
It can be used to validate links from different directories, projects, or online links.


# Overview

<p align="center">
<table class="image">
<tr><td> <img src="media/1.png"  /></td></tr>
<tr><td class="caption" align="center">Analyzing Repository</td></tr>
</table>
</p>


# Contributions and used Repositories

* Checkout the PENDING directory to implement features that might need for the tool.
* Special thanks to my friend [Alexandre De Masi](https://github.com/SheepOnMeth) for the testing.
