# gdriveBACKUP

Google Drive can be used to backup large amounts of data. Some great Google API code available for grabbing data from external drives ([gdrive](https://github.com/prasmussen/gdrive); written by prasmussen) is wonderful, but will create new versions of files that already exist, and if it crashes, will need to be started again from scratch, and you will need to figure out what it already uploaded and what it did not. 

gdriveBACKUP.py is a python script that will sweep your Google Drive and local directory structures (including mounted drives), determine what files and directories do not exist on Google Drive, and then will upload the files to Google Drive sequentially using gdrive. If it crashes, it knows where it left-off, and will start running right where it left off (assuming you select this option). This code is not fast, but it does obey Google's rules and will not get you "banned" from Google Drive API calls, which is obviously a plus.

gdriveRESTORE.py is similar to gdriveBACKUP.py except it downloads (restores) files from Google Drive to your local directory. Any file or subdirectory that does not exist locally will be downloaded sequentially. 

## Getting Started

To get started, just download the python code gdriveBACKUP.py

### Prerequisites

Make sure python is installed. You will also need to download and install "gdrive", which can be found here: https://github.com/prasmussen/gdrive. This involves some steps, but is really darn easy.

### Initial Setup
There isn't any.

### Basic usage of gdriveBACKUP.py

To run this code, just cd to the directory holding gdriveBACKUP.py, and run the command with
```
python gdriveBACKUP.py <localDir> <gdDirID> 

```
where arguments are explained below.


To see the order of arguments and what can be called, use
```
>>python gdriveBACKUP.py -h

usage: gdriveBACKUP.py [-h] [--puwilo] [--loadbasefileonly] [--checkfilesize] [--savefileDir SAVEFILEDIR]
localDir gdDir gdDirID

positional arguments:
localDir            local file OR directory to upload. For directories, path should NOT contain a trailing backslash: e.g. correct = /Users/eabarnes/MISC
gdDirID             GD ID to the directory or file you wish to backup/upload.

optional arguments:
-h, --help          show this help message and exit
--puwilo            pick-up-where-I-left-off, i.e. load all data files that are saved (default: False)
--loadbasefileonly  only load the file with local and GD directories saved (default: False)
--checkfilesize     check both the name and file size - if sizes differ, delete GD file and upload local file (default: False)
--savefileDir SAVEFILEDIR
                    the base directory where to save the npz files that keep track of where things are (default: empty)
--dryrun						dry run of the command, so no files are actually uploaded to GD and no directories are made on GD (default: False)

```

### Basic usage of gdriveRESTORE.py

To run this code, just cd to the directory holding gdriveRESTORE.py, and run the command with
```
python gdriveRESTORE.py <localDir> <gdDirID> 

```
where arguments are explained below.


To see the order of arguments and what can be called, use
```
>>python gdriveBACKUP.py -h

usage: gdriveRESTORE.py [-h] [--puwilo] [--loadbasefileonly] [--checkfilesize]
[--savefileDir SAVEFILEDIR]
localDir gdDir gdDirID

positional arguments:
localDir            local directory where you want to download the data. Path should NOT contain a trailing backslash: e.g. correct = /Users/eabarnes/MISC
gdDirID             GD ID to the directory or file you wish to restore/download.

optional arguments:
-h, --help          show this help message and exit
--puwilo            pick-up-where-I-left-off, i.e. load all data files that are saved (default: False)
--loadbasefileonly  only load the file with local and GD directories saved (default: False)
--checkfilesize     check both the name and file size - if sizes differ, delete local file and download GD file (default: False)
--savefileDir SAVEFILEDIR
                    the base directory where to save the npz files that keep track of where things are (default: current working directory = os.cwd())
--dryrun						dry run of the command, so no files/directories are actually downloaded from GD (default: False)

```
## Little notes

* Currently, the maximum number of files in any one Google Drive directory cannot exceed 10,000,000 files. This can be modified in the python code quite easily.

## Authors

* **Elizabeth Barnes** - *Initial work*

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Thank you to prasmussen for writing the gdrive code. My script would not work without it.

