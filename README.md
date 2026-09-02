# One Meaningful Game

### Turn Your R36S/R36H Into a Dedicated Single-Game Console

Digital consumerism has transformed the way we experience video games. We've moved from owning games to constantly consuming them. The problem isn't simply that there are too many games. It's that we have too little time, attention, and presence to truly experience them.

A video game is not just a product. It is art.

This project is a gaming meditation.

### How it works

You create your own One Meaningful Game collection by choosing a MAME ROM of your liking, along with two or three other ROMs that you want to play from time to time.

1. The first time you switch on the console, you'll be given the opportunity to play your One Meaningful Game.

2. Each time you reboot or switch off your console, one of the side games you've chosen for your collection will run sequentially.

### Build your collection

A collection is a folder containing the game files.

1. Download the content of this project.

2. Rename `EASYROMS/omg-collection/collection-name` to your chosen name (e.g. `EASYROMS/omg-collection/my-collection`).

3. Copy the One Meaningful Game MAME ROM you've chosen into the appropriate MAME version folder. You can have ROMs for:

    * `mame2003`
    * `mame2010`
    * `mame` (latest version)

4. Edit `BOOT/omg/config.txt` and specify the name of your collection: `install_collection=my-collection`.

5. **(OPTIONAL)** Copy the side games you've chosen into the `random` subfolder.

6. **(OPTIONAL)** Create a cover for the collection (the boot screen): a 640×480, 24-bit RGB Windows Bitmap (`.bmp`) image. Save it as `EASYROMS/omg-collection/collection-name/logo.bmp`.

### Install

DISCLAIMER: THIS IS AN AMATEUR PROJECT. IT WORKS, BUT USE IT AT YOUR OWN RISK. INSTALL IT ON A FRESH DARKOS INSTALLATION. IT WILL NOT WORK ON AN EXISTING DARKOS SD CARD.

**ATTENTION PLEASE: The installation will configure your dArkOS to run only One Meaningful Game. Once the installation process has been completed, you will not be able to easily revert the installation.**

1. [Download the latest release of dArkOSRE-R36](https://github.com/southoz/dArkOSRE-R36/releases) and create an SD card for it [following the instructions](https://github.com/southoz/dArkOSRE-R36/wiki/Firmware-Installation).

2. Before running dArkOSRE for the first time, copy the contents of the `BOOT` folder to the `BOOT` partition of your SD card. You need to overwrite the `firstboot.sh` file.

3. Run dArkOSRE for the first time. It will install dArkOS and One Meaningful Collection. You should see this message on the screen:

```text
   ============================================================
   
                      ONE MEANINGFUL GAME
   
    Copy the '/EASYROMS/omg-collection' to the EASYROMS partition
                                &
                        Reboot the system
   
   ============================================================
```

4. Copy `EASYROMS/omg-collection/` to the `EASYROMS` partition.
5. Reboot the console

### Have Fun :)
