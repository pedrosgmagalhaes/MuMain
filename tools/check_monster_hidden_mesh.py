#!/usr/bin/env python3
"""Checks that no monster hides the only mesh of its model.

`hiddenMesh` is the mesh that is NOT drawn (docs/monster-data.md). It is a plain index
comparison (BMD::IsMeshHidden), so a value of 0 hides mesh 0 - and a model that has a
single mesh would be left with nothing to draw, which is how the Cabo Polonio monsters
(700-704) shipped invisible: alive, named, pickable, with only their effects drawn.

The default of a character is -1, "hide nothing" (CreateCharacterPointer sets
o->HiddenMesh = -1; MonsterSetupApply then keeps it for an entry without the key, via
setup.hiddenMesh.value_or(start.hiddenMesh)). An entry without `hiddenMesh` is therefore
correct, and this check only looks at entries that name a mesh.

The check reads the models' BMD headers directly: version 10 is plain, version 12 carries
its payload encrypted with the game's own MapFileDecrypt.

Usage: python tools/check_monster_hidden_mesh.py [Data-directory]
The directory defaults to src/bin/Data (the data the client ships).
"""
import argparse
import json
import os
import struct
import sys

MAP_XOR = bytes((0xD1, 0x73, 0x52, 0xF6, 0xD2, 0x9A, 0xCB, 0x27,
                 0x3E, 0xAF, 0x59, 0x31, 0x37, 0xB3, 0xE7, 0xA2))


def map_file_decrypt(src):
    out = bytearray(len(src))
    key = 0x5E
    for i, b in enumerate(src):
        out[i] = ((b ^ MAP_XOR[i % 16]) - (key & 0xFF)) & 0xFF
        key = (b + 0x3D) & 0xFF
    return bytes(out)


def read_meshes(path):
    """(mesh count, triangles of mesh 0) of a BMD, or None when it is not one."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:3] != b"BMD":
        return None
    version = data[3]
    if version == 0x0C:
        size = struct.unpack("<i", data[4:8])[0]
        body, offset = map_file_decrypt(data[8:8 + size]), 0
    elif version == 0x0A:
        body, offset = data, 4
    else:
        return None
    if len(body) < offset + 38:
        return None
    count = struct.unpack("<h", body[offset + 32:offset + 34])[0]
    header = body[offset + 38:offset + 40]
    triangles = struct.unpack("<h", header)[0] if len(header) == 2 and count > 0 else 0
    return count, triangles


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("data", nargs="?", default=os.path.join("src", "bin", "Data"),
                        help="the client's Data directory (default: src/bin/Data)")
    args = parser.parse_args()

    monsters_path = os.path.join(args.data, "Monsters", "Monsters.json")
    models_path = os.path.join(args.data, "Monsters", "Models.json")
    with open(monsters_path, encoding="utf-8") as f:
        monsters = json.load(f)["monsters"]
    with open(models_path, encoding="utf-8") as f:
        models = {m["slot"]: m for m in json.load(f)["models"]}

    meshes = {}
    failures = []
    partial = []
    unreadable = []
    for entry in monsters:
        slot = entry.get("model")
        hidden = entry.get("hiddenMesh")
        if hidden is None or not isinstance(slot, str) or slot in ("player", "none"):
            continue
        if slot not in models:
            continue
        if slot not in meshes:
            # Models.json names the file from the client folder, not from Data.
            meshes[slot] = read_meshes(os.path.join(os.path.dirname(args.data), models[slot]["file"]))
        info = meshes[slot]
        name = entry["name"]["en"]
        numbers = [n["number"] for n in entry.get("numbers", [])]
        if info is None:
            unreadable.append((name, slot, numbers))
            continue
        count, triangles = info
        if hidden == 0 and count == 1:
            failures.append((name, slot, numbers, triangles))
        elif hidden == 0 and triangles > 0:
            partial.append((name, slot, numbers, triangles, count))

    for name, slot, numbers, triangles in failures:
        print("FAIL %s %s hides mesh 0, its model's only mesh (%d triangles): the monster "
              "draws nothing at all." % (name, numbers, triangles))
    for name, slot, numbers, triangles, count in partial:
        print("note %s %s hides mesh 0 of %d (%d triangles); the rest still draws - check "
              "that this is meant." % (name, numbers, count, triangles))
    for name, slot, numbers in unreadable:
        print("note %s %s: model %s not readable here" % (name, numbers, slot))

    print("%d monster entries checked, %d hide their only mesh, %d hide mesh 0 of several"
          % (len(monsters), len(failures), len(partial)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
