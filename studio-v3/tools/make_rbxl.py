#!/usr/bin/env python3
"""Gera arkher-v3.rbxl no formato binario MODERNO do Roblox (v0).

Spec: rojo-rbx/rbx-dom (rbx_binary) — o formato que o Studio atual grava.
Chunks sem compressao (o decodificador do Studio aceita; confirmado na spec).

Validacao:
  * referent array: byte-identico ao fixture modulescripts-100 (PRNT subjects)
  * round-trip: o proprio decoder (pyrbxl2) le o arquivo gerado e a arvore
    deve bater exata com a intendida (classes, nomes, sources).
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(ROOT, "commandbar")
OUT = os.path.join(DIST, "arkher-v3.rbxl")

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"

# ---------------- primitivas de codificacao ----------------

def zigzag32_enc(n: int) -> int:
    n &= 0xFFFFFFFF
    if n & 0x80000000:
        n -= 0x100000000
    return ((n << 1) ^ (n >> 31)) & 0xFFFFFFFF


def referent_array_enc(refs) -> bytes:
    """Layout planar (byte b do valor i em i+b*n; planos lidos como BE),
    zigzag32, delta-encoded."""
    n = len(refs)
    buf = bytearray(4 * n)
    last = 0
    for i, ref in enumerate(refs):
        d = ref - last
        last = ref
        x = zigzag32_enc(d)
        # BE: byte0 (MSB) no plano 0 ... byte3 (LSB) no plano 3
        buf[i] = (x >> 24) & 0xFF
        buf[i + n] = (x >> 16) & 0xFF
        buf[i + 2 * n] = (x >> 8) & 0xFF
        buf[i + 3 * n] = x & 0xFF
    return bytes(buf)


def s(b: str) -> bytes:
    raw = b.encode("utf-8")
    return struct.pack("<I", len(raw)) + raw


def chunk(name: bytes, payload: bytes) -> bytes:
    # sem compressao: clen=0, len, reserved=0
    return name + struct.pack("<III", 0, len(payload), 0) + payload


# ---------------- arvore do place ----------------

# Services reais persistidos num place moderno (DataModel completo).
# Os 7 "devidos" do ARKHER: ReplicatedStorage (kits), ReplicatedFirst
# (bootstrap server), ServerScriptService (server principal), ServerStorage
# (dados privados), StarterPlayer > StarterPlayerScripts/StarterCharacterScripts
# (client), StarterGui (UI), StarterPack (tool) + NetworkClient (canal legado).
SERVICES = [
    # raiz/ambiente
    "Workspace", "Lighting", "Players", "ReplicatedStorage", "ReplicatedFirst",
    "SoundService", "CSGDictionaryService", "NonReplicatedCSGDictionaryService",
    "Chat", "TimerService", "TweenService",
    # starters
    "StarterPlayer", "StarterPack", "StarterGui",
    # identidade/assistencia
    "LocalizationService", "TeleportService", "CollectionService",
    "PhysicsService", "Geometry", "InsertService", "GamePassService",
    "Debris", "CookiesService", "VRService", "ContextActionService",
    "ScriptService", "AssetService", "TouchInputService",
    # server
    "ServerScriptService", "ServerStorage",
    # web/legacy client
    "LuaWebService", "HttpService", "NetworkClient",
    # analytics/teste
    "AnalyticsService", "VirtualInputManager", "TestService", "Teams",
    "StudioData",
    # storage/dados modernos
    "AvatarStoreService", "BadgeService", "Backpack", "ChangeHistoryService",
    "CloudAuthService", "CloudStorageService", "ContentProvider",
    "DataStoreCustomEvent", "DiscoveryApi", "ExperienceService",
    "FriendService", "GameLocalizationService", "GamePublishService",
    "GroupService", "MacroService", "MaterialService", "MarketplaceService",
    "MemoryStoreService", "MetricsService", "MessagingService",
    "MicrosoftStoreService", "NextGenCompressedVideoService",
    "NotificationService", "OauthService", "PathfindingService",
    "PluginManager", "PolicyService", "PurchaseService", "RandomService",
    "RankedStatsService", "RobloxDataStoreService", "RunService",
    "ShareService", "ShaderCacheService", "ShopService", "SpatialAudioService",
    "StatisticsService", "StudioService", "SubscriptionService",
    "TextBoxService", "TextureService", "TicketService", "TimeService",
    "TranslateService", "TrustBadgesService", "UGCChatService",
    "UserInfoService", "VideoService", "VideoLumaService", "VipService",
    "WorldRoot",
    # gui
    "CoreGui",
]

# (classe, nome, parent=None=raiz)
TREE = []
for svc in SERVICES:
    TREE.append((svc, svc, None))
TREE.append(("StarterPlayerScripts", "StarterPlayerScripts", "StarterPlayer"))
TREE.append(("StarterCharacterScripts", "StarterCharacterScripts", "StarterPlayer"))
TREE.append(("Folder", "ArkherV3", "ReplicatedStorage"))
TREE.append(("ModuleScript", "ArkherKit_A", "ArkherV3"))
TREE.append(("ModuleScript", "ArkherKit_B", "ArkherV3"))
TREE.append(("LocalScript", "ArkherMainUI", "StarterPlayerScripts"))
TREE.append(("LocalScript", "ArkherBundle_Editors", "StarterPlayerScripts"))
TREE.append(("LocalScript", "ArkherBundle_Scene", "StarterPlayerScripts"))
TREE.append(("LocalScript", "ArkherBundle_System", "StarterPlayerScripts"))

SCRIPT_SOURCES = {
    ("ModuleScript", "ArkherKit_A"): os.path.join(DIST, "ArkherKit_A.lua"),
    ("ModuleScript", "ArkherKit_B"): os.path.join(DIST, "ArkherKit_B.lua"),
    ("LocalScript", "ArkherMainUI"): os.path.join(DIST, "ArkherStudio_MainUI.lua"),
    ("LocalScript", "ArkherBundle_Editors"): os.path.join(DIST, "UI_Bundle_Editors.lua"),
    ("LocalScript", "ArkherBundle_Scene"): os.path.join(DIST, "UI_Bundle_Scene.lua"),
    ("LocalScript", "ArkherBundle_System"): os.path.join(DIST, "UI_Bundle_System.lua"),
}

SERVICE_CLASSES = set(SERVICES)


def build() -> bytes:
    # referents 0..N-1 na ordem da TREE
    ref_by_name = {}
    instances = []  # (class, name, parent_ref)
    for i, (cls, name, parent) in enumerate(TREE):
        if name in ref_by_name:
            sys.exit(f"nome duplicado: {name}")
        ref_by_name[name] = i
        instances.append((cls, name, ref_by_name[parent] if parent else None))

    # grupos por classe (ordem de aparecimento)
    type_order = []
    type_refs = {}
    for i, (cls, name, par) in enumerate(instances):
        if cls not in type_refs:
            type_refs[cls] = []
            type_order.append(cls)
        type_refs[cls].append(i)

    out = bytearray()
    out += MAGIC
    out += struct.pack("<H", 0)
    out += struct.pack("<I", len(type_order))
    out += struct.pack("<I", len(instances))
    out += b"\x00" * 8

    # META (opcional; incluso como o rojo escreve)
    meta = struct.pack("<I", 1) + s("ExplicitAutoJoints") + s("true")
    out += chunk(b"META", meta)

    # INST
    for tid, cls in enumerate(type_order):
        refs = type_refs[cls]
        is_svc = 1 if cls in SERVICE_CLASSES else 0
        payload = struct.pack("<I", tid) + s(cls) + struct.pack("<B", is_svc)
        payload += struct.pack("<I", len(refs))
        payload += referent_array_enc(refs)
        if is_svc:
            payload += b"\x01" * len(refs)
        out += chunk(b"INST", payload)

    # PROP: Name para todas as classes; Source para classes onde TODAS as
    # instancias tem source (um valor por instancia, na ordem de referent)
    for tid, cls in enumerate(type_order):
        refs = type_refs[cls]
        payload = struct.pack("<I", tid) + s("Name") + struct.pack("<B", 1)  # 1 = String
        for i in refs:
            payload += s(instances[i][1])
        out += chunk(b"PROP", payload)
        have_src = all((instances[i][0], instances[i][1]) in SCRIPT_SOURCES for i in refs)
        if have_src:
            sp = struct.pack("<I", tid) + s("Source") + struct.pack("<B", 1)
            for i in refs:
                k = (instances[i][0], instances[i][1])
                src = open(SCRIPT_SOURCES[k], encoding="utf-8").read()
                if len(src) > 100_000:
                    sys.exit(f"{k} excede 100.000 chars")
                sp += s(src)
            out += chunk(b"PROP", sp)

    # PRNT (todos, ordem de referent)
    prnt = struct.pack("<B", 0)
    prnt += struct.pack("<I", len(instances))
    prnt += referent_array_enc(list(range(len(instances))))
    parents = [-1 if par is None else par for _, _, par in instances]
    prnt += referent_array_enc(parents)
    out += chunk(b"PRNT", prnt)

    # END
    out += chunk(b"END\x00", b"</roblox>")
    return bytes(out)


def main():
    # teste 1: referent_array_enc byte-identico ao fixture
    import lz4.block  # noqa: F401
    sys.path.insert(0, HERE)
    import pyrbxl2
    fx = pyrbxl2.parse(open("/tmp/rbx-dom/rbx_binary/benches/files/modulescripts-100-lines-100.rbxm", "rb").read())
    for name, payload, parsed in fx.chunks:
        if name == b"PRNT":
            count = int.from_bytes(payload[1:5], "little")
            fx_subjects = payload[5:5 + 4 * count]
            mine = referent_array_enc(list(range(1, 100)) + [0])
            assert mine == fx_subjects, "referent_array_enc diverge do fixture!"
            print("teste 1 OK: referent_array byte-identico ao fixture")
            break

    data = build()
    open(OUT, "wb").write(data)
    print(f"gerado: {OUT} ({len(data)} bytes)")

    # teste 2: round-trip com o proprio decoder
    m = pyrbxl2.parse(data)
    assert m.num_types == len(set(c for c, _, _ in TREE))
    assert m.num_instances == len(TREE)
    type_by_id, instances_cls, order = pyrbxl2.build_index(m)
    # nomes
    names = {}
    sources = {}
    for name, payload, parsed in m.chunks:
        if name != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        tid = cr.u32()
        pname = cr.string()
        t = cr.u8()
        assert t == 1
        refs = None
        for nc in m.chunks:
            if nc[0] == b"INST" and nc[2] is not None and nc[2][0] == tid:
                refs = nc[2][3]
                break
        vals = [cr.take(cr.u32()).decode("utf-8") for _ in refs]
        for ref, v in zip(refs, vals):
            if pname == "Name":
                names[ref] = v
            elif pname == "Source":
                sources[ref] = v
    # arvore
    prnt = next(parsed for n, p, parsed in m.chunks if n == b"PRNT" and parsed)
    ver, subjects, parents = prnt
    parent_of = dict(zip(subjects, parents))
    cls_of = {}
    for nc in m.chunks:
        if nc[0] == b"INST" and nc[2]:
            tid, tname, is_s, refs, flags = nc[2]
            for r in refs:
                cls_of[r] = tname
    # comparar com a intencao
    ref_by_name = {name: i for i, (_, name, _) in enumerate(TREE)}
    ok = True
    for i, (cls, name, parent) in enumerate(TREE):
        if cls_of.get(i) != cls:
            print(f"  FALHA classe ref={i} {name}: {cls_of.get(i)} != {cls}")
            ok = False
        if names.get(i) != name:
            print(f"  FALHA nome ref={i}: {names.get(i)!r} != {name!r}")
            ok = False
        exp_par = ref_by_name[parent] if parent else -1
        if parent_of.get(i) != exp_par:
            print(f"  FALHA parent ref={i} {name}: {parent_of.get(i)} != {exp_par}")
            ok = False
        if (cls, name) in SCRIPT_SOURCES:
            exp = open(SCRIPT_SOURCES[(cls, name)], encoding="utf-8").read()
            if sources.get(i) != exp:
                print(f"  FALHA source ref={i} {name}")
                ok = False
    print("teste 2 OK: round-trip 100% (classes, nomes, pais, sources)" if ok else "teste 2 FALHOU")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
