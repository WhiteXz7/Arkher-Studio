#!/usr/bin/env python3
"""Teste do gerador rbxlx: XML válido, CFrame ortonormal, escape, stats."""
import math
import os
import sys
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxlx  # noqa: E402

TREE = {"c": "Workspace", "n": "Workspace", "k": [
    {"c": "Model", "n": "Casa", "p": {}, "k": [
        {"c": "Part", "n": "Parede", "p": {
            "pos": {"x": 0, "y": 5, "z": -3}, "rot": {"x": 0, "y": 0.7853982, "z": 0},
            "size": {"x": 4, "y": 1, "z": 2}, "color": {"x": 0.9, "y": 0.1, "z": 0.1},
            "trans": 0, "anchor": True, "cc": True, "ct": True, "cq": True,
            "cs": True, "locked": False, "reflect": 0}},
        {"c": "SpawnLocation", "n": "Spawn", "p": {
            "pos": {"x": 0, "y": 1, "z": 0}, "size": {"x": 6, "y": 1, "z": 6}}},
        {"c": "Script", "n": "Oi", "p": {"source": 'print("a<b>&c")', "enabled": True}},
        {"c": "Terrain", "n": "Terrain", "p": {}},
        {"c": "WeirdFutureClass", "n": "X", "p": {}},
    ]},
]}


class T(unittest.TestCase):
    def test_place(self):
        data, stats = rbxlx.place_file(TREE, title="T")
        root = ET.fromstring(data)
        items = root.findall("Item")
        classes = [i.get("class") for i in items]
        self.assertIn("Workspace", classes)
        self.assertIn("Lighting", classes)
        self.assertIn("StarterPlayer", classes)
        ws = items[classes.index("Workspace")]
        model = ws.find("Item")
        self.assertEqual(model.get("class"), "Model")
        got = [i.get("class") for i in model.findall("Item")]
        self.assertEqual(got, ["Part", "SpawnLocation", "Script", "Folder", "Folder"])
        # CFrame: R00..R22 formam matriz de rotação (linhas unitárias, det=+1)
        cf = model.findall("Item")[0].find("./Properties/CoordinateFrame")
        m = [[float(cf.find(f"R{r}{c}").text) for c in range(3)] for r in range(3)]
        for r in range(3):
            n = math.sqrt(sum(m[r][c] ** 2 for c in range(3)))
            self.assertAlmostEqual(n, 1.0, places=4)
        det = (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
               - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
               + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
        self.assertAlmostEqual(det, 1.0, places=4)
        # 45° em Y: R00=R22≈0.7071
        self.assertAlmostEqual(m[0][0], 0.7071, places=3)
        # escape do source
        src = model.findall("Item")[2].find("./Properties/ProtectedString").text
        self.assertEqual(src, 'print("a<b>&c")')
        # stats
        self.assertEqual(stats["parts"], 2)
        self.assertEqual(stats["scripts"], 1)
        self.assertIn("WeirdFutureClass", stats["skipped"])
        print(f"  place OK: {stats['bytes']} bytes, parts={stats['parts']} scripts={stats['scripts']}")

    def test_model(self):
        data, stats = rbxlx.model_file({"c": "Folder", "n": "Pack", "k": []})
        ET.fromstring(data)
        self.assertEqual(stats["parts"], 0)
        print("  model OK")


if __name__ == "__main__":
    unittest.main(verbosity=1)
