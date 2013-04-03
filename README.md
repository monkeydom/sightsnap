# sightsnap - an OS X command line utility to snap webcam images

## Design Goals
* no memory leaks - suitable for long time time lapsing
* add text overlays or timestamps

## Requirements
* Mac OS X 10.8 or higher, 64-bit only

## Download Binary
* [sightsnap v0.1](http://cl.ly/Nz2O)

## License

* [MIT](http://www.opensource.org/licenses/mit-license.php)

## Usage

<pre>
sightsnap v0.2 by @monkeydom
usage: sightsnap [options] [outputfilename[.jpg|.png]] [options]

Default output filename is signtsnap.jpg
  -l, --listDevices         List all available video devices and their formats.
  -d, --device <device>     Use this <device>. First partial case-insensitive
                            name match is taken.
  -t, --time <delay>        Takes a frame every <delay> seconds and saves it as
                            outputfilename-XXXXXXX.jpg continuously.
  -k, --skipframes <n>      Skips <n> frames before taking a picture. Gives cam
                            warmup time. (default is 3, frames are @15fps)
  -j, --jpegQuality <q>     JPEG image quality from 0.0 to 1.0 (default is 0.8).
  -x, --maxwidth <w>        If image is wider than <w> px, scale it down to fit.
  -y, --maxheight <h>       If image is higher than <h> px, scale it down to fit.
  -p, --timeStamp           Adds a Timestamp to the captured image.
  -f, --fontName <font>     Postscript font name to use. Use FontBook.app->Font Info
                            to find out about the available fonts on your system
                            (default is 'HelveticaNeue-Bold')
  -s, --fontSize <size>     Font size for timestamp in <size> px. (default is 40)
  -h, --help                Shows this help.

To make timelapse videos use ffmpeg like this:
  ffmpeg -r 15 -i 'sightsnap-%07d.jpg' sightsnap.mp4</pre>

## Acknowledgements
* uses [ArgumentParser](https://github.com/NSError/ArgumentParser)

## Created by
@monkeydom [twitter](http://twitter.com/monkeydom) [adn](http://app.net/monkeydom)