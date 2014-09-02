# sightsnap - an OS X command line utility to snap webcam images

## Design Goals
* no memory leaks - suitable for long time time lapsing
* add text overlays or timestamps

## Requirements
* Mac OS X 10.8 or higher, 64-bit only

## Download Binary
* [sightsnap v0.6](http://cl.ly/1Q2G1l0v1E2W/download/sightsnap.zip)

## Examples
### Lol-Commits including emojiis and repo information
![Lolcommit](http://cl.ly/OAF1/2013-04-09_11-41-04_domtina.local.jpg)
* [lolcommit-hook.rb](https://github.com/monkeydom/sightsnap/blob/develop/examples/lolsnapcommit-hook.rb)

## What's new

* mp4 creation on time lapse (currently without additional text overlays)
* extended the --time option to take a total time for image sequence grabbing to make e.g. animated gifs
* updated the post commit hook example to make animated gifs using ffmpeg

## License

* [MIT](http://www.opensource.org/licenses/mit-license.php)

## Usage

```
sightsnap v0.6 by @monkeydom
usage: sightsnap [options] [output[.jpg|.png]] [options]

Default output filename is signtsnap.jpg - if no extension is given, jpg is used.
If you add directory in front, it will be created.
  -l, --listDevices         List all available video devices and their formats.
  -d, --device <device>     Use this <device>. First partial case-insensitive
                            name match is taken.
  -t, --time <delay[,duration]>Takes a frame every <delay> seconds and saves it as
                            outputfilename-XXXXXXX.jpg continuously. Stops after <duration> seconds if given.
  -z, --startAtZero         Start at frame number 0 and overwrite - otherwise start
                            with next free frame number. Time mode only.
  -m, --mp4                 Also write out a movie as mp4 with the timelapse directly. Time mode only.
  -k, --skipframes <n>      Skips <n> frames before taking a picture. Gives cam
                            warmup time. (default is 2, frames are @6fps)
  -j, --jpegQuality <q>     JPEG image quality from 0.0 to 1.0 (default is 0.8).
  -x, --maxwidth <w>        If image is wider than <w> px, scale it down to fit.
  -y, --maxheight <h>       If image is higher than <h> px, scale it down to fit.
                            When <w> and <h> are given, the camera format used is optimized.
  -p, --timeStamp           Adds a Timestamp to the captured image.
  -o, --onlyOneTimeStamp    Freeze the TimeStamp to the first value for all images.
  -T, --title <text>        Adds <text> to the upper right of the image.
  -C, --comment <text>      Adds <text> to the lower left of the image.
  -f, --fontName <font>     Postscript font name to use. Use FontBook.app->Font Info
                            to find out about the available fonts on your system
                            (default is 'HelveticaNeue-Bold')
  -s, --fontSize <size>     Font size for timestamp in <size> px. (default is 40)
  -h, --help                Shows this help.

To make timelapse videos use ffmpeg like this:
  ffmpeg -i 'sightsnap-%07d.jpg' sightsnap.mp4
To make animated gifs use: 
  ffmpeg -r 10 -i Test3-%07d.jpg -vf 'scale=768:-1' test3.gif
  ```

**Special consideration**: if your texts might start with a '-' then you need to use the alternative syntax. E.g. for the comment area `-C='-text that starts with a hyphen'`

## Acknowledgements
* uses [ArgumentParser](https://github.com/NSError/ArgumentParser)

## Created by
@monkeydom [twitter](http://twitter.com/monkeydom) [adn](http://alpha.app.net/monkeydom)