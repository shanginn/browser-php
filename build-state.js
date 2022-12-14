#!/usr/bin/env node
"use strict";

const path = require("path");
const fs   = require("fs");
const V86  = require("./tools/libv86.js").V86;

const imageName = 'browser-php';

const BASE_DIR = path.join(__dirname, ".");
const OUTPUT_FILE = path.join(BASE_DIR, `images/${imageName}-state-base.bin`);

process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.setEncoding("utf8");
process.stdin.on("data", handle_key);

let emulator = new V86({
    bios: { url: path.join(BASE_DIR, "/tools/bios/seabios.bin") },
    vga_bios: { url: path.join(BASE_DIR, "/tools/bios/vgabios.bin") },
    autostart: true,
    memory_size: 512 * 1024 * 1024,
    vga_memory_size: 8 * 1024 * 1024,
    network_relay_url: "<UNUSED>",
    bzimage_initrd_from_filesystem: true,
    cmdline: "rw init=/bin/systemd root=host9p console=ttyS0 spectre_v2=off pti=off",
    filesystem: {
        basefs: {
            url: path.join(BASE_DIR, `/images/${imageName}-base-fs.json`),
        },
        baseurl: path.join(BASE_DIR, `/images/${imageName}-9p-rootfs-flat/`),
    },
    screen_dummy: true,
});

console.log("Now booting, please stand by ...");

let boot_start = Date.now();
let serial_text = "";
let booted = false;

emulator.add_listener("serial0-output-char", function(c) {
    process.stdout.write(c);

    serial_text += c;

    if(!booted && serial_text.endsWith("root@localhost:~# ")) {
        console.error("\nBooted in %d", (Date.now() - boot_start) / 1000);
        booted = true;

        // sync and drop caches: Makes it safer to change the filesystem as fewer files are rendered
        emulator.serial0_send("sync;echo 3 >/proc/sys/vm/drop_caches\n");
        emulator.serial0_send("chsh -s /usr/local/bin/psysh\n");
        emulator.serial0_send("/usr/local/bin/psysh\n");

        setTimeout(function () {
            emulator.save_state(function(err, s) {
                if(err) throw err;

                fs.writeFile(OUTPUT_FILE, new Uint8Array(s), function(err) {
                    if(err) throw err;
                    console.error("Saved as " + OUTPUT_FILE);
                    stop();
                });
            });
        }, 10 * 5000);
    }
});

function handle_key(c) {
    if(c === "\u0003") {
        // ctrl c
        stop();
    } else {
        emulator.serial0_send(c);
    }
}

function stop() {
    emulator.stop();
    process.stdin.pause();
}
