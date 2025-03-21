local extData = {

	ped_assassins = {
		{
			Name = 'Cop',
			Hash = 0x5E3DA4A4,
			PedType = 6,
			Weapon = 0x1D073A89,
		},
		{
			Name = 'Security',
			Hash = 0xDA2C984E,
			PedType = 21,
			Weapon = 0x3656C8C1,
		},
		{
			Name = 'FIB',
			Hash = 0x5CDEF405,
			PedType = 27,
			Weapon = 0x2BE6766B,
		},
		{
			Name = 'Military',
			Hash = 0xF2DAA2ED,
			PedType = 29,
			Weapon = 0xBFEFFF6D,
		},
		{
			Name = 'Juggernaut',
			Hash = 0x90EF5134,
			PedType = 26,
			Weapon = 0x42BF8A85,
		},
		{
			Name = 'Taliban',
			Hash = 0x4705974A,
			PedType = 26,
			Weapon = 0xB1CA77B1,
		},
		{
			Name = 'Transvestite',
			Hash = 0xE0E69974,
			PedType = 26,
			Weapon = 0xAF3696A1,
		},
		{
			Name = 'Furry',
			Hash = 1344679353,
			PedType = 26,
			Weapon = 0x958A4A8F,
		},
		{
			Name = 'Clown',
			Hash = 0x04498DDE,
			PedType = 26,
			Weapon = 0x958A4A8F,
		},
		{
			Name = 'Bigfoot',
			Hash = 0x61D4C771,
			PedType = 28,
			Weapon = nil,
		},
		{
			Name = 'Panther',
			Hash = 0xE71D5E68,
			PedType = 28,
			Weapon = nil,
		},
		{
			Name = 'Mountain Lion',
			Hash = 0x1250D7BA,
			PedType = 28,
			Weapon = nil,
		}
	},

	
	shoot_entitys = {
		{
			Name = 'Boat',
			Hash = -0x6479D18A
		},
		{
			Name = 'Bumper Car',
			Hash = -0x49CEEDE
		},
		{
			Name = 'XMAS Tree',
			Hash = 0xE3BA450
		},
		{
			Name = 'Orange Ball',
			Hash = 0x8DA1C0E
		},
		{
			Name = 'Stone',
			Hash = 0x79C0A750
		},
		{
			Name = 'Money Bag',
			Hash = 0x113FD533
		},
		{
			Name = 'Cash Pile',
			Hash = -0x11A14369
		},
		{
			Name = 'Trash',
			Hash = 0x72654280
		},
		{
			Name = 'Roller Car',
			Hash = 0x5C05F6C1
		},
		{
			Name = 'Cable Car',
			Hash = -0x2BBD6A23
		}
	},
	

	Bodyguards = {
		{
			Name = 'Ped Type',
			Children = {
				{
					Name = 'Blackops',
					Hash = 0x5076A73B
				},
				{
					Name = 'SWAT',
					Hash = 0x8D8F1B10
				},
				{
					Name = 'Agent',
					Hash = 0xF161D212
				},
				{
					Name = 'Clown',
					Hash = 0x04498DDE
				},
				{
					Name = 'Taliban',
					Hash = 0x4705974A
				},
				{
					Name = 'Transvestite',
					Hash = 0xE0E69974
				},
				{
					Name = 'Furry',
					Hash = 1344679353
				},
				{
					Name = 'Juggernaut',
					Hash = 0x90EF5134
				},
				{
					Name = 'Topless',
					Hash = 2633130371
				},
				{
					Name = 'Stripper',
					Hash = 0x81441B71
				},
				{
					Name = 'Random', -- Do not modify this entry!
					Hash = -2
				},
				{
					Name = 'Clone', -- Do not modify this entry!
					Hash = -1
				}
			}
		},
		{
			Name = 'Primary Weapon',
			Children = {
				{
					Name = 'Heavy Rifle',
					Hash = 0xC78D71B4
				},
				{
					Name = 'Military Rifle',
					Hash = 0x9D1F17E6
				},
				{
					Name = 'Combat MG Mk II',
					Hash = 0xDBBD7280
				},
				{
					Name = 'SMG',
					Hash = 0x2BE6766B
				},
				{
					Name = 'Carbine Rifle',
					Hash = 0x83BF0278
				},
				{
					Name = 'Pump Shotgun Mk II',
					Hash = 0x555AF99A
				},
				{
					Name = 'Unholy Hellbringer',
					Hash = 0x476BF155
				},
				{
					Name = "Minigun",
					Hash = 0x42BF8A85
				},
				{
					Name = "RPG",
					Hash = 0xB1CA77B1
				},
				{
					Name = 'Random', -- Do not modify this entry!
					Hash = -2
				},
				{
					Name = 'None', -- Do not modify this entry!
					Hash = -1
				}
			}
		},
		{
			Name = 'Secondary Weapon',
			Children = {
				{
					Name = 'Pistol Mk II',
					Hash = 0xBFE256D4
				},
				{
					Name = 'AP Pistol',
					Hash = 0x22D8FE39
				},
				{
					Name = 'Micro SMG',
					Hash = 0x13532244
				},
				{
					Name = 'Pistol .50',
					Hash = 0x99AEEB3B
				},
				{
					Name = 'Ceramic Pistol',
					Hash = 0x2B5EF5EC
				},
				{
					Name = 'Heavy Revolver MK II',
					Hash = 0xCB96392F
				},
				{
					Name = 'Machine Pistol',
					Hash = 0xDB1AA450
				},
				{
					Name = 'Navy Revolver',
					Hash = 0x917F6C8C
				},
				{
					Name = 'Random', -- Do not modify this entry!
					Hash = -2
				},
				{
					Name = 'None', -- Do not modify this entry!
					Hash = -1
				}
			}
		}
	},

	block_locations = {
        {
			Name = "Los Santos Customs",
			Children = {
				{
					Name = "Block Main LSC",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-357.451, -134.309, 38.539), Rotation = v3(0, 0, -20), Freeze = true, Invisible = true}
					},
					Teleport = v3(-370.4, -104.72, 47),
					Heading = -110.83449554443
				},
				{
					Name = "Block La Mesa LSC",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(722.985, -1089.206, 23.043), Rotation = v3(0, 0, 0), Freeze = true, Invisible = true}
					},
					Teleport = v3(700, -1085, 24),
					Heading = -100
				},
				{
					Name = "Block LSIA LSC",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-1145.788, -1991.130, 13.163), Rotation = v3(0, 0, 45), Freeze = true, Invisible = true}
					},
					Teleport = v3(-1117.1, -1983.3, 23),
					Heading = 104.5
				},
				{
					Name = "Block Desert LSC",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(1178.552, 2646.437, 37.874), Rotation = v3(0, 0, 90), Freeze = true, Invisible = true}
					},
					Teleport = v3(1182, 2673.2, 39),
					Heading = 163.3
				},
				{
					Name = "Block Paleto Bay LSC",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(112.545, 6619.685, 31.604), Rotation = v3(0, 0, -45), Freeze = true, Invisible = true}
					},
					Teleport = v3(140.8, 6601.9, 32),
					Heading = 57
				},
				{
					Name = "Block Benny's LSC",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-208.559, -1308.740, 31.718), Rotation = v3(0, 0, 90), Freeze = true, Invisible = true}
					},
					Teleport = v3(-184.2, -1292.5, 34),
					Heading = 124.3
				},
				{
					Name = "Windmill Main LSC",
					Objects = {
						{Hash = 0x745F3383, Position = v3(-354.170, -96.722, 36.232), Rotation = v3(-90, 0, 150), Freeze = true, Invisible = false}
					},
					Teleport = v3(-370.4, -104.72, 47),
					Heading = -110.834
				},
			}
        },
        {
			Name = "Casino",
			Children = {
				{
					Name = "Block Entrance",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(924.692, 62.243, 81.210), Rotation = v3(0, 0, 80), Freeze = true, Invisible = true},
						{Hash = 0xC42C019A, Position = v3(910.317, 36.022, 80.596), Rotation = v3(0, 0, 25), Freeze = true, Invisible = true}
					},
					Teleport = v3(920.8, 80.5, 80),
					Heading = -177
				},
				{
					Name = "Block Garage",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(935.786, -0.085, 80.166), Rotation = v3(0, 0, 60), Freeze = true, Invisible = true}
					},
					Teleport = v3(940, -21, 80),
					Heading = 4.9
				},
				{
					Name = "Block Roof",
					Objects = {
						{Hash = 0xC42C019A, Position = v3(964.025, 58.947, 113.343), Rotation = v3(0, 0, -30), Freeze = true, Invisible = true}
					},
					Teleport = v3(954.8, 63.34, 114),
					Heading = -124.2
				},
				{
					Name = "Block Music Locker",
					Objects = {
						{Hash = 251770068, Position = v3(988.603, 80.947, 80.99), Rotation = v3(0, 0, -30), Freeze = true, Invisible = true}
					},
					Teleport = v3(990.224, 94.522, 80.990),
					Heading = -124.2
				},
				{
					Name = "Windmill at Entrance",
					Objects = {
						{Hash = 0x745F3383, Position = v3(917.713, 7.888, 78.632), Rotation = v3(-90, 0, 0), Freeze = true, Invisible = false}
					},
					Teleport = v3(890.75, 18.9, 80),
					Heading = -42.7
				}
			}
        },
		{
			Name = "Maze Bank",
			Children = {
				{
					Name = 'Block Entrance',
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-81.541, -792.253, 44.622), Rotation = v3(0, 0, 100), Freeze = true, Invisible = true},
						{Hash = 0xC42C019A, Position = v3(-70.231, -802.176, 44.230), Rotation = v3(0, 0, 0), Freeze = true, Invisible = true}
					},
					Teleport = v3(-55.1, -776.5, 46),
					Heading = 125.4
				},
				{
					Name = 'Block Garage',
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-83.269, -773.024, 39.806), Rotation = v3(0, -35, 105), Freeze = true, Invisible = true}
					},
					Teleport = v3(-86.2, -762.2, 44),
					Heading = -165.7
				},
				{
					Name = 'Block Roof',
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-66.390, -813.327, 320.405), Rotation = v3(0, 0, 60), Freeze = true, Invisible = true},
						{Hash = 0xC42C019A, Position = v3(-66.451, -822.872, 321.197), Rotation = v3(0, 0, 100), Freeze = true, Invisible = true},
						{Hash = 0xC42C019A, Position = v3(-68.104, -818.675, 323.359), Rotation = v3(0, 90, 0), Freeze = true, Invisible = true}
					},
					Teleport = v3(-76.6, -817.6, 328),
					Heading = 0
				},
				{
					Name = 'Block Arena War Entrance',
					Objects = {
						{Hash = 0xC42C019A, Position = v3(-371.32809448242, -1859.2064208984, 21.246929168701), Rotation = v3(0, 15, -75), Freeze = true, Invisible = true},
						{Hash = 0xC42C019A, Position = v3(-396.87942504883, -1869.1518554688, 22.718107223511), Rotation = v3(0, 15, -60), Freeze = true, Invisible = true}
					},
					Teleport = v3(-379.6, -1850, 23),
					Heading = -166.6
				}
			}
		},
		{
			Name = "Custom",
			Children = {
				{
					Name = 'Block Orbital Cannon Room',
					Objects = {
						{Hash = 0xC42C019A, Position = v3(335.956, 4834.332, -58.686), Rotation = v3(0, 0, 35), Freeze = true, Invisible = true},
						{Hash = 0xC42C019A, Position = v3(326.332, 4827.670, -60.258), Rotation = v3(0, -90, 0), Freeze = true, Invisible = true}
					},
					Teleport = v3(145.5, -1307.8, 29.2),
					Heading = 121.2
				},
				{
					Name = 'Block Inactive Screens Orbital Room',
					Objects = {
						{Hash = 0xAC905876, Position = v3(336.016, 4834.129, -58.0754662), Rotation = v3(-25.160162, 2.82980454e-06, 122.541527), Freeze = true, Invisible = true},
						{Hash = 0xAC905876, Position = v3(336.016, 4834.129, -58.9853134), Rotation = v3(-25.160162, 2.82980454e-06, 122.541527), Freeze = true, Invisible = true},
						{Hash = 0xAC905876, Position = v3(336.016, 4834.129, -59.5252228), Rotation = v3(-25.160162, 2.82980454e-06, 122.541527), Freeze = true, Invisible = true},
						{Hash = 0xAC905876, Position = v3(336.016, 4834.129, -57.5355568), Rotation = v3(-25.160162, 2.82980454e-06, 122.541527), Freeze = true, Invisible = true}
					},
					Teleport = v3(342.8, 4838.2, -57),
					Heading = 122
				},
				{
					Name = 'Block Strip Club',
					Objects = {
						{Hash = 0xC42C019A, Position = v3(128.849, -1298.689, 29.232), Rotation = v3(0, 0, 30), Freeze = true, Invisible = true}
					},
					Teleport = v3(145.5, -1307.8, 29.2),
					Heading = 121
				}
			}
		}
    },

	vehicle_blacklist = {
		{
			Name = 'Ground Vehicle Models',
			Children = {
				{
					Name = 'Deluxo',
					Hash = 0x586765FB
				},
				{
					Name = 'Scramjet',
					Hash = 0xD9F0503D
				},
				{
					Name = 'Vigilante',
					Hash = 0xB5EF4C33
				},
				{
					Name = 'Oppressor',
					Hash = 0x34B82784
				},
				{
					Name = 'Oppressor Mk II',
					Hash = 0x7B54A9D3
				},
				{
					Name = 'Insurgent Pickup',
					Hash = 0x9114EADA
				},
				{
					Name = 'Insurgent Pickup Custom',
					Hash = 0x8D4B7A8A
				},
				{
					Name = 'Phantom Wedge',
					Hash = 0x9DAE1398
				},
				{
					Name = 'Nightshark',
					Hash = 0x19DD9ED1
				},
				{
					Name = 'Chernobog',
					Hash = 0xD6BC7523
				},
				{
					Name = 'APC',
					Hash = 0x2189D250
				},
				{
					Name = 'Rhino',
					Hash = 0x2EA68690
				},
				{
					Name = 'Khanjali',
					Hash = 0xAA6F980A
				},
				{
					Name = 'Halftrack',
					Hash = 0xFE141DA6
				},
				{
					Name = 'Ramp Buggy',
					Hash = 0xCEB28249
				},
				{
					Name = 'Ramp Buggy 2',
					Hash = 0xED62BFA9
				},
				{
					Name = 'RC Bandito',
					Hash = 0xEEF345EC
				},
				{
					Name = 'Mini Tank',
					Hash = 0xB53C6C52
				}
			}
		},
		{
			Name = 'Air Vehicle Models',
			Children = {
				{
					Name = 'Akula',
					Hash = 0x46699F47
				},
				{
					Name = 'Annihilator',
					Hash = 0x31F0B376
				},
				{
					Name = 'Buzzard',
					Hash = 0x2F03547B
				},
				{
					Name = 'Hunter',
					Hash = 0xFD707EDE
				},
				{
					Name = 'Savage',
					Hash = 0xFB133A17
				},
				{
					Name = 'Valkyrie',
					Hash = 0xA09E15FD
				},
				{
					Name = 'Valkyrie 2',
					Hash = 0x5BFA5C4B
				},
				{
					Name = 'Annihilator 2',
					Hash = 0x11962E49
				},{
					Name = 'Avenger',
					Hash = 0x81BD2ED0
				},
				{
					Name = 'Bombushka',
					Hash = 0xFE0A508C
				},
				{
					Name = 'Hydra',
					Hash = 0x39D6E83F
				},
				{
					Name = 'Lazer',
					Hash = 0xB39B0AE6
				},
				{
					Name = 'B-11 Strikeforce',
					Hash = 0x64DE07A1
				},
				{
					Name = 'Alkonost',
					Hash = 0xEA313705
				}
			}
		},
		{
			Name = 'Miscellaneous Models',
			Children = {
				{
					Name = 'Stromberg',
					Hash = 0x34DBA661
				},
				{
					Name = 'Toreador',
					Hash = 0x56C8A5EF
				},
				{
					Name = 'Patrol Boat',
					Hash = 0xEF813606
				},
				{
					Name = 'Weaponized Dinghy',
					Hash = 0xC58DA34A
				},
				{
					Name = 'Predator',
					Hash = 0xE2E7D4AB
				},
				{
					Name = 'Kosatka',
					Hash = 0x4FAF0D70
				}
			}
		}
	},

	entity_spam = {
		{
			Name = "Michael",
			Hash = 225514697
		},
		{
			Name = "Franklin",
			Hash = 2602752943
		},
		{
			Name = "Trevor",
			Hash = 2608926626
		},
		{
			Name = "Franklin 2",
			Hash = 2937109846
		},
		{
			Name = "Lamardavis",
			Hash = 22425093
		},
		{
			Name = 'Wade',
			Hash = 0x92991B72
		},
		{
			Name = 'Tracy',
			Hash = 0xDE352A35
		},
		{
			Name = 'Cargoplane',
			Hash = 0x15F27762
		},
		{
			Name = 'Volatol',
			Hash = 0x1AAD0DED
		},
		{
			Name = 'Jet',
			Hash = 0x3F119114
		},
		{
			Name = 'F1 Hunter',
			Hash = 4252008158
		},
		{
			Name = 'Chernobog',
			Hash = 3602674979
		},
		{
			Name = 'Bus Stop',
			Hash = 0x7FACD66F
		},
		{
			Name = 'Fire Hydrant',
			Hash = 0xBF8AD31
		},
		{
			Name = 'Street Lights',
			Hash = 0xC09CB0B8
		},
	},

	custom_vehicles = {
		{'WarMachine', {
			{0x9dae1398, 1030400667, 0x2F03547B, 2971578861, 3871829598, 3229200997, 0x187D938D, 782665360},
			{0x9dae1398, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 15},
			{1030400667, {0, -4, 0}, nil, {0, 0, 0, 0, 1}},
			{0x2F03547B, {0, -8, 4}, {-90, 0, 0}, {0, 0, 0, 0, 1}, true, nil, nil, nil, 0x97F5FE8D, true},
			{2971578861, {-0.3, -0.6, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.3,  0.6, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.7,    0, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.7,    0, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.3,  0.6, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.3, -0.6, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.3, -0.6, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.3,  0.6, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.7,    0, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.7,    0, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.3,  0.6, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.3, -0.6, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.3, -0.6, 2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.3,  0.6, 2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.7,    0, 2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.7,    0, 2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, {-0.3,  0.6, 2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{2971578861, { 0.3, -0.6, 2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{3871829598, {0, 0,   2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{3871829598, {0, 0, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{3871829598, {0, 0, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{3229200997, {0, 0,   2}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{3229200997, {0, 0, 5.9}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{3229200997, {0, 0, 9.8}, {-90, 0, 0}, nil, nil, nil, 16, 3},
			{0x187D938D, {0, -8.25, 5.3}, nil, {0, 0, 0, 0, 1}},
			{782665360, {0, -8, 3.1}, nil, {0, 0, 0, 0, 1}},
			}, },
		{'WarMachine XXL', {
			{0x9dae1398, 1030400667, 0x761E2AD3, 0x2F03547B, 1980814227, 782665360, 94602826, 3229200997, 0x187D938D},
			{0x9dae1398, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 20, 5},
			{1030400667, {   0, -4, 0}, nil, {0, 0, 0, 0, 1}},
			{0x9dae1398, {-1.9, -4, 0}, nil, {0, 0, 0, 0, 1}},
			{1030400667, {-1.9, -8, 0}, nil, {0, 0, 0, 0, 1}},
			{0x9dae1398, { 1.9, -4, 0}, nil, {0, 0, 0, 0, 1}},
			{1030400667, { 1.9, -8, 0}, nil, {0, 0, 0, 0, 1}},
			{0x761E2AD3, {0, -15, 3.5}, nil, {0, 0, 0, 0, 1}},
			{0x2F03547B, {-4.85, -16.5, 5.8}, {-90, 0, 0}, {0, 0, 0, 0, 1}, true, nil, nil, nil, 0x97F5FE8D, true},
			{0x2F03547B, { 4.85, -16.5, 5.8}, {-90, 0, 0}, {0, 0, 0, 0, 1}, true, nil, nil, nil, 0x97F5FE8D, true},
			{0x2F03547B, { -9.7, -16.5, 5.8}, {-90, 0, 0}, {0, 0, 0, 0, 1}, true, nil, nil, nil, 0x97F5FE8D, true},
			{0x2F03547B, {  9.7, -16.5, 5.8}, {-90, 0, 0}, {0, 0, 0, 0, 1}, true, nil, nil, nil, 0x97F5FE8D, true},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 9},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 10},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 11},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 8},
			{0x9dae1398, {   0,  -6, 3.5}, nil, {0, 0, 0, 0, 1}},
			{1030400667, {   0, -10, 3.5}, nil, {0, 0, 0, 0, 1}},
			{0x9dae1398, {-1.9, -10, 3.5}, nil, {0, 0, 0, 0, 1}},
			{1030400667, {-1.9, -14, 3.5}, nil, {0, 0, 0, 0, 1}},
			{0x9dae1398, { 1.9, -10, 3.5}, nil, {0, 0, 0, 0, 1}},
			{1030400667, { 1.9, -14, 3.5}, nil, {0, 0, 0, 0, 1}},
			{0x187D938D, {0, -10, 7}, nil, {0, 0, 0, 0, 1}},
			{1030400667, {-10, -18, 5.5}, {0, 180,  90}, {0, 0, 0, 0, 1}},
			{1030400667, { 10, -18, 5.5}, {0, 180, -90}, {0, 0, 0, 0, 1}},
			{782665360, {-4.85, -16.5, 5.8}, nil},
			{782665360, { 4.85, -16.5, 5.8}, nil},
			{782665360, { -9.7, -16.5, 5.8}, nil},
			{782665360, {  9.7, -16.5, 5.8}, nil},
			{782665360, {-4.85, -16.5, 5.8}, {-90, 0, 0}},
			{782665360, { 4.85, -16.5, 5.8}, {-90, 0, 0}},
			{782665360, { -9.7, -16.5, 5.8}, {-90, 0, 0}},
			{782665360, {  9.7, -16.5, 5.8}, {-90, 0, 0}},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16,  9},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16,  9},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16,  10},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16,  10},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16, 11},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16, 11},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16, 8},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16, 8},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16,  9},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16,  9},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16,  9},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16,  10},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16,  10},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16,  10},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16, 11},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16, 11},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16, 11},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16, 8},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16, 8},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16, 8},
			}, },
		{'Marshall-Lazer', {
			{1233534620, 3013282534},
			{1233534620, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 9},
			{3013282534, {0, -1.5, 1.5}, {15, 0, 0}},
			}, },
		{'Marshall-Lazer 2', {
			{1233534620, 3013282534},
			{1233534620, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 9},
			{3013282534, {0, -1.5, 1.5}},
			}, },
		{'Marshall-Insurgent', {
			{1233534620, 0x8D4B7A8A, 0x7B7E56F0},
			{1233534620, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 9},
			{0x8D4B7A8A, {0, 0.05, 0.7}, nil, {0, 0, 0, 0, 1}},
			{0x7B7E56F0, {0, 0.05, 0.7}, nil, {0, 0, 0, 0, 1}},
			}, },
		{'XXL Drone', {
			{0x39D6E83F, 0xFB133A17, 0x3D6AAA9B},
			{0x39D6E83F, nil, nil, {0, 0, 0, 0, 1}, nil, 50, nil, nil, nil, nil, 35, 10},
			{0xFB133A17, {11.5, 9, -1.5}, {0, 0, -45}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, 0xCE5FF074, true},
			{0xFB133A17, {-11.5, 9, -1.5}, {0, 0, 45}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, 0xCE5FF074, true},
			{0xFB133A17, {11.5, -13.5, -1.5}, {0, 0, 225}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, 0xCE5FF074, true},
			{0xFB133A17, {-11.5, -13.5, -1.5}, {0, 0, 135}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, 0xCE5FF074, true},
			{0x3D6AAA9B, {-7, 3.5, -1}, {0, 90, 45}, {0, 0, 0, 0, 1}},
			{0x3D6AAA9B, {7, 3.5, -1}, {0, -90, -45}, {0, 0, 0, 0, 1}},
			{0x3D6AAA9B, {-7, -7, -1}, {0, -90, 135}, {0, 0, 0, 0, 1}},
			{0x3D6AAA9B, {7, -7, -1}, {0, 90, -135}, {0, 0, 0, 0, 1}},
			}, },
		{'Flying Train Chopper', {
			{0x39D6E83F, 0xFB133A17, 0x3D6AAA9B},
			{0xFB133A17, nil, nil, {0, 0, 0, 0, 1}, nil, 75, nil, nil, nil, nil, 30, 10},
			{0x3D6AAA9B, {0, -3, -1}, {0, 0, 0}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, true},
			}, },
		{'Flying Train-Hydra Chopper', {
			{0x39D6E83F, 0xFB133A17, 0x3D6AAA9B},
			{0xFB133A17, nil, nil, {0, 0, 0, 0, 1}, nil, 50, nil, nil, nil, nil, 30, 10},
			{0x39D6E83F, {0, 0, -1}, {0, 0, 0}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, true},
			{0x3D6AAA9B, {0, -3, -1}, {0, 0, 0}, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, true},
			}, },
		{'Monster Hydra', {
			{3449006043, 970385471, 3084515313},
			{3449006043, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 10},
			{970385471, {0, 0.5, 1.2}},
			{3084515313, {-5.4, -2.8, 1}, {2, -16, 0}},
			{3084515313, {5.4, -2.8, 1}, {2, 16, 0}},
			}, },
		{'OutOfDistance Truck', {
			{0x187D938D, 2984635849},
			{0x187D938D, nil, nil, nil, true, nil, nil, nil, nil, nil, 5},
			{2984635849, {0, 0, -1}, {0, 0, -180}},
			}, },
		{'Lawn Mover', {
			{0xE5BA6858, 0x89BA59F5},
			{0xE5BA6858, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 6, -0.75},
			{0x89BA59F5, {0, 0, -0.9}, nil, nil, nil, nil, nil, nil, 0x97F5FE8D},
			}, },
		{'XXL Lawn Mower', {
			{0x8D4B7A8A, 0x7B7E56F0, 0xFB133A17},
			{0x8D4B7A8A, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 18},
			{0x7B7E56F0, nil, nil, {0, 0, 0, 0, 1}},
			{0xFB133A17, {0, 0, -3}, nil, {0, 0, 0, 0, 1}, false, nil, nil, nil, 0x97F5FE8D}
			}, },
		{'Deer Rider', {
			{0xE5BA6858},
			{0xE5BA6858, nil, nil, {0, 0, 0, 0, 1}, true, nil, nil, nil, nil, nil, 3},
			{0, {0, -0.225, 0.225}, nil, nil, nil, nil, nil, nil, 0xD86B5A95},
			}, },
		{'Husky Rider', {
			{0xE5BA6858},
			{0xE5BA6858, nil, nil, {0, 0, 0, 0, 1}, true, nil, nil, nil, nil, nil, 3},
			{0, {0, -0.1, 0.185}, nil, nil, nil, nil, nil, nil, 0x4E8F95A2},
			}, },
		{'Hydra Humpback', {
			{970385471},
			{970385471, nil, nil, nil, true, nil, nil, nil, nil, nil, 12, 16},
			{0, {0, 0, -3.5}, nil, nil, nil, nil, nil, nil, 0x471BE4B2},
			}, },
		{'2-Wheeler', {
			{0xdff0594c, 0x43935b76, 0x3086f33b, 0xb685e324, 0xb34e141d},
			{0xdff0594c, nil, nil, nil, nil, nil, nil, nil, nil, nil, 3, nil, 0},
			{0x43935b76, {-0.32, 0.02, -0.2}, {0, 0, 90}},
			{0x3086f33b, {-0.3, 0.5, -0.07}},
			{0x43935b76, {0.34, 0.01, -0.18}, {0, 0, 90}},
			{0x3086f33b, {0.34, 0.52, -0.07}, {0, 0, 180}},
			{0xb685e324, {0, 0.48, -0.07}, {0, -90, 0}},
			{0xb685e324, {-0.3, 0.32, 0.3}, {30, 0, 0}},
			{0xb34e141d, nil, nil, nil, nil, nil, 24},
			}, },
		{'Cartman', {
			{1131912276, 979462386},
			{1131912276, nil, nil, nil, nil, nil, nil, nil, nil, nil, 2, nil, 0},
			{979462386, {0, 0, 0.13}},
			}, },
		{'Cartman 2', {
			{0x43779c54, 0x334b38db},
			{0x43779c54, nil, nil, nil, nil, nil, nil, nil, nil, nil, 2, nil, 0},
			{0x334b38db, {0, -0.3, -0.4}},
			}, },
		{'Broomstick', {
			{0x7B54A9D3, 1689385044},
			{0x7B54A9D3, nil, nil, nil, true, nil, nil, nil, nil, nil, 1},
			{1689385044, {0, -0.6, 0.2}, {32.5, 0, 180}},
			}, },
		{'Gaming PC', {
			{2704629607, 2084153992},
			{2704629607, nil, nil, {0, 0, 0, 0, 1}, nil, nil, nil, nil, nil, nil, 3},
			{2084153992, {0, 0.9, -0.1}},
			}, },
		{'Driving Seashark', {
			{0xE5BA6858, 0xED762D49},
			{0xE5BA6858, nil, nil, nil, true, nil, nil, nil, nil, nil, 3},
			{0xED762D49, {0, 0, -0.35}},
			}, },
		{'Surfboard', {
			{0xE2E7D4AB, 344984267},
			{0xE2E7D4AB, nil, nil, nil, true, nil, nil, nil, nil, nil, 7},
			{344984267, {-0.5, -0.75, -0.3}, {-90, 0, 0}},
			}, },
		{'Hoverboard', {
			{0x58CDAF30, 1159992493},
			{0x58CDAF30, nil, nil, nil, true, nil, nil, nil, nil,nil, 2},
			{1159992493, {0, 0.45, -0.8}, {-90, 0, 0}, nil, nil, nil, nil, nil, nil, true},
			}, },
		{'Floating Dump', {
			{0xE2E7D4AB, 0x810369E2},
			{0xE2E7D4AB, nil, nil, nil, true, nil, nil, nil, nil, nil, 12},
			{0x810369E2},
			}, },
		{'Flying Dump', {
			{0x2F03547B, 0x810369E2},
			{0x2F03547B, nil, nil, nil, true, nil, nil, nil, nil, nil, 10, 2},
			{0x810369E2},
			}, },
		{'Submarine Blimp', {
			{0xC07107EE, 0xF7004C86},
			{0xC07107EE, nil, nil, nil, true, nil, nil, nil, nil, nil, 20},
			{0xF7004C86},
			}, },
		{'Bandito Tree', {
			{0xEEF345EC, 0xB3B836B0},
			{0xEEF345EC, nil, nil, nil, nil, nil, nil, nil, nil, nil, 2},
			{0xB3B836B0, {0, 0, -0.3}},
			}, },
		{'Attach Tree', {
			{0xB3B836B0},
			{0},
			{0xB3B836B0, {0, 0, -0.3}},
			}, },
		{'Flying Seamine', {
			{0x58CDAF30, 1039126093},
			{0x58CDAF30, nil, nil, nil, nil, nil, nil, nil, nil, nil, 2},
			{1039126093},
			}, },
		{'Attach Ramp', {
			{3233397978},
			{0},
			{3233397978, {0, 4.5, 0.25}, {0, 0, 180}},
			}, },
		{'Attach Invisible Ramp', {
			{3233397978},
			{0},
			{3233397978, {0, 4.5, 0.25}, {0, 0, 180}, nil, true},
			}, },
		{'Attach Invisible Ramp 2', {
			{0x9dae1398},
			{0},
			{0x9dae1398, {0, -2.25, 0}, nil, nil, true},
			}, },
		{'Attach Invisible Ramp 3', {
			{0xED62BFA9},
			{0},
			{0xED62BFA9, {0, 2.25, 0.25}, {-7.5, 0, 0}, nil, true},
			}, },
		{'Sofa Car', {
			{376180694}, 
			{0, nil, nil, nil, true},
			{376180694, {0, -0.2, -0.75}, {0, 0, 180}},
			}, },
		{'Monster of Loch Ness', {
			{1265391242, 0x427badc1},
			{1265391242, nil, nil, nil, nil, nil, nil, nil, nil, nil, 2},
			{0x427badc1, {-0.3, -1, 1.4}, {0, 0, -90}},
			}, },
		{'Hydra 5-Seats', {
			{970385471, 1131912276, 1840382115},
			{970385471, nil, nil, nil, nil, nil, nil, nil, nil, nil, 10},
			{1131912276, {-2.25, -2.31, 0.34}, nil, nil, true},
			{1131912276, { 2.25, -2.31, 0.34}, nil, nil, true},
			{1131912276, { -4.5, -3.35, 0.31}, nil, nil, true},
			{1131912276, {  4.5, -3.35, 0.31}, nil, nil, true},
			{1840382115, {-2.25, -2.81, 0.74}, {0, 0, 180}},
			{1840382115, { 2.25, -2.81, 0.74}, {0, 0, 180}},
			{1840382115, { -4.5, -3.85, 0.44}, {0, 0, 180}},
			{1840382115, {  4.5, -3.85, 0.44}, {0, 0, 180}},
			}, },
		{'Hakuchou + Sidecar', {
			{1265391242, 55628203, 1840382115},
			{1265391242, nil, nil, nil, nil, nil, nil, nil, nil, nil, 2},
			{55628203, {0.5, 0, -0.3}},
			{1840382115, {0.5, -0.5, 0.1}, {0, 0, 180}},
			}, },
		{'Wheelchair', {
			{0x187D938D, 1262298127},
			{0x187D938D, nil, nil, nil, true, nil, nil, nil, nil, nil, 3},
			{1262298127, {-0.425, -0.05, -0.25}, {0, 0, 180}},
			}, },
		{'Wheelbarrow + Jesus', {
			{0x187D938D, 1133730678, 1265391242},
			{0x187D938D, nil, nil, nil, true, nil, nil, nil, nil, nil, 3},
			{1133730678, {-0.425, 0.1, -0.75}, {0, 0, 90}},
			{1265391242, {-0.425, -1.125, -0.345}, nil, nil, true, nil, nil, nil, 0xCE2CB751, true},
			}, },
		{'Big Penis', {
			{0x187D938D, 3859819303, 148511758},
			{0x187D938D, nil, nil, nil, true, nil, nil, nil, nil, nil, 7},
			{3859819303, {0, 0, 2}},
			{3859819303, {0, 0, 6}},
			{3859819303, {0, 0, 10}},
			{148511758, {-2, 0, 0}},
			{148511758, {2, 0, 0}},
			}, },
		{'Street Blazer + Spinning Wheels', {
			{0xE5BA6858, 1230400944},
			{0xE5BA6858, nil, nil, nil, nil, nil, nil, nil, nil, nil, 3},
			{1230400944, nil, {0, -90, 0}, nil, nil, nil, 1},
			{1230400944, nil, {0, -90, 0}, nil, nil, nil, 2},
			{1230400944, nil, {0, -90, 0}, nil, nil, nil, 3},
			{1230400944, nil, {0, -90, 0}, nil, nil, nil, 4},
			}, },
		{'Driveable Train', {
			{3471458123, 1030400667},
			{3471458123, nil, nil, nil, true, nil, nil, nil, nil, nil, 15},
			{1030400667},
			}, },
		{'Cargoplane XXL', {
			{0x15F27762},
			{0x15F27762, nil, nil, nil, nil, 350, nil, nil, nil, nil, 100, 75},
			{0x15F27762, { -50,  -50, 0}},
			{0x15F27762, {  50,  -50, 0}},
			{0x15F27762, {-100, -100, 0}},
			{0x15F27762, { 100, -100, 0}},
			}, },
		{'UFO', {
			{970385471, 3026699584},
			{970385471, nil, nil, nil, true, 100, nil, nil, nil, nil, 45, 10},
			{3026699584, {0, 0, 10}},
			}, },
		{'UFO Damaged', {
			{970385471, 3974683782}, 
			{970385471, nil, nil, nil, true, 100, nil, nil, nil, nil, 45, 10},
			{3974683782, {0, 0, 10}},
			}, },
		{'Spinning UFO', {
			{970385471, 0x2F03547B, 3026699584},
			{970385471, nil, nil, nil, true, 125, nil, nil, nil, nil, 45, 10},
			{0x2F03547B, {0, 0, 10}, nil, nil, true, nil, nil, nil, 0x97F5FE8D, 1},
			{3026699584, {0, 0, 1}, nil, nil, nil, nil, 16, 2, nil, true},
			}, },
		{'Driveable Tug Boat', {
			{3471458123, 2194326579},
			{3471458123, nil, nil, nil, true, nil, nil, nil, nil, nil, 20},
			{2194326579},
			}, },
		{'Hydra Luxor', {
			{970385471, 3080673438},
			{970385471, nil, nil, nil, true, 100, nil, nil, nil, nil, 12},
			{3080673438},
			}, },
		{'XL Tank', {
			{782665360},
			{782665360, nil, nil, nil, nil, nil, nil, nil, nil, nil, 15},
			{782665360, { 0, -6, 0}},
			{782665360, {-4,  0, 0}},
			{782665360, {-4, -6, 0}},
			{782665360, {-2, -2, 2}},
			}, },
		{'XXL Tank', {
			{782665360},
			{782665360, nil, nil, nil, nil, nil, nil, nil, nil, nil, 20},
			{782665360, { 0,  -6, 0}},
			{782665360, { 0, -12, 0}},
			{782665360, {-3,   0, 0}},
			{782665360, {-3,  -6, 0}},
			{782665360, {-3, -12, 0}},
			{782665360, { 3,   0, 0}},
			{782665360, { 3,  -6, 0}},
			{782665360, { 3, -12, 0}},
			{782665360, { 0,   0, 2}},
			{782665360, { 0,  -6, 2}},
			{782665360, { 0, -12, 2}},
			{782665360, {-3,   0, 2}},
			{782665360, {-3,  -6, 2}},
			{782665360, {-3, -12, 2}},
			{782665360, { 3,   0, 2}},
			{782665360, { 3,  -6, 2}},
			{782665360, { 3, -12, 2}},
			{782665360, { 0,   0, 4}},
			{782665360, { 0,  -6, 4}},
			{782665360, { 0, -12, 4}},
			{782665360, {-3,   0, 4}},
			{782665360, {-3,  -6, 4}},
			{782665360, {-3, -12, 4}},
			{782665360, { 3,   0, 4}},
			{782665360, { 3,  -6, 4}},
			{782665360, { 3, -12, 4}},
			{782665360, { 1.5, -3, 6}},
			{782665360, { 1.5, -9, 6}},
			{782665360, {-1.5, -9, 6}},
			{782665360, {-1.5, -3, 6}},
			{782665360, {   0, -6, 8}},
			}, },
		{'StarWars Tie-Fighter', {
			{0xB39B0AE6, 0x3d6aaa9b, 0x9dae1398, 0x3defce4d, 0x708d300f, 0x70b0e25a, 0x592c8b76, 0xffd7d47d, 0x177606a2, 0x3794acc9, 0x79454d60, 0x9e4d88ca, 0x5b7e4520, 0xd9621159, 0xf697c81b, 0xd43979f7},
			{0xB39B0AE6, nil, nil, nil, nil, 350, nil, nil, nil, nil, 35, 15},
			{0x3d6aaa9b, {-1, -2, 0}, {0, -90, 0}},
			{0x3d6aaa9b, {1, -2, 0}, {0, 90, 0}},
			{0x3d6aaa9b, {-16.8, -12.7, -0.6}, {0, -90, 90}},
			{0x3d6aaa9b, {17, -12.7, -0.6}, {0, 90, -90}},
			{0x3d6aaa9b, {-8.5, -12.7, -0.6}, {0, -90, 90}},
			{0x3d6aaa9b, {8.7, -12.7, -0.6}, {0, 90, -90}},
			{0x9dae1398, {2, 2, 0}, {0, 90, 0}},
			{0x9dae1398, {-2, 2, 0}, {0,-90, 0}},
			{0x9dae1398, {-4, -2, 0}, {0, -90, 0}},
			{0x9dae1398, { 4, -2, 0}, {0, 90, 0}},
			{0x3defce4d, {0, 7.1, -0.22}, {-90, 0, 0}},
			{0x708d300f, {-5, -13,   1.6}, { 13,  78,  135}},
			{0x708d300f, { 4, -13,   1.6}, { 13, -78, -135}},
			{0x708d300f, { 5, -13,  -4.6}, {-13, -78, -135}},
			{0x708d300f, {-5, -13,  -4.6}, { -9,  75,  135}},
			{0x708d300f, { 0,  -9, 0.173}, {  0,  90,    0}},
			{0x708d300f, { 0,  -9,   0.2}, {  0, -90,    0}},
			{0x70b0e25a, { 3.7, -7, 0}, { 90, 0, 91}},
			{0x70b0e25a, {-3.6, -7, 0}, {-90, 0, 90}},
			{0x592c8b76, {    0,  -0.5, -2.1}, {-180,   0, -90}},
			{0x592c8b76, {    0,  -8.6, -2.1}, { 180,   0, -90}},
			{0x592c8b76, {-17.7, -13.1,  0.4}, { 178, -15,   0}},
			{0x592c8b76, {-17.6, -12.8, -1.7}, {   0, -15,   0}},
			{0x592c8b76, { 17.7, -12.9,  0.6}, {-180,  15,   0}},
			{0x592c8b76, { 17.4, -12.7, -2.2}, {   0,  15,   0}},
			{0xffd7d47d, { 20, -6.4, -7.3}, {-60, 0, 90}},
			{0xffd7d47d, { 20, -6.5,  6.3}, { 60, 0, 90}},
			{0xffd7d47d, {-20, -6.4, -7.3}, { 60, 0, 90}},
			{0xffd7d47d, {-20, -6.5,  6.3}, {-60, 0, 90}},
			{0x177606a2, {  -20, -6.9,    8}, {-90, 0,  0}},
			{0x177606a2, {-21.5, -6.9,  5.4}, {-90, 0, 0}},
			{0x177606a2, {   20, -6.9,    8}, {-90, 0, 0}},
			{0x177606a2, { 21.5, -6.9,  5.4}, {-90, 0, 0}},
			{0x177606a2, {  -20, -6.8,   -9}, {-90, 0, 0}},
			{0x177606a2, {-21.4, -6.8, -6.4}, {-90, 0, 0}},
			{0x177606a2, { 19.9, -6.8,   -9}, {-90, 0, 0}},
			{0x177606a2, { 21.3, -6.8, -6.3}, {-90, 0, 0}},
			{0x3794acc9, {  -20, 0.8,     8}, {0, 0, 0}},
			{0x3794acc9, {-21.5, 0.8,   5.4}, {0, 0, 0}},
			{0x3794acc9, {   20, 0.8,     8}, {0, 0, 0}},
			{0x3794acc9, { 21.5, 0.8,   5.4}, {0, 0, 0}},
			{0x3794acc9, {  -20, 0.9,    -9}, {0, 0, 0}},
			{0x3794acc9, {-21.4, 0.9,  -6.4}, {0, 0, 0}},
			{0x3794acc9, {   20, 0.9,    -9}, {0, 0, 0}},
			{0x3794acc9, { 21.3, 0.9, -6.34}, {0, 0, 0}},
			{0x79454d60, { -16.1, -11.42, -0.56}, {   90,   0,  0}},
			{0x79454d60, { 16.05, -11.51, -0.49}, {   90,   0,  0}},
			{0x79454d60, {-15.88, -16.01, -0.59}, {  -90,   0,  0}},
			{0x79454d60, { 16.11, -16.01,  -0.6}, {  -90,   0,  0}},
			{0x79454d60, {  19.7, -15.31,  6.35}, {  -30,  90,  90}},
			{0x79454d60, { -19.8,  -15.3,  -7.4}, {  -30,  90,  90}},
			{0x79454d60, { -19.6, -15.34,   6.4}, {-30.3, -90, -90}},
			{0x79454d60, {  19.8, -15.21,  -7.4}, {  150, -90, -90}},
			{0x9e4d88ca, {-6.7,   -24, -0.8}, {90, 0, 0}},
			{0x9e4d88ca, {-2.9, -24.4,  1.9}, {90, 0, 0}},
			{0x9e4d88ca, { 2.9, -24.4,  1.9}, {90, 0, 0}},
			{0x9e4d88ca, {   6,   -24, -0.8}, {90, 0, 0}},
			{0x9e4d88ca, {-2.7, -24.4, -3.9}, {90, 0, 0}},
			{0x9e4d88ca, { 3.1, -24.4, -3.9}, {90, 0, 0}},
			{0x5b7e4520, {0, -16.63, -1}, {90, 0, 0}},
			{0xd9621159, {0,   3.24, -0.19}, { 90, 0, 0}},
			{0xd9621159, {0, -18.81,    -1}, {-90, 0, 0}},
			{0xf697c81b, {     0,   0.7,    1.2}, {    180,      0,     90}},
			{0xf697c81b, {     0,  -9.3,    2.6}, {    180,      0,     90}},
			{0xf697c81b, { -22.5, -8.15,   1.79}, { -149.6, -124.6,     90}},
			{0xf697c81b, { -17.2, -7.99, -11.72}, {  150.4,   -124,     90}},
			{0xf697c81b, { -22.4, -7.91,   -2.8}, {    152, -54.82,   87.8}},
			{0xf697c81b, {-17.21, -8.09,  10.78}, {  -31.6,  124.1,    -90}},
			{0xf697c81b, {  17.2,    -8, -11.73}, {   -149, -124.1,   91.5}},
			{0xf697c81b, { 22.46, -8.02,  -2.57}, {   -151,    -56,   89.6}},
			{0xf697c81b, { 22.52, -8.11,   1.65}, {-148.66,  124.7, -91.15}},
			{0xf697c81b, { 17.18, -8.09,  10.74}, {  157.7, -50.51,   79.9}},
			{0xd43979f7, {0, -0.73, -2.4}, {0, 180, 0}},
			{0xd43979f7, {0, -8.84, -2.4}, {0, 180, 0}},
			}, },
		{'StarWars Star-Destroyer', {
			{970385471, 0x2F03547B, 0x9dae1398, 1030400667, 0x761E2AD3, 0x810369E2, 0x3D6AAA9B, 2655881418, 4206403457, 932490441, 350630312, 3764890420, 4057348071, 1980814227, 0x187D938D, 782665360, 94602826, 3229200997},
			{970385471, nil, nil, nil, true, 150, nil, nil, nil, nil, 80, 50},
			{0x2F03547B, { 20, -25, -24}, {-90, 0, 180}, nil, true, nil, nil, nil, 0x97F5FE8D, 1},
			{0x2F03547B, {  0, -25, -24}, {-90, 0, 180}, nil, true, nil, nil, nil, 0x97F5FE8D, 1},
			{0x2F03547B, {-20, -25, -24}, {-90, 0, 180}, nil, true, nil, nil, nil, 0x97F5FE8D, 1},
			{0x9dae1398, {0, 40, -20}},
			{1030400667, {   0, -4, 0}, nil, nil, nil, nil, nil, 5},
			{0x9dae1398, {-1.9, -4, 0}, nil, nil, nil, nil, nil, 5},
			{1030400667, {-1.9, -8, 0}, nil, nil, nil, nil, nil, 5},
			{0x9dae1398, { 1.9, -4, 0}, nil, nil, nil, nil, nil, 5},
			{1030400667, { 1.9, -8, 0}, nil, nil, nil, nil, nil, 5},
			{0x761E2AD3, {0, -15, 3.5}, nil, nil, nil, nil, nil, 5},
			{0x2F03547B, {-4.85, -16.5, 5.8}, {-90, 0, 0}, nil, true, nil, nil, 5, 0x97F5FE8D, 1},
			{0x2F03547B, { 4.85, -16.5, 5.8}, {-90, 0, 0}, nil, true, nil, nil, 5, 0x97F5FE8D, 1},
			{0x2F03547B, { -9.7, -16.5, 5.8}, {-90, 0, 0}, nil, true, nil, nil, 5, 0x97F5FE8D, 1},
			{0x2F03547B, {  9.7, -16.5, 5.8}, {-90, 0, 0}, nil, true, nil, nil, 5, 0x97F5FE8D, 1},
			{0x810369E2, {0, -15, -8}},
			{0x3D6AAA9B, { 4, -10, -12}, {90, 0, 0}},
			{0x3D6AAA9B, {-4, -10, -12}, {90, 0, 0}},
			{0x3D6AAA9B, { 4, -18, -12}, {90, 0, 0}},
			{0x3D6AAA9B, {-4, -18, -12}, {90, 0, 0}},
			{2655881418, {2,  3, 5}, nil, nil, nil, nil, 16, 2},
			{2655881418, {2, -3, 5}, nil, nil, nil, nil, 16, 2},
			{2655881418, {4,  0, 5}, nil, nil, nil, nil, 16, 2},
			{2655881418, {-2, 3, 5}, nil, nil, nil, nil, 16, 2},
			{2655881418, {-2,-3, 5}, nil, nil, nil, nil, 16, 2},
			{2655881418, {-4, 0, 5}, nil, nil, nil, nil, 16, 2},
			{2655881418, {2,  3, 5}, nil, nil, nil, nil, 16, 3},
			{2655881418, {2, -3, 5}, nil, nil, nil, nil, 16, 3},
			{2655881418, {4,  0, 5}, nil, nil, nil, nil, 16, 3},
			{2655881418, {-2, 3, 5}, nil, nil, nil, nil, 16, 3},
			{2655881418, {-2,-3, 5}, nil, nil, nil, nil, 16, 3},
			{2655881418, {-4, 0, 5}, nil, nil, nil, nil, 16, 3},
			{2655881418, {2,  3, 5}, nil, nil, nil, nil, 16, 4},
			{2655881418, {2, -3, 5}, nil, nil, nil, nil, 16, 4},
			{2655881418, {4,  0, 5}, nil, nil, nil, nil, 16, 4},
			{2655881418, {-2, 3, 5}, nil, nil, nil, nil, 16, 4},
			{2655881418, {-2,-3, 5}, nil, nil, nil, nil, 16, 4},
			{2655881418, {-4, 0, 5}, nil, nil, nil, nil, 16, 4},
			{4206403457, { 0, 0, 4}, nil, nil, nil, nil, 16, 2},
			{4206403457, { 0, 0, 4}, nil, nil, nil, nil, 16, 3},
			{4206403457, { 0, 0, 4}, nil, nil, nil, nil, 16, 4},
			{932490441, { 1,  1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 2},
			{932490441, { 1, -1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 2},
			{932490441, { 2,    0, 5}, {90, 0, 0}, nil, nil, nil, 16, 2},
			{932490441, {-1,  1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 2},
			{932490441, {-1, -1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 2},
			{932490441, {-2,    0, 5}, {90, 0, 0}, nil, nil, nil, 16, 2},
			{932490441, { 1,  1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 3},
			{932490441, { 1, -1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 3},
			{932490441, { 2,    0, 5}, {90, 0, 0}, nil, nil, nil, 16, 3},
			{932490441, {-1,  1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 3},
			{932490441, {-1, -1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 3},
			{932490441, {-2,    0, 5}, {90, 0, 0}, nil, nil, nil, 16, 3},
			{932490441, { 1,  1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 4},
			{932490441, { 1, -1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 4},
			{932490441, { 2,    0, 5}, {90, 0, 0}, nil, nil, nil, 16, 4},
			{932490441, {-1,  1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 4},
			{932490441, {-1, -1.5, 5}, {90, 0, 0}, nil, nil, nil, 16, 4},
			{932490441, {-2,    0, 5}, {90, 0, 0}, nil, nil, nil, 16, 4}, 
			{350630312, {0, 40, -30}, {0, 180, 90}},
			{350630312, {0, 40, -22.5}, {0, 180, 90}},
			{350630312, { 15.5, 5, -30}, {0, 180, 90}},
			{350630312, {-15.5, 5, -30}, {0, 180, 90}},
			{3764890420, {25, -15, -30}, {0, 0, 23}},
			{3764890420, {-25, -15, -30}, {0, 0, -23}},
			{3764890420, {25, -15, -20}, {0, 17.5, 23}},
			{3764890420, {-25, -15, -20}, {0, -17.5, -23}},
			{3764890420, {20.75, -5, -20}, {0, 17.5, 23}},
			{3764890420, {-20.75, -5, -20}, {0, -17.5, -23}},
			{3764890420, {0, 25, -22.5}, {0, 0, 0}},
			{3764890420, {0, 25, -30}, {0, 0, 0}},
			{3764890420, {0, -20, -30}, {0, 0, 0}},
			{0x3D6AAA9B, {2, 70, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {9, 54, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {16, 38, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {23, 22, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {30, 6, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {37, -10, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {44, -26, -27.2}, {0, -90, 23}},
			{0x3D6AAA9B, {2, 70, -24.4}, {0, -90, 23}},
			{0x3D6AAA9B, {9, 54, -24.4}, {0, -90, 23}},		
			{0x3D6AAA9B, {16, 38, -24.4}, {0, -90, 23}},
			{0x3D6AAA9B, {23, 22, -24.4}, {0, -90, 23}},
			{0x3D6AAA9B, {30, 6, -24.4}, {0, -90, 23}},
			{0x3D6AAA9B, {37, -10, -24.4}, {0, -90, 23}},
			{0x3D6AAA9B, {44, -26, -24.4}, {0, -90, 23}},
			{0x3D6AAA9B, {30, 6, -30}, {0, -90, 23}},
			{0x3D6AAA9B, {37, -10, -30}, {0, -90, 23}},
			{0x3D6AAA9B, {44, -26, -30}, {0, -90, 23}},
			{0x3D6AAA9B, {-2, 70, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-9, 54, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-16, 38, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-23, 22, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-30, 6, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-37, -10, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-44, -26, -27.2}, {0, 90, -23}},
			{0x3D6AAA9B, {-2, 70, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-9, 54, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-16, 38, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-23, 22, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-30, 6, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-37, -10, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-44, -26, -24.4}, {0, 90, -23}},
			{0x3D6AAA9B, {-30, 6, -30}, {0, 90, -23}},
			{0x3D6AAA9B, {-37, -10, -30}, {0, 90, -23}},
			{0x3D6AAA9B, {-44, -26, -30}, {0, 90, -23}},
			{4057348071, {20, 20, -22.5}, {0, 0, 23}},
			{4057348071, {-20, 20, -22.5}, {0, 0, -23}},
			{4057348071, {5, -15, -15}, {0, 0, 23}},
			{4057348071, {-5, -15, -15}, {0, 0, -23}},
			{4057348071, {0, 0, -15}, {0, 0, 0}},
			{4057348071, {10, -25, -15}, {0, 0, 90}},
			{4057348071, {0, -25, -15}, {0, 0, 90}},
			{4057348071, {-10, -25, -15}, {0, 0, 90}},
			{4057348071, {0, 15, -20}, {-90, 90, 0}},
			{4057348071, {15, 15, -22.5}, {-90, -60, 0}},
			{4057348071, {-15, 15, -22.5}, {-90, 60, 0}},
			{4057348071, {0, -30, -25}, {-90, 90, 0}},
			{4057348071, {15, -30, -25}, {-90, 90, 0}},
			{4057348071, {30, -30, -25}, {-90, 90, 0}},
			{4057348071, {35, -30, -25}, {-90, 90, 0}},
			{4057348071, {-15, -30, -25}, {-90, 90, 0}},
			{4057348071, {-30, -30, -25}, {-90, 90, 0}},
			{4057348071, {-35, -30, -25}, {-90, 90, 0}},
			{4057348071, {0, -30, -15}, {-90, 90, 0}},
			{4057348071, {15, -30, -17.5}, {-90, -60, 0}},
			{4057348071, {-15, -30, -17.5}, {-90, 60, 0}},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 12},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 13},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 14},
			{1980814227, {-0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, { 0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, {-0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, { 0.9,    0,  4}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, {-0.5,  0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, { 0.5, -0.8,  4}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, {-0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, { 0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, {-0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, { 0.9,    0, 12}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, {-0.5,  0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{1980814227, { 0.5, -0.8, 12}, {-90, 0, 0}, nil, nil, nil, 16, 15},
			{0x9dae1398, {   0,  -6, 3.5}, nil, nil, nil, nil, nil, 5},
			{1030400667, {   0, -10, 3.5}, nil, nil, nil, nil, nil, 5},
			{0x9dae1398, {-1.9, -10, 3.5}, nil, nil, nil, nil, nil, 5},
			{1030400667, {-1.9, -14, 3.5}, nil, nil, nil, nil, nil, 5},
			{0x9dae1398, { 1.9, -10, 3.5}, nil, nil, nil, nil, nil, 5},
			{1030400667, { 1.9, -14, 3.5}, nil, nil, nil, nil, nil, 5},
			{0x187D938D, {0, -10, 7}, nil, nil, nil, nil, nil, 5},
			{1030400667, {-10, -18, 5.5}, {0, 180,  90}, nil, nil, nil, nil, 5},
			{1030400667, { 10, -18, 5.5}, {0, 180, -90}, nil, nil, nil, nil, 5},
			{782665360, {-4.85, -16.5, 5.8}, nil, nil, nil, nil, nil, 5},
			{782665360, { 4.85, -16.5, 5.8}, nil, nil, nil, nil, nil, 5},
			{782665360, { -9.7, -16.5, 5.8}, nil, nil, nil, nil, nil, 5},
			{782665360, {  9.7, -16.5, 5.8}, nil, nil, nil, nil, nil, 5},
			{782665360, {-4.85, -16.5, 5.8}, {-90, 0, 0}, nil, nil, nil, nil, 5},
			{782665360, { 4.85, -16.5, 5.8}, {-90, 0, 0}, nil, nil, nil, nil, 5},
			{782665360, { -9.7, -16.5, 5.8}, {-90, 0, 0}, nil, nil, nil, nil, 5},
			{782665360, {  9.7, -16.5, 5.8}, {-90, 0, 0}, nil, nil, nil, nil, 5},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16, 12},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16, 12},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16, 13},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16, 13},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16, 14},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16, 14},
			{94602826, {0, 0, 3.5}, nil, nil, nil, nil, 16, 15},
			{94602826, {0, 0,  12}, nil, nil, nil, nil, 16, 15},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16, 12},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16, 12},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16, 12},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16, 13},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16, 13},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16, 13},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16, 14},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16, 14},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16, 14},
			{3229200997, {0, 0, 3.5}, nil, nil, nil, nil, 16, 15},
			{3229200997, {0, 0,  12}, nil, nil, nil, nil, 16, 15},
			{3229200997, {0, 0,  15}, nil, nil, nil, nil, 16, 15}
			},
		}
	}
}

return extData