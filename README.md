# sightsnap - an OS X command line utility to snap webcam images

## Design Goals
* no memory leaks - suitable for long time time lapsing
* add text overlays or timestamps

## Requirements
* Mac OS X 10.8 or higher, 64-bit only

## Download Binary
* [sightsnap v0.4](http://cl.ly/O88U)

## Examples
### Lol-Commits including emojiis and repo information
![Lolcommit](http://cl.ly/OAF1/2013-04-09_11-41-04_domtina.local.jpg)

## License

* [MIT](http://www.opensource.org/licenses/mit-license.php)

## Usage

```
sightsnap v0.4 by @monkeydom
usage: sightsnap [options] [output[.jpg|.png]] [options]

Default output filename is signtsnap.jpg - if no extension is given, jpg is used.
If you add directory in front, it will be created.
  -l, --listDevices         List all available video devices and their formats.
  -d, --device <device>     Use this <device>. First partial case-insensitive
                            name match is taken.
  -t, --time <delay>        Takes a frame every <delay> seconds and saves it as
                            outputfilename-XXXXXXX.jpg continuously.
  -z, --startAtZero         Start at frame number 0 and overwrite - otherwise start
                            with next free frame number. Time mode only.
  -k, --skipframes <n>      Skips <n> frames before taking a picture. Gives cam
                            warmup time. (default is 2, frames are @6fps)
  -j, --jpegQuality <q>     JPEG image quality from 0.0 to 1.0 (default is 0.8).
  -x, --maxwidth <w>        If image is wider than <w> px, scale it down to fit.
  -y, --maxheight <h>       If image is higher than <h> px, scale it down to fit.
                            When <w> and <h> are given, the camera format used is optimized.
  -p, --timeStamp           Adds a Timestamp to the captured image.
  -T, --title <text>        Adds <text> to the upper right of the image.
  -C, --comment <text>      Adds <text> to the lower left of the image.
  -f, --fontName <font>     Postscript font name to use. Use FontBook.app->Font Info
                            to find out about the available fonts on your system
                            (default is 'HelveticaNeue-Bold')
  -s, --fontSize <size>     Font size for timestamp in <size> px. (default is 40)
  -h, --help                Shows this help.

To make timelapse videos use ffmpeg like this:
  ffmpeg -i 'sightsnap-%07d.jpg' sightsnap.mp4
```

## Acknowledgements
* uses [ArgumentParser](https://github.com/NSError/ArgumentParser)

## Created by
@monkeydom [twitter](http://twitter.com/monkeydom) [adn](http://alpha.app.net/monkeydom)