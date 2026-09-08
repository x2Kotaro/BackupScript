game:GetService("ContentProvider")
local v1 = game:GetService("ReplicatedStorage")
game:GetService("Lighting")
local v2 = v1:WaitForChild("Gradients")
game:GetService("KeyframeSequenceProvider")
local v3 = v1:WaitForChild("Assets")
local v4 = v3:WaitForChild("VFX")
local v5 = v3:WaitForChild("Sounds")
v4:WaitForChild("Abilities")
local v6 = v5:WaitForChild("Abilities")
v3:WaitForChild("GatherableStuff")
local v7 = v4:WaitForChild("ThrowableObjects")
v7:WaitForChild("Car")
v7:WaitForChild("TrashCan")
local v8 = v3:WaitForChild("Lightings")
v8:WaitForChild("Basic")
v8:WaitForChild("Yoshiwara")
v8:WaitForChild("Kaito")
v8:WaitForChild("Gamemodes")
v8:WaitForChild("Ruined")
v8.Yoshiwara:WaitForChild("SunRays")
v8.Yoshiwara:WaitForChild("Bloom")
v8.Kaito:WaitForChild("SunRays")
v8.Ruined:WaitForChild("SunRays")
v8.Ruined:WaitForChild("Bloom")
v8.Gamemodes:WaitForChild("DomainObtain")
v8.Gamemodes:WaitForChild("CollegeMission")
v8.Gamemodes.DomainObtain:WaitForChild("Bloom")
v8.Gamemodes.DomainObtain:WaitForChild("DepthOfField")
v8.Gamemodes.DomainObtain:WaitForChild("ColorCorrection")
v8.Gamemodes.DomainObtain:WaitForChild("Blur")
v8.Gamemodes.DomainObtain:WaitForChild("SunRays")
v8.Gamemodes.CollegeMission:WaitForChild("Bloom")
v8.Gamemodes.CollegeMission:WaitForChild("Blur")
v8.Gamemodes.CollegeMission:WaitForChild("DepthOfField")
v8.Gamemodes.CollegeMission:WaitForChild("ColorCorrection")
v8.Gamemodes.CollegeMission:WaitForChild("SunRays")
v8.Gamemodes.JogoCursedDungeon:WaitForChild("ColorCorrection")
v8.Gamemodes.JogoCursedDungeon:WaitForChild("SunRays")
v2:WaitForChild("RankedRanks")
v2.RankedRanks:WaitForChild("Diamond")
v2.RankedRanks:WaitForChild("Titanium")
v2:WaitForChild("SpecialRarity")
v2:WaitForChild("HeianRarity")
v2:WaitForChild("Health")
v2:WaitForChild("CE")
v2:WaitForChild("CEDamage")
v2:WaitForChild("PhyDamage")
v2:WaitForChild("Luck")
v2:WaitForChild("Burn")
v2:WaitForChild("Exp")
v2:WaitForChild("GradeExp")
v2:WaitForChild("CERegen")
v2:WaitForChild("Mastery")
v2:WaitForChild("SSSTier")
v2:WaitForChild("SSTier")
v2:WaitForChild("STier")
v2:WaitForChild("HealthRegen")
v2:WaitForChild("BlackFlash")
local v9 = {
    ["TestPlaceGameId"] = 9325490024,
    ["PlacesIDs"] = {
        ["RPG"] = 16997064928,
        ["Menu"] = 16997056665,
        ["RankedLobby"] = 17255868720,
        ["RankedGame"] = 17549123407,
        ["SFFLobby"] = 17796845390,
        ["SFFGame"] = 17801069764,
        ["SpiritBashRaceGame"] = 92614916552895,
        ["Prologue"] = 18594963890,
        ["Raid"] = 18939291647,
        ["Dungeon"] = 92950585659247,
        ["Challenge"] = 139381639685164,
        ["TradeHub"] = 79469902309075
    },
    ["TestPlacesIDs"] = {
        ["RPG"] = 121598051092948,
        ["Menu"] = 114549583071453
    },
    ["GameVersion"] = 1.04,
    ["ShowHitboxes"] = false,
    ["ShowSimplePath"] = false,
    ["DisableSpawnScript"] = false,
    ["CDMult"] = 1,
    ["RespawnTime"] = 8,
    ["CursedSpiritTestMode"] = false,
    ["CursedTechniqueUnlockQuestIndex"] = 17,
    ["SorcererGradeUnlockQuestIndex"] = 15,
    ["SkillsImpactFrameShowDistance"] = 85,
    ["ResetTime"] = 10,
    ["MinPVPLevel"] = 10,
    ["MaxCombo"] = 4,
    ["HumanFactorClicks"] = 0.2,
    ["UpComboAllignTime"] = 0.45,
    ["AirComboValueTime"] = 1.25,
    ["AdditionalWaitTimeBetweenComboClicks"] = 0.4,
    ["AdditionalStunTimeAfterFinalComboClick"] = 0.1,
    ["WeaponTypesStunLengths"] = {
        ["Light"] = 0.7,
        ["Medium"] = 1,
        ["Heavy"] = 1.1
    },
    ["WeaponTypesHitboxStopTime"] = {
        ["Light"] = 0.15,
        ["Medium"] = 0.22,
        ["Heavy"] = 0.3
    },
    ["CombatDamage"] = 2,
    ["CursedSpiritFifthClickStunTime"] = 0.2,
    ["CursedSpiritUpDownClickStunTime"] = 0.35,
    ["MaximumOutputModeMaxBarValue"] = 100,
    ["MaximumOutputModeBarValuePerSkill"] = 7.75,
    ["MaximumOutputModeTime"] = 50,
    ["MaximumOutputModeDecreasePerSec"] = 0.07,
    ["MaximumOutputCERestorePercent"] = 0.35,
    ["RainEventTime"] = 510,
    ["NormalCharacterNPCHealthNameBillSize"] = UDim2.new(3.5, 0, 1, 0)
}
local v10 = {
    ["Owner"] = {
        ["UserIds"] = { 236137313 },
        ["ChatColor"] = Color3.fromRGB(0, 0, 0):ToHex()
    },
    ["Developer"] = {
        ["UserIds"] = { 366850896, 487609777, 3956478085 },
        ["ChatColor"] = Color3.fromRGB(128, 57, 183):ToHex()
    },
    ["Manager"] = {
        ["UserIds"] = { 1461976555, 676859541, 1827123899 },
        ["ChatColor"] = Color3.fromRGB(255, 46, 46):ToHex()
    },
    ["Lead Tester"] = {
        ["UserIds"] = { 1182325651, 172691953, 1462764313 },
        ["ChatColor"] = Color3.fromRGB(6, 53, 134):ToHex()
    },
    ["Tester"] = {
        ["UserIds"] = {},
        ["ChatColor"] = Color3.fromRGB(13, 106, 160):ToHex()
    }
}
v9.PlayersPrivileges = v10
v9.EdgeClimbAnims = {
    "rbxassetid://17882623746",
    "rbxassetid://111673253305450",
    "rbxassetid://99575388041493",
    "rbxassetid://124011762122779",
    "rbxassetid://108939491204300"
}
local v11 = {
    ["GloomhornCurse"] = {
        {
            ["Index"] = 70008,
            ["Chance"] = 100,
            ["Amount"] = { 300, 400 }
        },
        {
            ["Index"] = 70000,
            ["Chance"] = 100,
            ["Amount"] = { 1, 4 }
        },
        {
            ["Index"] = 70031,
            ["Chance"] = 10,
            ["Amount"] = { 1, 1 }
        },
        {
            ["Index"] = 120005,
            ["Chance"] = 4,
            ["Amount"] = { 1, 1 }
        },
        {
            ["Index"] = 70009,
            ["Chance"] = 3,
            ["Amount"] = { 1, 1 }
        },
        {
            ["Index"] = 99999,
            ["Amount"] = { 2, 3 },
            ["Chance"] = 100
        }
    }
}
v9.Rewards = v11
local v12 = {
    ["5KLikes"] = {
        ["SoulPoints"] = 2500
    },
    ["RELEASE!!!"] = {
        ["SoulPoints"] = 2000
    },
    ["FirstShutdown"] = {
        ["SoulPoints"] = 1500
    },
    ["SorryForBugs"] = {
        ["SoulPoints"] = 4500
    }
}
v9.Codes = v12
local v13 = {
    ["ExpiredCode"] = {
        ["SoulPoints"] = 50
    },
    ["Code2"] = {
        ["SoulPoints"] = 100
    },
    ["Code"] = {
        ["SoulPoints"] = 50
    },
    ["MerryChirstmasEAandTesters"] = {
        ["SoulPoints"] = 6666
    }
}
v9.ExpiredCodes = v13
v9.FlyingVelocityDestroyPower = 15
v9.BreakableVelocityDecreaseRate = 0.2
local v14 = {}
local v15 = {
    ["Durability"] = 30,
    ["RespawnTime"] = 40,
    ["DestroyAnimation"] = "RandomDirectionFall",
    ["PrimaryPart"] = "Trunk",
    ["TweenTime"] = 2.65,
    ["Particles"] = {
        {
            ["ParticleAction"] = "Emit",
            ["ParticleHolder"] = v4
        }
    },
    ["SFX"] = {
        {
            ["SFXHolder"] = v5,
            ["Volume"] = 2
        }
    }
}
v14.CurvedTree = v15
local v16 = {
    ["Durability"] = 10,
    ["RespawnTime"] = 20,
    ["DestroyAnimation"] = "RandomDirectionFall",
    ["PrimaryPart"] = "Trunk",
    ["TweenTime"] = 2.65,
    ["Particles"] = {
        {
            ["ParticleAction"] = "Emit",
            ["ParticleHolder"] = v4
        }
    },
    ["SFX"] = {
        {
            ["SFXHolder"] = v5,
            ["Volume"] = 2
        }
    }
}
v14.SmallTree = v16
local v17 = {
    ["Durability"] = 20,
    ["RespawnTime"] = 30,
    ["DestroyAnimation"] = "RandomDirectionFall",
    ["PrimaryPart"] = "Trunk",
    ["TweenTime"] = 2.65,
    ["Particles"] = {
        {
            ["ParticleAction"] = "Emit",
            ["ParticleHolder"] = v4
        }
    },
    ["SFX"] = {
        {
            ["SFXHolder"] = v5,
            ["Volume"] = 2
        }
    }
}
v14.TallTree = v17
v14.SmallHouse = {
    ["Durability"] = 25,
    ["RespawnTime"] = 45,
    ["DestroyAnimation"] = "HouseBreak",
    ["DestroyPartsAmount"] = { 6, 9 },
    ["DestroyPartsSize"] = {
        { 5, 1.5, 5 },
        { 18, 2, 18 }
    },
    ["DestroyPartsSpawnOffset"] = {
        { -8, 8 },
        { -6, 6 },
        { -5, 5 }
    },
    ["DestroyPartsDebrisTime"] = 15,
    ["DestroyPartsVelocity"] = 115,
    ["AdditionalEffect"] = "SmallHouse",
    ["AnimParent"] = "Model"
}
v14.MediumHouse = {
    ["Durability"] = 30,
    ["RespawnTime"] = 60,
    ["DestroyAnimation"] = "HouseBreak",
    ["DestroyPartsAmount"] = { 9, 12 },
    ["DestroyPartsSize"] = {
        { 7, 3, 7 },
        { 23, 4, 23 }
    },
    ["DestroyPartsSpawnOffset"] = {
        { -8, 8 },
        { -7, 7 },
        { -5, 5 }
    },
    ["DestroyPartsDebrisTime"] = 15,
    ["DestroyPartsVelocity"] = 140,
    ["AdditionalEffect"] = "SmallHouse",
    ["AnimParent"] = "Model"
}
local v18 = {
    ["Durability"] = 5,
    ["RespawnTime"] = 25,
    ["DestroyAnimation"] = "BreakOnParts",
    ["PrimaryPart"] = "Cube",
    ["TweenTime"] = 2.65,
    ["Particles"] = {
        {
            ["ParticleAction"] = "Emit",
            ["ParticleHolder"] = v4
        }
    },
    ["SFX"] = {
        {
            ["SFXHolder"] = v5,
            ["Volume"] = 2
        }
    }
}
v14.Lantern = v18
local v19 = {
    ["Durability"] = 5,
    ["RespawnTime"] = 25,
    ["DestroyAnimation"] = "BreakOnParts",
    ["PrimaryPart"] = "Pillar",
    ["TweenTime"] = 2.65,
    ["Particles"] = {
        {
            ["ParticleAction"] = "Emit",
            ["ParticleHolder"] = v4
        }
    },
    ["SFX"] = {
        {
            ["SFXHolder"] = v5,
            ["Volume"] = 2
        }
    }
}
v14.StreetLight = v19
local v20 = {
    ["Durability"] = 5,
    ["RespawnTime"] = 25,
    ["DestroyAnimation"] = "Bush",
    ["PrimaryPart"] = "Bush",
    ["Particles"] = {
        {
            ["ParticleAction"] = "Emit",
            ["ParticleHolder"] = v4
        }
    },
    ["SFX"] = {
        {
            ["SFXHolder"] = v5,
            ["Volume"] = 2
        }
    }
}
v14.Bush = v20
v14.StoneDungeonPillar = {
    ["Durability"] = 30,
    ["RespawnTime"] = 0,
    ["DestroyAnimation"] = "PartsFlying"
}
v14.DungeonBarrel = {
    ["Durability"] = 5,
    ["RespawnTime"] = 0,
    ["DestroyAnimation"] = "WoodBreak"
}
v14.GroundLeaves = {
    ["Durability"] = 5,
    ["RespawnTime"] = 30,
    ["DestroyAnimation"] = "Destroy",
    ["AnimParent"] = "Part",
    ["TweenTime"] = 3.5
}
v14.NoEffect = {
    ["Durability"] = 10,
    ["RespawnTime"] = 30,
    ["DestroyAnimation"] = "Break",
    ["AnimParent"] = "Model",
    ["TweenTime"] = 3.5
}
v14.NoEffectPart = {
    ["Durability"] = 5,
    ["RespawnTime"] = 30,
    ["DestroyAnimation"] = "Break",
    ["AnimParent"] = "Part",
    ["TweenTime"] = 4
}
v9.ObjestDurabilities = v14
v9.SkinTones = {
    "543309",
    "8d5a3a",
    "b8744c",
    "ffcc99",
    "ffd5b0"
}
v9.TimeBetweenBountyHunt = 300
v9.ExpPerBountyWin = { 25, 1000 }
v9.BountyPerWin = 250
v9.MapIgnoreTags = { "WindShake" }
v9.ZoneMobsDespawnTime = 90
v9.NormalMobRespawnTime = 15
v9.BossMobRespawnTime = 180
v9.BasicAmbientVolume = {
    ["Birds"] = 0.6,
    ["VillageCrowd"] = 0.45,
    ["Town"] = 0.24
}
if game.PlaceId ~= v9.PlacesIDs.Menu then
    local v21 = {
        ["Hotarugawa Town"] = {
            ["Description"] = "A lovely town with horrible history...",
            ["Music"] = "Hotarugawa Town",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Town")
        },
        ["Kitagawa Village"] = {
            ["Description"] = "A place away from the problems.",
            ["Music"] = "Kitagawa Village",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("VillageCrowd")
        },
        ["Jujutsu High"] = {
            ["Description"] = "Jujutsu educational institutions dedicated to fostering the next generation of Sorcerers.",
            ["Music"] = "Jujutsu High",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Jujutsu High Outskirts"] = {
            ["Description"] = "Jujustu college outskirts plain.",
            ["Music"] = "Wilderness",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Wilderness"] = {
            ["Description"] = "Beautiful Nature.",
            ["Music"] = "Wilderness",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Behind House"] = {
            ["Description"] = "Something is here.",
            ["Music"] = "Wilderness",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Ruined Fujihara Village"] = {
            ["Description"] = "Destroed by followers village.",
            ["Music"] = "Ruined Fujihara Village",
            ["BasicMusicVolume"] = 0.52,
            ["LocationLighting"] = "Ruined"
        },
        ["Parched Lands"] = {
            ["Description"] = "Lands exhausted from cursed energy.",
            ["Music"] = "Ruined Fujihara Village",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Kaito",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Colosseum"] = {
            ["Description"] = "The greatest fighting arena one day.",
            ["Music"] = "Ruined Fujihara Village",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Kaito"
        },
        ["Hill Temple"] = {
            ["Description"] = "Grave of a legendary hero.",
            ["Music"] = "Hill Temple",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Kaito"
        },
        ["Kaito Village"] = {
            ["Description"] = "Village where the hero was born.",
            ["Music"] = "Kaito Village",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Kaito",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("VillageCrowd")
        },
        ["Cursed Meadow"] = {
            ["Description"] = "Cocroach cursed spirits hideout.",
            ["Music"] = "Kitagawa Village",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Minagata Village"] = {
            ["Description"] = "Sakura is blooming here like never before.",
            ["Music"] = "Minagata",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Pinky",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("VillageCrowd")
        },
        ["Minagata Outskirts"] = {
            ["Description"] = "Beautifule Nature.",
            ["Music"] = "Wilderness",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Kanazawa Town"] = {
            ["Description"] = "Semi-Modern occupied city.",
            ["Music"] = "Kanazawa",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Kanazawa",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Town")
        },
        ["Yoshiwara City"] = {
            ["Description"] = "A city where one of the Commanders rules.",
            ["Music"] = "Yoshiwara",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "Basic",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Town")
        },
        ["Blood Palace"] = {
            ["Description"] = "First Commander property",
            ["Music"] = "Hill Temple",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "BloodPalace",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        },
        ["Misty Forest"] = {
            ["Description"] = "An incredibly large accumulation of cursed energy.",
            ["Music"] = "MistyForest",
            ["BasicMusicVolume"] = 0.147,
            ["LocationLighting"] = "MistyForest",
            ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
        }
    }
    v9.Zones = v21
end
v9.LocationsUnlockAtQuestIndex = {
    ["Ruined Fujihara Village"] = 7,
    ["Hotarugawa Town"] = 11,
    ["Jujutsu High"] = 15,
    ["Minagata Village"] = 20,
    ["Kanazawa Town"] = 44,
    ["Kaito Village"] = 29,
    ["Yoshiwara City"] = 36
}
local v22 = {}
local v23 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.396078, 0.513726, 0.564706),
        ["Brightness"] = 6,
        ["ClockTime"] = 20.39999961853027,
        ["ColorShift_Bottom"] = Color3.new(0.141176, 0.2, 0.219608),
        ["ColorShift_Top"] = Color3.new(0.705882, 0.8, 1),
        ["EnvironmentDiffuseScale"] = 1,
        ["EnvironmentSpecularScale"] = 1,
        ["ExposureCompensation"] = 0.15,
        ["GeographicLatitude"] = 43,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.721569, 0.72549, 1),
        ["ShadowSoftness"] = 0.4000000059604645
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0.611765, 0.929412, 1),
        ["Decay"] = Color3.new(0.635294, 0.733333, 1),
        ["Density"] = 0.4199999868869781,
        ["Glare"] = 0.2099999934434891,
        ["Haze"] = 0.4000000059604645,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://591058823",
        ["SkyboxDn"] = "rbxassetid://591059876",
        ["SkyboxFt"] = "rbxassetid://591058104",
        ["SkyboxLf"] = "rbxassetid://591057861",
        ["SkyboxRt"] = "rbxassetid://591057625",
        ["SkyboxUp"] = "rbxassetid://591059642",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 10,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Clouds"] = {
        ["Cover"] = 0,
        ["Density"] = 45,
        ["Color"] = Color3.new(1, 1, 1)
    },
    ["ColorCorrection"] = v8.Gamemodes.CollegeMission.ColorCorrection,
    ["Blur"] = v8.Gamemodes.CollegeMission.Blur,
    ["Bloom"] = v8.Gamemodes.CollegeMission.Bloom,
    ["DepthOfField"] = v8.Gamemodes.CollegeMission.DepthOfField,
    ["SunRays"] = v8.Gamemodes.CollegeMission.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
}
v22.CollegeMission = v23
local v24 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.494118, 0.494118, 0.494118),
        ["Brightness"] = 3.5,
        ["ClockTime"] = 6.6,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 0.705882, 0.0235294),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.45,
        ["GeographicLatitude"] = 324,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(1, 0.666667, 0.498039),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 0.666667, 0),
        ["Decay"] = Color3.new(1, 1, 1),
        ["Density"] = 0.3479999899864197,
        ["Glare"] = 0.5,
        ["Haze"] = 0.5,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "http://www.roblox.com/asset/?id=15670828196",
        ["SkyboxDn"] = "http://www.roblox.com/asset/?id=15670829373",
        ["SkyboxFt"] = "http://www.roblox.com/asset/?id=15670830476",
        ["SkyboxLf"] = "http://www.roblox.com/asset/?id=15670831662",
        ["SkyboxRt"] = "http://www.roblox.com/asset/?id=15670833256",
        ["SkyboxUp"] = "http://www.roblox.com/asset/?id=15670834206",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Clouds"] = {
        ["Cover"] = 0.35,
        ["Density"] = 1,
        ["Color"] = Color3.new(1, 1, 1)
    },
    ["ColorCorrection"] = v8.Gamemodes.DomainObtain.ColorCorrection,
    ["Blur"] = v8.Gamemodes.DomainObtain.Blur,
    ["Bloom"] = v8.Gamemodes.DomainObtain.Bloom,
    ["DepthOfField"] = v8.Gamemodes.DomainObtain.DepthOfField,
    ["SunRays"] = v8.Gamemodes.DomainObtain.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
}
v22.DomainObtain = v24
local v25 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 1.75,
        ["ClockTime"] = 12,
        ["ColorShift_Bottom"] = Color3.new(0, 0, 0),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.5,
        ["GeographicLatitude"] = 25,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929,
        ["TimeOfDay"] = "12:00:00"
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0.780392, 0.780392, 0.780392),
        ["Decay"] = Color3.new(0.52, 0.82, 1),
        ["Density"] = 0.35,
        ["Glare"] = 0.75,
        ["Haze"] = 2.04,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = false,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "http://www.roblox.com/asset/?id=6285719338",
        ["SkyboxDn"] = "http://www.roblox.com/asset/?id=6285721078",
        ["SkyboxFt"] = "http://www.roblox.com/asset/?id=6285722964",
        ["SkyboxLf"] = "http://www.roblox.com/asset/?id=6285724682",
        ["SkyboxRt"] = "http://www.roblox.com/asset/?id=6285726335",
        ["SkyboxUp"] = "http://www.roblox.com/asset/?id=6285730635",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Clouds"] = {
        ["Cover"] = 0,
        ["Density"] = 0.357,
        ["Color"] = Color3.new(1, 1, 1)
    },
    ["ColorCorrection"] = v8.Gamemodes.JogoCursedDungeon.ColorCorrection,
    ["SunRays"] = v8.Gamemodes.JogoCursedDungeon.SunRays
}
v22["Jogo Cursed Dungeon"] = v25
local v26 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.705882, 0.760784, 1),
        ["Brightness"] = 2,
        ["ClockTime"] = 8.199999809265137,
        ["ColorShift_Bottom"] = Color3.new(0, 0.666667, 1),
        ["ColorShift_Top"] = Color3.new(0.705882, 0.8, 1),
        ["EnvironmentDiffuseScale"] = 0.25,
        ["EnvironmentSpecularScale"] = 1,
        ["ExposureCompensation"] = 0,
        ["GeographicLatitude"] = 43,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.721569, 0.72549, 1),
        ["ShadowSoftness"] = 0.4000000059604645
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0, 0.666667, 1),
        ["Decay"] = Color3.new(0, 0.329412, 0.494118),
        ["Density"] = 0.4280000030994415,
        ["Glare"] = 0,
        ["Haze"] = 0,
        ["Offset"] = 0.6740000247955322
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://591058823",
        ["SkyboxDn"] = "rbxassetid://591059876",
        ["SkyboxFt"] = "rbxassetid://591058104",
        ["SkyboxLf"] = "rbxassetid://591057861",
        ["SkyboxRt"] = "rbxassetid://591057625",
        ["SkyboxUp"] = "rbxassetid://591059642",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 10,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8:WaitForChild("Basic"):WaitForChild("Bloom"),
    ["Blur"] = v8:WaitForChild("Basic"):WaitForChild("Blur"),
    ["ColorCorrection"] = v8:WaitForChild("Basic"):WaitForChild("ColorCorrection"),
    ["DepthOfField"] = v8:WaitForChild("Basic"):WaitForChild("DepthOfField"),
    ["SunRays"] = v8:WaitForChild("Basic"):WaitForChild("SunRays"),
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.55,
        ["Density"] = 0.415,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.Basic = v26
local v27 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.705882, 0.760784, 1),
        ["Brightness"] = 2,
        ["ClockTime"] = 10.4,
        ["ColorShift_Bottom"] = Color3.new(0, 0.666667, 1),
        ["ColorShift_Top"] = Color3.new(0.705882, 0.8, 1),
        ["EnvironmentDiffuseScale"] = 0.25,
        ["EnvironmentSpecularScale"] = 1,
        ["ExposureCompensation"] = -0.2000000029802322,
        ["GeographicLatitude"] = 34,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.721569, 0.72549, 1),
        ["ShadowSoftness"] = 0.4000000059604645
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0, 0.666667, 1),
        ["Decay"] = Color3.new(0, 0.329412, 0.494118),
        ["Density"] = 0.4280000030994415,
        ["Glare"] = 0,
        ["Haze"] = 0,
        ["Offset"] = 0.6740000247955322
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://591058823",
        ["SkyboxDn"] = "rbxassetid://591059876",
        ["SkyboxFt"] = "rbxassetid://591058104",
        ["SkyboxLf"] = "rbxassetid://591057861",
        ["SkyboxRt"] = "rbxassetid://591057625",
        ["SkyboxUp"] = "rbxassetid://591059642",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 10,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8:WaitForChild("Basic"):WaitForChild("Bloom"),
    ["Blur"] = v8:WaitForChild("Basic"):WaitForChild("Blur"),
    ["ColorCorrection"] = v8:WaitForChild("Basic"):WaitForChild("ColorCorrection"),
    ["DepthOfField"] = v8:WaitForChild("Basic"):WaitForChild("DepthOfField"),
    ["SunRays"] = v8:WaitForChild("Basic"):WaitForChild("SunRays"),
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.55,
        ["Density"] = 0.415,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.Kanazawa = v27
local v28 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.262745, 0.298039, 0.301961),
        ["Brightness"] = 8,
        ["ClockTime"] = 22.39999961853027,
        ["ColorShift_Bottom"] = Color3.new(0.360784, 0.415686, 0.458824),
        ["ColorShift_Top"] = Color3.new(0.219608, 0.223529, 0.203922),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 1,
        ["GeographicLatitude"] = -18,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.376471, 0.4, 0.4),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0.141176, 0.141176, 0.141176),
        ["Decay"] = Color3.new(0.156863, 0.156863, 0.156863),
        ["Density"] = 0.4199999868869781,
        ["Glare"] = 0.5,
        ["Haze"] = 8.15999984741211,
        ["Offset"] = 0.75
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = false,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "http://www.roblox.com/asset/?id=6285719338",
        ["SkyboxDn"] = "http://www.roblox.com/asset/?id=6285721078",
        ["SkyboxFt"] = "http://www.roblox.com/asset/?id=6285722964",
        ["SkyboxLf"] = "http://www.roblox.com/asset/?id=6285724682",
        ["SkyboxRt"] = "http://www.roblox.com/asset/?id=6285726335",
        ["SkyboxUp"] = "http://www.roblox.com/asset/?id=6285730635",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Basic.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Basic.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.65,
        ["Density"] = 0.35,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.Night = v28
local v29 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.fromHex("#966900"),
        ["Brightness"] = 2.65,
        ["ClockTime"] = 15.2,
        ["ColorShift_Bottom"] = Color3.fromHex("#935d00"),
        ["ColorShift_Top"] = Color3.fromHex("#d89b00"),
        ["EnvironmentDiffuseScale"] = 0.308,
        ["EnvironmentSpecularScale"] = 0.812,
        ["ExposureCompensation"] = -0.05,
        ["GeographicLatitude"] = 340,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.fromHex("#ffc2a5"),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 0.25, 0),
        ["Decay"] = Color3.new(1, 0.6, 0),
        ["Density"] = 0.329,
        ["Glare"] = 0.21,
        ["Haze"] = 0.1,
        ["Offset"] = 0.75
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://591058823",
        ["SkyboxDn"] = "rbxassetid://591059876",
        ["SkyboxFt"] = "rbxassetid://591058104",
        ["SkyboxLf"] = "rbxassetid://591057861",
        ["SkyboxRt"] = "rbxassetid://591057625",
        ["SkyboxUp"] = "rbxassetid://591059642",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 10,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8:WaitForChild("Yoshiwara").Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Yoshiwara.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.5,
        ["Density"] = 0.17,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.Yoshiwara = v29
local v30 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 1.5,
        ["ClockTime"] = 15.6,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.2000000029802322,
        ["GeographicLatitude"] = 8,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 0.98, 0.47),
        ["Decay"] = Color3.new(1, 1, 1),
        ["Density"] = 0.3,
        ["Glare"] = 0.5,
        ["Haze"] = 0.5,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "http://www.roblox.com/asset/?id=15670828196",
        ["SkyboxDn"] = "http://www.roblox.com/asset/?id=15670829373",
        ["SkyboxFt"] = "http://www.roblox.com/asset/?id=15670830476",
        ["SkyboxLf"] = "http://www.roblox.com/asset/?id=15670831662",
        ["SkyboxRt"] = "http://www.roblox.com/asset/?id=15670833256",
        ["SkyboxUp"] = "http://www.roblox.com/asset/?id=15670834206",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Basic.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Kaito.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.4,
        ["Density"] = 0.35,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.Kaito = v30
local v31 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 3.25,
        ["ClockTime"] = 15.6,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.2000000029802322,
        ["GeographicLatitude"] = 8,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 0.443137, 0.403921),
        ["Decay"] = Color3.new(1, 1, 1),
        ["Density"] = 0.3,
        ["Glare"] = 0.5,
        ["Haze"] = 0.5,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "http://www.roblox.com/asset/?id=15670828196",
        ["SkyboxDn"] = "http://www.roblox.com/asset/?id=15670829373",
        ["SkyboxFt"] = "http://www.roblox.com/asset/?id=15670830476",
        ["SkyboxLf"] = "http://www.roblox.com/asset/?id=15670831662",
        ["SkyboxRt"] = "http://www.roblox.com/asset/?id=15670833256",
        ["SkyboxUp"] = "http://www.roblox.com/asset/?id=15670834206",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Basic.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Kaito.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.4,
        ["Density"] = 0.35,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.BloodPalace = v31
local v32 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 2,
        ["ClockTime"] = 9,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.25,
        ["GeographicLatitude"] = -19.875,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0.7843, 0.6667, 0.4235),
        ["Decay"] = Color3.new(0.3608, 0.2353, 0.0549),
        ["Density"] = 0.362,
        ["Glare"] = 0,
        ["Haze"] = 0,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = false,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://600830446",
        ["SkyboxDn"] = "rbxassetid://600831635",
        ["SkyboxFt"] = "rbxassetid://600832720",
        ["SkyboxLf"] = "rbxassetid://600886090",
        ["SkyboxRt"] = "rbxassetid://600833862",
        ["SkyboxUp"] = "rbxassetid://600835177",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Basic.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Ruined.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
}
v22.Rainy = v32
local v33 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 2,
        ["ClockTime"] = 9,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.7,
        ["GeographicLatitude"] = -19.875,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 1, 1),
        ["Decay"] = Color3.new(1, 1, 1),
        ["Density"] = 0.4,
        ["Glare"] = 0.1000000014901161,
        ["Haze"] = 0,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = false,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://246480323",
        ["SkyboxDn"] = "rbxassetid://246480523",
        ["SkyboxFt"] = "rbxassetid://246480105",
        ["SkyboxLf"] = "rbxassetid://246480549",
        ["SkyboxRt"] = "rbxassetid://246480565",
        ["SkyboxUp"] = "rbxassetid://246480504",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Ruined.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Ruined.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds")
}
v22.Ruined = v33
local v34 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 2,
        ["ClockTime"] = 9,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.25,
        ["GeographicLatitude"] = -19.875,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 0.9, 0.98),
        ["Decay"] = Color3.new(1, 1, 1),
        ["Density"] = 0.4,
        ["Glare"] = 0.15,
        ["Haze"] = 1,
        ["Offset"] = 0
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://11555017034",
        ["SkyboxDn"] = "rbxassetid://11555013415",
        ["SkyboxFt"] = "rbxassetid://11555010145",
        ["SkyboxLf"] = "rbxassetid://11555006545",
        ["SkyboxRt"] = "rbxassetid://11555000712",
        ["SkyboxUp"] = "rbxassetid://11554996247",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 21,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Basic.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Basic.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 0.4,
        ["Density"] = 0.3,
        ["Color"] = Color3.new(1, 1, 1)
    }
}
v22.Pinky = v34
local v35 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(0.498039, 0.498039, 0.498039),
        ["Brightness"] = 3,
        ["ClockTime"] = 9,
        ["ColorShift_Bottom"] = Color3.new(0.462745, 0.462745, 0.462745),
        ["ColorShift_Top"] = Color3.new(1, 1, 1),
        ["EnvironmentDiffuseScale"] = 0.6000000238418579,
        ["EnvironmentSpecularScale"] = 0.6499999761581421,
        ["ExposureCompensation"] = 0.2000000029802322,
        ["GeographicLatitude"] = -19.875,
        ["GlobalShadows"] = true,
        ["OutdoorAmbient"] = Color3.new(0.501961, 0.501961, 0.501961),
        ["ShadowSoftness"] = 0.300000011920929
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(0.55, 0.86, 1),
        ["Decay"] = Color3.new(0, 0.749019, 1),
        ["Density"] = 0.55,
        ["Glare"] = 0.05,
        ["Haze"] = 7.01,
        ["Offset"] = 0.386
    },
    ["Sky"] = {
        ["CelestialBodiesShown"] = true,
        ["MoonAngularSize"] = 11,
        ["MoonTextureId"] = "rbxasset://sky/moon.jpg",
        ["SkyboxBk"] = "rbxassetid://591058823",
        ["SkyboxDn"] = "rbxassetid://591059876",
        ["SkyboxFt"] = "rbxassetid://591058104",
        ["SkyboxLf"] = "rbxassetid://591057861",
        ["SkyboxRt"] = "rbxassetid://591057625",
        ["SkyboxUp"] = "rbxassetid://591059642",
        ["StarCount"] = 3000,
        ["SunAngularSize"] = 10,
        ["SunTextureId"] = "rbxasset://sky/sun.jpg"
    },
    ["Bloom"] = v8.Basic.Bloom,
    ["Blur"] = v8.Basic.Blur,
    ["ColorCorrection"] = v8.Basic.ColorCorrection,
    ["DepthOfField"] = v8.Basic.DepthOfField,
    ["SunRays"] = v8.Basic.SunRays,
    ["Ambience"] = v3:WaitForChild("Ambience"):WaitForChild("Birds"),
    ["Clouds"] = {
        ["Cover"] = 1,
        ["Density"] = 0.35,
        ["Color"] = Color3.new(0.34, 0.695, 1)
    }
}
v22.MistyForest = v35
local v36 = {
    ["Lighting"] = {
        ["Ambient"] = Color3.new(1, 0, 0),
        ["Brightness"] = 2,
        ["ColorShift_Top"] = Color3.new(1, 0.666667, 0),
        ["OutdoorAmbient"] = Color3.new(1, 1, 0),
        ["ExposureCompensation"] = 0
    },
    ["Atmosphere"] = {
        ["Color"] = Color3.new(1, 0.760784, 0.149019),
        ["Decay"] = Color3.new(1, 1, 0.498039)
    },
    ["Ambience"] = nil
}
v22.Volcano = v36
v9.LocationsLighting = v22
local v37 = {}
local v38 = {
    ["Amount"] = 100,
    ["RobuxPrice"] = 0,
    ["Description"] = "Event limited free 100 Soul Points!",
    ["DevProductID"] = "6EE9E302-4673-4666-947C-2A996280260F",
    ["Image"] = "",
    ["Discount"] = 0,
    ["Sale"] = false
}
local v39 = {
    "Limited",
    ["LimitedAmount"] = 1,
    ["LimitedTimeFinish"] = os.time({
        ["year"] = 2024,
        ["month"] = 2,
        ["day"] = 24
    })
}
v38.Tags = v39
v38.PurchaseID = "6EE9E302-4673-4666-947C-2A996280260F"
local v40 = {
    ["Amount"] = 100,
    ["RobuxPrice"] = 0,
    ["Description"] = "Free daily Soul Points!",
    ["DevProductID"] = "99D021D6-2E05-4669-9547-516AB07A5BBD",
    ["Image"] = "rbxassetid://131993094098252",
    ["Discount"] = 0,
    ["Sale"] = false,
    ["Items"] = {},
    ["Tags"] = {
        "Daily",
        ["LimitedAmount"] = 1
    },
    ["PurchaseID"] = "99D021D6-2E05-4669-9547-516AB07A5BBD"
}
local v41 = {
    ["Amount"] = 500,
    ["RobuxPrice"] = 200,
    ["Description"] = "Event limited 500 Soul Points!",
    ["DevProductID"] = "1758517680",
    ["Image"] = "",
    ["Discount"] = 100,
    ["Sale"] = true
}
local v42 = {
    "Limited",
    ["LimitedAmount"] = 3,
    ["LimitedTimeFinish"] = os.time({
        ["year"] = 2024,
        ["month"] = 3,
        ["day"] = 24
    })
}
v41.Tags = v42
v41.PurchaseID = "E72944AC-0E95-49EC-823E-E2B4DC168F02"
local v43 = {
    ["Amount"] = 1000,
    ["RobuxPrice"] = 299,
    ["Description"] = "Weekends Pack 1!",
    ["DevProductID"] = "3445465180",
    ["Image"] = "rbxassetid://124947336691338",
    ["Discount"] = 33,
    ["Sale"] = true,
    ["Tags"] = {
        "Weekends",
        ["LimitedAmount"] = 3
    },
    ["PurchaseID"] = "F600A25E-A220-4365-87E5-6CF3D4DCA258"
}
local v44 = {
    ["Amount"] = 3750,
    ["RobuxPrice"] = 999,
    ["Description"] = "Mega Weekends Pack!",
    ["DevProductID"] = "3445465287",
    ["Image"] = "rbxassetid://100245017991056",
    ["Discount"] = 50,
    ["Sale"] = true,
    ["Tags"] = {
        "Weekends",
        ["LimitedAmount"] = 2
    },
    ["PurchaseID"] = "EF3B0458-C09F-4426-9564-9E179B42E5DD"
}
local v45 = {
    ["Amount"] = 8750,
    ["RobuxPrice"] = 1999,
    ["Description"] = "Ultimate Weekends Pack!",
    ["DevProductID"] = "3445465409",
    ["Image"] = "rbxassetid://129906527826506",
    ["Discount"] = 75,
    ["Sale"] = true,
    ["Tags"] = {
        "Weekends",
        ["LimitedAmount"] = 1
    },
    ["PurchaseID"] = "a8e0f1af-6ce2-4bbc-9c38-a79f8a0d1122"
}
local v46 = {
    ["Amount"] = 550,
    ["RobuxPrice"] = 149,
    ["Description"] = "Monthly Pack!",
    ["DevProductID"] = "3445465558",
    ["Image"] = "rbxassetid://124947336691338",
    ["Discount"] = 45,
    ["Sale"] = true,
    ["Tags"] = {
        "Monthly",
        ["LimitedAmount"] = 5
    },
    ["PurchaseID"] = "582A4C5F-B373-4498-A0B8-2E02BB4064F5"
}
local v47 = {
    ["Amount"] = 3175,
    ["RobuxPrice"] = 749,
    ["Description"] = "Mega Monthly Pack!",
    ["DevProductID"] = "3445466294",
    ["Image"] = "rbxassetid://100245017991056",
    ["Discount"] = 70,
    ["Sale"] = true,
    ["Tags"] = {
        "Monthly",
        ["LimitedAmount"] = 4
    },
    ["PurchaseID"] = "cc076e75-1c90-4d98-b007-e62ae2d700f1"
}
local v48 = {
    ["Amount"] = 7500,
    ["RobuxPrice"] = 1499,
    ["Description"] = "Ultimate Monthly Pack!",
    ["DevProductID"] = "3445466412",
    ["Image"] = "rbxassetid://129906527826506",
    ["Discount"] = 100,
    ["Sale"] = true,
    ["Tags"] = {
        "Monthly",
        ["LimitedAmount"] = 3
    },
    ["PurchaseID"] = "cc7aaee6-bc9a-4a02-834c-55cdded3b079"
}
__set_list(v37, 1, {v38, v40, v41, v43, v44, v45, v46, v47, v48, {
    ["Amount"] = 500,
    ["RobuxPrice"] = 199,
    ["Description"] = "Grants you 500 Soul Points!",
    ["DevProductID"] = "3445404247",
    ["Image"] = "rbxassetid://83673208386364",
    ["Discount"] = 0,
    ["Sale"] = false,
    ["Tags"] = {},
    ["PurchaseID"] = "39639D67-FD68-4C70-B00C-C929AD06AFFB"
}, {
    ["Amount"] = 1500,
    ["RobuxPrice"] = 499,
    ["Description"] = "Grants you 1500 Soul Points!",
    ["DevProductID"] = "3445404568",
    ["Image"] = "rbxassetid://124947336691338",
    ["Discount"] = 20,
    ["Sale"] = false,
    ["Tags"] = {},
    ["PurchaseID"] = "79F18200-3424-447A-8577-566150EF0F40"
}, {
    ["Amount"] = 4500,
    ["RobuxPrice"] = 1299,
    ["Description"] = "Grants you 4500 Soul Points!",
    ["DevProductID"] = "3445404988",
    ["Image"] = "rbxassetid://100245017991056",
    ["Discount"] = 38,
    ["Sale"] = false,
    ["Tags"] = {},
    ["PurchaseID"] = "792a0d70-0d65-4394-a50b-718a170c003c"
}, {
    ["Amount"] = 10000,
    ["RobuxPrice"] = 2499,
    ["Description"] = "Grants you 10000 Soul Points!",
    ["DevProductID"] = "3445405401",
    ["Image"] = "rbxassetid://129906527826506",
    ["Discount"] = 60,
    ["Sale"] = false,
    ["Tags"] = {},
    ["PurchaseID"] = "560f82a2-e4a2-4dc2-ab3a-7ec914a00a00"
}})
v9.SoulPointsPacks = v37
v9.ProjectileFollowSpeedInDomain = 0.03
v9.FollowSpeedChangeMult = 6
v9.HeianBossBattleTime = 480
v9.HeianBossBattleLives = 3
v9.GoodwillBossSpawnTime = 360
v9.GoodwillExchangeGameTime = 900
v9.GoodwillRespawnTime = 20
v9.GoodwillPointsRecieveing = {
    ["Curse"] = 1,
    ["Strong Curse"] = 3,
    ["Very Strong Curse"] = 9,
    ["Hanami"] = 30,
    ["Player"] = 5
}
v9.BossSpeeches = {
    "Is thats all your capable of?",
    "This punch wouldn\'t hurt a fly",
    "Take this!",
    "Is that it?",
    "Arghhh!",
    "You can\'t defeat me!",
    "Ouch!"
}
local v49 = {}
local v50 = {
    ["SoulPoints"] = 350,
    ["Items"] = {
        {
            ["Index"] = 70000,
            ["Amount"] = { 5, 5 },
            ["Chance"] = 100
        },
        {
            ["Index"] = 70031,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 30
        },
        {
            ["Index"] = 110024,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 15
        },
        {
            ["Index"] = 90012,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 5
        },
        {
            ["Index"] = 70009,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 0.25
        },
        {
            ["Index"] = 99999,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 100
        }
    }
}
v49.Win = v50
local v51 = {
    ["SoulPoints"] = 0,
    ["Items"] = {
        {
            ["Index"] = 99999,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 25
        },
        {
            ["Index"] = 70000,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 15
        }
    }
}
v49.Defeat = v51
local v52 = {
    ["SoulPoints"] = 100,
    ["Items"] = {
        {
            ["Index"] = 70000,
            ["Amount"] = { 2, 3 },
            ["Chance"] = 100
        },
        {
            ["Index"] = 99999,
            ["Amount"] = { 1, 1 },
            ["Chance"] = 75
        }
    }
}
v49.Tie = v52
v9.GoodwillEventRewards = v49
v9.Gamemodes = {
    {
        ["Name"] = "RPG",
        ["Description"] = "Complete story, fight powerful enemies, explore new locations!",
        ["Teleport"] = v9.PlacesIDs.RPG
    },
    {
        ["Name"] = "Private Server",
        ["Description"] = "Your RPG world."
    },
    {
        ["Name"] = "Trade Hub",
        ["Description"] = "A place to trade with other sorcerers!",
        ["Teleport"] = v9.PlacesIDs.TradeHub,
        ["Closed"] = true
    },
    {
        ["Name"] = "Ranked",
        ["Description"] = "Compete with other sorcerers for the title of The Strongest!",
        ["Teleport"] = v9.PlacesIDs.RankedLobby,
        ["LevelReq"] = 60
    }
}
local v53 = {
    ["Settings"] = {
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -1.5,
        ["FinishOffset"] = 1
    }
}
v9.GamemodesGradient = v53
v9.EvasiveTimeDecreasePerSkillHit = 0.065
v9.ClanRerollPrice = 100
v9.InnateTechniqueRerollPrice = 100
v9.InnateTechniqueReqClanChance = 0.2
v9.MaxMissionsStorage = 2
v9.MissionCooldown = 420
v9.GradeStarterExp = 26
v9.GradeAdditionalExpPerGrade = 68
local v54 = {}
local v55 = {
    ["Name"] = "Grade 4",
    ["Index"] = 1,
    ["LocationsToClear"] = 1,
    ["MissionRewardScale"] = 0.1,
    ["MissionMobLevel"] = 15
}
local v56 = {}
local v57 = {}
local v58 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 600,
    ["GExp"] = 30,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 19,
            ["Amount"] = 10,
            ["Description"] = "Defeat Hotarugawa Soldiers"
        }
    }
}
local v59 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 560,
    ["GExp"] = 32,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 18,
            ["Amount"] = 8,
            ["Description"] = "Defeat Hotarugawa Town Curses"
        }
    }
}
local v60 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 550,
    ["GExp"] = 22,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 16,
            ["Amount"] = 1,
            ["Description"] = "Defeat Ruined Fujihara Village Invaders Leader"
        }
    }
}
__set_list(v57, 1, {v58, v59, v60})
v56.Normal = v57
v55.Missions = v56
local v61 = {
    ["Name"] = "Grade 3",
    ["Index"] = 2,
    ["LocationsToClear"] = 1,
    ["MissionRewardScale"] = 0.22,
    ["MissionMobLevel"] = 30,
    ["SoulPointsReward"] = 300,
    ["GExpReq"] = 26
}
local v62 = {}
local v63 = {}
local v64 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 980,
    ["GExp"] = 30,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 19,
            ["Amount"] = 10,
            ["Description"] = "Defeat Hotarugawa Soldiers"
        }
    }
}
local v65 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 980,
    ["GExp"] = 34,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 22,
            ["Amount"] = 10,
            ["Description"] = "Defeat Minagata Soldiers"
        }
    }
}
local v66 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 940,
    ["GExp"] = 25,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 20,
            ["Amount"] = 1,
            ["Description"] = "Defeat Town Warden"
        }
    }
}
local v67 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 940,
    ["GExp"] = 32,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 23,
            ["Amount"] = 1,
            ["Description"] = "Defeat Lieutenant"
        }
    }
}
__set_list(v63, 1, {v64, v65, v66, v67})
v62.Normal = v63
v61.Missions = v62
local v68 = {
    ["Name"] = "Semi-Grade 2",
    ["Index"] = 3,
    ["LocationsToClear"] = 2,
    ["MissionRewardScale"] = 0.32,
    ["MissionMobLevel"] = 45,
    ["SoulPointsReward"] = 400,
    ["GExpReq"] = 56
}
local v69 = {}
local v70 = {}
local v71 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 990,
    ["GExp"] = 29,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 22,
            ["Amount"] = 10,
            ["Description"] = "Defeat Minagata Soldiers"
        }
    }
}
local v72 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1000,
    ["GExp"] = 36,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 24,
            ["Amount"] = 10,
            ["Description"] = "Defeat Kanazawa Soldiers"
        }
    }
}
local v73 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1035,
    ["GExp"] = 39,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 25,
            ["Amount"] = 10,
            ["Description"] = "Defeat Strong Kanazawa Soldiers"
        }
    }
}
local v74 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1200,
    ["GExp"] = 32,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 23,
            ["Amount"] = 1,
            ["Description"] = "Defeat Lieutenant"
        }
    }
}
__set_list(v70, 1, {v71, v72, v73, v74})
v69.Normal = v70
v68.Missions = v69
local v75 = {
    ["Name"] = "Grade 2",
    ["Index"] = 4,
    ["LocationsToClear"] = 2,
    ["MissionRewardScale"] = 0.5,
    ["MissionMobLevel"] = 60,
    ["SoulPointsReward"] = 450,
    ["GExpReq"] = 154
}
local v76 = {}
local v77 = {}
local v78 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1000,
    ["GExp"] = 36,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 24,
            ["Amount"] = 14,
            ["Description"] = "Defeat Kanazawa Soldiers"
        }
    }
}
local v79 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1035,
    ["GExp"] = 39,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 25,
            ["Amount"] = 12,
            ["Description"] = "Defeat Strong Kanazawa Soldiers"
        }
    }
}
local v80 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1475,
    ["GExp"] = 37,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 26,
            ["Amount"] = 1,
            ["Description"] = "Defeat Vice-Captain"
        }
    }
}
__set_list(v77, 1, {v78, v79, v80})
v76.Normal = v77
v75.Missions = v76
local v81 = {
    ["Name"] = "Semi-Grade 1",
    ["LocationsToClear"] = 3,
    ["MissionRewardScale"] = 0.75,
    ["MissionMobLevel"] = 70,
    ["Index"] = 5,
    ["SoulPointsReward"] = 550,
    ["GExpReq"] = 245
}
local v82 = {}
local v83 = {}
local v84 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1500,
    ["GExp"] = 39,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 25,
            ["Amount"] = 10,
            ["Description"] = "Defeat Strong Kanazawa Soldiers"
        }
    }
}
local v85 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1905,
    ["GExp"] = 42,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 27,
            ["Amount"] = 8,
            ["Description"] = "Defeat Temple Curses"
        }
    }
}
local v86 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 1710,
    ["GExp"] = 41,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 26,
            ["Amount"] = 1,
            ["Description"] = "Defeat Vice-Captain"
        }
    }
}
local v87 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2100,
    ["GExp"] = 41,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 26,
            ["Amount"] = 1,
            ["Description"] = "Defeat Ryoma\'s Soul"
        }
    }
}
__set_list(v83, 1, {v84, v85, v86, v87})
v82.Normal = v83
v81.Missions = v82
local v88 = {
    ["Name"] = "Grade 1",
    ["Index"] = 6,
    ["LocationsToClear"] = 3,
    ["MissionRewardScale"] = 0.9,
    ["MissionMobLevel"] = 85,
    ["SoulPointsReward"] = 750,
    ["GExpReq"] = 360
}
local v89 = {}
local v90 = {}
local v91 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2040,
    ["GExp"] = 42,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 27,
            ["Amount"] = 8,
            ["Description"] = "Defeat Temple Curses"
        }
    }
}
local v92 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2475,
    ["GExp"] = 43,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 31,
            ["Amount"] = 10,
            ["Description"] = "Defeat Kato\'s Soldier"
        }
    }
}
local v93 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2700,
    ["GExp"] = 46,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 32,
            ["Amount"] = 10,
            ["Description"] = "Defeat Kato\'s Strong Soldier"
        }
    }
}
local v94 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2850,
    ["GExp"] = 45,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 30,
            ["Amount"] = 8,
            ["Description"] = "Defeat Meadow Curses"
        }
    }
}
local v95 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2205,
    ["GExp"] = 41,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 26,
            ["Amount"] = 1,
            ["Description"] = "Defeat Ryoma\'s Soul"
        }
    }
}
__set_list(v90, 1, {v91, v92, v93, v94, v95})
v89.Normal = v90
v88.Missions = v89
local v96 = {
    ["Name"] = "Special Grade",
    ["Index"] = 7,
    ["LocationsToClear"] = 3,
    ["MissionRewardScale"] = 1,
    ["MissionMobLevel"] = 105,
    ["SoulPointsReward"] = 1250,
    ["GExpReq"] = 465
}
local v97 = {}
local v98 = {}
local v99 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 2925,
    ["GExp"] = 46,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 32,
            ["Amount"] = 10,
            ["Description"] = "Defeat Kato\'s Strong Soldier"
        }
    }
}
local v100 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 3270,
    ["GExp"] = 45,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 30,
            ["Amount"] = 8,
            ["Description"] = "Defeat Meadow Curses"
        }
    }
}
local v101 = {
    ["TaskType"] = "Kill",
    ["EldersMessage"] = "Your help is needed at hotaraguwa town",
    ["Exp"] = 4050,
    ["GExp"] = 50,
    ["Goal"] = {
        {
            ["Completed"] = 0,
            ["Index"] = 999,
            ["Amount"] = 1,
            ["Description"] = "Defeat Kato Akumori"
        }
    }
}
__set_list(v98, 1, {v99, v100, v101})
v97.Normal = v98
v96.Missions = v97
__set_list(v54, 1, {v55, v61, v68, v75, v81, v88, v96})
v9.Grades = v54
local v102 = {}
local v103 = {
    ["DropChance"] = 63.65,
    ["BoxIndex"] = 70034,
    ["Rewards"] = {
        {
            ["Index"] = "EXP",
            ["Amount"] = { 50, 75 },
            ["RewardChance"] = 26.2
        },
        {
            ["Index"] = 70008,
            ["Amount"] = { 10, 25 },
            ["RewardChance"] = 26
        },
        {
            ["Index"] = "RandomTeleportationScroll",
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 19
        },
        {
            ["Index"] = "SoulPoints",
            ["Amount"] = { 20, 30 },
            ["RewardChance"] = 12
        },
        {
            ["Index"] = 70000,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 11
        },
        {
            ["Index"] = "2xBoosts",
            ["Time"] = { 3, 4 },
            ["RewardChance"] = 3
        },
        {
            ["Index"] = 70011,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 2
        },
        {
            ["Index"] = 70031,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.5
        },
        {
            ["Index"] = 90007,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.2
        },
        {
            ["Index"] = 70020,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.084
        },
        {
            ["Index"] = 70009,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.0075
        }
    }
}
v102.Box1 = v103
local v104 = {
    ["DropChance"] = 25,
    ["BoxIndex"] = 70035,
    ["Rewards"] = {
        {
            ["Index"] = "EXP",
            ["Amount"] = { 160, 185 },
            ["RewardChance"] = 20.4
        },
        {
            ["Index"] = "SoulPoints",
            ["Amount"] = { 60, 85 },
            ["RewardChance"] = 18
        },
        {
            ["Index"] = "RandomTeleportationScroll",
            ["Amount"] = { 1, 2 },
            ["RewardChance"] = 17
        },
        {
            ["Index"] = 70000,
            ["Amount"] = { 1, 2 },
            ["RewardChance"] = 15
        },
        {
            ["Index"] = 70008,
            ["Amount"] = { 45, 75 },
            ["RewardChance"] = 13.9
        },
        {
            ["Index"] = "2xBoosts",
            ["Time"] = { 7, 9 },
            ["RewardChance"] = 13
        },
        {
            ["Index"] = 70011,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 3.75
        },
        {
            ["Index"] = 70031,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.75
        },
        {
            ["Index"] = 70020,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.175
        },
        {
            ["Index"] = 70009,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.025
        }
    }
}
v102.Box2 = v104
local v105 = {
    ["DropChance"] = 8.5,
    ["BoxIndex"] = 70036,
    ["Rewards"] = {
        {
            ["Index"] = "SoulPoints",
            ["Amount"] = { 190, 240 },
            ["RewardChance"] = 21
        },
        {
            ["Index"] = 70000,
            ["Amount"] = { 2, 3 },
            ["RewardChance"] = 19
        },
        {
            ["Index"] = "2xBoosts",
            ["Time"] = { 12, 15 },
            ["RewardChance"] = 14
        },
        {
            ["Index"] = 70011,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 13
        },
        {
            ["Index"] = "EXP",
            ["Amount"] = { 400, 1250 },
            ["RewardChance"] = 11
        },
        {
            ["Index"] = 70008,
            ["Amount"] = { 100, 350 },
            ["RewardChance"] = 11
        },
        {
            ["Index"] = "RandomTeleportationScroll",
            ["Amount"] = { 2, 4 },
            ["RewardChance"] = 8
        },
        {
            ["Index"] = 70031,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 2
        },
        {
            ["Index"] = 70020,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.85
        },
        {
            ["Index"] = 70009,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.15
        }
    }
}
v102.Box3 = v105
local v106 = {
    ["DropChance"] = 2.5,
    ["BoxIndex"] = 70037,
    ["Rewards"] = {
        {
            ["Index"] = "2xBoosts",
            ["Time"] = { 20, 25 },
            ["RewardChance"] = 34.75
        },
        {
            ["Index"] = 70000,
            ["Amount"] = { 9, 12 },
            ["RewardChance"] = 32
        },
        {
            ["Index"] = "SoulPoints",
            ["Amount"] = { 650, 785 },
            ["RewardChance"] = 30
        },
        {
            ["Index"] = 70020,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 2.5
        },
        {
            ["Index"] = 70009,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 0.75
        }
    }
}
v102.Box4 = v106
local v107 = {
    ["DropChance"] = 0.35,
    ["BoxIndex"] = 70038,
    ["Rewards"] = {
        {
            ["Index"] = "2xBoosts",
            ["Time"] = { 75, 90 },
            ["RewardChance"] = 31
        },
        {
            ["Index"] = 70000,
            ["Amount"] = { 30, 34 },
            ["RewardChance"] = 32
        },
        {
            ["Index"] = "SoulPoints",
            ["Amount"] = { 2500, 2800 },
            ["RewardChance"] = 32
        },
        {
            ["Index"] = 70009,
            ["Amount"] = { 1, 1 },
            ["RewardChance"] = 5
        }
    }
}
v102.Box5 = v107
v9.BoxOfLuckDrops = v102
v9.SFFBeginMinTime = 0
v9.SFFGameOpenTime = 10
v9.SFFWaitForPlayersToJoin = 20
v9.SFFBeginWaitAFterPlayersWait = 10
v9.SFFMembersToStart = 5
v9.SFFPartiesAmount = 2
v9.SFFPartyLevelOffset = 35
v9.SFFEntranceLevel = 35
v9.SFFFightingMembersAtATime = 1
v9.RankedGameBeginTime = 10
v9.RatingPerGame = 15
v9.AdditionalRatingPerRatingDif = 10
v9.RankedPotentialStonesReward = { 1, 2 }
v9.RankedLives = 3
v9.RankedLobbyMaxPlayers = 2
v9.RankedRespawnTime = 4
v9.RankedSeasonNumber = 1
local v108 = {}
local v109 = {
    ["SeasonNumber"] = 1,
    ["Rewards"] = {
        {
            ["Index"] = 100000,
            ["RankedEmblemPrice"] = 1500,
            ["SpecialColoring"] = true
        },
        {
            ["Index"] = 100001,
            ["RankedEmblemPrice"] = 450,
            ["SpecialColoring"] = false
        }
    }
}
__set_list(v108, 1, {v109})
v9.RankedSeasonRewards = v108
local v110 = {}
local v111 = {
    ["Name"] = "Bronze I",
    ["Rating"] = 0,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.909803, 0.623529, 0.341176), Color3.new(0.803921, 0.541176, 0.145098)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
local v112 = {
    ["Name"] = "Bronze II",
    ["Rating"] = 40,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.909803, 0.623529, 0.341176), Color3.new(0.803921, 0.541176, 0.145098)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
local v113 = {
    ["Name"] = "Bronze III",
    ["Rating"] = 80,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.909803, 0.623529, 0.341176), Color3.new(0.803921, 0.541176, 0.145098)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
local v114 = {
    ["Name"] = "Silver I",
    ["Rating"] = 125,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.686274, 0.839215, 0.803921), Color3.new(0.556862, 0.729411, 0.70196)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
local v115 = {
    ["Name"] = "Silver II",
    ["Rating"] = 170,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.686274, 0.839215, 0.803921), Color3.new(0.556862, 0.729411, 0.70196)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
local v116 = {
    ["Name"] = "Silver III",
    ["Rating"] = 215,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.686274, 0.839215, 0.803921), Color3.new(0.556862, 0.729411, 0.70196)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
local v117 = {
    ["Name"] = "Gold I",
    ["Rating"] = 250,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2:WaitForChild("RankedRanks"):WaitForChild("Gold").Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
local v118 = {
    ["Name"] = "Gold II",
    ["Rating"] = 295,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.RankedRanks.Gold.Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
local v119 = {
    ["Name"] = "Gold III",
    ["Rating"] = 340,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.RankedRanks.Gold.Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
local v120 = {
    ["Name"] = "Diamond I",
    ["Rating"] = 400,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.RankedRanks.Diamond.Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
local v121 = {
    ["Name"] = "Diamond II",
    ["Rating"] = 460,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.RankedRanks.Diamond.Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
local v122 = {
    ["Name"] = "Diamond III",
    ["Rating"] = 520,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.RankedRanks.Diamond.Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
local v123 = {
    ["Name"] = "Titanium",
    ["Rating"] = 700,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.RankedRanks.Titanium.Color,
        ["Animate"] = true,
        ["Rotation"] = 0,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -1,
        ["FinishOffset"] = 1
    }
}
__set_list(v110, 1, {v111, v112, v113, v114, v115, v116, v117, v118, v119, v120, v121, v122, v123})
v9.RankedRanks = v110
v9.SlideHBSize = Vector3.new(10, 5.5, 9)
v9.SlideHBOffset = CFrame.new(0, 0, 0)
v9.MinDashTimeBeforeSlide = 0.15
v9.SlideStun = 1.2
v9.MinSlideAngle = 25
v9.SlideVelocityDecreaseOnSlopPerYGoingUp = 80
v9.SlideVelocityIncreaseOnSlopPerYGoingDown = 45
v9.SlideVelocitySpeedDecreasePerSec = 38
v9.FirstSlideVelocity = 57
v9.SlideJumpVelocity = 110
v9.SlideKickCD = 8
v9.SlideJumpCD = 4
v9.SlideVelocityMinMagnitude = 15
v9.MaxSlideVelocityMagnitude = 80
v9.M1Hitvelocity = 17.5
v9.FinalM1HitVelocity = 105
v9.DashVelocity = 67.5
v9.SideDashVelocity = 80
v9.SideDashTime = 0.6
v9.SideDashSlowDownWhenLeft = 0.3
v9.FrontDashTime = 1
v9.FrontDashVelocity = 62
v9.FrontDashSlowDownWhenLeft = 0.7
v9.BackDashTime = 0.95
v9.BackDashVelocity = 67
v9.BackDashSlowDownWhenLeft = 0.35
v9.FlyingKickHBSize = Vector3.new(10, 8, 10)
v9.FlyingKickHBOffset = CFrame.new(0, 0, 0)
v9.FlyingKickCD = 8
v9.FlyingKickEndlag = 0.5
v9.FlyingKickUsableWindow = 0.4
v9.FlyingKickUsableAfterTime = 0.32
v9.PerfectBlockStunTime = 2
v9.PerfectBlockActionTime = 0.1
v9.BlockBreakStunTime = 2
v9.BlockBreakDamageRecieveMult = 0.5
v9.BlockCD = 0.5
v9.BlackFlashCooldownTime = 40
v9.M1HitMeterDrainSpeedPerSec = 0.06
v9.BlackFlashM1HitMeterReq = 12
v9.BlackFlashM1HitMeterCapOffset = 4
v9.BlackFlashStreakTime = 20
v9.MaxBlackFlashStreak = 4
v9.BlackFlashStunTime = 2
v9.SkillBlackFlashTiming = 0.4
v9.BlackFlashClickTimingDecreasePerHit = 0.02
v9.SkillBlackFlashDamageIncrease = 1.25
v9.ItadoriClanMaxBlackFlaehes = 5
v9.ThroatStrainRegenPerSec = 1.35
v9.ThroatStrainHPPercentIfNotEnough = 15
v9.BloodBarRegenPerSec = 1
v9.BloodBarTakeHPPercentIfNotEnough = 7.25
v9.BloodBarBallsAmount = 4
v9.BloodBarBallsPositions = {
    CFrame.new(-3, 0, 0),
    CFrame.new(-1.5, 1.5, 2),
    CFrame.new(1.5, 1.5, 2),
    CFrame.new(3, 0, 0)
}
v9.BoogieWoogieMaxSwapDistance = 175
v9.ChallengeStarsAmount = {
    {
        ["Chance"] = 84,
        ["Stars"] = 1
    },
    {
        ["Chance"] = 15,
        ["Stars"] = 2
    },
    {
        ["Chance"] = 1,
        ["Stars"] = 3
    }
}
v9.GamemodeStarsAmount = {
    {
        ["Chance"] = 92,
        ["Stars"] = 1
    },
    {
        ["Chance"] = 7,
        ["Stars"] = 2
    },
    {
        ["Chance"] = 1,
        ["Stars"] = 3
    }
}
v9.EnemyBuffTypes = {
    {
        ["Name"] = "Herculean",
        ["Chance"] = 0.5,
        ["BossChance"] = 0.2,
        ["CharacterScale"] = 1.5,
        ["Buff"] = 5,
        ["NameChange"] = "\226\173\144\226\173\144\226\173\144\226\173\144\226\173\144"
    },
    {
        ["Name"] = "Forceful",
        ["Chance"] = 2.5,
        ["BossChance"] = 1,
        ["CharacterScale"] = 1.3,
        ["Buff"] = 3,
        ["NameChange"] = "\226\173\144\226\173\144\226\173\144"
    },
    {
        ["Name"] = "Powerful",
        ["Chance"] = 8,
        ["BossChance"] = 3,
        ["CharacterScale"] = 1.15,
        ["Buff"] = 2,
        ["NameChange"] = "\226\173\144\226\173\144"
    },
    {
        ["Name"] = nil,
        ["Chance"] = 89,
        ["BossChance"] = 95.8,
        ["CharacterScale"] = 1,
        ["Buff"] = 1
    }
}
v9.CECoatingCEReducePerPunch = 0.25
v9.CECoatingCEReducePerSkill = 4
v9.CECoatingCEPerStrength = 5
v9.CEBillboardGuiYSizePerCE = 0.01
v9.CEBillboardGuiXSizePerCE = 0.002
v9.MaxLevel = 105
v9.StarterExpToLevelUp = 400
v9.AddMaxExpToLevelUp = 250
v9.MobsToLevelUp = {
    {
        ["FromLevel"] = 1,
        ["MobsToLevelUp"] = 30
    },
    {
        ["FromLevel"] = 5,
        ["MobsToLevelUp"] = 35
    },
    {
        ["FromLevel"] = 10,
        ["MobsToLevelUp"] = 40
    },
    {
        ["FromLevel"] = 15,
        ["MobsToLevelUp"] = 45
    },
    {
        ["FromLevel"] = 20,
        ["MobsToLevelUp"] = 50
    },
    {
        ["FromLevel"] = 25,
        ["MobsToLevelUp"] = 55
    },
    {
        ["FromLevel"] = 30,
        ["MobsToLevelUp"] = 60
    },
    {
        ["FromLevel"] = 35,
        ["MobsToLevelUp"] = 70
    }
}
v9.ExpDropDecreaseMultsPerLevelDif = {
    ["Dif1"] = 1,
    ["Dif2"] = 1,
    ["Dif3"] = 1,
    ["Dif4"] = 0.9,
    ["Dif5"] = 0.8,
    ["Dif6"] = 0.7,
    ["Dif7"] = 0.6,
    ["Dif8"] = 0.5,
    ["Dif9"] = 0.25,
    ["Dif10"] = 0.1
}
v9.FlashstepsAmountPerAgility = { 50, 100 }
v9.StaminaRegenTime = 5.75
v9.StaminaPerAgility = {
    0,
    0,
    25,
    50,
    85
}
v9.AttributePointsPerLevel = 3
v9.FlashStepMinAgility = 50
v9.FlashStepSpeedBuff = 45
v9.FlashStepSpeedBuffPerAgility = 0.35
v9.FlashStepTime = 0.35
v9.BasicJumpHeight = 7.4
v9.BasicSpeed = 14
v9.BlockSpeed = 6
v9.PunchSpeed = 14
v9.RunSpeedBuff = 10.5
v9.BasicHealth = 100
v9.BeginLowHealthAnimAt = 0.2
v9.BasicCE = 5
v9.MinDamageToTheEnemy = 0.1
v9.BasicHealthRegen = 1
v9.BasicCERegen = 0.35
v9.ChestFallAnimTime = 5.5
v9.GamemodeCompleteAnimTime = 14
v9.CantEquipSkillsIndexes = { 2017, 2023 }
v9.MaxMasteryDamageBoost = 100
v9.GiveMasteryLevelOffset = 35
v9.GiveMasteryLevelMaxOffset = 35
v9.MasteryPerUsedSkill = 51
v9.MasteryPerLandedSkill = 51
v9.MasteryPerDomainCast = 460
v9.MaxMasteryLevel = 100
v9.AdditionalMasteryExpPerLevel = 1
v9.BeginMasteryExp = 80
v9.SkillHitMasteryTimeDebounce = 600
v9.CTSKillsUnlockMasteries = {
    1,
    10,
    30,
    55,
    80,
    100
}
v9.CTSKillsUnlockMasteries6Skills = {
    1,
    5,
    20,
    45,
    70,
    95,
    100
}
v9.CTSKillsUnlockMasteries7Skills = {
    1,
    5,
    15,
    30,
    55,
    75,
    95,
    100
}
v9.SkillInteruptEffectsFadeTime = 0.3
v9.DashCD = 3.5
v9.FlashStepCD = 6
v9.EvadeCD = 5
v9.FallCraterSpawnMagnitude = 100
v9.FallCraterSpawnHeight = 35
v9.FallCraterSpawnHeightMagnitude = 65
v9.InCombatHealthRegenDecrease = 0.5
v9.InCombatCERegenDecrease = 0.5
v9.BossHealthVisibiltyMagnitude = 100
v9.TakeDownGetUpHealth = 0.4
v9.TakeDownGetUpTime = 13
v9.MaxCursedSpiritBarValue = 1000
v9.CursedSpiritActivationCERestore = 0.75
v9.CursedSpiritActivationHealthRestore = 0.75
v9.CursedSpiritModeTime = 30
v9.CursedSpiritAdditionalModeTimePerMastery = 0.5
v9.SkillsBarIncreaseValueOnHitOrUse = {
    ["Hollow Technique: Purple"] = 100
}
v9.DungeonTime = 600
v9.DungeonEntranceMagnitude = 50
v9.DungeonMaxPartySize = 4
v9.DungeonDifficultyScaleWithPlayers = {
    1,
    1.5,
    2,
    2.5
}
v9.ChallengeTime = 720
v9.ChallengeBeginMinTime = 30
v9.ChallengeMaxPartySize = 4
v9.RaidMaxPartySize = 3
v9.RaidGameBeginTime = 2
v9.DomainClashTime = 10
v9.DomainClashTimeDifference = 1
v9.DomainTimePerMastery = 0.25
v9.DomainExpansionBoxDiagonal = 200
v9.DomainExpansionBoxOffset = 15
v9.DomainUseTime = 2.5
v9.DomainExpansionObtaining = {
    ["GradeIndex"] = 7,
    ["UseEssences"] = 7,
    ["GetIntoDomains"] = 8,
    ["WinSFFGames"] = 5,
    ["UnlockChance"] = 100
}
v9.CursedSpiritObtaining = {
    ["GradeIndex"] = 7,
    ["SpiritCage"] = 1,
    ["BindingChain"] = 3,
    ["WinSFFGames"] = 4
}
v9.ClashTime = 8
v9.DomainWhiteEffectTime = 2
v9.DomainMessages = {
    ["OtherDomainPreparingCloseBy"] = "Too close to other domain preparing.",
    ["OtherDomainCloseBy"] = "Too close to other domain.",
    ["DomainClashCloseBy"] = "Too close to the domain clash"
}
v9.TravellingMerchantInfo = {
    ["DebrisTime"] = 720,
    ["TotalLots"] = 3,
    ["MinSpawnTime"] = 60,
    ["MaxSpawnTime"] = 120
}
v9.AvailableForEnemiesScrollSkills = {
    2000,
    2002,
    2005,
    2006,
    2010,
    2011,
    2012,
    2013,
    2014,
    2016,
    2024,
    2025,
    2026,
    2027,
    2028,
    2029,
    2030
}
v9.AvailableForEnemiesEavsives = { 2003, 2022 }
v9.AvailableForEnemiesCTs = {
    "Blood Manipulation",
    "Ratio",
    "Straw Doll Technique",
    "Blazing Courage",
    "Explosive Flesh",
    "Cursed Speech",
    "Earth Manipulation",
    "Crystal Formation",
    "Disaster Flames",
    "Disaster Plants"
}
v9.AvailableForEnemiesCombat = {
    "Cursed Tanto",
    "Slaughter Demon",
    "Glaive",
    "Hammer"
}
v9.NotificationMessages = {
    ["CursedSpiritResetCurrentBeforeConsumingNew"] = "Reset your current cursed spirit before consuming a new one.",
    ["LevelIsTooLowToWearItem"] = "Your level is too low to wear this item.",
    ["DungeonMagnitudeTooHigh"] = "One of the party members is too far.",
    ["DungeonNotPartyLeader"] = "Only party leader can start the dungeon.",
    ["DungeonTooManyPartyMembers"] = "Your party has too many members.",
    ["PartyMemberInCombat"] = "One of the party members is in combat.",
    ["PartyMemberLowLevel"] = "One of the party members haven\'t met level requirement.",
    ["LeaveTheCombatFirst"] = "Leave the combat first.",
    ["RaidNotPartyLeader"] = "Only party leader can start the Raid.",
    ["BasicTechniqueAlreadyUnlocked"] = "You\'ve already learned this technique.",
    ["CTUnlockQuestIsntCompleted"] = "Complete \"Cursed Technique Unlock\" quest to use your Innate Technique.",
    ["StatsReqsHaventMet"] = "Stats requirements haven\'t met.",
    ["AlreadyUsedEssences"] = "You\'ve already absorbed the Domain Expansion Essences.",
    ["AlreadyUsedSpiritCage"] = "You\'ve already used the Active Spirit Cage.",
    ["HaventReachedDomainGradeReq"] = "Your body isn\'t ready to absorb the essences.",
    ["HaventReachedCursedSpiritGradeReq"] = "Your body isn\'t ready to use the Spirit Cage.",
    ["CursedSpiritMaxAmountConsumed"] = "You\'ve already consumed max amount of ",
    ["CursedSpiritHaventUnlocked"] = "Your body isn\'t ready to become a vessel.",
    ["YourStrengthIsTooLowToThrowObject"] = "Your Strength Attribute is too low to throw this object.",
    ["LevelReq"] = "Your level is too low for this."
}
local v124 = {}
local v125 = {
    ["Color"] = Color3.new(0.619608, 0.619608, 0.619608),
    ["Value"] = 1,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.529412, 0.592157, 0.686275), Color3.new(0.776471, 0.976471, 1)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
v124.Common = v125
local v126 = {
    ["Color"] = Color3.new(0.364706, 0.996078, 0.454902),
    ["Value"] = 2,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0, 0.666667, 0.498039), Color3.new(0.333333, 1, 0.498039)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
v124.Rare = v126
local v127 = {
    ["Color"] = Color3.new(0.4, 0, 1),
    ["Value"] = 3,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.333333, 0, 0.498039), Color3.new(0.666667, 0, 1)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
v124.Epic = v127
local v128 = {
    ["Color"] = Color3.new(0, 0.682353, 1),
    ["Value"] = 4,
    ["Settings"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0, 0.333333, 1), Color3.new(0, 0.666667, 1)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
v124.Glorious = v128
local v129 = {
    ["Color"] = Color3.new(1, 0, 0),
    ["Value"] = 5,
    ["Settings"] = {
        ["Gradient"] = v2.SpecialRarity.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v124.Special = v129
local v130 = {
    ["Color"] = Color3.new(1, 1, 0),
    ["Value"] = 6,
    ["Settings"] = {
        ["Gradient"] = v2.HeianRarity.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v124.Heian = v130
v9.Rarities = v124
local v131 = {}
local v132 = {
    ["Color"] = Color3.new(0.333333, 1, 0.498039),
    ["StrokeColor"] = Color3.new(0, 0.333333, 0),
    ["Settings"] = {
        ["Gradient"] = v2.Health.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.Health = v132
local v133 = {
    ["Color"] = Color3.new(1, 0, 0),
    ["StrokeColor"] = Color3.new(0.666667, 0, 0),
    ["Settings"] = {
        ["Gradient"] = v2.PhyDamage.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.PhyDamage = v133
local v134 = {
    ["Color"] = Color3.new(0.666667, 0.333333, 1),
    ["StrokeColor"] = Color3.new(0.333333, 0.333333, 1),
    ["Settings"] = {
        ["Gradient"] = v2.CEDamage.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.CEDamage = v134
local v135 = {
    ["Color"] = Color3.new(0, 0.666667, 1),
    ["StrokeColor"] = Color3.new(0, 0.333333, 0.498039),
    ["Settings"] = {
        ["Gradient"] = v2.CE.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.CE = v135
local v136 = {
    ["Color"] = Color3.new(0.666667, 0.666667, 1),
    ["StrokeColor"] = Color3.new(0.666667, 0.333333, 1),
    ["Settings"] = {
        ["Gradient"] = v2.CERegen.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.CERegen = v136
local v137 = {
    ["Color"] = Color3.new(0.666667, 1, 0.498039),
    ["StrokeColor"] = Color3.new(0, 0.666667, 0),
    ["Settings"] = {
        ["Gradient"] = v2.HealthRegen.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.HealthRegen = v137
local v138 = {
    ["Color"] = Color3.new(0.647058, 0.647058, 0.647058),
    ["StrokeColor"] = Color3.new(0.258823, 0.258823, 0.258823),
    ["Settings"] = {
        ["Gradient"] = v2.Exp.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.Speed = v138
local v139 = {
    ["Color"] = Color3.new(1, 1, 0.498039),
    ["StrokeColor"] = Color3.new(1, 0.564706, 0.180392),
    ["Settings"] = {
        ["Gradient"] = v2.Exp.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.Exp = v139
local v140 = {
    ["Color"] = Color3.new(0.333333, 0.733333, 1),
    ["StrokeColor"] = Color3.new(0.180392, 0.329411, 1),
    ["Settings"] = {
        ["Gradient"] = v2.GradeExp.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.GExp = v140
local v141 = {
    ["Color"] = Color3.new(0, 1, 0),
    ["StrokeColor"] = Color3.new(0, 0.666667, 0),
    ["Settings"] = {
        ["Gradient"] = v2.Luck.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.Luck = v141
local v142 = {
    ["Color"] = Color3.new(1, 0.666667, 0),
    ["StrokeColor"] = Color3.new(0.666667, 0.333333, 0),
    ["Settings"] = {
        ["Gradient"] = v2.Mastery.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.Mastery = v142
local v143 = {
    ["Color"] = Color3.new(1, 0.466666, 0),
    ["StrokeColor"] = Color3.new(0.666667, 0.333333, 0),
    ["Settings"] = {
        ["Gradient"] = v2.Burn.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.BurnDamage = v143
local v144 = {
    ["Color"] = Color3.new(1, 0, 0),
    ["StrokeColor"] = Color3.new(0, 0, 0),
    ["Settings"] = {
        ["Gradient"] = v2.BlackFlash.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
v131.BlackFlashDamage = v144
v9.BuffColors = v131
local v145 = {}
local v146 = {
    ["Name"] = "SSS",
    ["ChancePercent"] = 0.1,
    ["Buff"] = 1.35,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.SSSTier.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 4,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
local v147 = {
    ["Name"] = "SS",
    ["ChancePercent"] = 0.45,
    ["Buff"] = 1.2,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.SSTier.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 3.25,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
local v148 = {
    ["Name"] = "S",
    ["ChancePercent"] = 1,
    ["Buff"] = 1.1,
    ["Color"] = Color3.new(1, 1, 1),
    ["Settings"] = {
        ["Gradient"] = v2.STier.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    }
}
local v149 = {
    ["Name"] = "A",
    ["ChancePercent"] = 2.5,
    ["Buff"] = 1.05,
    ["Color"] = Color3.new(0.666667, 1, 1),
    ["Settings"] = {
        ["Animate"] = false
    }
}
local v150 = {
    ["Name"] = "B",
    ["ChancePercent"] = 5,
    ["Buff"] = 1,
    ["Color"] = Color3.new(1, 1, 0.498039),
    ["Settings"] = {
        ["Animate"] = false
    }
}
local v151 = {
    ["Name"] = "C",
    ["ChancePercent"] = 15,
    ["Buff"] = 0.85,
    ["Color"] = Color3.new(0.666667, 1, 1),
    ["Settings"] = {
        ["Animate"] = false
    }
}
local v152 = {
    ["Name"] = "D",
    ["ChancePercent"] = 30.95,
    ["Buff"] = 0.7,
    ["Color"] = Color3.new(0.596078, 0.596078, 0.596078),
    ["Settings"] = {
        ["Animate"] = false
    }
}
local v153 = {
    ["Name"] = "E",
    ["ChancePercent"] = 45,
    ["Buff"] = 0.5,
    ["Color"] = Color3.new(0.403922, 0.333333, 0.278431),
    ["Settings"] = {
        ["Animate"] = false
    }
}
__set_list(v145, 1, {v146, v147, v148, v149, v150, v151, v152, v153})
v9.ItemPotentials = v145
v9.AttributeColors = {
    ["Defense"] = Color3.new(0.458824, 0.964706, 0.552941),
    ["Strength"] = Color3.new(0.980392, 0.239216, 0.239216),
    ["Mind"] = Color3.new(0.458824, 0.717647, 0.980392),
    ["Intelligence"] = Color3.new(0.686275, 0.458824, 0.968627),
    ["Agility"] = Color3.new(0.776471, 0.776471, 0.776471)
}
v9.CEReinforcementSoftCaps = {
    { 75, 0.014 },
    { 150, 0.009 },
    { 300, 0.0025 },
    { 1050, 0.0015 }
}
local v154 = {
    ["Health"] = {
        ["StarterAmount"] = v9.BasicHealth,
        ["AttributeName"] = "Defense",
        ["SoftCaps"] = {
            { 100, 27 },
            { 150, 20 },
            { 300, 11 },
            { 1050, 9 }
        }
    },
    ["HealthRegen"] = {
        ["StarterAmount"] = 1,
        ["AttributeName"] = "Defense",
        ["SoftCaps"] = {
            { 100, 0.2 },
            { 150, 0.12 },
            { 300, 0.07 },
            { 1050, 0.03 }
        }
    },
    ["CE"] = {
        ["StarterAmount"] = v9.BasicCE,
        ["AttributeName"] = "Mind",
        ["SoftCaps"] = {
            { 80, 3.25 },
            { 120, 2.25 },
            { 300, 1.25 },
            { 1050, 0.85 }
        }
    },
    ["CERegen"] = {
        ["StarterAmount"] = 1.75,
        ["AttributeName"] = "Mind",
        ["SoftCaps"] = {
            { 80, 0.022 },
            { 120, 0.015 },
            { 300, 0.007 },
            { 1050, 0.005 }
        }
    },
    ["PhyDamage"] = {
        ["StarterAmount"] = 0,
        ["AttributeName"] = "Strength",
        ["Percent"] = "%",
        ["SoftCaps"] = {
            { 80, 2.7 },
            { 150, 1.95 },
            { 300, 1.15 },
            { 1050, 0.85 }
        }
    },
    ["CEDamage"] = {
        ["StarterAmount"] = 0,
        ["AttributeName"] = "Intelligence",
        ["Percent"] = "%",
        ["SoftCaps"] = {
            { 80, 7 },
            { 150, 5 },
            { 300, 3.5 },
            { 1050, 2.5 }
        }
    },
    ["WalkSpeed"] = {
        ["StarterAmount"] = 0,
        ["AttributeName"] = "Agility",
        ["SoftCaps"] = {
            { 75, 0.1 },
            { 150, 0.05 },
            { 300, 0.03 },
            { 1050, 0.01 }
        }
    }
}
v9.StatsBuffs = v154
local v155 = {
    ["Combat"] = {
        ["MinDamage"] = 8,
        ["SoftCaps"] = {
            { 50, 1.2 },
            { 80, 0.65 },
            { 150, 0.4 },
            { 300, 0.15 },
            { 1050, 0.1 }
        }
    }
}
v9.M1ClickDamages = v155
v9.NPCHairColors = {
    Color3.new(0, 0, 0),
    Color3.new(0.368627, 0.278431, 0.235294),
    Color3.new(0.541176, 0.407843, 0.345098),
    Color3.new(0.211765, 0.160784, 0.137255),
    Color3.new(1, 1, 1)
}
v9.NPCEyesColors = {
    Color3.new(0, 0, 0),
    Color3.new(0.368627, 0.278431, 0.235294),
    Color3.new(0.541176, 0.407843, 0.345098),
    Color3.new(0.678431, 0.949019, 0.968627),
    Color3.new(0.247058, 0.454901, 0.098039),
    Color3.new(0.188235, 0.462745, 0.847058),
    Color3.new(0.368627, 0.403921, 0.411764)
}
local v156 = {}
local v157 = {
    ["Items"] = {
        {
            ["Index"] = 110012,
            ["Amount"] = 1
        }
    }
}
v156.WaterfallCavePuzzle = v157
local v158 = {
    ["Items"] = {
        {
            ["Index"] = 70037,
            ["Amount"] = 1
        }
    }
}
v156.ColorButtons = v158
v9.PuzzlesRewards = v156
local v159 = {
    ["PotentialStones"] = {
        ["Gradient"] = v2.SSSTier.Color,
        ["Animate"] = true,
        ["Rotation"] = 45,
        ["TweenTime"] = 2.5,
        ["BeginOffset"] = -0.8,
        ["FinishOffset"] = 0.8
    },
    ["MasteryBooster"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(1, 0.666667, 0), Color3.new(1, 0.85098, 0)),
        ["Animate"] = false,
        ["Rotation"] = -90
    },
    ["ExpBooster"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(1, 0.917647, 0), Color3.new(1, 0.917647, 0)),
        ["Animate"] = false,
        ["Rotation"] = -90
    },
    ["LuckBooster"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0, 0.666667, 0), Color3.new(0, 1, 0.498039)),
        ["Animate"] = false,
        ["Rotation"] = -90
    },
    ["GExpBooster"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.17647, 0.792156, 1), Color3.new(0.290196, 0.690196, 1)),
        ["Animate"] = false,
        ["Rotation"] = -90
    },
    ["AttributePointsReset"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.803922, 1, 0.976471)),
        ["Animate"] = false,
        ["Rotation"] = -90
    },
    ["CursedSpiritReset"] = {
        ["Gradient"] = ColorSequence.new(Color3.new(0.666667, 0, 0), Color3.new(1, 0, 0)),
        ["Animate"] = false,
        ["Rotation"] = -90
    }
}
v9.DeveloperProductsColoring = v159
local v160 = {}
local v161 = {
    ["Name"] = "Potential Stone x5",
    ["Description"] = "Gives you x5 Potential Stone.",
    ["Image"] = "rbxassetid://102409210872208",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.PotentialStones,
    ["TravellingMerchantLot"] = true,
    ["BountyPrice"] = 1250
}
local v162 = {
    ["GiveItem"] = {
        ["Index"] = 70000,
        ["Amount"] = 5
    }
}
v161.Tags = v162
v161.LayoutOrder = 9
local v163 = {
    ["Name"] = "Attribute Points Reset",
    ["Description"] = "Resets your Attribute Points.",
    ["Image"] = "rbxassetid://73349225830125",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.AttributePointsReset,
    ["TravellingMerchantLot"] = true,
    ["BountyPrice"] = 1250
}
local v164 = {
    ["GiveItem"] = {
        ["Index"] = 70011,
        ["Amount"] = 1
    }
}
v163.Tags = v164
v163.LayoutOrder = 13
local v165 = {
    ["Name"] = "2x Exp 15 Minutes",
    ["Description"] = "Gives you 2x Exp booster for 15 Minutes.",
    ["Image"] = "rbxassetid://115368509429203",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.ExpBooster,
    ["BountyPrice"] = 1250
}
local v166 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Exp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xExpBoostTime",
        ["BuffDuration"] = 900
    }
}
v165.Tags = v166
v165.LayoutOrder = 5
local v167 = {
    ["Name"] = "2x GExp 15 Minutes",
    ["Description"] = "Gives you 2x GradeExp booster for 15 Minutes.",
    ["Image"] = "rbxassetid://105143917902484",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.GExpBooster,
    ["BountyPrice"] = 1250
}
local v168 = {
    ["TimeBuff"] = {
        ["BuffName"] = "GExp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xGExpBoostTime",
        ["BuffDuration"] = 900
    }
}
v167.Tags = v168
v167.LayoutOrder = 5
local v169 = {
    ["Name"] = "2x Mastery 15 Minutes",
    ["Description"] = "Gives you 2x Mastery level up booster for 15 Minutes.",
    ["Image"] = "rbxassetid://107537491621274",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.MasteryBooster,
    ["BountyPrice"] = 1250
}
local v170 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Mastery",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2MasteryBoostTime",
        ["BuffDuration"] = 900
    }
}
v169.Tags = v170
v169.LayoutOrder = 5
local v171 = {
    ["Name"] = "2x Luck 15 Minutes",
    ["Description"] = "Gives you 2x Luck booster for 15 Minutes.",
    ["Image"] = "rbxassetid://71396421339878",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.LuckBooster,
    ["BountyPrice"] = 1650
}
local v172 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Luck",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xLuckBoostTime",
        ["BuffDuration"] = 900
    }
}
v171.Tags = v172
v171.LayoutOrder = 1
local v173 = {
    ["Name"] = "Grimmjow Warm Up",
    ["Description"] = "Gives you a Grimmjow Warm Up Emote.",
    ["Image"] = "rbxassetid://85034262219293",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.Rarities.Glorious.Settings,
    ["BountyPrice"] = 3250
}
local v174 = {
    ["GiveItem"] = {
        ["Index"] = 90000,
        ["Amount"] = 1
    }
}
v173.Tags = v174
v173.LayoutOrder = 20
local v175 = {
    ["Name"] = "Ground Crush Scroll",
    ["Description"] = "Gives you a Ground Crush Scroll.",
    ["Image"] = "rbxassetid://91854472198954",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.Rarities.Glorious.Settings,
    ["BountyPrice"] = 4250
}
local v176 = {
    ["GiveItem"] = {
        ["Index"] = 110028,
        ["Amount"] = 1
    }
}
v175.Tags = v176
v175.LayoutOrder = 20
__set_list(v160, 1, {v161, v163, v165, v167, v169, v171, v173, v175})
v9.BountyShopLots = v160
local v177 = {}
local v178 = {
    ["Name"] = "2x Mastery 15 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 149,
    ["Description"] = "Gives you 2x Mastery booster for 15 Minutes.",
    ["DevProductID"] = "3340185868",
    ["Image"] = "rbxassetid://107537491621274",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.MasteryBooster,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 750
}
local v179 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Mastery",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xMasteryBoostTime",
        ["BuffDuration"] = 900
    }
}
v178.Tags = v179
v178.LayoutOrder = 13
local v180 = {
    ["Name"] = "2x Mastery 30 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 249,
    ["Description"] = "Gives you 2x Mastery booster for 30 Minutes.",
    ["DevProductID"] = "3340186100",
    ["Image"] = "rbxassetid://112252063363453",
    ["RecieveBonus"] = 20,
    ["TravellingMerchantSPPrice"] = 1250,
    ["Coloring"] = v9.DeveloperProductsColoring.MasteryBooster
}
local v181 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Mastery",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xMasteryBoostTime",
        ["BuffDuration"] = 1800
    }
}
v180.Tags = v181
v180.LayoutOrder = 14
local v182 = {
    ["Name"] = "2x Mastery 60 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 449,
    ["Description"] = "Gives you 2x Mastery booster for 60 Minutes.",
    ["DevProductID"] = "3340186241",
    ["Image"] = "rbxassetid://138481603785301",
    ["RecieveBonus"] = 33,
    ["TravellingMerchantSPPrice"] = 2250,
    ["Coloring"] = v9.DeveloperProductsColoring.MasteryBooster
}
local v183 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Mastery",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xMasteryBoostTime",
        ["BuffDuration"] = 3600
    }
}
v182.Tags = v183
v182.LayoutOrder = 15
local v184 = {
    ["Name"] = "2x Mastery 120 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 749,
    ["Description"] = "Gives you 2x Mastery booster for 120 Minutes.",
    ["DevProductID"] = "3340186421",
    ["Image"] = "rbxassetid://76224255922125",
    ["RecieveBonus"] = 60,
    ["TravellingMerchantSPPrice"] = 3750,
    ["Coloring"] = v9.DeveloperProductsColoring.MasteryBooster
}
local v185 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Mastery",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xMasteryBoostTime",
        ["BuffDuration"] = 7200
    }
}
v184.Tags = v185
v184.BestDeal = true
v184.LayoutOrder = 16
local v186 = {
    ["Name"] = "2x Exp 15 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 149,
    ["Description"] = "Gives you 2x Exp booster for 15 Minutes.",
    ["DevProductID"] = "3442165591",
    ["Image"] = "rbxassetid://115368509429203",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.ExpBooster,
    ["TravellingMerchantSPPrice"] = 750
}
local v187 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Exp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xExpBoostTime",
        ["BuffDuration"] = 900
    }
}
v186.Tags = v187
v186.LayoutOrder = 5
local v188 = {
    ["Name"] = "2x Exp 30 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 249,
    ["Description"] = "Gives you 2x Exp booster for 30 Minutes.",
    ["DevProductID"] = "3442169483",
    ["Image"] = "rbxassetid://101051784229833",
    ["RecieveBonus"] = 20,
    ["TravellingMerchantSPPrice"] = 1250,
    ["Coloring"] = v9.DeveloperProductsColoring.ExpBooster
}
local v189 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Exp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xExpBoostTime",
        ["BuffDuration"] = 1800
    }
}
v188.Tags = v189
v188.LayoutOrder = 6
local v190 = {
    ["Name"] = "2x Exp 60 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 449,
    ["Description"] = "Gives you 2x Exp booster for 60 Minutes.",
    ["DevProductID"] = "3442169672",
    ["Image"] = "rbxassetid://92881654572148",
    ["RecieveBonus"] = 33,
    ["TravellingMerchantSPPrice"] = 2250,
    ["Coloring"] = v9.DeveloperProductsColoring.ExpBooster
}
local v191 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Exp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xExpBoostTime",
        ["BuffDuration"] = 3600
    }
}
v190.Tags = v191
v190.LayoutOrder = 7
local v192 = {
    ["Name"] = "2x Exp 120 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 749,
    ["Description"] = "Gives you 2x Exp booster for 120 Minutes.",
    ["DevProductID"] = "3442169801",
    ["Image"] = "rbxassetid://109927303948151",
    ["RecieveBonus"] = 60,
    ["TravellingMerchantSPPrice"] = 3750,
    ["Coloring"] = v9.DeveloperProductsColoring.ExpBooster
}
local v193 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Exp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xExpBoostTime",
        ["BuffDuration"] = 7200
    }
}
v192.Tags = v193
v192.BestDeal = true
v192.LayoutOrder = 8
local v194 = {
    ["Name"] = "2x GExp 15 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 149,
    ["Description"] = "Gives you 2x Grade Exp booster for 15 Minutes.",
    ["DevProductID"] = "3484699912",
    ["Image"] = "rbxassetid://105143917902484",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.GExpBooster,
    ["TravellingMerchantSPPrice"] = 750
}
local v195 = {
    ["TimeBuff"] = {
        ["BuffName"] = "GExp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xGExpBoostTime",
        ["BuffDuration"] = 900
    }
}
v194.Tags = v195
v194.LayoutOrder = 9
local v196 = {
    ["Name"] = "2x GExp 30 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 249,
    ["Description"] = "Gives you 2x Grade Exp booster for 30 Minutes.",
    ["DevProductID"] = "3484700830",
    ["Image"] = "rbxassetid://98085707483429",
    ["RecieveBonus"] = 20,
    ["TravellingMerchantSPPrice"] = 1250,
    ["Coloring"] = v9.DeveloperProductsColoring.GExpBooster
}
local v197 = {
    ["TimeBuff"] = {
        ["BuffName"] = "GExp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xGExpBoostTime",
        ["BuffDuration"] = 1800
    }
}
v196.Tags = v197
v196.LayoutOrder = 10
local v198 = {
    ["Name"] = "2x GExp 60 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 449,
    ["Description"] = "Gives you 2x Grade Exp booster for 60 Minutes.",
    ["DevProductID"] = "3484701170",
    ["Image"] = "rbxassetid://120410152535074",
    ["RecieveBonus"] = 33,
    ["TravellingMerchantSPPrice"] = 2250,
    ["Coloring"] = v9.DeveloperProductsColoring.GExpBooster
}
local v199 = {
    ["TimeBuff"] = {
        ["BuffName"] = "GExp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xGExpBoostTime",
        ["BuffDuration"] = 3600
    }
}
v198.Tags = v199
v198.LayoutOrder = 11
local v200 = {
    ["Name"] = "2x GExp 120 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 749,
    ["Description"] = "Gives you 2x Grade Exp booster for 120 Minutes.",
    ["DevProductID"] = "3484701624",
    ["Image"] = "rbxassetid://112294987860581",
    ["RecieveBonus"] = 60,
    ["TravellingMerchantSPPrice"] = 3750,
    ["Coloring"] = v9.DeveloperProductsColoring.GExpBooster
}
local v201 = {
    ["TimeBuff"] = {
        ["BuffName"] = "GExp",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xGExpBoostTime",
        ["BuffDuration"] = 7200
    }
}
v200.Tags = v201
v200.BestDeal = true
v200.LayoutOrder = 12
local v202 = {
    ["Name"] = "2x Luck 15 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 199,
    ["Description"] = "Gives you 2x Luck booster for 15 Minutes.",
    ["DevProductID"] = "3340143823",
    ["Image"] = "rbxassetid://71396421339878",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.LuckBooster,
    ["TravellingMerchantSPPrice"] = 1000
}
local v203 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Luck",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xLuckBoostTime",
        ["BuffDuration"] = 900
    }
}
v202.Tags = v203
v202.LayoutOrder = 1
local v204 = {
    ["Name"] = "2x Luck 30 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 349,
    ["Description"] = "Gives you 2x Luck booster for 30 Minutes.",
    ["DevProductID"] = "3340144335",
    ["Image"] = "rbxassetid://114744936504339",
    ["RecieveBonus"] = 14,
    ["Coloring"] = v9.DeveloperProductsColoring.LuckBooster,
    ["TravellingMerchantSPPrice"] = 1750
}
local v205 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Luck",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xLuckBoostTime",
        ["BuffDuration"] = 1800
    }
}
v204.Tags = v205
v204.LayoutOrder = 2
local v206 = {
    ["Name"] = "2x Luck 60 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 599,
    ["Description"] = "Gives you 2x Luck booster for 60 Minutes.",
    ["DevProductID"] = "3340144896",
    ["Image"] = "rbxassetid://98458169389752",
    ["RecieveBonus"] = 33,
    ["Coloring"] = v9.DeveloperProductsColoring.LuckBooster,
    ["TravellingMerchantSPPrice"] = 3000
}
local v207 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Luck",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xLuckBoostTime",
        ["BuffDuration"] = 3600
    }
}
v206.Tags = v207
v206.LayoutOrder = 3
local v208 = {
    ["Name"] = "2x Luck 120 Minutes",
    ["Chance"] = 2,
    ["RobuxPrice"] = 999,
    ["Description"] = "Gives you 2x Luck booster for 120 Minutes.",
    ["DevProductID"] = "3340145443",
    ["Image"] = "rbxassetid://121480551845895",
    ["RecieveBonus"] = 60,
    ["Coloring"] = v9.DeveloperProductsColoring.LuckBooster,
    ["TravellingMerchantSPPrice"] = 5000
}
local v209 = {
    ["TimeBuff"] = {
        ["BuffName"] = "Luck",
        ["BuffValue"] = { 100, "%" },
        ["DisplayBuffValue"] = 2,
        ["BuffInitiator"] = "2xLuckBoostTime",
        ["BuffDuration"] = 7200
    }
}
v208.Tags = v209
v208.BestDeal = true
v208.LayoutOrder = 4
__set_list(v177, 1, {v178, v180, v182, v184, v186, v188, v190, v192, v194, v196, v198, v200, v202, v204, v206, v208})
local v210 = {
    ["Name"] = "Potential Stone x5",
    ["Chance"] = 3,
    ["RobuxPrice"] = 199,
    ["Description"] = "Gives you x5 Potential Stone.",
    ["DevProductID"] = "3340200849",
    ["Image"] = "rbxassetid://102409210872208",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.PotentialStones,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 1000
}
local v211 = {
    ["GiveItem"] = {
        ["Index"] = 70000,
        ["Amount"] = 5
    }
}
v210.Tags = v211
v210.LayoutOrder = 17
local v212 = {
    ["Name"] = "Potential Stone x15",
    ["Chance"] = 3,
    ["RobuxPrice"] = 499,
    ["Description"] = "Gives you 15 Potential Stones.",
    ["DevProductID"] = "3340201051",
    ["Image"] = "rbxassetid://75220102628223",
    ["RecieveBonus"] = 20,
    ["Coloring"] = v9.DeveloperProductsColoring.PotentialStones,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 2500
}
local v213 = {
    ["GiveItem"] = {
        ["Index"] = 70000,
        ["Amount"] = 15
    }
}
v212.Tags = v213
v212.LayoutOrder = 18
local v214 = {
    ["Name"] = "Potential Stone x25",
    ["Chance"] = 3,
    ["RobuxPrice"] = 749,
    ["Description"] = "Gives you 25 Potential Stones.",
    ["DevProductID"] = "3340201414",
    ["Image"] = "rbxassetid://115634082475027",
    ["RecieveBonus"] = 33,
    ["Coloring"] = v9.DeveloperProductsColoring.PotentialStones,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 3750
}
local v215 = {
    ["GiveItem"] = {
        ["Index"] = 70000,
        ["Amount"] = 25
    }
}
v214.Tags = v215
v214.LayoutOrder = 19
local v216 = {
    ["Name"] = "Potential Stone x50",
    ["Chance"] = 3,
    ["RobuxPrice"] = 1249,
    ["Description"] = "Gives you x50 Potential Stones.",
    ["DevProductID"] = "3340201539",
    ["Image"] = "rbxassetid://79204337880484",
    ["RecieveBonus"] = 60,
    ["Coloring"] = v9.DeveloperProductsColoring.PotentialStones,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 6250
}
local v217 = {
    ["GiveItem"] = {
        ["Index"] = 70000,
        ["Amount"] = 50
    }
}
v216.Tags = v217
v216.BestDeal = true
v216.LayoutOrder = 20
local v218 = {
    ["Name"] = "Attribute Points Reset",
    ["Chance"] = 12,
    ["RobuxPrice"] = 39,
    ["Description"] = "Gives an Attribute Points Reset Elixir.",
    ["DevProductID"] = "3340188016",
    ["Image"] = "rbxassetid://73349225830125",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.Rarities.Glorious.Settings,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 250
}
local v219 = {
    ["GiveItem"] = {
        ["Index"] = 70011,
        ["Amount"] = 1
    }
}
v218.Tags = v219
v218.LayoutOrder = 21
local v220 = {
    ["Name"] = "Cursed Emblem",
    ["Chance"] = 30,
    ["RobuxPrice"] = 149,
    ["Description"] = "Gives a Cursed Emblem.",
    ["DevProductID"] = "3340187601",
    ["Image"] = "rbxassetid://134283257879508",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.DeveloperProductsColoring.PotentialStones,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 750
}
local v221 = {
    ["GiveItem"] = {
        ["Index"] = 70020,
        ["Amount"] = 1
    }
}
v220.Tags = v221
v220.LayoutOrder = 22
local v222 = {
    ["Name"] = "Soul Swap Stone",
    ["Chance"] = 11,
    ["RobuxPrice"] = 149,
    ["Description"] = "Gives a Soul Swap Stone.",
    ["DevProductID"] = "3493080136",
    ["Image"] = "rbxassetid://125609232850539",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.Rarities.Glorious.Settings,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 750
}
local v223 = {
    ["GiveItem"] = {
        ["Index"] = 70031,
        ["Amount"] = 1
    }
}
v222.Tags = v223
v222.LayoutOrder = 23
local v224 = {
    ["Name"] = "Domain Expansion Essence",
    ["Chance"] = 3,
    ["RobuxPrice"] = 4999,
    ["Description"] = "Gives a Domain Expansion Essence.",
    ["DevProductID"] = "3493090555",
    ["Image"] = "rbxassetid://121243976103415",
    ["RecieveBonus"] = 0,
    ["Coloring"] = v9.Rarities.Heian.Settings,
    ["TravellingMerchantLot"] = true,
    ["TravellingMerchantSPPrice"] = 25000
}
local v225 = {
    ["GiveItem"] = {
        ["Index"] = 70009,
        ["Amount"] = 1
    }
}
v224.Tags = v225
v224.LayoutOrder = 24
__set_list(v177, 17, {v210, v212, v214, v216, v218, v220, v222, v224})
v9.DeveloperProducts = v177
local v226 = {
    ["Blue Daisy"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Blue Daisy"),
        ["ModelOffset"] = CFrame.new(0, 0.4, 0),
        ["RespawnTime"] = 35,
        ["GatherTime"] = 1.5,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70003,
        ["GatherAnim"] = "Ground"
    },
    ["Chrysanthemum"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Chrysanthemum"),
        ["ModelOffset"] = CFrame.new(0, 0.4, 0),
        ["RespawnTime"] = 40,
        ["GatherTime"] = 2,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70002,
        ["GatherAnim"] = "Ground"
    },
    ["Saint\'s Tear"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Saint\'s Tear"),
        ["ModelOffset"] = CFrame.new(0, 2.4, 0),
        ["RespawnTime"] = 600,
        ["GatherTime"] = 7,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70006,
        ["GatherAnim"] = "Ground"
    },
    ["Cursed Flower"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Cursed Flower"),
        ["ModelOffset"] = CFrame.new(0, 0, 0),
        ["RespawnTime"] = 120,
        ["GatherTime"] = 5,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70021,
        ["GatherAnim"] = "Ground"
    },
    ["MysteryLetter2"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("MysteryLetter2"),
        ["ModelOffset"] = CFrame.new(0, -0.48, 0),
        ["RespawnTime"] = 0,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70023,
        ["GatherAnim"] = "None"
    },
    ["MysteryLetter3"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("MysteryLetter3"),
        ["ModelOffset"] = CFrame.new(0, -0.48, 0),
        ["RespawnTime"] = 0,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70024,
        ["GatherAnim"] = "None"
    },
    ["MysteryLetter4"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("MysteryLetter4"),
        ["ModelOffset"] = CFrame.new(0, -0.48, 0),
        ["RespawnTime"] = 0,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70025,
        ["GatherAnim"] = "None"
    },
    ["MysteryLetter5"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("MysteryLetter5"),
        ["ModelOffset"] = CFrame.new(0, -0.48, 0),
        ["RespawnTime"] = 0,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70026,
        ["GatherAnim"] = "None"
    },
    ["MysteryLetter6"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("MysteryLetter6"),
        ["ModelOffset"] = CFrame.new(0, -0.48, 0),
        ["RespawnTime"] = 0,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70027,
        ["GatherAnim"] = "None"
    },
    ["Lost Treasure"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Lost Treasure"),
        ["ModelOffset"] = CFrame.new(0, 0, 0),
        ["RespawnTime"] = 15,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70041,
        ["GatherAnim"] = "None"
    },
    ["Cursed Energy Shard I"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Cursed Energy Shard I"),
        ["ModelOffset"] = CFrame.new(0, 1, 0),
        ["RespawnTime"] = 15,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70044,
        ["GatherAnim"] = "None"
    },
    ["Cursed Energy Shard II"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Cursed Energy Shard II"),
        ["ModelOffset"] = CFrame.new(0, 1, 0),
        ["RespawnTime"] = 15,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70045,
        ["GatherAnim"] = "None"
    },
    ["Cursed Energy Shard III"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Cursed Energy Shard III"),
        ["ModelOffset"] = CFrame.new(0, 1, 0),
        ["RespawnTime"] = 15,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70046,
        ["GatherAnim"] = "None"
    },
    ["Discarded Ring"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Discarded Ring"),
        ["ModelOffset"] = CFrame.new(0, -0.25, 0),
        ["RespawnTime"] = 15,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70047,
        ["GatherAnim"] = "None"
    },
    ["MysteryEmblem"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("MysteryEmblem"),
        ["ModelOffset"] = CFrame.new(0, -0.48, 0),
        ["RespawnTime"] = 0,
        ["GatherTime"] = 1,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70028,
        ["GatherAnim"] = "None"
    },
    ["Apple"] = {
        ["Model"] = v3.GatherableStuff:FindFirstChild("Apple"),
        ["ModelOffset"] = CFrame.new(0, 0.4, 0),
        ["RespawnTime"] = 15,
        ["GatherTime"] = 4,
        ["GatherText"] = "Gather",
        ["GiveOnGatherIndex"] = 70019,
        ["GatherAnim"] = "Tree"
    }
}
v9.GatherableStuff = v226
local v227 = {
    ["Heian"] = {
        ["DropAmount"] = { 1, 1 },
        ["UseAmount"] = 1,
        ["DropChance"] = 0.25
    },
    ["Special"] = {
        ["DropAmount"] = { 1, 1 },
        ["UseAmount"] = 1,
        ["DropChance"] = 1
    },
    ["Glorious"] = {
        ["DropAmount"] = { 1, 1 },
        ["UseAmount"] = 1,
        ["DropChance"] = 4
    },
    ["Epic"] = {
        ["DropAmount"] = { 1, 1 },
        ["UseAmount"] = 1,
        ["DropChance"] = 10
    }
}
v9.ScrollsRaritiesInfo = v227
local v228 = {}
local v229 = {
    ["Model"] = v3.ThrowableObjects:WaitForChild("Car"),
    ["ModelOffset"] = CFrame.new(0, 3.05, 0),
    ["ModelOffsetAngles"] = CFrame.Angles(0, 1.5707963267948966, 0),
    ["RespawnTime"] = 30,
    ["ThrowTime"] = 0,
    ["ThrowText"] = "Throw",
    ["MaxActivationDistance"] = 14,
    ["StrengthPointsReq"] = 35,
    ["Animation"] = "rbxassetid://119498748614393"
}
local v230 = {}
local v231 = {
    ["Action"] = "AddSFX",
    ["AmountSettings"] = {},
    ["Name"] = "SFX1",
    ["SFXHolder"] = v6.ThrowableObjects:WaitForChild("CarHit"),
    ["SFXParent"] = {
        ["Origin"] = "Character",
        ["Name"] = "HumanoidRootPart"
    },
    ["Volume"] = 0.75,
    ["DebrisTime"] = 3,
    ["EnableDelay"] = 0,
    ["DisableOnInterupt"] = true
}
__set_list(v230, 1, {v231})
v229.OnHitClientEffects = v230
local v232 = {
    ["ProjectileName"] = "Projectile1",
    ["DamagePercent"] = 0,
    ["RepeatAmount"] = 1,
    ["RepeatTime"] = 1,
    ["DamageType"] = "CE",
    ["BlockBreak"] = "BlockBreak",
    ["HBSize"] = Vector3.new(10, 6, 10),
    ["DestroyHBSize"] = Vector3.new(4, 4, 4),
    ["CFrame"] = {
        ["Origin"] = "Character",
        ["CFrame"] = CFrame.new(0, 0, -3.5)
    },
    ["ProjectileDirection"] = {
        ["CharLV"] = 1,
        ["MouseY"] = 1
    },
    ["ProjectileVelocity"] = 120,
    ["ProjectileYAcceleration"] = 0.5,
    ["MaxDistance"] = 300,
    ["GoesThroughEnemy"] = true,
    ["DestroyOnWallHit"] = true,
    ["StunTime"] = 2.2,
    ["RagdollTime"] = 2.2,
    ["KBDir"] = {
        ["ProjectileDirection"] = 0.9,
        ["Vector"] = Vector3.new(0, 0, 0)
    },
    ["KBVel"] = 35,
    ["KBTime"] = 0.25,
    ["ObjectDestroyPower"] = 25,
    ["OnHitFunction"] = {}
}
local v233 = {
    ["StopProjectile"] = {
        {
            ["Action"] = "TweenUnderGround",
            ["AfterTime"] = 5,
            ["TweenDistance"] = 20,
            ["TweenTime"] = 3
        },
        {
            ["Action"] = "TweenTransparency",
            ["AfterTime"] = 5,
            ["TweenTime"] = 3
        },
        {
            ["Action"] = "Debris",
            ["Time"] = 8
        }
    }
}
local v234 = {}
local v235 = {
    ["Action"] = "AddPart",
    ["PartName"] = "RockHit",
    ["Anchored"] = true,
    ["PartCFrame"] = {
        ["Origin"] = "WallHit",
        ["CFrame"] = CFrame.new(0, 0, 0)
    },
    ["PartHolder"] = v3.VFX.ThrowableObjects:WaitForChild("Car"):WaitForChild("Hit"),
    ["DisableGroundEffectsInTheAir"] = false,
    ["SpawnDelay"] = 0,
    ["EnableDelay"] = 0,
    ["DebrisTime"] = 5,
    ["FadeAwaySettings"] = {
        ["Time"] = 1,
        ["GoUnderGround"] = -10
    }
}
local v236 = {
    ["Action"] = "ManipulateParticles",
    ["Parent"] = {
        ["ParentOwner"] = "IgnoreFolder",
        ["Name"] = "RockHit"
    },
    ["ParticleAction"] = "EmitExisting",
    ["EnableDelay"] = 0,
    ["LifeTime"] = 1
}
local v237 = {
    ["Action"] = "AddSFX",
    ["AmountSettings"] = {},
    ["Name"] = "BoomSFX",
    ["SFXHolder"] = v6.ThrowableObjects:WaitForChild("CarLand"),
    ["SFXParent"] = {
        ["Origin"] = "IgnoreFolder",
        ["Name"] = "RockHit"
    },
    ["Volume"] = 3,
    ["DebrisTime"] = 5,
    ["EnableDelay"] = 0
}
__set_list(v234, 1, {v235, v236, v237})
v233.ClientEffects = v234
v232.OnWallHitFunction = v233
local v238 = {
    ["StopProjectile"] = {
        {
            ["Action"] = "Destroy"
        }
    }
}
v232.OnMaxDistanceFunction = v238
v229.Projectile = v232
v228.Car = v229
local v239 = {
    ["Model"] = v3.ThrowableObjects:WaitForChild("TrashCan"),
    ["ModelOffset"] = CFrame.new(0, 1.3, 0),
    ["ModelOffsetAngles"] = CFrame.Angles(0, 0, 0),
    ["RespawnTime"] = 16,
    ["ThrowTime"] = 0,
    ["MaxActivationDistance"] = 7,
    ["ThrowText"] = "Throw",
    ["StrengthPointsReq"] = 5,
    ["Animation"] = "rbxassetid://119498748614393"
}
local v240 = {}
local v241 = {
    ["Action"] = "AddSFX",
    ["AmountSettings"] = {},
    ["Name"] = "SFX1",
    ["SFXHolder"] = v6.ThrowableObjects:WaitForChild("TrashcanHit"),
    ["SFXParent"] = {
        ["Origin"] = "Character",
        ["Name"] = "HumanoidRootPart"
    },
    ["Volume"] = 0.75,
    ["DebrisTime"] = 3,
    ["EnableDelay"] = 0,
    ["DisableOnInterupt"] = true
}
__set_list(v240, 1, {v241})
v239.OnHitClientEffects = v240
local v242 = {
    ["ProjectileName"] = "Projectile1",
    ["DamagePercent"] = 0,
    ["RepeatAmount"] = 1,
    ["RepeatTime"] = 1,
    ["DamageType"] = "CE",
    ["BlockBreak"] = false,
    ["HBSize"] = Vector3.new(4.5, 7, 4.5),
    ["DestroyHBSize"] = Vector3.new(1.5, 1.5, 1.5),
    ["CFrame"] = {
        ["Origin"] = "Character",
        ["CFrame"] = CFrame.new(0, 0, -3.5)
    },
    ["ProjectileDirection"] = {
        ["CharLV"] = 1,
        ["MouseY"] = 1
    },
    ["ProjectileVelocity"] = 185,
    ["ProjectileYAcceleration"] = 0.3,
    ["MaxDistance"] = 300,
    ["GoesThroughEnemy"] = true,
    ["DestroyOnWallHit"] = true,
    ["StunTime"] = 1.7,
    ["RagdollTime"] = 1.7,
    ["KBDir"] = {
        ["ProjectileDirection"] = 0.9,
        ["Vector"] = Vector3.new(0, 0, 0)
    },
    ["KBVel"] = 25,
    ["KBTime"] = 0.25,
    ["ObjectDestroyPower"] = 5,
    ["OnHitFunction"] = {}
}
local v243 = {
    ["StopProjectile"] = {
        {
            ["Action"] = "Destroy"
        }
    }
}
local v244 = {}
local v245 = {
    ["Action"] = "AddPart",
    ["PartName"] = "RockHit",
    ["Anchored"] = true,
    ["PartCFrame"] = {
        ["Origin"] = "WallHit",
        ["CFrame"] = CFrame.new(0, 0, 0)
    },
    ["PartHolder"] = v3.VFX.ThrowableObjects:WaitForChild("TrashCan"):WaitForChild("Hit"),
    ["DisableGroundEffectsInTheAir"] = false,
    ["SpawnDelay"] = 0,
    ["EnableDelay"] = 0,
    ["DebrisTime"] = 5,
    ["FadeAwaySettings"] = {
        ["Time"] = 1,
        ["GoUnderGround"] = -10
    }
}
local v246 = {
    ["Action"] = "ManipulateParticles",
    ["Parent"] = {
        ["ParentOwner"] = "IgnoreFolder",
        ["Name"] = "RockHit"
    },
    ["ParticleAction"] = "EmitExisting",
    ["EnableDelay"] = 0,
    ["LifeTime"] = 1
}
local v247 = {
    ["Action"] = "AddSFX",
    ["AmountSettings"] = {},
    ["Name"] = "BoomSFX",
    ["SFXHolder"] = v6.ThrowableObjects:WaitForChild("TrashcanLand"),
    ["SFXParent"] = {
        ["Origin"] = "IgnoreFolder",
        ["Name"] = "RockHit"
    },
    ["Volume"] = 1.75,
    ["DebrisTime"] = 5,
    ["EnableDelay"] = 0
}
__set_list(v244, 1, {v245, v246, v247})
v243.ClientEffects = v244
v242.OnWallHitFunction = v243
local v248 = {
    ["StopProjectile"] = {
        {
            ["Action"] = "Destroy"
        }
    }
}
v242.OnMaxDistanceFunction = v248
v239.Projectile = v242
v228.TrashCan = v239
v9.ThrowableObjects = v228
v9.CECoatingHitSFX = {
    "rbxassetid://92703733134290",
    "rbxassetid://120698477186539",
    "rbxassetid://116249910643987",
    "rbxassetid://120698477186539",
    "rbxassetid://116249910643987"
}
v9.CECoatingHitVolume = 1.25
v9.HealthRegenAfterDecreaseLockTime = 1
v9.CERegenAfterDecreaseLockTime = 0
v9.Images = {
    ["DomainExpansionIcon"] = "rbxassetid://133445435218412"
}
v9.HitAnimations = { "rbxassetid://15471494053", "rbxassetid://15471497521", "rbxassetid://15471509683" }
local v249 = {}
local v250 = {
    ["Name"] = "Mobs",
    ["Color"] = Color3.fromRGB(77, 255, 172)
}
local v251 = {
    ["Name"] = "Bosses",
    ["Color"] = Color3.fromRGB(170, 0, 0),
    ["Rewards"] = {
        {
            ["BossIndex"] = 16,
            ["RewardIndex"] = 70034,
            ["Amount"] = 4
        },
        {
            ["BossIndex"] = 20,
            ["RewardIndex"] = 70035,
            ["Amount"] = 3
        },
        {
            ["BossIndex"] = 23,
            ["RewardIndex"] = 70035,
            ["Amount"] = 5
        },
        {
            ["BossIndex"] = 51,
            ["RewardIndex"] = 70036,
            ["Amount"] = 2
        },
        {
            ["BossIndex"] = 70,
            ["RewardIndex"] = 70036,
            ["Amount"] = 3
        },
        {
            ["BossIndex"] = 26,
            ["RewardIndex"] = 70036,
            ["Amount"] = 4
        },
        {
            ["BossIndex"] = 28,
            ["RewardIndex"] = 70037,
            ["Amount"] = 2
        },
        {
            ["BossIndex"] = 10003,
            ["RewardIndex"] = 70037,
            ["Amount"] = 5
        },
        {
            ["BossIndex"] = 999,
            ["RewardIndex"] = 70037,
            ["Amount"] = 4
        },
        {
            ["BossIndex"] = 10005,
            ["RewardIndex"] = 70038,
            ["Amount"] = 1
        }
    }
}
local v252 = {
    ["Name"] = "Dungeons",
    ["Color"] = Color3.fromRGB(255, 85, 0),
    ["Rewards"] = {
        {
            ["DungeonName"] = "Hotarugawa Dungeon",
            ["RewardIndex"] = 70036,
            ["Amount"] = 2
        },
        {
            ["DungeonName"] = "Kanazawa Dungeon",
            ["RewardIndex"] = 70037,
            ["Amount"] = 2
        },
        {
            ["DungeonName"] = "Meadow Dungeon",
            ["RewardIndex"] = 70038,
            ["Amount"] = 1
        }
    }
}
local v253 = {
    ["Name"] = "Challenges",
    ["Color"] = Color3.fromRGB(98, 0, 147),
    ["Rewards"] = {
        {
            ["ChallengeName"] = "Temple Challenge",
            ["RewardIndex"] = 70038,
            ["Amount"] = 1
        },
        {
            ["ChallengeName"] = "Yoshiwara Challenge",
            ["RewardIndex"] = 70038,
            ["Amount"] = 2
        }
    }
}
local v254 = {
    ["Name"] = "World Events",
    ["Color"] = Color3.fromRGB(85, 85, 127)
}
local v255 = {
    ["Name"] = "Cursed Dungeons",
    ["Color"] = Color3.fromRGB(255, 0, 0),
    ["Rewards"] = {
        {
            ["CursedDungeonName"] = "Jogo Cursed Dungeon",
            ["RewardIndex"] = 70037,
            ["Amount"] = 4
        }
    }
}
__set_list(v249, 1, {v250, v251, v252, v253, v254, v255, {
    ["Name"] = "College Missions",
    ["Color"] = Color3.fromRGB(39, 138, 251)
}, {
    ["Name"] = "Goodwill Exchange Event",
    ["Color"] = Color3.fromRGB(39, 191, 251)
}, {
    ["Name"] = "Boxes Of Luck",
    ["Color"] = "Rainbow"
}})
v9.IndexTabs = v249
v9.TeleportScrollsInfo = {
    {
        ["EnergyShardsPrice"] = 1,
        ["GiveTeleportationScrollIndex"] = 70012
    },
    {
        ["EnergyShardsPrice"] = 3,
        ["GiveTeleportationScrollIndex"] = 70033
    },
    {
        ["EnergyShardsPrice"] = 5,
        ["GiveTeleportationScrollIndex"] = 70013
    },
    {
        ["EnergyShardsPrice"] = 10,
        ["GiveTeleportationScrollIndex"] = 70014
    },
    {
        ["EnergyShardsPrice"] = 15,
        ["GiveTeleportationScrollIndex"] = 70015
    },
    {
        ["EnergyShardsPrice"] = 25,
        ["GiveTeleportationScrollIndex"] = 70016
    },
    {
        ["EnergyShardsPrice"] = 35,
        ["GiveTeleportationScrollIndex"] = 70017
    },
    {
        ["EnergyShardsPrice"] = 50,
        ["GiveTeleportationScrollIndex"] = 70018
    }
}
local v256 = {}
local v257 = {
    ["BoxNumber"] = "Box1"
}
local v258 = {
    ["Exp"] = 500,
    ["Items"] = {
        {
            ["Index"] = 70008,
            ["Amount"] = 100
        }
    }
}
v257.Reward = v258
v257.Level = {
    {
        "Curved",
        "Triple",
        "Straight",
        "Straight",
        "Ending"
    },
    {
        "Straight",
        "Curved",
        "Ending",
        "Ending",
        "Ending"
    },
    {
        "Curved",
        "Triple",
        "Start3",
        "Triple",
        "Straight"
    },
    {
        "Curved",
        "Curved",
        "Straight",
        "Triple",
        "Triple"
    },
    {
        "Ending",
        "Ending",
        "Curved",
        "Ending",
        "Ending"
    }
}
local v259 = {
    ["BoxNumber"] = "Box2"
}
local v260 = {
    ["Exp"] = 850,
    ["Items"] = {
        {
            ["Index"] = 70000,
            ["Amount"] = 3
        }
    }
}
v259.Reward = v260
v259.Level = {
    {
        "Ending",
        "Triple",
        "Ending",
        "Ending",
        "Ending"
    },
    {
        "Ending",
        "Curved",
        "Triple",
        "Triple",
        "Straight"
    },
    {
        "Curved",
        "Straight",
        "Start3",
        "Curved",
        "Triple"
    },
    {
        "Curved",
        "Triple",
        "Curved",
        "Ending",
        "Triple"
    },
    {
        "Ending",
        "Ending",
        "Ending",
        "Straight",
        "Curved"
    }
}
local v261 = {
    ["BoxNumber"] = "Box3"
}
local v262 = {
    ["Exp"] = 700,
    ["Items"] = {
        {
            ["Index"] = 70008,
            ["Amount"] = 250
        },
        {
            ["Index"] = 70000,
            ["Amount"] = 2
        }
    }
}
v261.Reward = v262
v261.Level = {
    {
        "Curved",
        "Ending",
        "Curved",
        "Ending",
        "Ending"
    },
    {
        "Triple",
        "Ending",
        "Curved",
        "Triple",
        "Triple"
    },
    {
        "Curved",
        "Triple",
        "Start2",
        "Triple",
        "Ending"
    },
    {
        "Curved",
        "Triple",
        "Curved",
        "Curved",
        "Curved"
    },
    {
        "Ending",
        "Ending",
        "Triple",
        "Ending",
        "Ending"
    }
}
local v263 = {
    ["BoxNumber"] = "Box4"
}
local v264 = {
    ["Exp"] = 700,
    ["Items"] = {
        {
            ["Index"] = 70008,
            ["Amount"] = 125
        },
        {
            ["Index"] = 70000,
            ["Amount"] = 3
        }
    }
}
v263.Reward = v264
v263.Level = {
    {
        "Ending",
        "Curved",
        "Ending",
        "Ending",
        "Ending"
    },
    {
        "Curved",
        "Triple",
        "Triple",
        "Triple",
        "Curved"
    },
    {
        "Ending",
        "Curved",
        "Start3",
        "Triple",
        "Ending"
    },
    {
        "Curved",
        "Triple",
        "Curved",
        "Ending",
        "Ending"
    },
    {
        "Ending",
        "Straight",
        "Triple",
        "Straight",
        "Curved"
    }
}
local v265 = {
    ["BoxNumber"] = "Box5",
    ["LevelReq"] = 25,
    ["Reward"] = {
        ["Exp"] = 700,
        ["SoulPoints"] = 200
    },
    ["Level"] = {
        {
            "Ending",
            "Straight",
            "Straight",
            "Curved",
            "Ending"
        },
        {
            "Ending",
            "Ending",
            "Ending",
            "Triple",
            "Straight"
        },
        {
            "Curved",
            "Triple",
            "Start3",
            "Triple",
            "Curved"
        },
        {
            "Curved",
            "Curved",
            "Triple",
            "Ending",
            "Ending"
        },
        {
            "Ending",
            "Curved",
            "Triple",
            "Straight",
            "Curved"
        }
    }
}
local v266 = {
    ["BoxNumber"] = "Box6",
    ["LevelReq"] = 25,
    ["Reward"] = {
        ["Exp"] = 1000,
        ["SoulPoints"] = 500
    },
    ["Level"] = {
        {
            "Ending",
            "Ending",
            "Curved",
            "Curved",
            "Straight",
            "Ending",
            "Ending"
        },
        {
            "Curved",
            "Curved",
            "Straight",
            "Triple",
            "Straight",
            "Straight",
            "Curved"
        },
        {
            "Ending",
            "Curved",
            "Triple",
            "Straight",
            "Ending",
            "Ending",
            "Ending"
        },
        {
            "Triple",
            "Straight",
            "Triple",
            "Start3",
            "Curved",
            "Straight",
            "Straight"
        },
        {
            "Triple",
            "Ending",
            "Triple",
            "Triple",
            "Curved",
            "Triple",
            "Curved"
        },
        {
            "Ending",
            "Ending",
            "Straight",
            "Curved",
            "Triple",
            "Ending",
            "Ending"
        },
        {
            "Ending",
            "Triple",
            "Curved",
            "Ending",
            "Triple",
            "Triple",
            "Curved"
        }
    }
}
local v267 = {
    ["BoxNumber"] = "Box7",
    ["LevelReq"] = 25,
    ["Reward"] = {
        ["Exp"] = 1000,
        ["SoulPoints"] = 500
    },
    ["Level"] = {
        {
            "Ending",
            "Ending",
            "Straight",
            "Triple",
            "Triple",
            "Triple",
            "Curved"
        },
        {
            "Curved",
            "Straight",
            "Straight",
            "Triple",
            "Ending",
            "Ending",
            "Ending"
        },
        {
            "Curved",
            "Triple",
            "Ending",
            "Triple",
            "Triple",
            "Straight",
            "Curved"
        },
        {
            "Ending",
            "Curved",
            "Straight",
            "Start3",
            "Ending",
            "Ending",
            "Triple"
        },
        {
            "Ending",
            "Ending",
            "Triple",
            "Triple",
            "Curved",
            "Ending",
            "Ending"
        },
        {
            "Straight",
            "Ending",
            "Straight",
            "Triple",
            "Triple",
            "Straight",
            "Curved"
        },
        {
            "Curved",
            "Triple",
            "Curved",
            "Curved",
            "Straight",
            "Ending",
            "Ending"
        }
    }
}
local v268 = {
    ["BoxNumber"] = "Box8",
    ["LevelReq"] = 25,
    ["Reward"] = {
        ["Exp"] = 1000,
        ["SoulPoints"] = 500
    },
    ["Level"] = {
        {
            "Ending",
            "Ending",
            "Triple",
            "Straight",
            "Ending",
            "Ending",
            "Curved"
        },
        {
            "Curved",
            "Straight",
            "Triple",
            "Triple",
            "Ending",
            "Curved",
            "Curved"
        },
        {
            "Ending",
            "Straight",
            "Curved",
            "Straight",
            "Ending",
            "Triple",
            "Curved"
        },
        {
            "Ending",
            "Ending",
            "Triple",
            "Start3",
            "Triple",
            "Curved",
            "Straight"
        },
        {
            "Triple",
            "Triple",
            "Triple",
            "Triple",
            "Straight",
            "Curved",
            "Ending"
        },
        {
            "Ending",
            "Curved",
            "Straight",
            "Triple",
            "Curved",
            "Curved",
            "Ending"
        },
        {
            "Ending",
            "Triple",
            "Straight",
            "Ending",
            "Curved",
            "Straight",
            "Ending"
        }
    }
}
local v269 = {
    ["BoxNumber"] = "Box9"
}
local v270 = {
    ["Exp"] = 1000,
    ["Items"] = {
        {
            ["Index"] = 70000,
            ["Amount"] = 5
        }
    }
}
v269.Reward = v270
v269.Level = {
    {
        "Ending",
        "Ending",
        "Ending",
        "Ending",
        "Curved",
        "Straight",
        "Ending"
    },
    {
        "Straight",
        "Triple",
        "Triple",
        "Triple",
        "Triple",
        "Straight",
        "Curved"
    },
    {
        "Curved",
        "Triple",
        "Curved",
        "Straight",
        "Ending",
        "Ending",
        "Straight"
    },
    {
        "Curved",
        "Triple",
        "Curved",
        "Start3",
        "Straight",
        "Curved",
        "Ending"
    },
    {
        "Ending",
        "Triple",
        "Ending",
        "Triple",
        "Triple",
        "Ending",
        "Ending"
    },
    {
        "Ending",
        "Triple",
        "Straight",
        "Triple",
        "Ending",
        "Curved",
        "Curved"
    },
    {
        "Curved",
        "Curved",
        "Ending",
        "Triple",
        "Straight",
        "Triple",
        "Ending"
    }
}
local v271 = {
    ["BoxNumber"] = "Box10"
}
local v272 = {
    ["Exp"] = 1250,
    ["Items"] = {
        {
            ["Index"] = 70000,
            ["Amount"] = 10
        }
    }
}
v271.Reward = v272
v271.Level = {
    {
        "Ending",
        "Ending",
        "Ending",
        "Straight",
        "Straight",
        "Curved",
        "Ending",
        "Ending",
        "Ending",
        "Ending"
    },
    {
        "Triple",
        "Triple",
        "Ending",
        "Ending",
        "Curved",
        "Straight",
        "Triple",
        "Curved",
        "Straight",
        "Straight"
    },
    {
        "Ending",
        "Curved",
        "Triple",
        "Curved",
        "Curved",
        "Triple",
        "Straight",
        "Ending",
        "Straight",
        "Straight"
    },
    {
        "Curved",
        "Straight",
        "Straight",
        "Triple",
        "Triple",
        "Triple",
        "Triple",
        "Triple",
        "Triple",
        "Straight"
    },
    {
        "Ending",
        "Ending",
        "Curved",
        "Ending",
        "Straight",
        "Triple",
        "Triple",
        "Ending",
        "Ending",
        "Straight"
    },
    {
        "Curved",
        "Triple",
        "Triple",
        "Triple",
        "Triple",
        "Start2Curved",
        "Curved",
        "Curved",
        "Straight",
        "Curved"
    },
    {
        "Straight",
        "Straight",
        "Curved",
        "Straight",
        "Triple",
        "Ending",
        "Triple",
        "Triple",
        "Triple",
        "Ending"
    },
    {
        "Straight",
        "Ending",
        "Triple",
        "Ending",
        "Triple",
        "Straight",
        "Ending",
        "Curved",
        "Triple",
        "Curved"
    },
    {
        "Ending",
        "Curved",
        "Triple",
        "Ending",
        "Triple",
        "Ending",
        "Ending",
        "Triple",
        "Ending",
        "Ending"
    },
    {
        "Ending",
        "Curved",
        "Ending",
        "Straight",
        "Triple",
        "Straight",
        "Ending",
        "Curved",
        "Triple",
        "Ending"
    }
}
__set_list(v256, 1, {v257, v259, v261, v263, v265, v266, v267, v268, v269, v271})
v9.CursedBoxesLevels = v256
v9.MainBodyParts = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg"
}
v9.MiniBossAppearance = {
    ["Shirt"] = 10001,
    ["Pants"] = 20001,
    ["Coat"] = 50002,
    ["Eyes"] = "Random",
    ["EyesColor"] = "Random",
    ["Mouth"] = "Random",
    ["Hair1"] = "Random",
    ["Hair1Color"] = "Random"
}
v9.NormalWorldEventDespawnTime = 900
v9.NormalWorldEventSpawnTime = 180
v9.RaidBossWorldEventSpawnTime = 300
v9.MaxWorldEventsAmountAtATime = 8
local v273 = {}
local v274 = {}
local v275 = {
    ["Chance"] = 4,
    ["Rarity"] = "Special",
    ["Name"] = "Gloomhorn Curse",
    ["LayoutOrder"] = 100,
    ["MobsAmount"] = 1,
    ["MiniBossAmount"] = 0,
    ["BasedIndex"] = 10007,
    ["Building"] = "None"
}
local v276 = {}
local v277 = {
    ["Level"] = 105,
    ["Chance"] = 100
}
local v278 = {
    ["Name"] = "Gloomhorn Curse",
    ["ExpDrop"] = 1250,
    ["M1Damage"] = 14
}
local v279 = {
    ["Health"] = {
        ["StatHealth"] = { 14500 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 225, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 225 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 4 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 415 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v278.Buffs = v279
v278.Level = 105
v277.NormalEnemy = v278
v277.Rewards = v9.Rewards.GloomhornCurse
v277.SoulPoints = {
    ["Chance"] = 60,
    ["Amount"] = { 80, 100 }
}
__set_list(v276, 1, {v277})
v275.ChangedStats = v276
local v280 = {
    ["Chance"] = 25,
    ["Rarity"] = "Glorious",
    ["Name"] = "Soldiers Group",
    ["LayoutOrder"] = 50,
    ["MobsAmount"] = 3,
    ["MiniBossAmount"] = 1,
    ["BasedIndex"] = 19,
    ["Building"] = "Campfire"
}
local v281 = {}
local v282 = {
    ["Level"] = 45,
    ["Chance"] = 34
}
local v283 = {
    ["Name"] = "Soldier",
    ["ExpDrop"] = 50,
    ["M1Damage"] = 21
}
local v284 = {
    ["Health"] = {
        ["StatHealth"] = { 455 }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 0 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 7 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 0 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v283.Buffs = v284
v283.Level = 45
v282.NormalEnemy = v283
local v285 = {
    ["Name"] = "Boss Soldier",
    ["CharacterScale"] = 1.1,
    ["ExpDrop"] = 425,
    ["M1Damage"] = 31
}
local v286 = {
    ["Health"] = {
        ["StatHealth"] = { 1400 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 25, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 25 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 45 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v285.Buffs = v286
v285.CECoating = true
v285.Appearance = v9.MiniBossAppearance
v285.ScrollsSkillsAmount = 3
v285.CTSkillsAmount = 2
v285.EvasivesAmount = 1
v285.Level = 45
v282.BossEnemy = v285
v282.Rewards = {
    {
        ["Index"] = 70008,
        ["Chance"] = 100,
        ["Amount"] = { 35, 50 }
    },
    {
        ["Index"] = 110025,
        ["Chance"] = 7.5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70000,
        ["Chance"] = 5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70031,
        ["Chance"] = 0.25,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70009,
        ["Chance"] = 0.15,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 99999,
        ["Amount"] = { 1, 1 },
        ["Chance"] = 30
    }
}
v282.SoulPoints = {
    ["Chance"] = 35,
    ["Amount"] = { 30, 40 }
}
local v287 = {
    ["Level"] = 75,
    ["Chance"] = 33
}
local v288 = {
    ["Name"] = "Soldier",
    ["ExpDrop"] = 85,
    ["M1Damage"] = 28
}
local v289 = {
    ["Health"] = {
        ["StatHealth"] = { 650 }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 0 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 0 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v288.Buffs = v289
v288.Level = 75
v287.NormalEnemy = v288
local v290 = {
    ["Name"] = "Boss Soldier",
    ["CharacterScale"] = 1.1,
    ["ExpDrop"] = 750,
    ["M1Damage"] = 36
}
local v291 = {
    ["Health"] = {
        ["StatHealth"] = { 2850 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 110, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 110, "%" }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 100 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v290.Buffs = v291
v290.Appearance = v9.MiniBossAppearance
v290.ScrollsSkillsAmount = 3
v290.CTSkillsAmount = 4
v290.EvasivesAmount = 1
v290.Level = 75
v287.BossEnemy = v290
v287.Rewards = {
    {
        ["Index"] = 70008,
        ["Chance"] = 100,
        ["Amount"] = { 150, 200 }
    },
    {
        ["Index"] = 110025,
        ["Chance"] = 9,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70000,
        ["Chance"] = 8.5,
        ["Amount"] = { 1, 2 }
    },
    {
        ["Index"] = 70031,
        ["Chance"] = 0.5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70009,
        ["Chance"] = 0.3,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 99999,
        ["Amount"] = { 1, 2 },
        ["Chance"] = 60
    }
}
v287.SoulPoints = {
    ["Chance"] = 55,
    ["Amount"] = { 60, 70 }
}
local v292 = {
    ["Level"] = 105,
    ["Chance"] = 33
}
local v293 = {
    ["Name"] = "Soldier",
    ["ExpDrop"] = 100,
    ["M1Damage"] = 33
}
local v294 = {
    ["Health"] = {
        ["StatHealth"] = { 1000 }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 0 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 0 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v293.Buffs = v294
v293.Level = 105
v292.NormalEnemy = v293
local v295 = {
    ["Name"] = "Boss Soldier",
    ["CharacterScale"] = 1.1,
    ["ExpDrop"] = 895,
    ["M1Damage"] = 42
}
local v296 = {
    ["Health"] = {
        ["StatHealth"] = { 4250 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 145, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 145, "%" }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 150 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v295.Buffs = v296
v295.MaximumOutput = true
v295.Appearance = v9.MiniBossAppearance
v295.ScrollsSkillsAmount = 4
v295.CTSkillsAmount = 5
v295.EvasivesAmount = 1
v295.Level = 105
v292.BossEnemy = v295
v292.Rewards = {
    {
        ["Index"] = 70008,
        ["Chance"] = 100,
        ["Amount"] = { 200, 250 }
    },
    {
        ["Index"] = 110025,
        ["Chance"] = 13,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70000,
        ["Chance"] = 12,
        ["Amount"] = { 1, 3 }
    },
    {
        ["Index"] = 70031,
        ["Chance"] = 1,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70009,
        ["Chance"] = 0.5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 99999,
        ["Amount"] = { 1, 2 },
        ["Chance"] = 90
    }
}
v292.SoulPoints = {
    ["Chance"] = 70,
    ["Amount"] = { 60, 75 }
}
__set_list(v281, 1, {v282, v287, v292})
v280.ChangedStats = v281
local v297 = {
    ["Chance"] = 30,
    ["Rarity"] = "Epic",
    ["Name"] = "Skitterface Group",
    ["LayoutOrder"] = 25,
    ["MobsAmount"] = 3,
    ["MiniBossAmount"] = 0,
    ["BasedIndex"] = 10006,
    ["Building"] = "HelpChild"
}
local v298 = {}
local v299 = {
    ["Level"] = 45,
    ["Chance"] = 50
}
local v300 = {
    ["Name"] = "Skitterface Curse",
    ["ExpDrop"] = 100,
    ["M1Damage"] = 14
}
local v301 = {
    ["Health"] = {
        ["StatHealth"] = { 450 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 35, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 35 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 8 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 0 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v300.Buffs = v301
v300.Level = 45
v299.NormalEnemy = v300
v299.Rewards = {
    {
        ["Index"] = 70008,
        ["Chance"] = 100,
        ["Amount"] = { 35, 50 }
    },
    {
        ["Index"] = 70000,
        ["Chance"] = 6,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70031,
        ["Chance"] = 0.5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70009,
        ["Chance"] = 0.15,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 99999,
        ["Amount"] = { 1, 1 },
        ["Chance"] = 30
    }
}
v299.SoulPoints = {
    ["Chance"] = 35,
    ["Amount"] = { 25, 35 }
}
local v302 = {
    ["Level"] = 75,
    ["Chance"] = 50
}
local v303 = {
    ["Name"] = "Skitterface Curse",
    ["ExpDrop"] = 185,
    ["M1Damage"] = 14
}
local v304 = {
    ["Health"] = {
        ["StatHealth"] = { 850 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 80, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 80 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 0 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v303.Buffs = v304
v303.Level = 75
v302.NormalEnemy = v303
v302.Rewards = {
    {
        ["Index"] = 70008,
        ["Chance"] = 100,
        ["Amount"] = { 140, 180 }
    },
    {
        ["Index"] = 70000,
        ["Chance"] = 8.5,
        ["Amount"] = { 1, 2 }
    },
    {
        ["Index"] = 70031,
        ["Chance"] = 0.5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70009,
        ["Chance"] = 0.3,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 99999,
        ["Amount"] = { 1, 1 },
        ["Chance"] = 60
    }
}
v302.SoulPoints = {
    ["Chance"] = 50,
    ["Amount"] = { 50, 65 }
}
__set_list(v298, 1, {v299, v302})
v297.ChangedStats = v298
local v305 = {
    ["Chance"] = 41,
    ["Rarity"] = "Rare",
    ["Name"] = "Flies Group",
    ["MobsAmount"] = 6,
    ["LayoutOrder"] = 1,
    ["MiniBossAmount"] = 0,
    ["BasedIndex"] = 10004,
    ["Building"] = "HelpChild"
}
local v306 = {}
local v307 = {
    ["Level"] = 45,
    ["Chance"] = 100
}
local v308 = {
    ["Name"] = "Fly Curse",
    ["ExpDrop"] = 20,
    ["M1Damage"] = 14
}
local v309 = {
    ["Health"] = {
        ["StatHealth"] = { 345 }
    },
    ["PhyDamage"] = {
        ["PhyDamage"] = { 15, "%" }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 15 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { 2 }
    },
    ["Jump"] = {
        ["WalkSpeed"] = { 0.5 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 0 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999 }
    }
}
v308.Buffs = v309
v308.Level = 45
v307.NormalEnemy = v308
v307.Rewards = {
    {
        ["Index"] = 70008,
        ["Chance"] = 100,
        ["Amount"] = { 25, 40 }
    },
    {
        ["Index"] = 70000,
        ["Chance"] = 5,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70031,
        ["Chance"] = 0.25,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 70009,
        ["Chance"] = 0.13,
        ["Amount"] = { 1, 1 }
    },
    {
        ["Index"] = 99999,
        ["Amount"] = { 1, 1 },
        ["Chance"] = 30
    }
}
v307.SoulPoints = {
    ["Chance"] = 25,
    ["Amount"] = { 20, 35 }
}
__set_list(v306, 1, {v307})
v305.ChangedStats = v306
__set_list(v274, 1, {v275, v280, v297, v305})
v273.Normal = v274
local v310 = {}
local v311 = {
    ["BasedIndex"] = 10005
}
local v312 = {}
local v313 = {
    ["Health"] = {
        ["StatHealth"] = { 18500 }
    },
    ["CEDamage"] = {
        ["CEDamage"] = { 345 }
    },
    ["Speed"] = {
        ["WalkSpeed"] = { -8 }
    },
    ["Jump"] = {
        ["JumpHeight"] = { -7.4 }
    },
    ["HealthRegen"] = {
        ["Regen"] = { 100 }
    },
    ["CERegen"] = {
        ["CERegen"] = { 999 }
    },
    ["CE"] = {
        ["CE"] = { 99999999 }
    }
}
v312.Buffs = v313
v311.ChangedStats = v312
v310.SinisterCurse = v311
v273.RaidBoss = v310
v9.WorldEvents = v273
v9.AnimsToPreload = {
    80845584878211,
    87639988596098,
    123527019328353,
    131333636883619,
    88445210596730,
    132760064092913,
    98503213823550,
    74495819871984,
    122875127521112,
    93984863367814,
    115351242157267,
    115786709438245,
    98062810508599,
    87145031025608,
    139982314150909,
    17393777998,
    121334002318188,
    121098339203807,
    96104594991248,
    103372515705686,
    17395439737,
    "rbxassetid://111673253305450",
    "rbxassetid://99575388041493",
    "rbxassetid://124011762122779",
    "rbxassetid://108939491204300",
    137850894319400,
    108420260525964,
    120764109896524,
    98996766927592,
    80026858072406,
    116109484746256,
    129210211566040,
    97754499547179,
    94643624929414,
    91927209964047,
    74859551349593,
    106713035456634,
    97447858713987,
    76715831078480,
    86692129618392,
    127837411427804,
    78550225869516,
    137138237119719,
    75356945501087,
    98849713836164,
    88326960874951,
    70586903452395,
    139570622476146,
    120499901287494,
    137229861198498,
    85811591675619,
    88723034972551,
    125333137366609,
    128562526589189,
    95956118963184,
    140331613156770,
    133575841301571,
    76898426757428,
    124087811535904,
    90832988748194,
    134043760488291,
    131020112131955,
    93581264952000,
    137450521785712,
    100814303078353,
    138718050515442,
    111122890694667,
    118200968931073,
    72293934913503,
    75642339408590,
    78881882779590,
    71489496202339,
    100145042795723,
    118195724918340,
    92786650114260,
    124573925983220,
    87110412521183,
    89958835833645,
    80828809700979,
    105602966440363,
    123656581409855,
    126009030453312,
    115525066113376,
    75287355715537,
    78258352378957,
    105143295997660,
    130843581581191,
    110127545153267,
    135593795135734,
    76654834081233,
    96849924870375,
    76322820960210,
    117952291145333,
    91541274768141,
    123506067603110,
    128778383169886,
    128086116215513,
    73235791160677,
    100072640070700,
    114418008079805,
    105470882336966,
    128307016773704,
    96517796005802,
    123271298250229,
    94933588848821,
    72549111646544,
    90661003712567,
    71833250311934,
    122445577068803,
    97282416881245,
    113992889695128,
    101879814448835,
    89891117123235,
    121471532659872,
    113648003097900,
    81836207636630,
    112758584288860,
    106231469248572,
    73237175985003,
    103718163713170,
    109419176677164,
    103751347332860,
    74934919775437,
    86088424529416,
    115118164422328,
    117022414244591,
    136392840742719,
    132548439949449,
    83666084830382,
    70521306714587,
    90885561737424,
    104973885566322,
    102445042614928,
    87711409624733,
    105078114573171,
    137529136197857,
    119634602543973,
    116479240692155,
    85611695552920,
    80855142718194,
    119926076836415,
    72489594085701,
    104187957729374,
    125413667302876,
    97935288983784,
    93673645689796,
    84797108404925,
    137184673022598,
    81823267101393,
    77609374667434,
    103760134864944,
    90794637638887,
    105813972526337,
    81093358267038,
    101751316372061,
    94915592586134,
    116955511865277,
    103317481497300,
    17394199716,
    103454416337523,
    114431244431517,
    129782822094580,
    101791686725155,
    119480855099929,
    93952368640025,
    117133095057760,
    73720211570440,
    16880505748,
    16880539001,
    16880673293,
    16880712601,
    107228931883012,
    137680747939498,
    135082670283350,
    78070374850177,
    73574133146512,
    15672651417,
    15676905109,
    15727809159,
    15727834664,
    15677078905,
    15677083534,
    79752885276512,
    131154326974836,
    123965670128126,
    116375805980761,
    99302959467494,
    94420051343274,
    102194182446207,
    135331517302728,
    124354063991532,
    16258164263,
    16258169459,
    16258175434,
    16258180915,
    132072890606779,
    122307995929654,
    121206476468526,
    14154029433,
    14154040931,
    14154052177,
    14154064204,
    15244191492,
    15244194432,
    15246309286,
    15246304154,
    15279919923,
    15279916690,
    15279908183,
    15319092634,
    15319097722,
    15324080706,
    15324087227,
    15324092334,
    15324099185,
    15324104982,
    15419693734,
    15419697556,
    15415469841,
    15415474935,
    15415478709,
    15415483075,
    15415487939,
    15415456537,
    15419699773,
    15419702820,
    15460571217,
    15460558520,
    15471461636,
    15471465638,
    15471494053,
    15471497521,
    15471509683,
    15471687686,
    15490957449,
    15539706248,
    15539717025,
    15539744589,
    15539750602,
    15539762464,
    15539768120,
    15539774380,
    15539779739,
    15539785331,
    15585988876,
    15586002786,
    15586013780,
    15586017010,
    15586031232,
    15586036662,
    15586042944,
    15586051069,
    15586058551,
    15589786477,
    15672651417,
    15676905109,
    15677078905,
    15677083534,
    15685996102,
    15686001525,
    15686104713,
    15686107428,
    15727809159,
    15727834664,
    15727942976,
    15727957720,
    16556927772,
    17114085955,
    17114717857,
    17483065946,
    17483069412,
    17483071456,
    17483073239,
    17483076124,
    18726840824,
    18748249141,
    120167334810557,
    94995650817919,
    133703660042954,
    118163253430266,
    129067958556021,
    137884771451374,
    121540214936423,
    124617012624381,
    93998043366133,
    126596665946783,
    112043767270385,
    73276488463489,
    18741760244,
    18428182754,
    18428195002,
    18428201066,
    120033325880075,
    104055340819560,
    18877611434,
    17386076849,
    85897362228063,
    18842804256,
    105332321199215,
    18962320680,
    18962331145,
    18962341876,
    18962352168,
    134749137832271,
    18703554139,
    18604322540,
    18606884472,
    18625809676,
    18625859555,
    18877590748,
    121791288675172,
    18842833146,
    18842813524,
    84997335640278,
    71892712072439,
    110837302436839,
    113593436042919,
    128513852845264,
    14153978516,
    14154029433,
    14154040931,
    14154052177,
    14154064204,
    17882623746,
    17899792642,
    17899806167,
    18112692174,
    18132864560,
    18187198345,
    18347695298,
    115084751604286,
    18392977894,
    18610163936,
    18625869167,
    121799212715818,
    116512502135863,
    118347196195356,
    18625891037,
    84401441876711,
    120628736973498,
    104341790506637,
    88580357202487,
    107525977671866,
    82671076856122,
    91973814117186,
    125828265115037,
    71624679328006,
    109173466522050,
    74869922081586,
    79354871067214,
    119317727460268,
    122770368010668,
    120868500722001,
    96652094225388,
    105106943983404,
    111198655068864,
    90004735588905,
    101527245958869,
    111746851952154,
    117882087130267,
    73688624162935,
    98721472885695,
    119498748614393,
    117790809993543,
    77530423631837,
    128480479037935,
    89309096747413,
    135465250417651,
    95063323650952,
    105355633509014,
    114702905868660,
    101504565244027,
    90758348064704,
    81056262193918,
    104249024871939,
    107146123756553,
    127975937988838,
    109246049499531,
    103125355401097,
    116993313552919,
    124420931165393,
    105470866142668,
    97031450115885,
    126407181569505,
    86299665506972,
    71936512592340,
    112037242988433,
    75090715061023,
    93146522134911,
    104760979062990,
    113868028888470,
    86321971119634,
    110504192253435,
    103225398347075,
    94292076262688,
    85839532478633,
    92512076596386,
    90680894981458
}
return v9
