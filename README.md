# Helpful Cadence Skill Scrips #

A repository of skill scripts I wrote to make layout in Cadence easier.

Most of these scripts have not been extensively tested, and many were not
intended for use by people other than myself. The following scripts might have
some use by other people and are generally documented within the files
themselves. This should serve only as a quickstart guide.


## GCA Barcode Generator v1.1 ##
Matthew Filmer 9/7/2018

Changelog
v1.1 - 9/10/2018
Added the ability to generate at either mask scale (positions -5 and 5) or design scale (positions -1 and 1)
Default position is now "-1" which is on the bottom right side at design scale

v1.0 - 9/7/2018
Initial release


### Overview ###
Generate a barcode compatible with the GCA Alphastep 200 (and probably other
GCA steppers) Barcodes are made up of 1-10 characters.  Valid characters
include A-Z, 0-9, and select special characters (ascii characters 32 - 95)
lowercase letters are converted to uppercase automatically.


### GCA Barcode Specification ###
Units are given in mask dimensions

Height: 3 mm
Start quiet zone: 4 mm
Each segment is an integer multiple of 0.15 mm long
Sync 1: 3x space-line all 1-1-1-1-1-1               total: 6  (0.9 mm)
Start character: 3x space-line 4-1-2-1-1-1          total: 10 (1.5 mm)
1-10 characters: 3x space-line varying weights      total: 10 (1.5 mm)
Checksum character: 3x space-line varying weights   total: 10 (1.5 mm)
Stop character: 3x space-line 5-1-1-1-1-1           total: 10 (1.5 mm)
Sync 2: 3x line-space all 1-1-1-1-1-1               total: 6  (0.9 mm)
End quiet zone: 4 mm
Total barcode length: 15.8mm (1 char) to 29.3 mm (10 chars)

### Usage ###
```
makeBarcode(barcodeText)
```
Generates a barcode in the default position of "-1": bottom right, design scale.
Uses the currenty active layer in the active cell. 
This is what most users probably want as it will result in the stepper imaging
patterns rotated "as designed". 
barcodeText: 1-10 character string (will be truncated to 10 characters if > 10 are given)

```
makeBarcode(barcodeText position)
```
Generates a barcode in the currently active layer in the active cell.
barcodeText: 1-10 character string (will be truncated to 10 characters if > 10 are given)
position: 1, -1, 5, or -5 to indicate barcode position and scale.
  1, 5 -> top left            -1,-5 -> bottom right
  1,-1 -> design scale         5,-5 -> mask scale
