# GoProX

[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/fxstein/goprox?include_prereleases)](https://github.com/fxstein/goprox/releases)
[![GitHub](https://img.shields.io/github/license/fxstein/goprox)](https://github.com/fxstein/GoProX/blob/main/LICENSE)
[![GitHub top language](https://img.shields.io/github/languages/top/fxstein/goprox)](https://github.com/fxstein/GoProX/search?l=Shell&type=code)
[![GitHub labels](https://img.shields.io/github/labels/fxstein/goprox/help%20wanted)](https://github.com/fxstein/GoProX/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)

The missing GoPro workflow and data manager for macOS.

For those with one or more GoPro cameras. When using these action cameras regularly, 
the limitations of the GoPro ecosystem quickly become very obvious. 
GoPro is focusing its efforts on its mobile app experience, and not much development 
is directed toward macOS.
GoProX is geared toward (semi-) professionals and prosumers that simply need
more from their devices.
GoProX is based on a data-first approach to importing, processing and maintaining
media generated by various GoPro devices. At this moment the tool is actively
developed and tested with GoPro Hero8, Hero9, Hero10, Hero11 and GoPro Max.

## Installation

The most common way to install `goprox` is via home-brew.

To install `goprox` simply type

```
brew install fxstein/fxstein/goprox
```

Alternatively, you can add the fxstein tap manually before installing goprox

```
brew tap fxstein/fxstein
brew install goprox
```

Once installed, you can upgrade `goprox` by simply running

```
brew upgrade goprox
```

Alternatively, you can also uninstall and reinstall goprox in case of issues with the
upgrade

``` 
brew uninstall goprox
brew install goprox
```

### Setup
To simplify repeat usage of `goprox` it supports saving its configuration in `~/.goprox`.
To create this configurations file, simply execute `goprox` with its `--setup` option:

```
goprox --setup --library "/mylibrary/dir" --source "." --copyright "My Name"
```

You can also create alternate configuration files by specifying the `--config` option:

```
goprox --config "myotherconfig" --setup --library "/myotherlibrary" --source "." --copyright "My Other Name"
```

All subsequent runs of `goprox` will by default leverage the setting stored in `~/.goprox`
unless the `--config` option is specified with an alternate configuration file.

The `--setup` option can be rerun as often as desired to change the settings stored in `~/.goprox`.
Whenever `--setup` detects a prior configuration it creates a backup copy named like 
`.goprox.bak.1657302965`. The configuration file is a simple text file that is sourced in `goprox`.

As part of the setup, `goprox` will create a library skeleton unless the library already exists. 
The default location is `~/goprox`, but placing the library on a dedicated storage device is highly 
encouraged as the data volumes will be very significant. 

This is the hierarchy of the `goprox` library:

```
goprox/ (named and placed as required)
├── archive/
├── imported/
├── processed/
└── deleted/
```
All subsequent runs of `goprox` will validate this storage hierarchy. See the storage hierarchy section
for more details

## Usage

Once installed and set up GoProX maintains a file system based media library that
is organized by time, camera types and media file types. The main goal is to
maintain all file details from the original to the processed items, even if media
files are further being processed in various apps including e.g.
[Apple Photos](https://www.apple.com/ios/photos/) or
[Blackmagic DaVinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve/).
Unfortunately, many commonly used apps ignore most of the important metadata,
making it very hard for users to filter, sort or search for common things inside ever-growing 
libraries of media.
GoProX performs a few simple tasks that will make your life with GoPro
media on Apple platforms a lot easier.
First, it renames the files as part of `--import` and `--process` tasks. This is an
often overlooked step that will lead to the loss of some of the most basic metadata
over time. Especially when files get exported, copied or moved, things like the original date 
& time, and the source of the original image can get lost easily, creating issues down the line.

It then adds additional tags and keywords into the processed media files to make
searching, filtering and corrections a lot easier.

GoProX supports `--geonames` lookups for GPS-based timezone information,
`--firmware` checks and upgrades, `--archive` of raw media into compressed
archives before `--import` and `--process` tasks are being applied, a `--clean`
task to remove processed media from storage devices as well as a `--timeshift`
task that makes it possible to bulk change the date and time information of
media files. It also makes it easy to apply default `--copyright` tags to all
processed media.
Default options can be set using the `--setup` tasks and settings are being
stored in the user's home directory in `~.goprox`.
The output can be timestamped via the `--time` option to log long-running tasks.
For developers, GoProX comes with a small set of test data from various cameras
that allows for testing and validation of changes with the `--test` option.

## Examples

```
goprox --import
```
The `--import` option will read from `source` (default to the current directory `.`) and 
import all image and video media files into `library\imported`.
This is best used for importing media files from the path of a mounted media card. To do 
so, insert your camera's microSD card into a reader attached to your Mac. Open Finder 
to see the mounted card, right-click it and select `New Terminal at Folder`. This will 
open a new zsh terminal at the mounted card folder.

Alternatively `--import` can process a `tar.gz` archive directly. It will first untar
the contents into a temp directory and then import from there. This is helpful when 
re-importing previously archived sd card data

```
goprox --archive
```
The `--archive` option will create a full archive of the `source` folder as a tarball inside
`library\archive` named like `20220802215621_GoPro_Hero10_2442.tar.gz`. This is useful to
preserve the full content of the SD card before making any changes to it. 

```
goprox --archive --import --clean
```
All the options can be performed in a single pass. In this example `goprox` will first
create a new `archive` of the `source`, then import all the media files contained on the
`source` and finally remove all media files from the `source`. The `--clean` option will 
only execute when combined with either `--archive` or `--import` or both to avoid 
accidental deletion of media files. 

```
goprox --firmware
```
The `--firmware` option will check the camera model and current firmware version of the sd card
currently mounted and will upgrade it to the latest GoPro firmware for your model if a newer 
one exists. Simply put the sd card back into the camera and on the next boot up the camera will 
upgrade itself. 

The `labs` modifier: `goprox --firmware labs` will perform the same check for the latest GoPro 
Labs firmware version. Ommitting the `labs` modifier in a later firmware check will return the
camera to the latest official firmware.

```
goprox --import --time
```
Adding the `--time` option creates a timestamped output of the `goprox` run to aid in logging
for long-running tasks that import or process thousands of media files.
All output of `goprox` is getting timestamped like 

`[2022-08-04 12:15:09] Info: goprox v00.08.08`

```
goprox --archive --import --clean --time --firmware
```
This example combines the most commonly used features for any import of media files directly
from the camera's sd card.
`--archive` creates a full tarball of the content 
`--import` imports all media files into the `library`
`--clean` removes all media files from the sd card upon successful completion of the `--archive` and `--import` tasks
`--time` timestamps all `goprox` output
`--fimware` checks the sd-card for the current firmware version of the camera and if necessary
installs the latest firmware onto the card for an automatic upgrade next time the camera is 
booted up. For this to function properly sd-cards of different cameras should not be mixed. 

It is recommended to perform as many `import` tasks as you have cameras with new footage.
Multiple camera sd-card can be imported simultaneously if a multi-card reader is available.

```
goprox --process --time
```
The `--process` option takes unmodified imported media files and rewrites them with enhanced
metadata. This is where `goprox` inserts tags and flags into the media files that are then picked
up by the likes of Apple Photos. For GoPro video media (mp4 & 360) `--process` also performs 
a UTC timeshift of all the Quicktime tags to allow downstream tools like Apple or Google Photos
to display the correct date and time.

By default, `process` will look for newly imported media files 
since the last `process` run. Alternatively, `all` or any valid time window can be specified 
`*[0-9](y|m|w|d|H|M|S)`. 
For example, `goprox --process 30d` will process the past 30d while `goprox --process all` will 
process all imported media files. Caution should be used when reprocessing older media files as the
content of a file will change with a newer version of `goprox`, as any change in metadata will lead 
to a modified file. 

## Filenames

### The Filenames Mess
GoPro uses various file-naming conventions in its cameras. There is no
clear structure and in most cases, you get some sort of prefix followed by a
running number and a file extension.

Here are some examples of GoPro Filenames:

```
GOPR0001.JPG
GH010008.MP4
GX010408.MP4
GS__3305.JPG
GS013331.360
```

If you happen to leverage the GoPro+ Cloud it gets a lot weirder with things
like

```
GPTempDownload.jpg
```

for anything GoPro Quik touches and forwards to e.g. Apple Photos.

There are many problems with these filenames - many not unique to GoPro. First of all, 
they are very non-descriptive. You might be able to deduct the camera
model to some extent, but that's about it. No date/time in case that information
gets lost somewhere along the way. But also the fact that these names are
created for a world where users only ever use a single camera at the same time.
As all cameras start with `0001` for the first media and continuously count up, it is 
only a question of time when you will run into naming conflicts with two or
more cameras. That usually means one file from one camera will overwrite another
file from another camera. And depending on usage each camera will
eventually, in some cases even regularly, restart at `0001`.

So instead of very complicated folder structures to keep images from colliding
with each other, GoProX creates more sophisticated filenames that allow you to
sort and act on the filenames themselves.

### A better way to name files
Let's take a look at the names of the files GoProX creates on `--import`:

```
20211010090947_GoPro_Hero10_7678_GOPR0768.JPG
20160130223238_GoPro_Max_6013_GS__1596.JPG
20210615110514_GoPro_Hero9_9650_GOPR1353.JPG
20201231054457_GoPro_Hero8_1659_GOPR0129.JPG
20210731003746_GoPro_Hero9_4139_GH013340.MP4
20211011072108_GoPro_Max_6013_GS012830.360
```

The first 8 digits are the original date when the photo was taken, followed by 6
digits of the time, followed by the model of the camera. The for digits after
that are the last four digits of the camera's serial number - to allow you to
find all the media from a particular camera. Especially important if you find
out after the fact that a setting was wrong in one of your cameras (Like when
you find a 2016 date for GoPro Max media). Finally, the original filename and
extension are added.

Right there is a wealth of information that helps with a lot of issues and even
software bugs in the likes of Apple Photos that for example messes up the date &
time for imported MP4 files. As the filename is kept along with the images and
videos it gives you a very simple way to double-check what is going on.

.360 videos from the GoPro Max listed here cannot be imported directly into the 
likes of Apple Photos. You will need GoPro Player on the Mac or GoPro Quik on iOS
to process them for further consumption. Alternatively, they can be used as mp4
files and processed in platforms like DaVinci Resolve or Adobe Premier with proper
plugins installed.

The `--process` option further refines the filenames and also adds and rewrites
embedded metadata. All file extensions are normalized to lowercase extensions
and the files are sorted by main file type.
As part of that process, `.360` files become `.mp4` files that are otherwise
identical to the GoPro `.360` format but can now be handled by most downstream
applications.

Processed files get an additional `P_` prefix to delineate from the unmodified 
imported files.

```
P_20210606094917_GoPro_Hero9_4139_GOPR0182.jpg
P_20210806114935_GoPro_Hero9_4139_GOPR3422.jpg
P_20220206144720_GoPro_Hero10_8034_GOPR2313.jpg
P_20220206145556_GoPro_Hero10_8034_GOPR2320.jpg
...
P_20210627102316_GoPro_Hero9_0021_GH013156.mp4
P_20211015084940_GoPro_Max_6013_GS013292.mp4
```    

## Exif & Metadata

### Tags

In addition to the names of the files getting supercharged, there is a ton of
information available inside the Exif metadata that macOS or Apple Photos keep
intact but ignores and does not even display unless you use Preview on a particular
file to inspect the metadata.
Apple Photos only gives you Title, Caption and Tags to work with to store
additional information aside from the most basic metadata.

This is where GoProX performs a little metadata shuffle to make at least some
of the attributes searchable from within Apple Photos.

Several of the low cardinality Exif fields are getting converted to a list of
tags. That list Apple Photos converts to its tags when importing the media.

Here is a list of tags that are being created by GoProX:

```GoProX: version
Make: ...
Camera: ...
Camera: ... ....
Software: ...
AutoRotation: ...
Orientation: ...
SceneCaptureType: ...
ProTune: ...
Sharpness: ...
MeteringMode: ...
GainControl: ...
Contrast: ...
Saturation: ...
WhiteBalance: ...
HDRSetting: ...
ExposureLockUsed: ...
ProjectionType: ...
ImageStabilization: ...
```

These tags can be used inside of Apple Photos for various tasks, most
importantly to create Smart Albums that key off one or more of them.

### Copyright information

As you will capture more and more media with multiple GoPro cameras, it is
always a good idea to set the Artist/Author/Copyright fields in Exif.
That way you keep a record of the files you have created.

## A Simple workflow

All of this needs to be part of a simple workflow that captures and stores the
original media as well as the processed files.
GoProX will most likely only be one step in your process and as been designed
to recursively walk the source tree and process all media files in its
structure. It does not matter if the source images are in a single folder or
organized by date, camera or whatever subject you choose.

On the output side, a very simple data-based file structure is created with one
folder per original media creation date.

The tool can be run on a single subfolder of your source files or at the root of
it. The output will always be the date folder hierarchy at the destination
folder.

When re-run, existing target files are skipped but logged in the error log. That
way large or incremental processing jobs can be restarted as often as you
like. This comes with some processing overhead for existing files but is
generally very fast.

If you want to reprocess certain files, simply delete them at the destination
folder and rerun the process.   

## Storage hierarchy

`goprox` is based on a simple file-based library structure for arching, importing, 
and processing media files over time. By default, it creates the following structure on
disk:

```
goprox/ (named and placed as required)
├── archive/
├── imported/
├── processed/
└── deleted/
```

Any of these first-level storage subtrees can be kept as directories or replaced by 
links to different storage devices. This helps distribute storage requirements across 
multiple devices but can be equally beneficial for processing performance. 

The following example keeps `archive` and `deleted` on the main drive while pointing 
`imported` and `processed` to different locations.

```
goprox/ (named and placed as required)
├── archive/
├── imported -> /Volumes/Office G-RAID/goprox/imported/
├── processed -> /Volumes/Office G-RAID/goprox/processed/
└── deleted/
```

To create this distributed structure, simply create another `goprox` library skeleton
on any storage device of your choice (in this case `/Volumes/Office G-RAID/`) (only
the portions of the structure you want to link to are required). For example:

```
/Volumes/Office G-RAID/goprox/ 
├── imported
├── processed
```

You could also consider putting `archive` on a dedicated low-cost storage device:

```
/Volumes/Office Dock/goprox/ 
├── archive
```

Once created, head over to the main library, remove the empty directories (if you are 
performing this as a migration see below) you would like to point to different 
locations, and simple run:

```
ln -s /Volumes/Office\ G-RAID/goprox/imported/ imported
ln -s /Volumes/Office\ G-RAID/goprox/processed/ processed
```

Once set up as required, `goprox` will be fully aware of the distributed nature of the
library and will validate the structure every time you run it. As part of the 
validation, it will check and warn of broken links and, if necessary, stop the execution 
of operations that would require the portions of the library that are unreachable.

This is necessary to avoid situations where external storage devices are not mounted
or simply not available when on the road.

Simple run `goprox` with no parameters to get the storage validation summary:

```
Info: Validating storage hierarchy... 
Info: goprox library: /Users/xxxxxxx/goprox directory validated 
Info: goprox archive: /Users/xxxxxxx/goprox/archive directory validated 
Warning: goprox imported: /Users/xxxxxxx/goprox/imported is a broken link to /Volumes/Office G-RAID/goprox/imported/
Warning: Make sure the storage device is mounted and the directory has not been moved. 
Warning: goprox processed: /Users/xxxxxxx/goprox/processed is a broken link to /Volumes/Office G-RAID/goprox/processed/ 
Warning: Make sure the storage device is mounted and the directory has not been moved. 
Info: goprox deleted: /Users/xxxxxxx/goprox/deleted directory validated 
Info: Finished storage hierarchy validation. 
Info: GoProx processing finished. 
```

In this particular example, you can still perform `--archive`, `--firmware`, or `--clean` tasks
but will see an error if you attempt `--import` or `--process`.

### Inside the library

Once you get started, you will see `goprox` fill the library's content with your
GoPro media data. 

Here is a sample summary of how `goprox` builts the tree inside the various components:

```
goprox/
├── archive/
│   ├── 20221015125658_GoPro_Hero10_8034.tar.gz
│   ├── 20221015131037_GoPro Max_6013.tar.gz
│   ├── 20221015103421_GoPro_Hero11_4632.tar.gz
│   └── 20220713183316_GoPro_Hero9_0021.tar.gz
├── imported/
│   ├── 2021
│   └── 2022
│       ├── 20220520
│       └── 20221013
│           ├── 20221013084759_GoPro_Hero11_5131_G0294305.JPG
│           ├── 20221013094220_GoPro_Hero10_4299_G0019484.JPG
│           ├── 20221013153428_GoPro_Max_6013_GS016167.360
│           └── geonames.json
└── processed/
    ├── JPEG
    │   ├── 2021
    │   └── 2022
    │       ├── 20220520
    │       └── 20221013
    │           ├── P_20221013084759_GoPro_Hero11_5131_G0294305.JPG
    │           └── P_20221013094220_GoPro_Hero10_4299_G0019484.JPG
    ├── MP4
    └── 360
        ├── 2021
        └── 2022
            ├── 20220520
            └── 20221013
                └── P_20221013153428_GoPro_Max_6013_GS016167.360

```

`archive` is a flat directory with the individual sdcard image backups as `tar.gz`.
These archives usually get migrated to long term storage (eg: AWS Glacier) or simply
deleted after a while. When you get started with `goprox`, it is strongly
recommended to perform archives as they are a simple, foolproof way to undo anything
that could go wrong as you experiment with features and your workflow.
`goprox` supports imports straight from an archive file. This allows you to rerun 
any process from scratch without ever losing any data. The cost is an extra copy 
of all the media.

`imported` contains a structure by year and then by date to keep the hierarchy 
manageable. Within a particular day, you will find all media `goprox` has imported.
These dates are derived from when the media was created/shot and NOT when it was 
imported. That information you can find in the modification dates of each file.
`goprox` has a strict DO-NOT-OVERRIDE existing files policy. It only adds, never 
replaces. If you want to rerun a particular day, delete those files within the tree
and re-run the import from your archives. Be aware that the archive dates do not
necessarily correspond with the individual file date. The archives are labeled by 
the day and time the archive has been created. All media files inside of `imported`
are unmodified but renamed. It is the exact media that came off your sdcard but
intelligently named according to the files EXIF data.

`processed` contains a further refined structure by file type, then year and date.
This is done because, in many cases, JPEG, MP4, and 360 files go through different 
workflows in post-production. For example, JPEGs might get imported into Apple Photos, 
whereas MP4s get used by Blackmagic DaVinci or similar. 360s usually have
to be processed by GoPro Player first before they can be used in cutting and editing.
`processed` media files are rewritten with additional metadata that allows Apps
to search, sort, and filter these files in new ways. To be able to distinguish
`imported` from `processed` media, a `P_` prefix is added to all processed 
media.

`deleted` is currently a placeholder for future functionality to allow upstream 
deletion propagation back into the goprox library. It will contain
lists of files that have been deleted in upstream Apps like Apple Photos to remove
those files retroactively from the `goprox` library. 

### Performance considerations

For extra performance, you could consider placing `imported` and `processed` on 
different SSDs. Internal NVME drives can get up to 1.3GB/s transfer rates, while 
external devices like Samsung's T7s max out at 600-700MB/s. The G-Raid can do 
about 400MB/s in RAID 0 and 200MB/s in RAID 1.

### Existing file migration

If you need to migrate file structures from one device to another, it is highly 
recommended to bypass Finder and use `cp` in archive mode to maximize copy performance 
but also preserve owner, date & time as well as other attributes in your library.

```
cp -RpPvn source target

cp -RpPvn /Volumes/Original/goprox/imported /Volumes/Office\ G-RAID/goprox
```

This will safely copy all the contents of the source to the new target. It will skip 
existing files (so you can re-run it in case of a failure) but it is important to 
capture and review its output, particularly the error out. For long running migrations
wrap in nohup:

```
nohup cp -RpPvn source target 1>>cp-progress.log 2>>cp-errors.log

nohup cp -RpPvn /Volumes/Original/goprox/imported /Volumes/Office\ G-RAID/goprox 1>>goprox-cp-progress.log 2>>goprox-cp-errors.log 
```

## Supported GoPro Models

`goprox` is actively being developed and tested with the following cameras:

* GoPro Hero 8 (HD8.01.02.51.00)
* GoPro Hero 9 (HD9.01.01.72.00)
* GoPro Hero 10 (H21.01.01.46.00)
* GoPro Hero 11 (H22.01.01.10.00)
* GoPro Max (H19.03.02.00.00)
* GoPro The Remote (GP.REMOTE.FW.01.02.00)

Most functionality should work with older GoPro models as well, just the `--firmware` and 
`--firmware labs` options are limited to these models.

## Performance

The [exiftool](https://exiftool.org) has phenomenal capabilities and if you let
it do the vast majority of work by itself, it is really fast.

Testing on 20,000 images on a 2017 iMac with a quad-core i5 and one 2TB SSD
(source: original files folder) plus one 14TB HDD (target: processed files
folder) have continuously resulted in 200MB+/sec read and write speeds at less
than 20% CPU utilization.

## Simplicity

I tried to keep the tool as simple as possible. This undoubtedly will come with
limitations for certain use-cases. Feel free to drop me a line or a PR with
enhancements.

## Credits & Disclaimers

GoProX is not related to GoPro Inc or its products. It is not supported nor
endorsed by GoPro Inc.
GoProX is not related to Apple Inc, Blackmagic Design Pty Ltd or any other
products or platforms referred to as part of the description or documentation of 
the tool unless explicitly stated.

GoProX leverages the [exiftool](https://exiftool.org) by Phil Harvey to extract
common GoPro metadata to name and tag images and videos for further processing.

GoProX leverages the [GeoNames](https://www.geonames.org) database by Marc Wick
to perform GPS-based geocode lookups of timezones and related data.

## Links & Resources

Homebrew tap to enable the installation of `goprox`: [homebrew-fxstein](https://github.com/fxstein/homebrew-fxstein)
