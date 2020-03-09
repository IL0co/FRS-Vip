
<h3 align="center">[FRS][Vip] Vip</h3>
<p align="center">Ranking icons for VIP Players</p>
<br />
<br />

<p align="center">
<img src="https://img.shields.io/github/downloads/IL0co/FRS-Vip/total?style=flat-square" /></a>
<a href="../../releases"><img src="https://img.shields.io/github/release/IL0co/FRS-Vip?style=flat-square"/></a>
<a href="../../issues"><img src="https://img.shields.io/github/issues/IL0co/FRS-Vip?style=flat-square" /></a>
<a href="../../pulls"><img src="https://img.shields.io/github/issues-pr/IL0co/FRS-Vip?style=flat-square" /></a> 
</p>

## Description
* This module allows you to buy ranks in a Vip

## Thumbs preview
**This function is enabled only if preview_mode > 0**

+ **If PreviewEnable == 1** You must upload the png file to any hosting in order to get the full url link to the image. After registering this link in the line **"preview"** in the desired item

<img src="https://i.imgur.com/C8oRmuj.png" width="70%">  

# Installation 

## Requirements
* [FRS Core](https://github.com/IL0co/FRS-Core)
* [Vip Core](https://hlmod.ru/resources/vip-core.245/)

## Filter key</font>
* <font color='#FFA500'>**vip**</font>

## Installation Instructions
1. Drop all files on to the server folder
2. Configure cfg files
3. Reboot the server or launch plugins manually

## Configuration files

* **addons/sourcemod/data/vip/modules/fakerank.txt**

+ **addons/sourcemod/data/vip/cfg/groups.ini**
```markdown
"VIP_GROUPS"
{
	"YouGroupName"
	{
     // "FakeRanks"         "enumeration of groups from the file "modules/fakerank.txt", divided through;"
        "FakeRanks"         "group1;group2"

        OR

        "FakeRanks"         "all"   // "all" - To give out access to all registered ranks
    }
}

```


## Contributions
Contributions are always welcome!
Just make a [pull request](../../pulls).

## Feedback (support the author a pretty penny!)
* [Telegram](https://t.me/LocoCat)

